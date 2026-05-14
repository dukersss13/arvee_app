import SwiftUI

private let recommendationFontScale: CGFloat = 1.05

private func scaledRecommendationFont(_ base: CGFloat) -> CGFloat {
    base * recommendationFontScale
}

/// Card for a single recommendation — shows the suggested match and an Accept button.
struct RecommendationCardView: View {
    let row: ResultRow
    let isSelected: Bool
    let isAcceptEnabled: Bool
    let onToggleSelected: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: onToggleSelected) {
                    HStack(spacing: 6) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: scaledRecommendationFont(13), weight: .semibold, design: .rounded))
                        Text(isSelected ? "Selected" : "Select")
                            .font(.system(size: scaledRecommendationFont(12), weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(isSelected ? .arveeTeal : .arveeInkMuted)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Transaction side
            sideLabel("Transaction", color: .arveeTeal)
            HStack {
                fieldColumn("Business", row.value(for: "Transaction Business Name"))
                Spacer()
                fieldColumn("Date", row.value(for: "Transaction Date"))
                Spacer()
                fieldColumn("Total", row.value(for: "Transaction Total"))
            }

            Divider().overlay(Color.arveeLine)

            // Proof side
            sideLabel("Proof", color: .arveeCoral)
            HStack {
                fieldColumn("Business", row.value(for: "Proof Business Name"))
                Spacer()
                fieldColumn("Date", row.value(for: "Proof Date"))
                Spacer()
                fieldColumn("Total", row.value(for: "Proof Total"))
            }

            // Reason / confidence
            if let reason = row.fields["Reason"], !reason.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: scaledRecommendationFont(10)))
                        .foregroundColor(.arveeTeal)
                    Text(reason)
                        .font(.system(size: scaledRecommendationFont(13.1), weight: .medium, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                }
            }

            // Accept button
            Button(action: onAccept) {
                Label("Accept", systemImage: "checkmark.circle.fill")
                    .font(.system(size: scaledRecommendationFont(15), weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isAcceptEnabled ? Color.arveeTeal : Color.arveeInkMuted)
                    .cornerRadius(10)
            }
            .disabled(!isAcceptEnabled)
        }
        .padding(14)
        .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 12)
    }

    private func sideLabel(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: scaledRecommendationFont(9), weight: .bold, design: .rounded))
            .foregroundColor(color)
            .tracking(0.5)
    }

    private func fieldColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: scaledRecommendationFont(9), weight: .semibold, design: .rounded))
                .foregroundColor(.arveeInkMuted)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: scaledRecommendationFont(13.2), weight: .regular, design: .rounded))
                .foregroundColor(.arveeInk)
                .lineLimit(1)
        }
    }
}
