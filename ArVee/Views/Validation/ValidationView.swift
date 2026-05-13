import SwiftUI

struct ValidationView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var viewModel: ValidationViewModel

    var body: some View {
        NavigationStack {
            Group {
                if !sessionVM.hasSession {
                    noSessionPlaceholder
                } else if viewModel.hasResults {
                    resultsView
                } else {
                    emptyResultsPlaceholder
                }
            }
            .arveePageBackground()
            .navigationTitle("Validation")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if viewModel.hasResults {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.clear()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.arveeInkMuted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - No Session

    private var noSessionPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundColor(.arveeInkMuted)
            Text("No session active")
                .font(.arveeHeadline())
                .foregroundColor(.arveeInk)
            Text("Go to Upload to create a session and run validation.")
                .font(.subheadline)
                .foregroundColor(.arveeInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Empty Results

    private var emptyResultsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.arveeInkMuted)
            Text("No results yet")
                .font(.arveeHeadline())
                .foregroundColor(.arveeInk)
            Text("Upload files and run validation from the Upload tab.")
                .font(.subheadline)
                .foregroundColor(.arveeInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Summary banner
            if let summary = viewModel.summary {
                Text(summary)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.arveeInk)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.arveeMint.opacity(0.25))
            }

            ScrollView {
                VStack(spacing: 16) {
                    // KPI cards
                    kpiRow
                        .padding(.top, 12)

                    // Sub-tab picker
                    Picker("Results", selection: $viewModel.selectedTab) {
                        ForEach(ValidationViewModel.ResultTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    // Result table
                    resultTable
                        .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            kpiCard(
                label: "Validated",
                value: viewModel.validatedRows.count,
                color: .arveeTeal,
                icon: "checkmark.circle.fill"
            )
            kpiCard(
                label: "Discrepancies",
                value: viewModel.discrepancies.count,
                color: .arveeCoral,
                icon: "exclamationmark.triangle.fill"
            )
            kpiCard(
                label: "Unmatched Tx",
                value: viewModel.unmatchedTransactions.count,
                color: .arveeInkMuted,
                icon: "doc.questionmark"
            )
            kpiCard(
                label: "Unmatched Proofs",
                value: viewModel.unmatchedProofs.count,
                color: .arveeInkMuted,
                icon: "photo.on.rectangle"
            )
        }
        .padding(.horizontal, 16)
    }

    private func kpiCard(label: String, value: Int, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.arveeInkMuted)
            }
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.arveeInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .arveeCard(cornerRadius: 12)
    }

    // MARK: - Result Table

    @ViewBuilder
    private var resultTable: some View {
        let rows: [ResultRow] = {
            switch viewModel.selectedTab {
            case .validated: return viewModel.validatedRows
            case .discrepancies: return viewModel.discrepancies
            case .unmatchedTx: return viewModel.unmatchedTransactions
            case .unmatchedProofs: return viewModel.unmatchedProofs
            }
        }()

        if rows.isEmpty {
            Text("No items")
                .foregroundColor(.arveeInkMuted)
                .padding()
        } else {
            ResultTableView(rows: rows)
        }
    }
}
