import SwiftUI

struct MainTabView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var sessionVM = SessionViewModel()
    @StateObject private var validationVM = ValidationViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @AppStorage("arvee_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var resultsScrollTarget: ResultsSection?

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(AnyTransition.opacity)
            } else {
                // Authentication is disabled for local development — always show main tabs.
                contentTabs
                    .transition(AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.98)),
                        removal: AnyTransition.opacity
                    ))
            }
        }
        .arveeKeyboardDismissToolbar()
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: authVM.isAuthenticated)
        .onChange(of: authVM.isAuthenticated) { _, isAuthed in
            if !isAuthed {
                sessionVM.clear()
                validationVM.clear()
                chatVM.clear()
                selectedTab = 0
            }
        }
        .task {
            authVM.refreshAuthState()
            chatVM.setStateSyncHandler { sessionId in
                await validationVM.saveCurrentState(sessionId: sessionId)
            }
        }
    }

    private var contentTabs: some View {
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

            SettingsView(authViewModel: authVM)
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

/// Identifiable section target for scrolling within the Results tab.
enum ResultsSection: String, Identifiable, CaseIterable {
    case validated, discrepancies, unmatchedTx, unmatchedProofs, recommendations
    var id: String { rawValue }
}

private struct OnboardingView: View {
    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "square.and.arrow.up.on.square",
            title: "Upload Statements & Proofs",
            body: "Import transaction statements, receipts, and supporting proofs in one place."
        ),
        OnboardingSlide(
            icon: "checkmark.shield",
            title: "Validate With ArVee",
            body: "ArVee matches records, flags discrepancies, and gives practical recommendations."
        ),
        OnboardingSlide(
            icon: "bubble.left.and.text.bubble.right",
            title: "Ask the ArVee Agent",
            body: "Ask finance-related questions and get focused answers from your data context."
        )
    ]

    @State private var selection = 0
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.arveeInkMuted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                TabView(selection: $selection) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                        VStack(spacing: 20) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.arveeTealSoft)
                                    .frame(width: 120, height: 120)

                                Image(systemName: slide.icon)
                                    .font(.system(size: 42, weight: .semibold))
                                    .foregroundStyle(Color.arveeTealGradient)
                            }

                            Text(slide.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.arveeInk)
                                .multilineTextAlignment(.center)

                            Text(slide.body)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.arveeInkMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 26)

                            Spacer()
                        }
                        .tag(idx)
                        .padding(.bottom, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if selection < slides.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selection += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Label(selection < slides.count - 1 ? "Next" : "Get Started", systemImage: selection < slides.count - 1 ? "arrow.right" : "checkmark")
                }
                .buttonStyle(ArveePrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
            }
            .arveePageBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct OnboardingSlide {
    let icon: String
    let title: String
    let body: String
}
