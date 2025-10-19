//
//  ContentView.swift
//  cmdX
//
//  Created by Y-n on 2024/07/14.
//

import SwiftUI
import AppKit
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var keyInterceptor: KeyInterceptor
    @EnvironmentObject var updateChecker: UpdateChecker

    // MARK: - State
    @State private var autoLaunch: Bool = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: App icon + name
            HStack(alignment: .center, spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                    .accessibilityHidden(true)

                Text("cmdX")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .accessibilityLabel("App name: cmdX")
            }

            // Description
            Text("Cut and move files in Finder with familiar shortcuts: press Command-X to mark files, then Command-V to move them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Controls
            VStack(alignment: .leading, spacing: 12) {
                Button(action: openAccessibilitySettings) {
                    Text("Open Accessibility Settings")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .help("Grant Accessibility permission so cmdX can listen for shortcuts and trigger Move in Finder.")

                Toggle(isOn: $autoLaunch) {
                    Text("Start automatically on launch")
                }
                .toggleStyle(.checkbox)
                .onChange(of: autoLaunch) { newValue in
                    if #available(macOS 13.0, *) {
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            UserDefaults.standard.set(newValue, forKey: "cmdx.autostart.enabled")
                        } catch {
                            // Revert toggle if the operation failed
                            autoLaunch = !newValue
                            NSLog("cmdX: Failed to update Login Item: \(error.localizedDescription)")
                        }
                    } else {
                        setLaunchAtLogin(enabled: newValue)
                        UserDefaults.standard.set(newValue, forKey: "cmdx.autostart.enabled")
                    }
                }
                .help("Start cmdX when you log in to your Mac.")
            }

            Divider()

            HStack(spacing: 12) {
                Button("Search for Updates") {
                    updateChecker.checkForUpdates(manualCheck: true)
                }
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 520, height: 280)
        // Use the system window background so text and controls pick appropriate colors in light/dark mode
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            // Initialize autostart toggle
            if #available(macOS 13.0, *) {
                // Prefer stored preference if available
                if UserDefaults.standard.object(forKey: "cmdx.autostart.enabled") != nil {
                    autoLaunch = UserDefaults.standard.bool(forKey: "cmdx.autostart.enabled")
                } else {
                    autoLaunch = (SMAppService.mainApp.status == .enabled)
                }
            } else {
                if UserDefaults.standard.object(forKey: "cmdx.autostart.enabled") != nil {
                    autoLaunch = UserDefaults.standard.bool(forKey: "cmdx.autostart.enabled")
                } else {
                    autoLaunch = isLoginItemInstalled()
                }
            }
        }
    }

    // MARK: - Actions
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Launch at Login via LaunchAgent
    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.yourcompany.commandX"
    }

    private func launchAgentPlistPath() -> URL {
        let fm = FileManager.default
        let agents = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        try? fm.createDirectory(at: agents, withIntermediateDirectories: true, attributes: nil)
        return agents.appendingPathComponent("\(bundleIdentifier).loginitem.plist")
    }

    private func isLoginItemInstalled() -> Bool {
        let path = launchAgentPlistPath().path
        return FileManager.default.fileExists(atPath: path)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(KeyInterceptor.shared)
            .environmentObject(UpdateChecker())
            .frame(width: 520, height: 280)
    }
}

