import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct UploadView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var validationVM: ValidationViewModel
    @Binding var selectedTab: Int

    @State private var showLoadField = false
    @State private var loadSessionId = ""
    @State private var showTxDocPicker = false
    @State private var showProofDocPicker = false
    @State private var hourglassRotation: Double = 0
    @State private var bufferingTextIndex = 0
    @State private var previewImage: PreviewImage?

    @Environment(\.openURL) private var openURL

    private let bufferingTexts = [
        "Teaching receipts to line up politely...",
        "Tickling the totals until they confess...",
        "Whispering with your transactions and proofs...",
        "Polishing your validation results with sparkle...",
    ]

    private var currentStep: StepState {
        if validationVM.hasResults { return .complete }
        if validationVM.hasTransactionFiles || validationVM.hasProofFiles { return .active }
        return .pending
    }

    private var steps: [(label: String, state: StepState)] {
        let hasFiles = validationVM.hasTransactionFiles || validationVM.hasProofFiles
        let hasResults = validationVM.hasResults
        return [
            ("Upload", hasFiles || hasResults ? (hasResults ? .complete : .complete) : .active),
            ("Validate", hasResults ? .complete : (hasFiles ? .active : .pending)),
            ("Review", hasResults ? .active : .pending),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Error banner
                    if let error = sessionVM.errorMessage ?? validationVM.errorMessage {
                        StatusBanner(message: error, type: .error)
                    }

                    // Step indicator
                    StepIndicator(steps: steps)
                        .padding(.horizontal, 4)

                    // Upload cards (always visible)
                    uploadSection

                    // Validate button
                    if validationVM.hasTransactionFiles || validationVM.hasProofFiles {
                        validateButton
                    }

                    // Validating indicator
                    if validationVM.isValidating {
                        validatingOverlay
                    }

                    // Success state
                    if validationVM.hasResults {
                        successCard
                    }

                    // Session management (collapsed)
                    sessionFooter

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .arveePageBackground()
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if sessionVM.hasSession {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.arveeSuccess)
                                .frame(width: 6, height: 6)
                            Text(sessionVM.sessionId?.prefix(8) ?? "")
                                .font(.arveeMono(.caption2))
                                .foregroundColor(.arveeInkMuted)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showTxDocPicker,
                allowedContentTypes: [.pdf, .commaSeparatedText],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    validationVM.transactionDocumentURLs.append(contentsOf: urls)
                }
            }
            .fileImporter(
                isPresented: $showProofDocPicker,
                allowedContentTypes: [.pdf, .commaSeparatedText, .image],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    validationVM.proofDocumentURLs.append(contentsOf: urls)
                }
            }
        }
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(spacing: 14) {
            uploadCard(
                title: "Transactions",
                subtitle: "Bank statements or transaction records",
                icon: "doc.text.fill",
                photoSelection: $validationVM.transactionPhotos,
                documentURLs: validationVM.transactionDocumentURLs,
                photoCount: validationVM.transactionPhotos.count,
                onImportFiles: { showTxDocPicker = true },
                onRemovePhoto: { validationVM.removeTransactionPhoto(at: $0) },
                onRemoveDocument: { validationVM.removeTransactionDocument(at: $0) }
            )

            uploadCard(
                title: "Proofs",
                subtitle: "Receipts or proof-of-purchase images",
                icon: "receipt.fill",
                photoSelection: $validationVM.proofPhotos,
                documentURLs: validationVM.proofDocumentURLs,
                photoCount: validationVM.proofPhotos.count,
                onImportFiles: { showProofDocPicker = true },
                onRemovePhoto: { validationVM.removeProofPhoto(at: $0) },
                onRemoveDocument: { validationVM.removeProofDocument(at: $0) }
            )
        }
    }

    private func uploadCard(
        title: String,
        subtitle: String,
        icon: String,
        photoSelection: Binding<[PhotosPickerItem]>,
        documentURLs: [URL],
        photoCount: Int,
        onImportFiles: @escaping () -> Void,
        onRemovePhoto: @escaping (Int) -> Void,
        onRemoveDocument: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.arveeTealSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(.arveeTeal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.arveeInk)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.arveeInkMuted)
                }
                Spacer()
                let total = photoCount + documentURLs.count
                if total > 0 {
                    Text("\(total) file\(total == 1 ? "" : "s")")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.arveeTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.arveeTealSoft)
                        .cornerRadius(8)
                }
            }

            // Picker buttons
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: photoSelection,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.arveeTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.arveeTealSoft)
                        .cornerRadius(12)
                        .arveeDashedBorder()
                }

                Button(action: onImportFiles) {
                    Label("Files", systemImage: "folder")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.arveeCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.arveeCoral.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.arveeCoral.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [8, 5]))
                        )
                }
            }

            // Selected files list
            let hasItems = photoCount > 0 || !documentURLs.isEmpty
            if hasItems {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.arveeInkMuted)
                        Text("Tap a file to preview")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                        Spacer()
                    }

                    // Photo items
                    ForEach(0..<photoCount, id: \.self) { idx in
                        ArveeFileRow(
                            filename: "Photo \(idx + 1).jpg",
                            subtitle: "From photo library",
                            onTap: {
                                Task {
                                    await previewPhoto(at: idx, from: photoSelection.wrappedValue)
                                }
                            }
                        ) {
                            onRemovePhoto(idx)
                        }
                    }
                    // Document items
                    ForEach(Array(documentURLs.enumerated()), id: \.offset) { idx, url in
                        ArveeFileRow(
                            filename: url.lastPathComponent,
                            subtitle: url.pathExtension.uppercased(),
                            onTap: {
                                _ = openURL(url)
                            }
                        ) {
                            onRemoveDocument(idx)
                        }
                    }
                }
            }
        }
        .padding(16)
        .arveeCard()
        .padding(.horizontal, 16)
        .sheet(item: $previewImage) { item in
            NavigationStack {
                Color.black
                    .overlay(
                        Image(uiImage: item.image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    )
                    .ignoresSafeArea()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                previewImage = nil
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
        }
    }

    // MARK: - Validate Button

    private var validateButton: some View {
        Button {
            Task {
                await sessionVM.ensureSession()
                guard let sessionId = sessionVM.sessionId else { return }
                await validationVM.loadAllFiles()
                await validationVM.validate(sessionId: sessionId)
            }
        } label: {
            Label("Run Validation", systemImage: "checkmark.shield.fill")
        }
        .buttonStyle(ArveePrimaryButtonStyle())
        .disabled(validationVM.isValidating)
        .padding(.horizontal, 24)
    }

    // MARK: - Validating Overlay

    private var validatingOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.arveeTeal)
                .rotationEffect(.degrees(hourglassRotation))
                .onAppear {
                    hourglassRotation = 0
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        hourglassRotation = 360
                    }
                }

            Text("Validation in progress")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.arveeInk)

            Text(validationVM.validationStage ?? bufferingTexts[bufferingTextIndex])
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.arveeInk)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.25), value: bufferingTextIndex)
                .onReceive(Timer.publish(every: 1.7, on: .main, in: .common).autoconnect()) { _ in
                    bufferingTextIndex = (bufferingTextIndex + 1) % bufferingTexts.count
                }

            Text("This may take a moment while we process your documents")
                .font(.caption)
                .foregroundColor(.arveeInkMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .arveeGradientCard(accent: .arveeTeal, cornerRadius: 16)
        .padding(.horizontal, 16)
    }

    // MARK: - Success Card

    private var successCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.arveeSuccess)
            Text("Validation Complete")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.arveeInk)
            Text("\(validationVM.validatedRows.count) validated · \(validationVM.discrepancies.count) discrepancies")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.arveeInkMuted)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 2
                }
            } label: {
                Label("View Results", systemImage: "arrow.right")
            }
            .buttonStyle(ArveePrimaryButtonStyle())

            Button {
                validationVM.clear()
            } label: {
                Text("Start New")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.arveeInkMuted)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .arveeGradientCard(accent: .arveeSuccess, cornerRadius: 16)
        .padding(.horizontal, 16)
    }

    // MARK: - Session Footer

    private var sessionFooter: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLoadField.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.caption)
                    Text("Load existing session")
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.arveeInkMuted)
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
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 8)
    }

    private func previewPhoto(at index: Int, from items: [PhotosPickerItem]) async {
        guard index < items.count else { return }
        if let data = try? await items[index].loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            previewImage = PreviewImage(image: image)
        }
    }
}

private struct PreviewImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
