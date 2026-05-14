import SwiftUI

@main
struct ArVeeApp: App {
    private enum LaunchStorageKeys {
        static let onboardingCompleted = "arvee_completed_onboarding"
        static let lastSeenBuildIdentity = "arvee_last_seen_build_identity"
    }

    init() {
        resetOnboardingForNewBuildIfNeeded()

        // Ensure API URL is set on launch — write default if not yet saved
        let key = "apiBaseURL"
        if let saved = UserDefaults.standard.string(forKey: key), !saved.isEmpty {
            APIService.shared.setBaseURL(saved, persist: true)
        } else {
            let defaultURL = APIService.defaultBaseURL
            APIService.shared.setBaseURL(defaultURL, persist: true)
        }

        // Global appearance: warm paper theme
        let paperUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x1A1816) : UIColor(hex: 0xF4EFE4) }
        let tealUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x73BCF7) : UIColor(hex: 0x4EA8DE) }
        let inkUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xF0EBE2) : UIColor(hex: 0x1F1D1A) }

        UITabBar.appearance().backgroundColor = paperUI
        UITabBar.appearance().unselectedItemTintColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xA39B8E) : UIColor(hex: 0x5A554D) }

        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: inkUI]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: inkUI]

        UISegmentedControl.appearance().selectedSegmentTintColor = tealUI
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tealUI], for: .normal)
    }

    private func resetOnboardingForNewBuildIfNeeded() {
        let defaults = UserDefaults.standard
        let currentIdentity = buildIdentity()
        let previousIdentity = defaults.string(forKey: LaunchStorageKeys.lastSeenBuildIdentity)

        guard previousIdentity != currentIdentity else {
            return
        }

        defaults.set(false, forKey: LaunchStorageKeys.onboardingCompleted)
        defaults.set(currentIdentity, forKey: LaunchStorageKeys.lastSeenBuildIdentity)
    }

    private func buildIdentity() -> String {
        let info = Bundle.main.infoDictionary
        let shortVersion = (info?["CFBundleShortVersionString"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let buildNumber = (info?["CFBundleVersion"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        let version = (shortVersion?.isEmpty == false) ? shortVersion! : "0"
        let build = (buildNumber?.isEmpty == false) ? buildNumber! : "0"
        return "\(version)+\(build)"
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(.arveeTeal)
        }
    }
}
