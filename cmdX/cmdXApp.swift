//
//  cmdXApp.swift
//  cmdX
//

import SwiftUI
import AppKit
import Combine
import ServiceManagement

@main
struct cmdXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The status item lives in AppDelegate so the process doesn't quit when macOS hides it.
        Settings {
            EmptyView()
        }
    }
}

enum Preferences {
    static let hideMenuBarIcon = "cmdx.menuBarIcon.hidden"
    static let autostartConfigured = "cmdx.autostart.configured"
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let interceptor = KeyInterceptor.shared
    private let updateChecker = UpdateChecker()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var lastPopoverClose = Date.distantPast
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var visibilityObservation: NSKeyValueObservation?
    private var permissionTimer: Timer?

    private static let showSettingsNotification = Notification.Name("com.yonn2222.cmdX.showSettings")

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isAnotherInstanceRunning {
            // Another copy (e.g. a second install picked by Spotlight) is already running,
            // let it show its settings instead of silently doing nothing.
            DistributedNotificationCenter.default().postNotificationName(
                Self.showSettingsNotification, object: nil, userInfo: nil, deliverImmediately: true
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                exit(0)
            }
            return
        }

        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        observeUpdateAvailability()
        observeMenuBarIconPreference()
        setupPermissionHandling()
        configureAutostart()
        updateChecker.start()

        DistributedNotificationCenter.default().addObserver(
            forName: Self.showSettingsNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.revealSettings()
        }
    }

    private var isAnotherInstanceRunning: Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != ownPID
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Opening cmdX again while it runs is the way back to the settings when the icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealSettings()
        return false
    }

    private func revealSettings() {
        UserDefaults.standard.set(false, forKey: Preferences.hideMenuBarIcon)
        statusItem?.isVisible = true
        // Give the menu bar time to place the item. If macOS keeps it hidden
        // (System Settings > Menu Bar), fall back to a regular window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            if self.isStatusItemOnScreen {
                self.showPopover()
            } else {
                self.showSettingsWindow()
            }
        }
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
        item.behavior = [.removalAllowed]
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Preferences.hideMenuBarIcon) {
            item.isVisible = false
        } else if !item.isVisible {
            defaults.set(true, forKey: Preferences.hideMenuBarIcon)
        }
        statusItem = item

        // Keeps the preference in sync when the icon is Cmd-dragged out of the menu bar.
        visibilityObservation = item.observe(\.isVisible) { item, _ in
            let hidden = !item.isVisible
            if UserDefaults.standard.bool(forKey: Preferences.hideMenuBarIcon) != hidden {
                UserDefaults.standard.set(hidden, forKey: Preferences.hideMenuBarIcon)
            }
        }
    }

    private func makeSettingsController() -> NSViewController {
        let hostingController = NSHostingController(
            rootView: ContentView()
                .environmentObject(interceptor)
                .environmentObject(updateChecker)
        )
        hostingController.sizingOptions = .preferredContentSize
        return hostingController
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = makeSettingsController()
        self.popover = popover
    }

    private var isStatusItemOnScreen: Bool {
        guard let item = statusItem, item.isVisible, let window = item.button?.window, window.isVisible else {
            return false
        }
        return NSScreen.screens.contains { $0.frame.intersects(window.frame) }
    }

    private func showSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: makeSettingsController())
            window.title = "cmdX"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func observeUpdateAvailability() {
        updateChecker.$isUpdateAvailable
            .receive(on: RunLoop.main)
            .sink { [weak self] available in
                self?.statusItem?.button?.contentTintColor = available ? .systemRed : nil
            }
            .store(in: &cancellables)
    }

    private func observeMenuBarIconPreference() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .map { _ in UserDefaults.standard.bool(forKey: Preferences.hideMenuBarIcon) }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] hidden in
                guard let self, let item = self.statusItem, item.isVisible == hidden else { return }
                if hidden {
                    self.popover?.performClose(nil)
                }
                item.isVisible = !hidden
            }
            .store(in: &cancellables)
    }

    @objc private func togglePopover() {
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else if Date().timeIntervalSince(lastPopoverClose) > 0.25 {
            // The same click that closed the transient popover must not reopen it.
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        startEventMonitoring()
    }

    private func startEventMonitoring() {
        stopEventMonitoring()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let popover = self?.popover, popover.isShown else { return }
            DispatchQueue.main.async {
                popover.performClose(nil)
            }
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let popover = self.popover, popover.isShown else { return event }
            if let window = event.window,
               window != popover.contentViewController?.view.window,
               window != self.statusItem?.button?.window {
                popover.performClose(nil)
            }
            return event
        }
    }

    private func stopEventMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        lastPopoverClose = Date()
        stopEventMonitoring()
    }

    // MARK: - Accessibility

    private func setupPermissionHandling() {
        if !interceptor.refreshPermissionStatus() {
            interceptor.promptForAccessibilityPermission()
        }
        syncInterceptorWithPermission()

        // Posted whenever any app's Accessibility access changes. TCC updates slightly
        // after the notification, hence the delay.
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.syncInterceptorWithPermission()
            }
        }
    }

    // Revoking access kills the tap silently, so it is dropped and recreated on re-grant.
    // Polling only runs while access is missing.
    private func syncInterceptorWithPermission() {
        let granted = interceptor.refreshPermissionStatus()
        if granted && !interceptor.isRunning {
            interceptor.start()
        } else if !granted && interceptor.isRunning {
            interceptor.stop()
        }

        if granted {
            permissionTimer?.invalidate()
            permissionTimer = nil
        } else if permissionTimer == nil {
            let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.syncInterceptorWithPermission()
            }
            timer.tolerance = 0.5
            RunLoop.main.add(timer, forMode: .common)
            permissionTimer = timer
        }
    }

    // MARK: - Autostart

    private func configureAutostart() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Preferences.autostartConfigured) else { return }

        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("cmdX: failed to register login item - \(error.localizedDescription)")
        }
        defaults.set(true, forKey: Preferences.autostartConfigured)
    }
}
