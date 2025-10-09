//
//  commandXApp.swift
//  commandX
//

import SwiftUI
import AppKit

@main
struct commandXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let interceptor = KeyInterceptor.shared
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // If another instance of this app is already running, activate it and exit.
        if let bundleID = Bundle.main.bundleIdentifier {
            let ownPID = ProcessInfo.processInfo.processIdentifier
            let others = NSWorkspace.shared.runningApplications.filter { app in
                app.bundleIdentifier == bundleID && app.processIdentifier != ownPID
            }
            if let other = others.first {
                other.activate(options: [.activateIgnoringOtherApps])
                exit(0)
            }
        }
        
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Start the global event tap
        interceptor.start()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use white Command symbol (⌘) as icon
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "command", accessibilityDescription: "cmdX")
            button.image = image?.withSymbolConfiguration(config)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 520, height: 260)
        popover?.behavior = .transient
    popover?.delegate = self
        popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(interceptor))

    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    startEventMonitoring()
                }
            }
        }
    }

    // MARK: - Event monitoring to handle clicks outside the popover reliably
    private func startEventMonitoring() {
        stopEventMonitoring()

        // Global monitor (for clicks outside the app)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let popover = self.popover, popover.isShown else { return }
            DispatchQueue.main.async {
                popover.performClose(nil)
            }
        }

        // Local monitor (for clicks inside the app but outside the popover)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let popover = self.popover, popover.isShown else { return event }
            if let win = event.window, win != popover.contentViewController?.view.window {
                popover.performClose(nil)
            }
            return event
        }
    }

    private func stopEventMonitoring() {
        if let g = globalEventMonitor {
            NSEvent.removeMonitor(g)
            globalEventMonitor = nil
        }
        if let l = localEventMonitor {
            NSEvent.removeMonitor(l)
            localEventMonitor = nil
        }
    }

    // NSPopoverDelegate
    func popoverDidClose(_ notification: Notification) {
        stopEventMonitoring()
    }

}
