import SwiftUI

private let discrepancyFontScale: CGFloat = 1.05

private func scaledDiscrepancyFont(_ base: CGFloat) -> CGFloat {
    base * discrepancyFontScale
}

/// Interactive card for a discrepancy row — lets the user adjust the amount and accept.
struct DiscrepancyCardView: View {
    let row: ResultRow
    let onAccept: (Double?, String?) -> Void

    @State private var adjustedAmount: String = ""
    @State private var comment: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            // Reason
            if let reason = row.fields["Reason"], !reason.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: scaledDiscrepancyFont(10)))
                        .foregroundColor(.arveeInkMuted)
                    Text(reason)
                        .font(.system(size: scaledDiscrepancyFont(11), weight: .regular, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                }
            }

            Divider().overlay(Color.arveeLine)

            // Editable fields
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Adjusted Amount")
                        .font(.system(size: scaledDiscrepancyFont(10), weight: .semibold, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                    TextField(
                        row.value(for: "Transaction Total"),
                        text: $adjustedAmount
                    )
                    .keyboardType(.decimalPad)
                    .font(.system(size: scaledDiscrepancyFont(15), weight: .regular, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.arveeSand.opacity(0.3))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Comment")
                        .font(.system(size: scaledDiscrepancyFont(10), weight: .semibold, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                    TextField("Optional", text: $comment)
                        .font(.system(size: scaledDiscrepancyFont(15), weight: .regular, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.arveeSand.opacity(0.3))
                        .cornerRadius(8)
                }
            }

            // Accept button
            Button {
                let amount = Double(adjustedAmount.trimmingCharacters(in: .whitespaces))
                let trimmedComment = comment.trimmingCharacters(in: .whitespaces)
                onAccept(amount, trimmedComment.isEmpty ? nil : trimmedComment)
            } label: {
                Label("Accept Match", systemImage: "checkmark.circle.fill")
                    .font(.system(size: scaledDiscrepancyFont(15), weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.arveeTeal)
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .arveePremiumGlassCard(accent: .arveeCoral, cornerRadius: 12)
        .onAppear {
            adjustedAmount = row.value(for: "Transaction Total")
        }
    }

    private func sideLabel(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: scaledDiscrepancyFont(9), weight: .bold, design: .rounded))
            .foregroundColor(color)
            .tracking(0.5)
    }

    private func fieldColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: scaledDiscrepancyFont(9), weight: .semibold, design: .rounded))
                .foregroundColor(.arveeInkMuted)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: scaledDiscrepancyFont(13.2), weight: .regular, design: .rounded))
                .foregroundColor(.arveeInk)
                .lineLimit(1)
        }
    }
}
