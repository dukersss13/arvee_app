import SwiftUI

struct OnboardingView: View {
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
