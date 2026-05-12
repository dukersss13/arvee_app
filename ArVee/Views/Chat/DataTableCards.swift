import SwiftUI

/// Displays top categories as a compact card with category name and amount.
struct TopCategoriesCard: View {
    let categories: [CategoryValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOP CATEGORIES")
                .font(.arveeEyebrow())
                .foregroundColor(.arveeInkMuted)
                .tracking(1)

            ForEach(categories) { cat in
                HStack {
                    Text(cat.category)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.arveeInk)
                    Spacer()
                    Text(String(format: "$%.2f", cat.value))
                        .font(.system(.subheadline, design: .monospaced).monospacedDigit())
                        .foregroundColor(.arveeInkMuted)
                }
                .padding(.vertical, 2)

                if cat.id != categories.last?.id {
                    Divider().overlay(Color.arveeLine)
                }
            }
        }
        .padding()
        .arveeCard(cornerRadius: 12)
    }
}

/// Displays the comparison table with delta and percent change.
struct ComparisonTableCard: View {
    let table: ComparisonTable

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let cols = table.columns, cols.count >= 2 {
                Text("COMPARISON")
                    .font(.arveeEyebrow())
                    .foregroundColor(.arveeInkMuted)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerRow
                    Divider().overlay(Color.arveeLine)

                    // Data rows
                    if let rows = table.rows {
                        ForEach(rows) { row in
                            dataRow(row)
                            Divider().overlay(Color.arveeLine)
                        }
                    }
                }
            }
        }
        .padding()
        .arveeCard(cornerRadius: 12)
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
        .foregroundColor(.arveeInkMuted)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.arveeTableHead)
    }

    private func dataRow(_ row: ComparisonRow) -> some View {
        HStack(spacing: 0) {
            Text(row.category)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.arveeInk)
            Text(formatAmount(row.period1))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(.arveeInk)
            Text(formatAmount(row.period2))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(.arveeInk)
            Text(formatDelta(row.delta))
                .foregroundColor(deltaColor(row.delta))
                .frame(width: 80, alignment: .trailing)
            Text(formatPercent(row.percentChange))
                .foregroundColor(deltaColor(row.delta))
                .frame(width: 70, alignment: .trailing)
        }
        .font(.system(.caption, design: .monospaced).monospacedDigit())
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
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
        guard let v = value else { return .arveeInk }
        return v >= 0 ? .arveeTeal : .arveeDanger
    }
}
