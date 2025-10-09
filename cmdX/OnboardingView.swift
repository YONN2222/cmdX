import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("commandX_hasSeenIntro") private var hasSeenIntro: Bool = false
    @State private var dontShowAgain: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "scissors.badge.ellipsis")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to commandX")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Make Finder behave like Windows: use ⌘+X to cut and move files with ⌘+V.")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("How it works")
                    .font(.headline)
                Text("• When you press ⌘+X in Finder, commandX copies the selected files (⌘+C) and stores a cut flag.")
                Text("• When you paste afterwards (⌘+V) in Finder, commandX simulates ⌥+⌘+V so Finder moves the files instead of copying them.")
                Text("• If you press ⌘+C after cutting, the cut flag is cleared and paste will copy as usual.")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions — Accessibility")
                    .font(.headline)
                Text("To let commandX observe your keyboard and synthesize the move command, you must grant Accessibility permission in System Settings. This permission allows the app to intercept keyboard shortcuts and simulate a Move command in Finder.")
                    .foregroundColor(.secondary)

                Text("How to enable:")
                    .font(.subheadline)
                Text("1. Open System Settings → Privacy & Security → Accessibility")
                Text("2. Find ‘commandX’ and enable the toggle")
                Text("3. You may need to quit & relaunch commandX for the setting to take effect")
                    .foregroundColor(.secondary)
            }

            Toggle("Don't show this again", isOn: $dontShowAgain)
                .toggleStyle(.checkbox)
                .accessibilityLabel("Do not show introduction again")

            HStack {
                Button("Open Accessibility Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Open Accessibility settings in System Settings")

                Spacer()

                Button("Close") {
                    if dontShowAgain {
                        hasSeenIntro = true
                    }
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 520)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}
