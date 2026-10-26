//
//  ContentView.swift
//  cmdX
//

import SwiftUI
import AppKit
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var keyInterceptor: KeyInterceptor
    @EnvironmentObject var updateChecker: UpdateChecker

    @AppStorage(Preferences.hideMenuBarIcon) private var hideMenuBarIcon = false
    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("cmdX")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Cut and move files in Finder with familiar shortcuts: press Command-X to mark files, then Command-V to move them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            permissionStatusView

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Start automatically at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
                    .help("Start cmdX when you log in to your Mac.")

                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Hide menu bar icon", isOn: $hideMenuBarIcon)
                    Text("cmdX keeps running. Open cmdX again from Applications or Spotlight to show the icon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 20)
                }

                Picker("Check for updates", selection: $updateChecker.frequency) {
                    ForEach(UpdateCheckFrequency.allCases) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }
                .fixedSize()
                .help("How often cmdX looks for new releases on GitHub.")
            }
            .toggleStyle(.checkbox)

            Divider()

            HStack(spacing: 12) {
                Button("Check for Updates Now") {
                    updateChecker.checkForUpdates(manualCheck: true)
                }

                Spacer()

                Button("Quit cmdX") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 440)
        .onAppear {
            keyInterceptor.refreshPermissionStatus()
            launchAtLogin = isLaunchAtLoginEnabled
        }
    }

    private var permissionStatusView: some View {
        let granted = keyInterceptor.hasAccessibilityPermission
        let tint: Color = granted ? .green : .orange

        return HStack(spacing: 10) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(granted ? "Accessibility access granted" : "Accessibility access needed")
                    .font(.subheadline.weight(.semibold))
                Text(granted
                     ? "cmdX can handle Command-X and Command-V in Finder."
                     : "cmdX can't handle shortcuts until you allow it in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if granted {
                Button("Settings…", action: openAccessibilitySettings)
            } else {
                Button("Grant Access…") {
                    keyInterceptor.promptForAccessibilityPermission()
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(tint.opacity(0.45)))
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var isLaunchAtLoginEnabled: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard enabled != isLaunchAtLoginEnabled else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("cmdX: failed to update login item - \(error.localizedDescription)")
            launchAtLogin = isLaunchAtLoginEnabled
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(KeyInterceptor.shared)
        .environmentObject(UpdateChecker())
}
