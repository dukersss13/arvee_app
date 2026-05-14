import SwiftUI

struct MainTabView: View {
    @StateObject private var sessionVM = SessionViewModel()
    @StateObject private var validationVM = ValidationViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @State private var selectedTab = 0
    @State private var resultsScrollTarget: ResultsSection?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                sessionVM: sessionVM,
                validationVM: validationVM,
                selectedTab: $selectedTab,
                resultsScrollTarget: $resultsScrollTarget
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
                viewModel: validationVM,
                scrollTarget: $resultsScrollTarget
            )
            .tabItem {
                Label("Results", systemImage: "checkmark.shield")
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
        .task {
            chatVM.setStateSyncHandler { sessionId in
                await validationVM.saveCurrentState(sessionId: sessionId)
            }
        }
    }
}

/// Identifiable section target for scrolling within the Results tab.
enum ResultsSection: String, Identifiable, CaseIterable {
    case validated, discrepancies, unmatchedTx, unmatchedProofs, recommendations
    var id: String { rawValue }
}
