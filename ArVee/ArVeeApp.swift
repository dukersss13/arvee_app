import SwiftUI

@main
struct ArVeeApp: App {
    init() {
        // Load saved API URL from UserDefaults
        if let saved = UserDefaults.standard.string(forKey: "apiBaseURL"), !saved.isEmpty {
            APIService.shared.baseURL = saved
        }

        // Global appearance: warm paper theme
        let paperUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x1A1816) : UIColor(hex: 0xF4EFE4) }
        let tealUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x2DB8A2) : UIColor(hex: 0x0F7B6C) }
        let inkUI = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xF0EBE2) : UIColor(hex: 0x1F1D1A) }

        UITabBar.appearance().backgroundColor = paperUI
        UITabBar.appearance().unselectedItemTintColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xA39B8E) : UIColor(hex: 0x5A554D) }

        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: inkUI]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: inkUI]

        UISegmentedControl.appearance().selectedSegmentTintColor = tealUI
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tealUI], for: .normal)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(.arveeTeal)
        }
    }
}
