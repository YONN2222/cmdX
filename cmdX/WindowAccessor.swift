import SwiftUI
import AppKit

/// A small NSViewRepresentable that gives access to the hosting NSWindow.
/// The provided closure is called when the view is attached to a window.
struct WindowAccessor: NSViewRepresentable {
    var onAppear: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        // If the view is already in a window (rare), call immediately on next runloop.
        DispatchQueue.main.async {
            if let w = view.window {
                onAppear(w)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Each update try to call the closure if attached to a window.
        DispatchQueue.main.async {
            if let w = nsView.window {
                onAppear(w)
            }
        }
    }
}
