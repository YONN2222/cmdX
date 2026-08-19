import Cocoa
import Carbon
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
            NSLog("cmdX: failed to create event tap - make sure Input Monitoring is allowed")
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
        let isCmd = flags.contains(.maskCommand)

        if let chars = event.keyboardGetUnicodeString() {
            let s = chars.lowercased()
            if isCmd && s == "x" {
                shared.cutPending = true
                shared.publishCutState(true)
                postShortcut(keyCode: kVK_ANSI_C, flags: [.maskCommand])
                return nil
            }
            if isCmd && s == "c" {
                shared.cutPending = false
                shared.publishCutState(false)
                return Unmanaged.passUnretained(event)
            }
            if isCmd && s == "v" {
                guard shared.cutPending else {
                    return Unmanaged.passUnretained(event)
                }
                shared.cutPending = false
                shared.publishCutState(false)
                postShortcut(keyCode: kVK_ANSI_V, flags: [.maskCommand, .maskAlternate])
                return nil
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func publishCutState(_ value: Bool) {
        DispatchQueue.main.async {
            self.lastActionWasCut = value
        }
    }
}


private extension CGEvent {
    func keyboardGetUnicodeString() -> String? {
        let length: Int = 4
        var chars = [UniChar](repeating: 0, count: length)
        var actualLength: Int = 0
        self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &actualLength, unicodeString: &chars)
        if actualLength > 0 {
            return String(utf16CodeUnits: chars, count: actualLength)
        }
        return nil
    }
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

private let kVK_ANSI_X: CGKeyCode = 7
private let kVK_ANSI_C: CGKeyCode = 8
private let kVK_ANSI_V: CGKeyCode = 9
