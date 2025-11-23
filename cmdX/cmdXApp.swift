//
//  commandXApp.swift
//  commandX
//

import SwiftUI
import AppKit
import ServiceManagement
import UserNotifications

@main
struct cmdXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegateWrapper.self) var appDelegate
    @StateObject private var keyInterceptor = KeyInterceptor()
    @StateObject private var updateChecker = UpdateChecker()
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    init() {
        setupKeyInterceptor()
        setupUpdateChecker()
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(keyInterceptor)
                .environmentObject(updateChecker)
                .onAppear {
                    self.appDelegate.updateChecker = self.updateChecker
                }
        } label: {
            HStack {
                Image(systemName: "command")
                if updateChecker.isUpdateAvailable {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 8))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupKeyInterceptor() {
        DispatchQueue.main.async {
            self.keyInterceptor.start()
        }
    }
    
    private func setupUpdateChecker() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("DEBUG: Notification permission granted")
            } else {
                print("DEBUG: Notification permission denied: \(error?.localizedDescription ?? "unknown")")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("DEBUG: Starting initial update check...")
            self.updateChecker.checkForUpdates()
        }
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                print("DEBUG: Hourly update check...")
                self.updateChecker.checkForUpdates()
            }
        }
    }
}

class AppDelegateWrapper: NSObject, NSApplicationDelegate {
    var updateChecker: UpdateChecker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let interceptor = KeyInterceptor.shared
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        NSApp.setActivationPolicy(.accessory)
        interceptor.start()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use white Command symbol (⌘) as icon
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "command", accessibilityDescription: "cmdX")
            button.image = image?.withSymbolConfiguration(config)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 520, height: 280)
        popover?.behavior = .transient
    popover?.delegate = self
        popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(interceptor))

        let defaults = UserDefaults.standard
        let configuredKey = "cmdx.autostart.configured"
        if !defaults.bool(forKey: configuredKey) {
            if #available(macOS 13.0, *) {
                do {
                    try SMAppService.mainApp.register()
                    defaults.set(true, forKey: "cmdx.autostart.enabled")
                } catch {
                    setLaunchAtLogin(enabled: true)
                    defaults.set(true, forKey: "cmdx.autostart.enabled")
                }
            } else {
                setLaunchAtLogin(enabled: true)
                defaults.set(true, forKey: "cmdx.autostart.enabled")
            }
            defaults.set(true, forKey: configuredKey)
        }

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

    private func startEventMonitoring() {
        stopEventMonitoring()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let popover = self.popover, popover.isShown else { return }
            DispatchQueue.main.async {
                popover.performClose(nil)
            }
        }

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

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitoring()
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.yonn2222.cmdX"
    }

    private func launchAgentPlistPath() -> URL {
        let fm = FileManager.default
        let agents = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        try? fm.createDirectory(at: agents, withIntermediateDirectories: true, attributes: nil)
        return agents.appendingPathComponent("\(bundleIdentifier).loginitem.plist")
    }

    private func setLaunchAtLogin(enabled: Bool) {
        let fm = FileManager.default
        let plistURL = launchAgentPlistPath()
        if enabled {
            let executable = (Bundle.main.infoDictionary?["CFBundleExecutable"] as? String) ?? "commandX"
            let exePath = Bundle.main.bundlePath + "/Contents/MacOS/" + executable
            let dict: [String: Any] = [
                "Label": bundleIdentifier,
                "ProgramArguments": [exePath],
                "RunAtLoad": true
            ]
            if let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
                try? data.write(to: plistURL)
            }
        } else {
            try? fm.removeItem(at: plistURL)
        }
    }

}
