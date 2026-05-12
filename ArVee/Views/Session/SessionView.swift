import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var manualSessionId = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let error = viewModel.errorMessage {
                        StatusBanner(message: error, type: .error)
                    }

                    if let sessionId = viewModel.sessionId {
                        activeSessionSection(sessionId: sessionId)
                    } else {
                        noSessionSection
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .arveePageBackground()
            .navigationTitle("Session")
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Loading session...")
                }
            }
        }
    }

    // MARK: - No Session

    private var noSessionSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 56))
                .foregroundColor(.arveeInkMuted)
                .padding(.top, 20)

            Text("No Active Session")
                .font(.arveeBrand(22))
                .foregroundColor(.arveeInk)

            Text("Create a new session or load an existing one to get started.")
                .font(.subheadline)
                .foregroundColor(.arveeInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.createSession() }
            } label: {
                Label("Create New Session", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ArveePrimaryButtonStyle())
            .padding(.horizontal, 32)

            dividerWithText("OR")

            VStack(alignment: .leading, spacing: 12) {
                Text("LOAD EXISTING")
                    .font(.arveeEyebrow())
                    .foregroundColor(.arveeInkMuted)
                    .tracking(1)

                TextField("Enter Session ID", text: $manualSessionId)
                    .textFieldStyle(ArveeTextFieldStyle())
                    .textInputAutocapitalization(.never)

                Button {
                    let id = manualSessionId.trimmingCharacters(in: .whitespaces)
                    guard !id.isEmpty else { return }
                    Task { await viewModel.loadSession(id: id) }
                } label: {
                    Text("Load Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArveeSecondaryButtonStyle())
                .disabled(manualSessionId.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
            .arveeCard()
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Active Session

    private func activeSessionSection(sessionId: String) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.arveeTeal)
                        .frame(width: 10, height: 10)
                    Text("Active Session")
                        .font(.arveeHeadline())
                        .foregroundColor(.arveeInk)
                    Spacer()
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.arveeDanger.opacity(0.7))
                    }
                }

                HStack {
                    Text(sessionId)
                        .font(.arveeMono(.caption))
                        .foregroundColor(.arveeInkMuted)
                        .lineLimit(1)
                    Spacer()
                }

                Divider().overlay(Color.arveeLine)

                if !viewModel.transactions.isEmpty {
                    inputSummary(label: "Transactions", count: viewModel.transactions.count, icon: "doc.text")
                }
                if !viewModel.proofs.isEmpty {
                    inputSummary(label: "Proofs", count: viewModel.proofs.count, icon: "receipt")
                }
            }
            .padding(16)
            .arveeCard()
            .padding(.horizontal, 24)
        }
    }

    private func inputSummary(label: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.arveeTeal)
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.arveeInk)
            Spacer()
            Text("\(count) items")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(.arveeTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.arveeTeal.opacity(0.1))
                .cornerRadius(999)
        }
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            Rectangle().fill(Color.arveeLine).frame(height: 1)
            Text(text)
                .font(.arveeEyebrow())
                .foregroundColor(.arveeInkMuted)
            Rectangle().fill(Color.arveeLine).frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}
