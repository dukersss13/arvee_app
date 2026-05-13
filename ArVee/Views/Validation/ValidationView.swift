import SwiftUI

struct ValidationView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var viewModel: ValidationViewModel
    @State private var isExporting = false

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
                        HStack(spacing: 12) {
                            Button {
                                exportPDF()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.arveeTeal)
                            }
                            .disabled(isExporting)
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
    }

    // MARK: - No Session

    private var noSessionPlaceholder: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.arveeTealSoft)
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.arveeTealGradient)
                }
                Text("No session active")
                    .font(.arveeHeadline())
                    .foregroundColor(.arveeInk)
                Text("Go to Upload to create a session and run validation.")
                    .font(.subheadline)
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(22)
            .arveeCard(cornerRadius: 20)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
    }

    // MARK: - Empty Results

    private var emptyResultsPlaceholder: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.arveeCoral.opacity(0.08))
                        .frame(width: 88, height: 88)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.arveeCoral)
                }
                Text("No results yet")
                    .font(.arveeHeadline())
                    .foregroundColor(.arveeInk)
                Text("Upload files and run validation from the Upload tab.")
                    .font(.subheadline)
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(22)
            .arveeCard(cornerRadius: 20)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Summary banner
            if let summary = viewModel.summary {
                HStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundColor(.arveeTeal)
                    Text(summary)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.arveeInk)
                        .lineLimit(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.arveeMint.opacity(0.3), Color.arveeMint.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    // KPI cards
                    kpiRow
                        .padding(.top, 10)

                    // Pill tab picker
                    pillTabPicker
                        .padding(.horizontal, 16)

                    // Result table
                    resultTable
                        .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            gradientKpiCard(
                label: "Validated",
                value: viewModel.validatedRows.count,
                accentColor: .arveeTeal,
                icon: "checkmark.circle.fill"
            )
            gradientKpiCard(
                label: "Discrepancies",
                value: viewModel.discrepancies.count,
                accentColor: .arveeCoral,
                icon: "exclamationmark.triangle.fill"
            )
            gradientKpiCard(
                label: "Unmatched Tx",
                value: viewModel.unmatchedTransactions.count,
                accentColor: .arveeInkMuted,
                icon: "doc.questionmark"
            )
            gradientKpiCard(
                label: "Unmatched Proofs",
                value: viewModel.unmatchedProofs.count,
                accentColor: .arveeInkMuted,
                icon: "photo.on.rectangle"
            )
        }
        .padding(.horizontal, 16)
    }

    private func gradientKpiCard(label: String, value: Int, accentColor: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .tracking(0.5)
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentColor.opacity(0.6))
            }
            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.arveeInk)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .arveeGradientCard(accent: accentColor, cornerRadius: 14)
    }

    // MARK: - Pill Tab Picker

    private var pillTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ValidationViewModel.ResultTab.allCases, id: \.self) { tab in
                    let count = tabCount(for: tab)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(tab.rawValue)
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(viewModel.selectedTab == tab ? .arveeTeal : .arveeInkMuted)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        viewModel.selectedTab == tab
                                            ? Color.arveeTealSoft
                                            : Color.arveeInkMuted.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                        }
                        .foregroundColor(viewModel.selectedTab == tab ? .arveeTeal : .arveeInkMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedTab == tab
                                ? Color.arveeTealSoft
                                : Color.clear
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    viewModel.selectedTab == tab
                                        ? Color.arveeTeal.opacity(0.3)
                                        : Color.arveeLine,
                                    lineWidth: 0.5
                                )
                        )
                    }
                }
            }
        }
    }

    private func tabCount(for tab: ValidationViewModel.ResultTab) -> Int {
        switch tab {
        case .validated: return viewModel.validatedRows.count
        case .discrepancies: return viewModel.discrepancies.count
        case .unmatchedTx: return viewModel.unmatchedTransactions.count
        case .unmatchedProofs: return viewModel.unmatchedProofs.count
        }
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
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundColor(.arveeInkMuted)
                Text("No items")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .arveeCard(cornerRadius: 14)
            .padding(.horizontal, 16)
        } else {
            ResultTableView(rows: rows)
        }
    }

    // MARK: - Export

    private func exportPDF() {
        guard !viewModel.validatedRows.isEmpty else { return }
        isExporting = true
        Task {
            do {
                let rowDicts: [[String: Any]] = viewModel.validatedRows.map { row in
                    row.fields as [String: Any]
                }
                let pdfData = try await APIService.shared.exportPDF(rows: rowDicts)
                // Share the PDF via share sheet
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("validated_transactions.pdf")
                try pdfData.write(to: tempURL)
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
            }
            isExporting = false
        }
    }
}
