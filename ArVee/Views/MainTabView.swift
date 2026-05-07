import SwiftUI

struct MainTabView: View {
    @StateObject private var sessionVM = SessionViewModel()
    @StateObject private var validationVM = ValidationViewModel()
    @StateObject private var chatVM = ChatViewModel()

    var body: some View {
        TabView {
            SessionView(viewModel: sessionVM)
                .tabItem {
                    Label("Session", systemImage: "folder.badge.gearshape")
                }

            ValidationView(
                sessionVM: sessionVM,
                viewModel: validationVM
            )
            .tabItem {
                Label("Validate", systemImage: "checkmark.shield")
            }

            ChatView(
                sessionVM: sessionVM,
                viewModel: chatVM
            )
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right")
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
