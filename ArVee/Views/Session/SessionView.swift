import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var manualSessionId = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let error = viewModel.errorMessage {
                    StatusBanner(message: error, type: .error)
                }

                if let sessionId = viewModel.sessionId {
                    activeSessionSection(sessionId: sessionId)
                } else {
                    noSessionSection
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Session")
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Loading session...")
                }
            }
        }
    }

    // MARK: - No Session

    private var noSessionSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Active Session")
                .font(.title2.weight(.semibold))

            Button {
                Task { await viewModel.createSession() }
            } label: {
                Label("Create New Session", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            dividerWithText("OR")

            HStack {
                TextField("Enter Session ID", text: $manualSessionId)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)

                Button("Load") {
                    let id = manualSessionId.trimmingCharacters(in: .whitespaces)
                    guard !id.isEmpty else { return }
                    Task { await viewModel.loadSession(id: id) }
                }
                .buttonStyle(.bordered)
                .disabled(manualSessionId.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Active Session

    private func activeSessionSection(sessionId: String) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Active Session")
                        .font(.headline)
                    Text(sessionId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(role: .destructive) {
                    viewModel.clear()
                } label: {
                    Image(systemName: "xmark.circle")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            if !viewModel.transactions.isEmpty {
                inputSummary(label: "Transactions", count: viewModel.transactions.count)
            }
            if !viewModel.proofs.isEmpty {
                inputSummary(label: "Proofs", count: viewModel.proofs.count)
            }
        }
    }

    private func inputSummary(label: String, count: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text("\(count) items")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}
