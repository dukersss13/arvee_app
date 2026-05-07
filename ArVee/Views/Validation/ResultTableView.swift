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
                            .font(.caption.weight(.semibold))
                            .frame(minWidth: 100, alignment: .leading)
                            .padding(8)
                            .background(Color(.systemGray5))
                    }
                }

                Divider()

                // Rows
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(rows) { row in
                            HStack(spacing: 0) {
                                ForEach(columns, id: \.self) { col in
                                    Text(row.value(for: col))
                                        .font(.caption)
                                        .frame(minWidth: 100, alignment: .leading)
                                        .padding(8)
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func formatHeader(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
