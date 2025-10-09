import Cocoa
import Carbon
import Combine

final class KeyInterceptor: ObservableObject {
    static let shared = KeyInterceptor()

    @Published private(set) var isRunning = false
    @Published private(set) var lastActionWasCut = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

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
            NSLog("commandX: failed to create event tap — make sure Input Monitoring is allowed")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isRunning = true
            NSLog("commandX: event tap started")
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
        NSLog("commandX: event tap stopped")
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Only handle keyDown events
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // Check frontmost app is Finder
        if !isFrontmostAppFinder() {
            return Unmanaged.passUnretained(event)
        }

        // Get keycode and flags
        let flags = event.flags

        // Ignore events we simulated ourselves
        if KeyInterceptor.isPosting {
            return Unmanaged.passUnretained(event)
        }

        // We'll check for Cmd+X (cut), Cmd+C (copy), Cmd+V (paste)
        let isCmd = flags.contains(.maskCommand)

        // keycodes for X, C, V (US layout)
        // X = 7, C = 8, V = 9 on many macs, but keycodes can vary between keyboards.
        // Use Unicode mapping instead: get the characters
        if let chars = event.keyboardGetUnicodeString() {
            let s = chars.lowercased()
            if isCmd && s == "x" {
                // Intercept Cmd+X: perform Cmd+C and set cut state
                KeyInterceptor.isPosting = true
                postKeySequence(copyOnly: true)
                KeyInterceptor.isPosting = false
                shared.setCutState(true)
                // Swallow original event
                return nil
            }
            if isCmd && s == "c" {
                // If user copies after a cut, clear cut state
                shared.setCutState(false)
                return Unmanaged.passUnretained(event)
            }
            if isCmd && s == "v" {
                if shared.lastActionWasCut {
                    // simulate Option+Cmd+V (Move)
                    KeyInterceptor.isPosting = true
                    postKeySequence(pasteMove: true)
                    KeyInterceptor.isPosting = false
                    shared.setCutState(false)
                    return nil
                }
                return Unmanaged.passUnretained(event)
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func setCutState(_ v: Bool) {
        DispatchQueue.main.async {
            self.lastActionWasCut = v
        }
    }

    // Helpers to post key events programmatically
    private static func postKeySequence(copyOnly: Bool = false, pasteMove: Bool = false) {
        if copyOnly {
            // Post Cmd+C
            postShortcut(keyCode: kVK_ANSI_C, flags: [.maskCommand])
            return
        }
        if pasteMove {
            // Post Option+Cmd+V
            postShortcut(keyCode: kVK_ANSI_V, flags: [.maskCommand, .maskAlternate])
            return
        }
    }
}

// MARK: - Utilities

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

// Post key shortcut using Quartz virtual keycodes
private func postShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
    let src = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = flags
    let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = flags
    keyDown?.post(tap: .cgAnnotatedSessionEventTap)
    keyUp?.post(tap: .cgAnnotatedSessionEventTap)
}

// Minimal Virtual keycode constants (from <HIToolbox/Events.h>)
private let kVK_ANSI_X: CGKeyCode = 7
private let kVK_ANSI_C: CGKeyCode = 8
private let kVK_ANSI_V: CGKeyCode = 9

extension KeyInterceptor {
    // flag used to avoid processing events we synthesize
    fileprivate static var isPosting = false
}
