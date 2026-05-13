import SwiftUI
import PhotosUI

struct UploadView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var validationVM: ValidationViewModel
    @State private var loadSessionId = ""
    @State private var showLoadField = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Error banner
                    if let error = sessionVM.errorMessage ?? validationVM.errorMessage {
                        StatusBanner(message: error, type: .error)
                    }

                    // Session bar (compact)
                    sessionBar

                    if sessionVM.hasSession {
                        // Upload cards
                        uploadSection

                        // Actions
                        actionButtons

                        // Progress
                        if validationVM.isValidating {
                            validatingIndicator
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .arveePageBackground()
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Session Bar

    private var sessionBar: some View {
        VStack(spacing: 12) {
            if let sessionId = sessionVM.sessionId {
                // Active session row
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.arveeTeal)
                        .frame(width: 8, height: 8)
                    Text("Session")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.arveeInkMuted)
                    Text(sessionId)
                        .font(.arveeMono(.caption2))
                        .foregroundColor(.arveeInk)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        sessionVM.clear()
                        validationVM.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.arveeInkMuted)
                    }
                }
            } else {
                // No session — create or load
                HStack(spacing: 10) {
                    Button {
                        Task { await sessionVM.createSession() }
                    } label: {
                        Label("New Session", systemImage: "plus.circle.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(ArveePrimaryCompactButtonStyle())

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLoadField.toggle()
                        }
                    } label: {
                        Label("Load", systemImage: "tray.and.arrow.down")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                    }
                    .buttonStyle(ArveeMutedCompactButtonStyle())
                }

                if showLoadField {
                    HStack(spacing: 8) {
                        TextField("Paste session ID", text: $loadSessionId)
                            .textFieldStyle(ArveeTextFieldStyle())
                            .textInputAutocapitalization(.never)

                        Button {
                            let id = loadSessionId.trimmingCharacters(in: .whitespaces)
                            guard !id.isEmpty else { return }
                            Task { await sessionVM.loadSession(id: id) }
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.arveeTealGradient)
                        }
                        .disabled(loadSessionId.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            if sessionVM.isLoading {
                ProgressView()
                    .tint(.arveeTeal)
            }
        }
        .padding(14)
        .arveeCard(cornerRadius: 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(spacing: 14) {
            uploadCard(
                title: "Transactions",
                subtitle: "Bank statements or transaction records",
                icon: "doc.text",
                badge: "PDF / Image",
                selection: $validationVM.transactionPhotos,
                count: validationVM.transactionFiles.count
            )

            uploadCard(
                title: "Proofs",
                subtitle: "Receipts or proof-of-purchase images",
                icon: "receipt",
                badge: "PNG / JPG",
                selection: $validationVM.proofPhotos,
                count: validationVM.proofFiles.count
            )
        }
    }

    private func uploadCard(
        title: String,
        subtitle: String,
        icon: String,
        badge: String,
        selection: Binding<[PhotosPickerItem]>,
        count: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.arveeTeal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.arveeInk)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.arveeInkMuted)
                }
                Spacer()
                Text(badge)
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundColor(.arveeTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.arveeTeal.opacity(0.08))
                    .cornerRadius(6)
            }

            PhotosPicker(
                selection: selection,
                maxSelectionCount: 20,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                        .font(.subheadline)
                    Text(count > 0 ? "\(count) selected — tap to change" : "Select photos")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                }
                .foregroundColor(.arveeTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.arveeCard.opacity(0.6))
                .cornerRadius(12)
                .arveeDashedBorder()
            }
        }
        .padding(16)
        .arveeCard()
        .padding(.horizontal, 16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                guard let sessionId = sessionVM.sessionId else { return }
                Task {
                    await validationVM.loadPhotos()
                    await validationVM.validate(sessionId: sessionId)
                }
            } label: {
                Label("Run Validation", systemImage: "checkmark.shield.fill")
            }
            .buttonStyle(ArveePrimaryButtonStyle())
            .disabled(
                validationVM.transactionPhotos.isEmpty && validationVM.proofPhotos.isEmpty
            )

            Button {
                validationVM.clear()
            } label: {
                Label("Clear All", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ArveeTertiaryButtonStyle())
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Validating Indicator

    private var validatingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.arveeTeal)
            Text("Validating receipts...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.arveeInkMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.arveeMint.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Compact Button Styles

struct ArveePrimaryCompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.arveeTealGradient)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ArveeMutedCompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.arveeTealDark)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.arveeMint.opacity(0.5))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
