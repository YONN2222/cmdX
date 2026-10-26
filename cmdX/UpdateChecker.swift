import AppKit
import Combine
import UserNotifications

enum UpdateCheckFrequency: String, CaseIterable, Identifiable {
    case never
    case hourly
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .never: "Never"
        case .hourly: "Hourly"
        case .daily: "Daily"
        case .weekly: "Weekly"
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .never: nil
        case .hourly: 3600
        case .daily: 86_400
        case .weekly: 604_800
        }
    }
}

final class UpdateChecker: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var isUpdateAvailable = false
    @Published var frequency: UpdateCheckFrequency {
        didSet { UserDefaults.standard.set(frequency.rawValue, forKey: Self.frequencyKey) }
    }

    private static let frequencyKey = "cmdx.updateCheck.frequency"
    private static let legacyEnabledKey = "cmdx.updateCheck.enabled"
    private static let lastCheckKey = "cmdx.updateCheck.lastCheck"
    private static let lastNotifiedVersionKey = "cmdx.updateCheck.lastNotifiedVersion"
    private static let latestReleaseAPI = URL(string: "https://api.github.com/repos/YONN2222/cmdX/releases/latest")!
    private static let releasesPage = URL(string: "https://github.com/YONN2222/cmdX/releases/latest")!

    private var latestVersionURL: URL?
    private var schedulerTimer: Timer?

    override init() {
        frequency = Self.storedFrequency()
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    private static func storedFrequency() -> UpdateCheckFrequency {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: frequencyKey), let stored = UpdateCheckFrequency(rawValue: raw) {
            return stored
        }
        if defaults.object(forKey: legacyEnabledKey) != nil, !defaults.bool(forKey: legacyEnabledKey) {
            return .never
        }
        return .daily
    }

    func start() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                NSLog("cmdX: notification authorization failed - \(error.localizedDescription)")
            } else if !granted {
                NSLog("cmdX: notifications not allowed, falling back to alerts")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.checkIfDue()
        }

        // Short enough for the hourly option, and catches up after the Mac was asleep.
        let timer = Timer(timeInterval: 900, repeats: true) { [weak self] _ in
            self?.checkIfDue()
        }
        timer.tolerance = 120
        RunLoop.main.add(timer, forMode: .common)
        schedulerTimer = timer
    }

    private func checkIfDue() {
        guard let interval = frequency.interval else { return }
        if let lastCheck = UserDefaults.standard.object(forKey: Self.lastCheckKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastCheck)
            if elapsed >= 0 && elapsed < interval {
                return
            }
        }
        checkForUpdates()
    }

    func checkForUpdates(manualCheck: Bool = false) {
        URLSession.shared.dataTask(with: Self.latestReleaseAPI) { data, response, error in
            DispatchQueue.main.async {
                self.handleResponse(data: data, response: response, error: error, manualCheck: manualCheck)
            }
        }.resume()
    }

    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, manualCheck: Bool) {
        if let error {
            return handleFailure(error.localizedDescription, manualCheck: manualCheck)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            return handleFailure("invalid response", manualCheck: manualCheck)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            return handleFailure("GitHub returned HTTP \(httpResponse.statusCode)", manualCheck: manualCheck)
        }
        guard let data, let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else {
            return handleFailure("response could not be decoded", manualCheck: manualCheck)
        }

        UserDefaults.standard.set(Date(), forKey: Self.lastCheckKey)

        let latestVersion = Self.normalizedVersion(release.tagName)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        latestVersionURL = URL(string: release.htmlURL)

        guard Self.isVersion(latestVersion, newerThan: currentVersion) else {
            isUpdateAvailable = false
            if manualCheck {
                showAlert(title: "No Update Available", message: "You are already using the latest version of cmdX (\(currentVersion)).")
            }
            return
        }

        isUpdateAvailable = true

        if manualCheck {
            showUpdateAlert(version: latestVersion)
            return
        }

        guard UserDefaults.standard.string(forKey: Self.lastNotifiedVersionKey) != latestVersion else { return }
        notifyAboutUpdate(version: latestVersion)
    }

    private func handleFailure(_ reason: String, manualCheck: Bool) {
        NSLog("cmdX: update check failed - \(reason)")
        guard manualCheck else { return }
        showAlert(
            title: "Unable to Check for Updates",
            message: "cmdX couldn't check for updates. Check your internet connection and try again.",
            style: .warning
        )
    }

    static func normalizedVersion(_ tag: String) -> String {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        return trimmed.lowercased().hasPrefix("v") ? String(trimmed.dropFirst()) : trimmed
    }

    static func isVersion(_ latest: String, newerThan current: String) -> Bool {
        let latestParts = latest.split(separator: ".").map { Int($0) ?? 0 }
        let currentParts = current.split(separator: ".").map { Int($0) ?? 0 }

        for index in 0..<max(latestParts.count, currentParts.count) {
            let latestPart = index < latestParts.count ? latestParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if latestPart != currentPart {
                return latestPart > currentPart
            }
        }
        return false
    }

    // MARK: - Presentation

    private func notifyAboutUpdate(version: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.sendNotification(version: version)
                case .denied:
                    UserDefaults.standard.set(version, forKey: Self.lastNotifiedVersionKey)
                    self.showUpdateAlert(version: version)
                default:
                    // The permission prompt is still open, try again on the next check.
                    break
                }
            }
        }
    }

    private func sendNotification(version: String) {
        let content = UNMutableNotificationContent()
        content.title = "cmdX \(version) is available"
        content.body = "Click to open the download page."
        content.sound = .default

        let request = UNNotificationRequest(identifier: "cmdx-update-notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("cmdX: failed to deliver update notification - \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                UserDefaults.standard.set(version, forKey: Self.lastNotifiedVersionKey)
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.openDownloadPage()
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    private func openDownloadPage() {
        NSWorkspace.shared.open(latestVersionURL ?? Self.releasesPage)
    }

    private func showUpdateAlert(version: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "cmdX \(version) is available. Do you want to go to the download page?"
        alert.addButton(withTitle: "Open Download Page")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            openDownloadPage()
        }
    }

    private func showAlert(title: String, message: String, style: NSAlert.Style = .informational) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

nonisolated struct GitHubRelease: Codable, Sendable {
    let tagName: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
