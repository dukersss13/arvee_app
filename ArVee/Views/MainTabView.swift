import SwiftUI

struct MainTabView: View {
    @StateObject private var sessionVM = SessionViewModel()
    @StateObject private var validationVM = ValidationViewModel()
    @StateObject private var chatVM = ChatViewModel()

    var body: some View {
        TabView {
            UploadView(
                sessionVM: sessionVM,
                validationVM: validationVM
            )
            .tabItem {
                Label("Upload", systemImage: "arrow.up.doc")
            }

            ValidationView(
                sessionVM: sessionVM,
                viewModel: validationVM
            )
            .tabItem {
                Label("Validation", systemImage: "checkmark.shield")
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
        .tint(.arveeTeal)
        .toolbarBackground(Color.arveePaper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
