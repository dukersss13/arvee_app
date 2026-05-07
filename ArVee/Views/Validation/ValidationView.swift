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
            .navigationTitle("Validate")
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
                .foregroundColor(.orange)
            Text("Create or load a session first")
                .font(.headline)
            Text("Go to the Session tab to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Upload

    private var uploadView: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                    Label("Validate", systemImage: "checkmark.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.transactionPhotos.isEmpty && viewModel.proofPhotos.isEmpty)
                .padding(.horizontal, 32)
            }
            .padding(.top)
        }
    }

    private func filePickerSection(
        title: String,
        subtitle: String,
        icon: String,
        selection: Binding<[PhotosPickerItem]>,
        count: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
                if count > 0 {
                    Text("\(count) ready")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            PhotosPicker(
                selection: selection,
                maxSelectionCount: 20,
                matching: .images
            ) {
                Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            if let summary = viewModel.summary {
                Text(summary)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
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

            Button(role: .destructive) {
                viewModel.clear()
            } label: {
                Label("Clear Results", systemImage: "trash")
            }
            .padding()
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
                .foregroundColor(.secondary)
                .padding()
        } else {
            ResultTableView(rows: rows)
        }
    }
}
