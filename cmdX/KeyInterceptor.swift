import Cocoa
import Combine

final class KeyInterceptor: ObservableObject {
    static let shared = KeyInterceptor()

    @Published private(set) var isRunning = false
    @Published private(set) var lastActionWasCut = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var cutPending = false

    fileprivate static let syntheticMarker: Int64 = 0x636D_6458

    init() {}

    func start() {
        guard eventTap == nil else { return }

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
        cutPending = false
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
            shared.cutPending = true
            shared.publishCutState(true)
            postShortcut(keyCode: Keycode.c, flags: [.maskCommand])
            return nil

        case Keycode.c:
            shared.cutPending = false
            shared.publishCutState(false)
            return Unmanaged.passUnretained(event)

        case Keycode.v:
            guard shared.cutPending else {
                return Unmanaged.passUnretained(event)
            }
            shared.cutPending = false
            shared.publishCutState(false)
            postShortcut(keyCode: Keycode.v, flags: [.maskCommand, .maskAlternate])
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func publishCutState(_ value: Bool) {
        DispatchQueue.main.async {
            self.lastActionWasCut = value
        }
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
