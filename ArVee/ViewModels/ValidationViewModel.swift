import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
final class ValidationViewModel: ObservableObject {
    @Published var isValidating = false
    @Published var validationStage: String?
    @Published var validationPercent: Int?
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
    private var currentSessionId: String?
    private var validationSSEClient: ValidationSSEClient?
    private let acceptedSourceKey = "__accepted_source"
    private let originalTransactionTotalKey = "__original_transaction_total"
    private let originalTransactionCategoryKey = "__original_transaction_category"
    private let originalProofCategoryKey = "__original_proof_category"
    private let originalReasonKey = "__original_reason"

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
        validationStage = "Starting Validation..."
        validationPercent = 0
        errorMessage = nil
        currentSessionId = sessionId
        do {
            try await runValidationStream(
                sessionId: sessionId,
                transactionFiles: transactionFiles,
                proofFiles: proofFiles
            )
        } catch {
            // Fallback for environments where streamed validation is unavailable.
            do {
                validationStage = "Taking the scenic route through your documents..."
                let response = try await api.validate(
                    sessionId: sessionId,
                    transactionFiles: transactionFiles,
                    proofFiles: proofFiles
                )
                applyValidationResponse(response)
                validationPercent = 100
                validationStage = "Validation complete."
            } catch {
                if (error as NSError).code == NSURLErrorCancelled {
                    errorMessage = nil
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
        isValidating = false
        validationStage = nil
        validationPercent = nil
    }

    /// Cancel an in-progress validation run.
    func cancelValidation() {
        validationSSEClient?.cancel()
        validationSSEClient = nil
        isValidating = false
        validationStage = nil
        validationPercent = nil
        errorMessage = nil
    }

    private func runValidationStream(
        sessionId: String,
        transactionFiles: [FilePayload],
        proofFiles: [FilePayload]
    ) async throws {
        let request = api.validateStreamRequest(
            sessionId: sessionId,
            transactionFiles: transactionFiles,
            proofFiles: proofFiles
        )

        let client = ValidationSSEClient()
        validationSSEClient = client

        try await withCheckedThrowingContinuation { continuation in
            var didFinish = false

            func completeOnce(_ work: @escaping @MainActor () -> Void) {
                guard !didFinish else { return }
                didFinish = true
                Task { @MainActor in
                    work()
                    self.validationSSEClient = nil
                }
            }

            client.onProgress = { [weak self] stage, percent in
                Task { @MainActor in
                    self?.validationStage = stage
                    self?.validationPercent = percent
                }
            }

            client.onDone = { [weak self] response in
                guard let self = self else { return }
                completeOnce {
                    self.applyValidationResponse(response)
                    continuation.resume()
                }
            }

            client.onError = { [weak self] message in
                completeOnce {
                    self?.validationSSEClient?.cancel()
                    continuation.resume(throwing: NSError(
                        domain: "ValidationSSEClient",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    ))
                }
            }

            client.start(
                url: request.url,
                body: request.body,
                contentType: request.contentType,
                headers: request.headers
            )
        }
    }

    private func applyValidationResponse(_ response: ValidationResponse) {
        summary = response.summary
        validatedRows = (response.validatedTransactions ?? []).map { ResultRow(from: $0) }
        discrepancies = (response.discrepancies ?? []).map { ResultRow(from: $0) }
        unmatchedTransactions = (response.unmatchedTransactions ?? []).map { ResultRow(from: $0) }
        unmatchedProofs = (response.unmatchedProofs ?? []).map { ResultRow(from: $0) }
        recommendations = (response.recommendations ?? []).map { ResultRow(from: $0) }
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
        let originalTransactionTotal = fields["Transaction Total"] ?? fields["total"] ?? ""

        let transactionTotal = adjustedAmount ?? parseCurrencyAmount(fields["Transaction Total"] ?? fields["total"] ?? "")
        let proofTotal = parseCurrencyAmount(fields["Proof Total"] ?? "")
        if let tx = transactionTotal, let proof = proofTotal, abs(tx - proof) > 0.0001 {
            discrepancies.insert(row, at: index)
            errorMessage = "Adjusted amount must equal proof total before accepting this match."
            return
        }

        fields["Result"] = "Validated (Discrepancy Accepted)"
        if let tx = transactionTotal {
            fields["Adjusted Amount"] = String(format: "%.2f", tx)
            fields["Transaction Total"] = String(format: "%.2f", tx)
        }

        if fields["Category"]?.isEmpty ?? true {
            let txCategory = fields["Transaction Category"] ?? ""
            let proofCategory = fields["Proof Category"] ?? ""
            fields["Category"] = !txCategory.isEmpty ? txCategory : proofCategory
        }
        if let c = comment, !c.isEmpty {
            fields["Comment"] = c
        }
        fields[acceptedSourceKey] = "discrepancy"
        fields[originalTransactionTotalKey] = originalTransactionTotal
        fields[originalTransactionCategoryKey] = fields["Transaction Category"] ?? ""
        fields[originalProofCategoryKey] = fields["Proof Category"] ?? ""
        fields[originalReasonKey] = fields["Reason"] ?? ""

        row = ResultRow(fields: fields)
        validatedRows.append(row)
        persistSessionStateIfPossible()
    }

    /// Accept a recommendation, moving it to validated and removing matched items from unmatched lists.
    func acceptRecommendation(at index: Int) {
        guard index < recommendations.count else { return }
        let rec = recommendations.remove(at: index)
        var fields = rec.fields
        fields["Result"] = "Validated (Recommended)"

        let txCategory = (
            fields["Transaction Category"]
            ?? fields["transaction_category"]
            ?? fields["Category"]
            ?? fields["category"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let proofCategory = (
            fields["Proof Category"]
            ?? fields["proof_category"]
            ?? fields["Category"]
            ?? fields["category"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let unifiedCategory = !txCategory.isEmpty
            ? txCategory
            : (!proofCategory.isEmpty ? proofCategory : "Other")

        // Keep all category fields in sync so validated cards always show
        // one editable category dropdown.
        fields["Category"] = unifiedCategory
        fields["Transaction Category"] = unifiedCategory
        fields["Proof Category"] = unifiedCategory
        fields[acceptedSourceKey] = "recommendation"
        fields[originalTransactionCategoryKey] = txCategory
        fields[originalProofCategoryKey] = proofCategory
        fields[originalReasonKey] = rec.value(for: "Reason")

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
        persistSessionStateIfPossible()
    }

    func canRemoveAcceptedValidatedRow(_ row: ResultRow) -> Bool {
        let source = row.value(for: acceptedSourceKey).lowercased()
        return source == "recommendation" || source == "discrepancy" || source == "manual"
    }

    func removeAcceptedValidatedRow(rowId: UUID) {
        guard let idx = validatedRows.firstIndex(where: { $0.id == rowId }) else { return }
        let row = validatedRows.remove(at: idx)
        let source = row.value(for: acceptedSourceKey).lowercased()

        if source == "discrepancy" {
            restoreDiscrepancy(from: row)
        } else if source == "recommendation" {
            restoreRecommendationAndUnmatchedRows(from: row)
        } else if source == "manual" {
            restoreManualMatch(from: row)
        }

        persistSessionStateIfPossible()
    }

    /// Update category for a validated match row and persist changes.
    func updateValidatedCategory(for rowId: UUID, category: String) {
        guard let idx = validatedRows.firstIndex(where: { $0.id == rowId }) else { return }
        var fields = validatedRows[idx].fields
        fields["Category"] = category
        fields["Transaction Category"] = category
        fields["Proof Category"] = category
        validatedRows[idx] = ResultRow(id: rowId, fields: fields)
        persistSessionStateIfPossible()
    }

    /// Accept all recommendations at once.
    func acceptAllRecommendations() {
        while !recommendations.isEmpty {
            acceptRecommendation(at: 0)
        }
    }

    /// Accept a user-selected subset of recommendations by row ID.
    func acceptRecommendations(withIds selectedIds: Set<UUID>) {
        guard !selectedIds.isEmpty else { return }

        let selectedIndices = recommendations.enumerated().compactMap { idx, row in
            selectedIds.contains(row.id) ? idx : nil
        }

        for idx in selectedIndices.sorted(by: >) {
            acceptRecommendation(at: idx)
        }
    }

    /// Manually match an unmatched transaction with an unmatched proof.
    func manualMatch(transactionIndex: Int, proofIndex: Int) {
        guard transactionIndex < unmatchedTransactions.count,
              proofIndex < unmatchedProofs.count else { return }
        let tx = unmatchedTransactions.remove(at: transactionIndex)
        let proof = unmatchedProofs.remove(at: proofIndex)

        let txBizForMatch = tx.value(for: "Business Name").isEmpty
            ? tx.value(for: "business_name")
            : tx.value(for: "Business Name")
        let proofBizForMatch = proof.value(for: "Business Name").isEmpty
            ? proof.value(for: "business_name")
            : proof.value(for: "Business Name")

        // If a recommendation references this manually matched pair,
        // remove it so users do not see stale accept options.
        recommendations.removeAll { rec in
            rec.value(for: "Transaction Business Name") == txBizForMatch
                && rec.value(for: "Proof Business Name") == proofBizForMatch
        }

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
        let txCategory = tx.value(for: "Category").isEmpty ? tx.value(for: "category") : tx.value(for: "Category")
        let proofCategory = proof.value(for: "Category").isEmpty ? proof.value(for: "category") : proof.value(for: "Category")
        let unifiedCategory = !txCategory.isEmpty ? txCategory : proofCategory
        if !unifiedCategory.isEmpty {
            fields["Category"] = unifiedCategory
            fields["Transaction Category"] = unifiedCategory
            fields["Proof Category"] = unifiedCategory
        }
        fields["Result"] = "Manually Matched"
        fields["Reason"] = "Matched manually by user"
        fields[acceptedSourceKey] = "manual"

        validatedRows.append(ResultRow(fields: fields))
        persistSessionStateIfPossible()
    }

    func saveCurrentState(sessionId: String) async {
        do {
            try await api.saveSessionState(sessionId: sessionId, state: buildSessionStatePayload())
        } catch {
            // Non-blocking persistence; surface a lightweight error for diagnostics.
            errorMessage = "Failed to sync session state: \(error.localizedDescription)"
        }
    }

    private func persistSessionStateIfPossible() {
        guard let sessionId = currentSessionId else { return }
        Task { await saveCurrentState(sessionId: sessionId) }
    }

    private func buildSessionStatePayload() -> [String: Any] {
        var payload: [String: Any] = [
            "validatedTransactions": validatedRows.map(\.fields),
            "discrepancies": discrepancies.map(\.fields),
            "unmatchedTransactions": unmatchedTransactions.map(\.fields),
            "unmatchedProofs": unmatchedProofs.map(\.fields),
            "recommendations": recommendations.map(\.fields),
        ]

        if let summary, !summary.isEmpty {
            payload["summary"] = summary
        }

        return payload
    }

    private func stripInternalFields(from fields: [String: String]) -> [String: String] {
        fields.filter { !($0.key.hasPrefix("__")) }
    }

    private func restoreDiscrepancy(from row: ResultRow) {
        var restored = stripInternalFields(from: row.fields)

        let originalTransactionTotal = row.value(for: originalTransactionTotalKey)
        if !originalTransactionTotal.isEmpty {
            restored["Transaction Total"] = originalTransactionTotal
        }

        restored.removeValue(forKey: "Result")
        restored.removeValue(forKey: "Adjusted Amount")
        restored.removeValue(forKey: "Comment")
        restored.removeValue(forKey: "Category")

        if !containsDiscrepancy(restored) {
            discrepancies.append(ResultRow(fields: restored))
        }
    }

    private func restoreRecommendationAndUnmatchedRows(from row: ResultRow) {
        let txCategory = row.value(for: originalTransactionCategoryKey).isEmpty
            ? row.value(for: "Transaction Category")
            : row.value(for: originalTransactionCategoryKey)
        let proofCategory = row.value(for: originalProofCategoryKey).isEmpty
            ? row.value(for: "Proof Category")
            : row.value(for: originalProofCategoryKey)
        let originalReason = row.value(for: originalReasonKey).isEmpty
            ? row.value(for: "Reason")
            : row.value(for: originalReasonKey)

        var recommendationFields: [String: String] = [
            "Transaction Business Name": row.value(for: "Transaction Business Name"),
            "Transaction Total": row.value(for: "Transaction Total"),
            "Transaction Date": row.value(for: "Transaction Date"),
            "Transaction Category": txCategory,
            "Proof Business Name": row.value(for: "Proof Business Name"),
            "Proof Total": row.value(for: "Proof Total"),
            "Proof Date": row.value(for: "Proof Date"),
            "Proof Category": proofCategory,
        ]
        if !originalReason.isEmpty {
            recommendationFields["Reason"] = originalReason
        }

        if !containsRecommendation(recommendationFields) {
            recommendations.append(ResultRow(fields: recommendationFields))
        }

        let txUnmatched: [String: String] = [
            "Business Name": row.value(for: "Transaction Business Name"),
            "Total": row.value(for: "Transaction Total"),
            "Date": row.value(for: "Transaction Date"),
            "Category": txCategory,
        ]
        if !containsUnmatched(unmatchedTransactions, candidate: txUnmatched) {
            unmatchedTransactions.append(ResultRow(fields: txUnmatched))
        }

        let proofUnmatched: [String: String] = [
            "Business Name": row.value(for: "Proof Business Name"),
            "Total": row.value(for: "Proof Total"),
            "Date": row.value(for: "Proof Date"),
            "Category": proofCategory,
        ]
        if !containsUnmatched(unmatchedProofs, candidate: proofUnmatched) {
            unmatchedProofs.append(ResultRow(fields: proofUnmatched))
        }
    }

    private func restoreManualMatch(from row: ResultRow) {
        let txCategory = row.value(for: "Transaction Category")
        let proofCategory = row.value(for: "Proof Category")

        let txUnmatched: [String: String] = [
            "Business Name": row.value(for: "Transaction Business Name"),
            "Total": row.value(for: "Transaction Total"),
            "Date": row.value(for: "Transaction Date"),
            "Category": txCategory,
        ]
        if !containsUnmatched(unmatchedTransactions, candidate: txUnmatched) {
            unmatchedTransactions.append(ResultRow(fields: txUnmatched))
        }

        let proofUnmatched: [String: String] = [
            "Business Name": row.value(for: "Proof Business Name"),
            "Total": row.value(for: "Proof Total"),
            "Date": row.value(for: "Proof Date"),
            "Category": proofCategory,
        ]
        if !containsUnmatched(unmatchedProofs, candidate: proofUnmatched) {
            unmatchedProofs.append(ResultRow(fields: proofUnmatched))
        }
    }

    private func containsRecommendation(_ candidate: [String: String]) -> Bool {
        recommendations.contains { row in
            sameValue(row, candidate, key: "Transaction Business Name")
                && sameValue(row, candidate, key: "Transaction Total")
                && sameValue(row, candidate, key: "Transaction Date")
                && sameValue(row, candidate, key: "Proof Business Name")
                && sameValue(row, candidate, key: "Proof Total")
                && sameValue(row, candidate, key: "Proof Date")
        }
    }

    private func containsDiscrepancy(_ candidate: [String: String]) -> Bool {
        discrepancies.contains { row in
            sameValue(row, candidate, key: "Transaction Business Name")
                && sameValue(row, candidate, key: "Transaction Date")
                && sameValue(row, candidate, key: "Proof Business Name")
                && sameValue(row, candidate, key: "Proof Date")
        }
    }

    private func containsUnmatched(_ rows: [ResultRow], candidate: [String: String]) -> Bool {
        rows.contains { row in
            sameValue(row, candidate, key: "Business Name")
                && sameValue(row, candidate, key: "Total")
                && sameValue(row, candidate, key: "Date")
        }
    }

    private func sameValue(_ row: ResultRow, _ candidate: [String: String], key: String) -> Bool {
        row.value(for: key).trimmingCharacters(in: .whitespacesAndNewlines)
            == (candidate[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clear() {
        summary = nil
        validationStage = nil
        validationPercent = nil
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
        currentSessionId = nil
    }

    private func parseCurrencyAmount(_ raw: String) -> Double? {
        let cleaned = raw
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}
