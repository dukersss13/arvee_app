import SwiftUI

/// Card-based result rows for displaying validated/discrepancy/unmatched items.
struct ResultTableView: View {
    let rows: [ResultRow]

    /// Priority display columns (shown prominently); remaining shown in expanded detail.
    private let priorityKeys = ["business_name", "total", "date", "currency", "category", "status"]

    /// Ordered column keys derived from the first row.
    private var columns: [String] {
        guard let first = rows.first else { return [] }
        return first.fields.keys.sorted()
    }

    /// Columns shown on the card face.
    private var displayColumns: [String] {
        let available = columns
        let priority = priorityKeys.filter { available.contains($0) }
        let remaining = available.filter { !priorityKeys.contains($0) }
        return priority + remaining
    }

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                resultCard(row: row, index: idx)
            }
        }
        .padding(.horizontal, 16)
    }

    private func resultCard(row: ResultRow, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary info row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    if let name = row.fields["business_name"], !name.isEmpty {
                        Text(name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.arveeInk)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        if let date = row.fields["date"], !date.isEmpty {
                            Text(date)
                                .font(.caption)
                                .foregroundColor(.arveeInkMuted)
                        }
                        if let category = row.fields["category"], !category.isEmpty {
                            Text(category)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.arveeTeal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.arveeTealSoft)
                                .cornerRadius(4)
                        }
                    }
                }
                Spacer()
                if let total = row.fields["total"], !total.isEmpty {
                    let currency = row.fields["currency"] ?? "$"
                    Text("\(currency)\(total)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundColor(.arveeInk)
                }
            }

            // Extra fields (excluding the ones already shown)
            let extraKeys = displayColumns.filter {
                !["business_name", "total", "date", "currency", "category"].contains($0)
            }
            let extraFields = extraKeys.compactMap { key -> (String, String)? in
                guard let val = row.fields[key], !val.isEmpty, val != "Optional(nil)" else { return nil }
                return (key, val)
            }

            if !extraFields.isEmpty {
                Divider().overlay(Color.arveeLine)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(extraFields, id: \.0) { key, value in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(formatHeader(key))
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundColor(.arveeInkMuted)
                                    .tracking(0.3)
                                Text(value)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.arveeInk)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .arveeCard(cornerRadius: 12)
    }

    private func formatHeader(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
