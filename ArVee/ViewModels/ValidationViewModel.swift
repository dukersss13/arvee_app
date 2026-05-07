import Foundation
import SwiftUI
import PhotosUI

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

    // File selection
    @Published var transactionPhotos: [PhotosPickerItem] = []
    @Published var proofPhotos: [PhotosPickerItem] = []
    @Published var transactionFiles: [FilePayload] = []
    @Published var proofFiles: [FilePayload] = []

    private let api = APIService.shared

    var hasResults: Bool { !validatedRows.isEmpty || !discrepancies.isEmpty }

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

    func loadPhotos() async {
        transactionFiles = await loadPayloads(from: transactionPhotos)
        proofFiles = await loadPayloads(from: proofPhotos)
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

    func clear() {
        summary = nil
        validatedRows = []
        discrepancies = []
        unmatchedTransactions = []
        unmatchedProofs = []
        recommendations = []
        transactionPhotos = []
        proofPhotos = []
        transactionFiles = []
        proofFiles = []
        errorMessage = nil
    }
}
