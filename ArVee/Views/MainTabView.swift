import SwiftUI

struct MainTabView: View {
    @StateObject private var sessionVM = SessionViewModel()
    @StateObject private var validationVM = ValidationViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                sessionVM: sessionVM,
                validationVM: validationVM,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            UploadView(
                sessionVM: sessionVM,
                validationVM: validationVM,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Upload", systemImage: "arrow.up.doc")
            }
            .tag(1)

            ValidationView(
                sessionVM: sessionVM,
                viewModel: validationVM
            )
            .tabItem {
                Label("Validation", systemImage: "checkmark.shield")
            }
            .tag(2)

            ChatView(
                sessionVM: sessionVM,
                viewModel: chatVM
            )
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right")
            }
            .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.arveeTeal)
        .toolbarBackground(Color.arveePaper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
