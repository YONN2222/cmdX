import Cocoa
import Combine
import ApplicationServices

final class KeyInterceptor: ObservableObject {
    static let shared = KeyInterceptor()

    @Published private(set) var isRunning = false
    @Published private(set) var lastActionWasCut = false
    @Published private(set) var hasAccessibilityPermission: Bool = AXIsProcessTrusted()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activityToken: NSObjectProtocol?
    private var didLogTapFailure = false

    private var cutPasteboardState = CutPasteboardState()

    fileprivate static let syntheticMarker: Int64 = 0x636D_6458

    init() {}

    func start() {
        guard eventTap == nil else { return }

        guard refreshPermissionStatus() else {
            NSLog("cmdX: accessibility permission not granted, event tap not started")
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            return KeyInterceptor.handleEvent(proxy: proxy, type: type, event: event)
        }

        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: mask,
                                     callback: callback,
                                     userInfo: nil)

        guard let eventTap = eventTap else {
            guard !didLogTapFailure else { return }
            didLogTapFailure = true
            NSLog("cmdX: failed to create event tap - grant Accessibility access in System Settings > Privacy & Security")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isRunning = true
            didLogTapFailure = false
            beginBackgroundActivity()
            NSLog("cmdX: event tap started")
        }
    }

    // Without visible UI macOS puts the app into App Nap, the tap callback then times out
    // and the system disables the tap. Idle system sleep stays allowed.
    private func beginBackgroundActivity() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .suddenTerminationDisabled, .automaticTerminationDisabled],
            reason: "cmdX intercepts Finder shortcuts and has to stay responsive without visible UI"
        )
    }

    @discardableResult
    func refreshPermissionStatus() -> Bool {
        let trusted = AXIsProcessTrusted()
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
        }
        return trusted
    }

    // The system dialog only appears while access is undecided.
    func promptForAccessibilityPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
        }
    }

    func stop() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
        isRunning = false
        cancelCut()
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
        NSLog("cmdX: event tap stopped")
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = shared.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                NSLog("cmdX: event tap re-enabled after \(type == .tapDisabledByTimeout ? "timeout" : "user input")")
            }
            return nil
        }

        // Cheapest checks first: this runs for every keystroke system-wide.
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        guard flags.contains(.maskCommand),
              !flags.contains(.maskAlternate),
              !flags.contains(.maskControl) else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == Keycode.x || keyCode == Keycode.c || keyCode == Keycode.v,
              event.getIntegerValueField(.eventSourceUserData) != syntheticMarker,
              isFrontmostAppFinder() else {
            return Unmanaged.passUnretained(event)
        }

        switch keyCode {
        case Keycode.x:
            shared.beginCut()
            postShortcut(keyCode: Keycode.c, flags: [.maskCommand])
            return nil

        case Keycode.c:
            shared.cancelCut()
            return Unmanaged.passUnretained(event)

        case Keycode.v:
            guard shared.consumeCutIfPasteboardIsCurrent() else {
                return Unmanaged.passUnretained(event)
            }
            postShortcut(keyCode: Keycode.v, flags: [.maskCommand, .maskAlternate])
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func beginCut() {
        cutPasteboardState.begin(currentChangeCount: NSPasteboard.general.changeCount)
        publishCutState(true)
    }

    private func cancelCut() {
        cutPasteboardState.cancel()
        publishCutState(false)
    }

    private func consumeCutIfPasteboardIsCurrent() -> Bool {
        let shouldMove = cutPasteboardState.consume(
            currentChangeCount: NSPasteboard.general.changeCount
        )
        publishCutState(false)
        return shouldMove
    }

    private func publishCutState(_ value: Bool) {
        DispatchQueue.main.async {
            self.lastActionWasCut = value
        }
    }
}

struct CutPasteboardState {
    private var expectedChangeCount: Int?

    mutating func begin(currentChangeCount: Int) {
        // Finder takes pasteboard ownership once when it handles the synthetic Cmd-C.
        expectedChangeCount = currentChangeCount &+ 1
    }

    mutating func cancel() {
        expectedChangeCount = nil
    }

    mutating func consume(currentChangeCount: Int) -> Bool {
        defer { cancel() }
        return expectedChangeCount == currentChangeCount
    }
}

private enum Keycode {
    static let x: CGKeyCode = 7
    static let c: CGKeyCode = 8
    static let v: CGKeyCode = 9
}

private func isFrontmostAppFinder() -> Bool {
    if let front = NSWorkspace.shared.frontmostApplication {
        return front.bundleIdentifier == "com.apple.finder"
    }
    return false
}

private func postShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
    let src = CGEventSource(stateID: .hidSystemState)
    guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
          let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) else {
        NSLog("cmdX: failed to synthesize keystroke \(keyCode)")
        return
    }

    for event in [keyDown, keyUp] {
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: KeyInterceptor.syntheticMarker)
    }

    keyDown.post(tap: .cgAnnotatedSessionEventTap)
    keyUp.post(tap: .cgAnnotatedSessionEventTap)
}
