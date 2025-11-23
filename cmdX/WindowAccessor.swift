import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    var onAppear: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let w = view.window {
                onAppear(w)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let w = nsView.window {
                onAppear(w)
            }
        }
    }
}
