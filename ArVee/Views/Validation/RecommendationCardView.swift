import SwiftUI

/// Card for a single recommendation — shows the suggested match and an Accept button.
struct RecommendationCardView: View {
    let row: ResultRow
    let onAccept: () -> Void

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

            // Reason / confidence
            if let reason = row.fields["Reason"], !reason.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.arveeTeal)
                    Text(reason)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                }
            }

            // Accept button
            Button(action: onAccept) {
                Label("Accept", systemImage: "checkmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.arveeTeal)
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .arveeCard(cornerRadius: 12)
    }

    private func sideLabel(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .tracking(0.5)
    }

    private func fieldColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.arveeInkMuted)
            Text(value.isEmpty ? "—" : value)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.arveeInk)
                .lineLimit(1)
        }
    }
}
