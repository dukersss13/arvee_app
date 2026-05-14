import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    var onQuickReplyTap: ((String) -> Void)? = nil

    private var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            // Text bubble
            HStack {
                if isUser { Spacer(minLength: 60) }

                VStack(alignment: .leading, spacing: 8) {
                    if message.isPending && message.text.isEmpty {
                        TypingIndicator()
                    } else {
                        Text(message.text)
                            .textSelection(.enabled)
                    }
                }
                .padding(12)
                .foregroundColor(isUser ? .white : .arveeInk)
                .background(
                    Group {
                        if isUser {
                            Color.arveeTealGradient
                        } else {
                            LinearGradient(
                                colors: [Color.arveePaper, Color.arveePaper],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                )
                .clipShape(BubbleShape(isUser: isUser))
                .overlay(
                    Group {
                        if !isUser {
                            BubbleShape(isUser: isUser)
                                .stroke(Color.arveeLine, lineWidth: 0.5)
                        }
                    }
                )

                if !isUser { Spacer(minLength: 60) }
            }

            // Chart (assistant only)
            if let chart = message.chart, !isUser {
                ChartCardView(chart: chart)
                    .padding(.trailing, 60)
            }

            // Top categories table
            if let categories = message.topCategories, !categories.isEmpty, !isUser {
                TopCategoriesCard(categories: categories)
                    .padding(.trailing, 60)
            }

            // Comparison table
            if let table = message.comparisonTable, !isUser {
                ComparisonTableCard(table: table)
                    .padding(.trailing, 60)
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
                            .background(Color.arveeTealSoft.opacity(0.45))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .arveeCard(cornerRadius: 14)
                .padding(.trailing, 60)
            }
        }
        .padding(.horizontal, 12)
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
