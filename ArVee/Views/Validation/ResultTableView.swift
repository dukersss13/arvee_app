import SwiftUI

/// Generic table view for displaying result rows (validated, discrepancies, etc.)
struct ResultTableView: View {
    let rows: [ResultRow]

    /// Ordered column keys derived from the first row.
    private var columns: [String] {
        guard let first = rows.first else { return [] }
        return first.fields.keys.sorted()
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { col in
                        Text(formatHeader(col))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(.arveeInkMuted)
                            .frame(minWidth: 100, alignment: .leading)
                            .padding(8)
                    }
                }
                .background(Color.arveeTableHead)

                Divider().overlay(Color.arveeLine)

                // Rows
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                            HStack(spacing: 0) {
                                ForEach(columns, id: \.self) { col in
                                    Text(row.value(for: col))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.arveeInk)
                                        .frame(minWidth: 100, alignment: .leading)
                                        .padding(8)
                                }
                            }
                            .background(idx % 2 == 0 ? Color.clear : Color.arveeTeal.opacity(0.03))
                            Divider().overlay(Color.arveeLine)
                        }
                    }
                }
            }
        }
        .padding(1)
        .arveeCard(cornerRadius: 12)
        .padding(.horizontal, 16)
    }

    private func formatHeader(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
