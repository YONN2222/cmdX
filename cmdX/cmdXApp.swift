//
//  cmdXApp.swift
//  cmdX
//

import SwiftUI
import AppKit
import Combine
import ServiceManagement
import UserNotifications

@main
struct cmdXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The app's lifetime is anchored to this background agent + its run loop,
        // NOT to the menu bar item. That is the whole fix: the menu bar icon is a
        // classic `NSStatusItem` (created in AppDelegate), so when macOS 26 hides
        // or removes it, the icon disappears but the process — and the key
        // interceptor — keeps running. This empty `Settings` scene only satisfies
        // the `App` protocol; it shows nothing.
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let interceptor = KeyInterceptor.shared
    let updateChecker = UpdateChecker()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var updateCancellable: AnyCancellable?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance guard: if another copy is already running, defer to it.
        if let bundleID = Bundle.main.bundleIdentifier {
            let ownPID = ProcessInfo.processInfo.processIdentifier
            let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == bundleID && $0.processIdentifier != ownPID
            }
            if alreadyRunning {
                exit(0)
            }
        }

        // Run as a background agent: no Dock icon, no app-switcher entry.
        NSApp.setActivationPolicy(.accessory)

        // The whole point of the app. It is started here — independent of the
        // menu bar item — so it keeps running even if the icon is hidden.
        interceptor.start()

        setupStatusItem()
        setupPopover()
        observeUpdateAvailability()
        setupPermissionHandling()

        configureAutostart()
        setupUpdateChecking()
    }

    // Never quit just because a window closed (e.g. the Settings window). The
    // status item being hidden does not close a window, but this guarantees the
    // agent — and the key interceptor — stays alive regardless.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Menu bar item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "command", accessibilityDescription: "cmdX")
            button.image = image?.withSymbolConfiguration(config)
            button.action = #selector(togglePopover)
            button.target = self
        }
        // Let the user hide it from the menu bar without quitting the app.
        item.behavior = [.removalAllowed]
        statusItem = item
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 520, height: 360)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(interceptor)
                .environmentObject(updateChecker)
        )
        self.popover = popover
    }

    /// Turns the menu bar icon red when an update is available (the old red dot).
    private func observeUpdateAvailability() {
        updateCancellable = updateChecker.$isUpdateAvailable
            .receive(on: RunLoop.main)
            .sink { [weak self] available in
                self?.statusItem?.button?.contentTintColor = available ? .systemRed : nil
            }
    }

    /// On launch, verifies Accessibility permission and prompts if it's missing.
    /// Then polls so the popover's status stays live and the interceptor starts
    /// automatically the moment the user grants access (no relaunch needed).
    private func setupPermissionHandling() {
        if !interceptor.refreshPermissionStatus() {
            interceptor.promptForAccessibilityPermission()
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let granted = self.interceptor.refreshPermissionStatus()
            if granted && !self.interceptor.isRunning {
                self.interceptor.start()
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            startEventMonitoring()
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

    // MARK: - Autostart

    private func configureAutostart() {
        let defaults = UserDefaults.standard
        let configuredKey = "cmdx.autostart.configured"
        guard !defaults.bool(forKey: configuredKey) else { return }

        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                setLaunchAtLogin(enabled: true)
            }
        } else {
            setLaunchAtLogin(enabled: true)
        }
        defaults.set(true, forKey: "cmdx.autostart.enabled")
        defaults.set(true, forKey: configuredKey)
    }

    // MARK: - Update checking

    private func setupUpdateChecking() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if !granted {
                print("DEBUG: Notification permission denied: \(error?.localizedDescription ?? "unknown")")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.updateChecker.checkForUpdates()
        }

        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateChecker.checkForUpdates()
        }
    }

    // MARK: - Launch at login fallback (pre-macOS 13)

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
            let executable = (Bundle.main.infoDictionary?["CFBundleExecutable"] as? String) ?? "cmdX"
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
