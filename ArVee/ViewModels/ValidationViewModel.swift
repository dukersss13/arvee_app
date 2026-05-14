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

    var hasResults: Bool { !validatedRows.isEmpty || !discrepancies.isEmpty || !unmatchedTransactions.isEmpty || !unmatchedProofs.isEmpty || !recommendations.isEmpty }

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

    // MARK: - Interactive Actions

    /// Accept a discrepancy with optional adjusted amount and comment, moving it to validated.
    func acceptDiscrepancy(at index: Int, adjustedAmount: Double?, comment: String?) {
        guard index < discrepancies.count else { return }
        var row = discrepancies.remove(at: index)
        var fields = row.fields
        fields["Result"] = "Validated (Manual)"
        if let adj = adjustedAmount {
            fields["Adjusted Amount"] = String(format: "%.2f", adj)
        }
        if let c = comment, !c.isEmpty {
            fields["Comment"] = c
        }
        row = ResultRow(fields: fields)
        validatedRows.append(row)
    }

    /// Accept a recommendation, moving it to validated and removing matched items from unmatched lists.
    func acceptRecommendation(at index: Int) {
        guard index < recommendations.count else { return }
        let rec = recommendations.remove(at: index)
        var fields = rec.fields
        fields["Result"] = "Validated (Recommended)"

        // Remove matching items from unmatched lists by business name
        let txName = rec.value(for: "Transaction Business Name")
        let proofName = rec.value(for: "Proof Business Name")
        if !txName.isEmpty {
            unmatchedTransactions.removeAll { $0.value(for: "Business Name") == txName || $0.value(for: "business_name") == txName }
        }
        if !proofName.isEmpty {
            unmatchedProofs.removeAll { $0.value(for: "Business Name") == proofName || $0.value(for: "business_name") == proofName }
        }

        validatedRows.append(ResultRow(fields: fields))
    }

    /// Accept all recommendations at once.
    func acceptAllRecommendations() {
        while !recommendations.isEmpty {
            acceptRecommendation(at: 0)
        }
    }

    /// Manually match an unmatched transaction with an unmatched proof.
    func manualMatch(transactionIndex: Int, proofIndex: Int) {
        guard transactionIndex < unmatchedTransactions.count,
              proofIndex < unmatchedProofs.count else { return }
        let tx = unmatchedTransactions.remove(at: transactionIndex)
        let proof = unmatchedProofs.remove(at: proofIndex)

        // Build a validated row combining fields from both
        var fields: [String: String] = [:]
        let txBiz = tx.value(for: "Business Name").isEmpty ? tx.value(for: "business_name") : tx.value(for: "Business Name")
        let txTotal = tx.value(for: "Total").isEmpty ? tx.value(for: "total") : tx.value(for: "Total")
        let txDate = tx.value(for: "Date").isEmpty ? tx.value(for: "date") : tx.value(for: "Date")
        let proofBiz = proof.value(for: "Business Name").isEmpty ? proof.value(for: "business_name") : proof.value(for: "Business Name")
        let proofTotal = proof.value(for: "Total").isEmpty ? proof.value(for: "total") : proof.value(for: "Total")
        let proofDate = proof.value(for: "Date").isEmpty ? proof.value(for: "date") : proof.value(for: "Date")

        fields["Transaction Business Name"] = txBiz
        fields["Transaction Total"] = txTotal
        fields["Transaction Date"] = txDate
        fields["Proof Business Name"] = proofBiz
        fields["Proof Total"] = proofTotal
        fields["Proof Date"] = proofDate
        fields["Result"] = "Manually Matched"
        fields["Reason"] = "Matched manually by user"

        validatedRows.append(ResultRow(fields: fields))
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
