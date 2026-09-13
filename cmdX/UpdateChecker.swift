import Combine
import SwiftUI
import UserNotifications

class UpdateChecker: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isUpdateAvailable = false
    private var latestVersionURL: URL?
    private var notificationsEnabled = false

    static let checkForUpdatesEnabledKey = "cmdx.updateCheck.enabled"
    private static let lastNotifiedVersionKey = "cmdx.updateCheck.lastNotifiedVersion"

    private var isAutomaticCheckingEnabled: Bool {
        if UserDefaults.standard.object(forKey: Self.checkForUpdatesEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Self.checkForUpdatesEnabledKey)
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationsEnabled = (settings.authorizationStatus == .authorized)
            print("DEBUG: Notifications enabled: \(self.notificationsEnabled)")
        }
    }

    func checkForUpdates(manualCheck: Bool = false) {
        guard manualCheck || isAutomaticCheckingEnabled else {
            print("DEBUG: Skipping automatic update check (disabled by user)")
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationsEnabled = (settings.authorizationStatus == .authorized)
            print("DEBUG: Notification status check - enabled: \(self.notificationsEnabled)")
        }

        let url = URL(string: "https://api.github.com/repos/YONN2222/cmdX/releases/latest")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                self.handleUpdateCheckFailure(error.localizedDescription, manualCheck: manualCheck)
                return
            }

            guard let data else {
                self.handleUpdateCheckFailure("The server returned no data.", manualCheck: manualCheck)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.handleUpdateCheckFailure("The server returned an invalid response.", manualCheck: manualCheck)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                self.handleUpdateCheckFailure("GitHub returned HTTP \(httpResponse.statusCode).", manualCheck: manualCheck)
                return
            }
            
            if let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) {
                let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
                self.latestVersionURL = URL(string: release.htmlURL)
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                
                print("DEBUG: Latest version from GitHub: \(latestVersion)")
                print("DEBUG: Current version: \(currentVersion)")
                print("DEBUG: Is newer: \(self.isNewer(latestVersion: latestVersion, currentVersion: currentVersion))")
                
                if self.isNewer(latestVersion: latestVersion, currentVersion: currentVersion) {
                    DispatchQueue.main.async {
                        self.isUpdateAvailable = true
                        print("DEBUG: Update is available! Setting flag.")

                        let alreadyNotifiedThisVersion = UserDefaults.standard.string(forKey: Self.lastNotifiedVersionKey) == latestVersion

                        if manualCheck {
                            self.showUpdateAlert()
                        } else if alreadyNotifiedThisVersion {
                            print("DEBUG: Already notified about \(latestVersion), skipping repeat alert")
                        } else {
                            UserDefaults.standard.set(latestVersion, forKey: Self.lastNotifiedVersionKey)
                            if self.notificationsEnabled {
                                print("DEBUG: Sending notification (notifications enabled)")
                                self.sendNotification()
                            } else {
                                print("DEBUG: Showing popup (notifications disabled)")
                                self.showUpdateAlert()
                            }
                        }
                    }
                } else {
                    print("DEBUG: No update available (current version is up to date or newer)")
                    if manualCheck {
                        DispatchQueue.main.async {
                            self.showNoUpdateAlert()
                        }
                    }
                }
            } else {
                self.handleUpdateCheckFailure("The server response could not be decoded.", manualCheck: manualCheck)
            }
        }.resume()
    }

    private func handleUpdateCheckFailure(_ reason: String, manualCheck: Bool) {
        NSLog("cmdX: update check failed - \(reason)")
        guard manualCheck else { return }

        DispatchQueue.main.async {
            self.showUpdateCheckFailedAlert()
        }
    }

    private func isNewer(latestVersion: String, currentVersion: String) -> Bool {
        let latestComponents = latestVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        print("DEBUG: Latest components: \(latestComponents)")
        print("DEBUG: Current components: \(currentComponents)")
        
        let maxCount = max(latestComponents.count, currentComponents.count)
        
        for i in 0..<maxCount {
            let latest = i < latestComponents.count ? latestComponents[i] : 0
            let current = i < currentComponents.count ? currentComponents[i] : 0
            
            print("DEBUG: Position \(i): latest=\(latest), current=\(current)")
            
            if latest > current {
                print("DEBUG: Returning true (latest > current)")
                return true
            }
            if latest < current {
                print("DEBUG: Returning false (latest < current)")
                return false
            }
        }
        
        print("DEBUG: Returning false (versions equal)")
        return false
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
    content.title = "Update available"
    content.body = "A new version of cmdX is available. Click to open the download page."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_CATEGORY"
        content.userInfo = ["url": latestVersionURL?.absoluteString ?? ""]
        
        let request = UNNotificationRequest(identifier: "cmdx-update-notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Error adding notification: \(error)")
            } else {
                print("DEBUG: Notification added successfully")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("DEBUG: Notification clicked!")
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            self.showUpdateAlert()
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("DEBUG: Will present notification")
        completionHandler([.banner, .sound])
    }

    private func showUpdateAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = "A new version of cmdX is available. Do you want to go to the download page?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Download Page")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = self.latestVersionURL {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func showNoUpdateAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "No Update Available"
            alert.informativeText = "You are already using the latest version of cmdX."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showUpdateCheckFailedAlert() {
        let alert = NSAlert()
        alert.messageText = "Unable to Check for Updates"
        alert.informativeText = "cmdX couldn't check for updates. Check your internet connection and try again."
        alert.alertStyle = .warning
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
