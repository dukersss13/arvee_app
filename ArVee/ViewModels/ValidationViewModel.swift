import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
final class ValidationViewModel: ObservableObject {
    @Published var isValidating = false
    @Published var errorMessage: String?
    @Published var summary: String?
    @Published var validatedRows: [ResultRow] = []
    @Published var discrepancies: [ResultRow] = []
    @Published var unmatchedTransactions: [ResultRow] = []
    @Published var unmatchedProofs: [ResultRow] = []
    @Published var recommendations: [ResultRow] = []
    @Published var selectedTab: ResultTab = .validated

    // Photo selection
    @Published var transactionPhotos: [PhotosPickerItem] = []
    @Published var proofPhotos: [PhotosPickerItem] = []

    // Document selection (PDF/CSV)
    @Published var transactionDocumentURLs: [URL] = []
    @Published var proofDocumentURLs: [URL] = []

    // Merged payloads (photos + documents)
    @Published var transactionFiles: [FilePayload] = []
    @Published var proofFiles: [FilePayload] = []

    private let api = APIService.shared

    var hasResults: Bool { !validatedRows.isEmpty || !discrepancies.isEmpty }

    var hasTransactionFiles: Bool {
        !transactionPhotos.isEmpty || !transactionDocumentURLs.isEmpty
    }

    var hasProofFiles: Bool {
        !proofPhotos.isEmpty || !proofDocumentURLs.isEmpty
    }

    var totalTransactionCount: Int {
        transactionPhotos.count + transactionDocumentURLs.count
    }

    var totalProofCount: Int {
        proofPhotos.count + proofDocumentURLs.count
    }

    enum ResultTab: String, CaseIterable {
        case validated = "Validated"
        case discrepancies = "Discrepancies"
        case unmatchedTx = "Unmatched Tx"
        case unmatchedProofs = "Unmatched Proofs"
    }

    func validate(sessionId: String) async {
        isValidating = true
        errorMessage = nil
        do {
            let response = try await api.validate(
                sessionId: sessionId,
                transactionFiles: transactionFiles,
                proofFiles: proofFiles
            )
            summary = response.summary
            validatedRows = (response.validatedTransactions ?? []).map { ResultRow(from: $0) }
            discrepancies = (response.discrepancies ?? []).map { ResultRow(from: $0) }
            unmatchedTransactions = (response.unmatchedTransactions ?? []).map { ResultRow(from: $0) }
            unmatchedProofs = (response.unmatchedProofs ?? []).map { ResultRow(from: $0) }
            recommendations = (response.recommendations ?? []).map { ResultRow(from: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isValidating = false
    }

    /// Load all selected files (photos + documents) into payloads for upload.
    func loadAllFiles() async {
        let photoTx = await loadPayloads(from: transactionPhotos)
        let docTx = loadDocuments(from: transactionDocumentURLs)
        transactionFiles = photoTx + docTx

        let photoProof = await loadPayloads(from: proofPhotos)
        let docProof = loadDocuments(from: proofDocumentURLs)
        proofFiles = photoProof + docProof
    }

    private func loadPayloads(from items: [PhotosPickerItem]) async -> [FilePayload] {
        var payloads: [FilePayload] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let filename = "image_\(UUID().uuidString.prefix(8)).jpg"
                payloads.append(FilePayload(filename: filename, data: data, mimeType: "image/jpeg"))
            }
        }
        return payloads
    }

    private func loadDocuments(from urls: [URL]) -> [FilePayload] {
        var payloads: [FilePayload] = []
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { continue }
            let ext = url.pathExtension.lowercased()
            let mime: String
            switch ext {
            case "pdf": mime = "application/pdf"
            case "csv": mime = "text/csv"
            default: mime = "application/octet-stream"
            }
            payloads.append(FilePayload(filename: url.lastPathComponent, data: data, mimeType: mime))
        }
        return payloads
    }

    func removeTransactionPhoto(at index: Int) {
        guard index < transactionPhotos.count else { return }
        transactionPhotos.remove(at: index)
    }

    func removeTransactionDocument(at index: Int) {
        guard index < transactionDocumentURLs.count else { return }
        transactionDocumentURLs.remove(at: index)
    }

    func removeProofPhoto(at index: Int) {
        guard index < proofPhotos.count else { return }
        proofPhotos.remove(at: index)
    }

    func removeProofDocument(at index: Int) {
        guard index < proofDocumentURLs.count else { return }
        proofDocumentURLs.remove(at: index)
    }

    func clear() {
        summary = nil
        validatedRows = []
        discrepancies = []
        unmatchedTransactions = []
        unmatchedProofs = []
        recommendations = []
        transactionPhotos = []
        proofPhotos = []
        transactionDocumentURLs = []
        proofDocumentURLs = []
        transactionFiles = []
        proofFiles = []
        errorMessage = nil
    }
}
