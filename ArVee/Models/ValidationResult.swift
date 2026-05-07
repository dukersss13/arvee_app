import Foundation

struct ValidationResponse: Codable {
    let sessionId: String
    let summary: String?
    let ingestionCost: CostSummary?
    let categorizeCost: CostSummary?
    let transactions: [[String: AnyCodable]]?
    let proofs: [[String: AnyCodable]]?
    let validatedTransactions: [[String: AnyCodable]]?
    let discrepancies: [[String: AnyCodable]]?
    let unmatchedTransactions: [[String: AnyCodable]]?
    let unmatchedProofs: [[String: AnyCodable]]?
    let recommendations: [[String: AnyCodable]]?
}

struct CostSummary: Codable {
    let model: String?
    let inputTokens: Int?
    let outputTokens: Int?
    let llmCalls: Int?
    let estimatedTotalCostUsd: Double?
}

/// A row from validated/discrepancy/unmatched tables.
struct ResultRow: Identifiable, Hashable {
    let id = UUID()
    let fields: [String: String]

    init(from dict: [String: AnyCodable]) {
        var mapped: [String: String] = [:]
        for (key, value) in dict {
            mapped[key] = "\(value.value)"
        }
        self.fields = mapped
    }

    func value(for key: String) -> String {
        fields[key] ?? ""
    }

    static func == (lhs: ResultRow, rhs: ResultRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
