import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    var onQuickReplyTap: ((String) -> Void)? = nil
    @State private var pendingTextPulse = false

    private var isUser: Bool { message.role == .user }
    private let bubbleCornerRadius: CGFloat = 18

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 10) {
            // Text bubble
            HStack(alignment: .bottom, spacing: 8) {
                if isUser { Spacer(minLength: 52) }

                if !isUser {
                    avatarView(symbol: "sparkles", tint: .arveeTeal)
                }

                VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                    Text(isUser ? "YOU" : "ARVEE")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 8) {
                        if message.isPending && message.text.isEmpty {
                            TypingIndicator()
                        } else {
                            Text(message.text)
                                .font(.system(.body, design: .rounded))
                                .lineSpacing(2)
                                .textSelection(.enabled)
                                .opacity((message.isPending && !isUser) ? (pendingTextPulse ? 1.0 : 0.35) : 1.0)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .foregroundColor(isUser ? .white : .arveeInk)
                    .frame(maxWidth: 320, alignment: .leading)
                    .background(bubbleFill)
                    .clipShape(BubbleShape(isUser: isUser, radius: bubbleCornerRadius, tailSize: 7))
                    .overlay(
                        BubbleShape(isUser: isUser, radius: bubbleCornerRadius, tailSize: 7)
                            .stroke(bubbleStroke, lineWidth: isUser ? 0.6 : 1.0)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: bubbleCornerRadius - 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(isUser ? 0.24 : 0.46), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .padding(.horizontal, 2)
                            .padding(.top, 1)
                    }
                    .shadow(color: bubbleShadowColor, radius: isUser ? 14 : 10, x: 0, y: isUser ? 8 : 4)
                    .shadow(color: Color.arveeInk.opacity(isUser ? 0.05 : 0.08), radius: 4, x: 0, y: 2)
                    .onAppear {
                        updatePendingPulse(isActive: message.isPending && !isUser)
                    }
                    .onChange(of: message.isPending) { _, isPending in
                        updatePendingPulse(isActive: isPending && !isUser)
                    }
                }

                if isUser {
                    avatarView(symbol: "person.fill", tint: .arveeCoral)
                }

                if !isUser { Spacer(minLength: 52) }
            }

            // Chart (assistant only)
            if let chart = message.chart, !isUser {
                ChartCardView(chart: chart)
                    .padding(.leading, 36)
                    .padding(.trailing, 52)
            }

            // Top categories table
            if let categories = message.topCategories, !categories.isEmpty, !isUser {
                TopCategoriesCard(categories: categories)
                    .padding(.leading, 36)
                    .padding(.trailing, 52)
            }

            // Comparison table
            if let table = message.comparisonTable, !isUser {
                ComparisonTableCard(table: table)
                    .padding(.leading, 36)
                    .padding(.trailing, 52)
            }

            // Quick-reply card options
            if let quickReplies = message.quickReplies,
               !quickReplies.isEmpty,
               !isUser,
               !message.isPending {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try one of these")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.arveeInkMuted)

                    ForEach(quickReplies, id: \.self) { reply in
                        Button {
                            onQuickReplyTap?(reply)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.arveeTeal)
                                Text(reply)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.arveeInk)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(Color.arveeTealSoft.opacity(0.42))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 14)
                .padding(.leading, 36)
                .padding(.trailing, 52)
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func avatarView(symbol: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
            Circle()
                .stroke(tint.opacity(0.28), lineWidth: 0.8)
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tint)
        }
        .frame(width: 24, height: 24)
        .padding(.bottom, 2)
    }

    private var bubbleFill: AnyShapeStyle {
        if isUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.arveeTeal, Color.arveeTealDark, Color.arveeTealDark.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [Color.arveeGlassHighlight, Color.arveeGlassBase, Color.arveeCardElevated.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var bubbleStroke: Color {
        isUser ? Color.white.opacity(0.25) : Color.arveeGlassStroke
    }

    private var bubbleShadowColor: Color {
        isUser ? Color.arveeTeal.opacity(0.24) : Color.arveeInk.opacity(0.10)
    }

    private func updatePendingPulse(isActive: Bool) {
        if isActive {
            pendingTextPulse = false
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pendingTextPulse = true
            }
        } else {
            pendingTextPulse = false
        }
    }
}

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.arveeTeal)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: i))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                phase = 1
            }
        }
    }

    private func dotScale(for index: Int) -> CGFloat {
        let offset = Double(index) * 0.2
        return 0.6 + 0.4 * sin((phase + offset) * .pi)
    }
}
