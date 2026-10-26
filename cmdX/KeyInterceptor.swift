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

    private var cutPasteboardState = CutPasteboardState()

    fileprivate static let syntheticMarker: Int64 = 0x636D_6458

    init() {}

    func start() {
        guard eventTap == nil else { return }

        // A keyboard event tap requires Accessibility permission. Without it,
        // tapCreate fails silently — so check first, publish the status for the
        // UI, and bail out cleanly until the user grants access.
        guard AXIsProcessTrusted() else {
            if hasAccessibilityPermission { hasAccessibilityPermission = false }
            NSLog("cmdX: accessibility permission not granted; event tap not started")
            return
        }
        if !hasAccessibilityPermission { hasAccessibilityPermission = true }

        // Prevent App Nap. When the menu bar icon is hidden the app has no
        // visible UI, so macOS would otherwise throttle it — which makes the
        // event-tap callback time out and the system disables the tap. Holding
        // this activity token keeps the app responsive while still allowing the
        // Mac to sleep normally when idle.
        if activityToken == nil {
            activityToken = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiatedAllowingIdleSystemSleep,
                          .suddenTerminationDisabled,
                          .automaticTerminationDisabled],
                reason: "cmdX intercepts keyboard shortcuts globally and must stay responsive even with no visible UI"
            )
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.flagsChanged.rawValue)

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
            NSLog("cmdX: failed to create event tap - grant Accessibility access in System Settings > Privacy & Security")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isRunning = true
            NSLog("cmdX: event tap started")
        }
    }

    /// Re-reads the current Accessibility trust status and publishes any change.
    @discardableResult
    func refreshPermissionStatus() -> Bool {
        let trusted = AXIsProcessTrusted()
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
        }
        return trusted
    }

    /// Asks macOS to show the Accessibility permission prompt for this app.
    /// (The system dialog only appears if access hasn't been decided yet;
    /// otherwise this just refreshes the published status.)
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
        // The system disables active event taps when the callback is too slow
        // (e.g. under App Nap) or on certain user input. When that happens it
        // notifies us with these event types — re-enable the tap or it stays
        // dead forever, which is exactly what made cmdX stop working when hidden.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = shared.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                NSLog("cmdX: event tap re-enabled after \(type == .tapDisabledByTimeout ? "timeout" : "user input")")
            }
            return nil
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == syntheticMarker {
            return Unmanaged.passUnretained(event)
        }

        guard isFrontmostAppFinder() else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        guard flags.contains(.maskCommand),
              !flags.contains(.maskAlternate),
              !flags.contains(.maskControl) else {
            return Unmanaged.passUnretained(event)
        }

        switch CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)) {
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
