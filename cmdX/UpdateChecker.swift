import Combine
import SwiftUI
import UserNotifications

class UpdateChecker: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isUpdateAvailable = false
    private var latestVersionURL: URL?
    private var notificationsEnabled = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        // Check notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationsEnabled = (settings.authorizationStatus == .authorized)
            print("DEBUG: Notifications enabled: \(self.notificationsEnabled)")
        }
    }

    func checkForUpdates(manualCheck: Bool = false) {
        // Update notification status before checking
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationsEnabled = (settings.authorizationStatus == .authorized)
            print("DEBUG: Notification status check - enabled: \(self.notificationsEnabled)")
        }
        
        let url = URL(string: "https://api.github.com/repos/YONN2222/cmdX/releases/latest")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                if manualCheck {
                    DispatchQueue.main.async {
                        self.showNoUpdateAlert()
                    }
                }
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
                        
                        if manualCheck {
                            // Show alert dialog for manual checks
                            self.showUpdateAlert()
                        } else {
                            // Automatic check: send notification if enabled, otherwise show popup
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
            }
        }.resume()
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
    content.body = "Open the app in the menu bar to install the update."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_CATEGORY"
        // We keep the URL in case it's needed elsewhere, but clicking the notification will
        // now activate the app (bring the menu-bar app forward) instead of opening the browser.
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
        // Instead of opening the release page in the browser, bring the app forward and
        // show the update alert so the user can interact with the menu-bar app.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            // Show the alert which offers to open the download page (or the user can open the menu-bar UI).
            self.showUpdateAlert()
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("DEBUG: Will present notification")
        // Show notification even when app is in foreground
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
}

struct GitHubRelease: Codable, Sendable {
    let tagName: String
    let htmlURL: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
