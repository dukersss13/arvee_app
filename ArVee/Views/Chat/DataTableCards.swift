import SwiftUI

/// Displays top categories as a compact card with category name and amount.
struct TopCategoriesCard: View {
    let categories: [CategoryValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Top Categories")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            ForEach(categories) { cat in
                HStack {
                    Text(cat.category)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "$%.2f", cat.value))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)

                if cat.id != categories.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// Displays the comparison table with delta and percent change.
struct ComparisonTableCard: View {
    let table: ComparisonTable

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let cols = table.columns, cols.count >= 2 {
                Text("Comparison")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerRow
                    Divider()

                    // Data rows
                    if let rows = table.rows {
                        ForEach(rows) { row in
                            dataRow(row)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Category")
                .frame(width: 100, alignment: .leading)
            Text("Period 1")
                .frame(width: 80, alignment: .trailing)
            Text("Period 2")
                .frame(width: 80, alignment: .trailing)
            Text("Delta")
                .frame(width: 80, alignment: .trailing)
            Text("Change")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.vertical, 6)
    }

    private func dataRow(_ row: ComparisonRow) -> some View {
        HStack(spacing: 0) {
            Text(row.category)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
            Text(formatAmount(row.period1))
                .frame(width: 80, alignment: .trailing)
            Text(formatAmount(row.period2))
                .frame(width: 80, alignment: .trailing)
            Text(formatDelta(row.delta))
                .foregroundColor(deltaColor(row.delta))
                .frame(width: 80, alignment: .trailing)
            Text(formatPercent(row.percentChange))
                .foregroundColor(deltaColor(row.delta))
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption.monospacedDigit())
        .padding(.vertical, 4)
    }

    private func formatAmount(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "$%.2f", v)
    }

    private func formatDelta(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "$%.2f", v))"
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f%%", v))"
    }

    private func deltaColor(_ value: Double?) -> Color {
        guard let v = value else { return .primary }
        return v >= 0 ? .teal : .red
    }
}
