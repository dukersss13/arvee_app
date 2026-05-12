import SwiftUI
import PhotosUI

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
                    uploadView
                }
            }
            .arveePageBackground()
            .navigationTitle("Validate")
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay {
                if viewModel.isValidating {
                    LoadingOverlay(message: "Validating receipts...")
                }
            }
        }
    }

    // MARK: - No Session

    private var noSessionPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.arveeCoral)
            Text("Create or load a session first")
                .font(.arveeHeadline())
                .foregroundColor(.arveeInk)
            Text("Go to the Session tab to get started.")
                .font(.subheadline)
                .foregroundColor(.arveeInkMuted)
        }
    }

    // MARK: - Upload

    private var uploadView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let error = viewModel.errorMessage {
                    StatusBanner(message: error, type: .error)
                }

                filePickerSection(
                    title: "Transactions",
                    subtitle: "Upload bank statements or transaction records",
                    icon: "doc.text",
                    selection: $viewModel.transactionPhotos,
                    count: viewModel.transactionFiles.count
                )

                filePickerSection(
                    title: "Proofs",
                    subtitle: "Upload receipts or proof of purchase",
                    icon: "receipt",
                    selection: $viewModel.proofPhotos,
                    count: viewModel.proofFiles.count
                )

                Button {
                    guard let sessionId = sessionVM.sessionId else { return }
                    Task {
                        await viewModel.loadPhotos()
                        await viewModel.validate(sessionId: sessionId)
                    }
                } label: {
                    Label("Run Validation", systemImage: "checkmark.shield.fill")
                }
                .buttonStyle(ArveePrimaryButtonStyle())
                .disabled(viewModel.transactionPhotos.isEmpty && viewModel.proofPhotos.isEmpty)
                .padding(.horizontal, 24)

                Button {
                    viewModel.clear()
                } label: {
                    Label("Clear All", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArveeTertiaryButtonStyle())
                .padding(.horizontal, 24)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func filePickerSection(
        title: String,
        subtitle: String,
        icon: String,
        selection: Binding<[PhotosPickerItem]>,
        count: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.arveeTeal)
                Text(title)
                    .font(.arveeHeadline())
                    .foregroundColor(.arveeInk)
                Spacer()
                if count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("\(count) ready")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .foregroundColor(.arveeTeal)
                }
            }

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.arveeInkMuted)

            PhotosPicker(
                selection: selection,
                maxSelectionCount: 20,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Select Photos")
                }
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.arveeTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.arveeCard.opacity(0.7))
                .cornerRadius(12)
                .arveeDashedBorder()
            }
        }
        .padding(16)
        .arveeCard()
        .padding(.horizontal, 24)
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            if let summary = viewModel.summary {
                Text(summary)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInk)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.arveeMint.opacity(0.3))
            }

            Picker("Results", selection: $viewModel.selectedTab) {
                ForEach(ValidationViewModel.ResultTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            resultTable

            Spacer()

            Button {
                viewModel.clear()
            } label: {
                Label("Clear Results", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ArveeDangerButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

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
