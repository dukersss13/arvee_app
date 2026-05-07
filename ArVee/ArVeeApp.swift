import SwiftUI

@main
struct ArVeeApp: App {
    init() {
        // Load saved API URL from UserDefaults
        if let saved = UserDefaults.standard.string(forKey: "apiBaseURL"), !saved.isEmpty {
            APIService.shared.baseURL = saved
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
