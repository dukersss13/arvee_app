import Foundation

struct SessionResponse: Codable {
    let sessionId: String
}

struct SessionInputsResponse: Codable {
    let sessionId: String
    let transactions: [InputRow]
    let proofs: [InputRow]
}

struct InputRow: Codable, Identifiable, Hashable {
    var id = UUID()
    let businessName: String?
    let total: Double?
    let date: String?
    let currency: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case businessName = "business_name"
        case total, date, currency, category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.businessName = try c.decodeIfPresent(String.self, forKey: .businessName)
        self.total = try c.decodeIfPresent(Double.self, forKey: .total)
        self.date = try c.decodeIfPresent(String.self, forKey: .date)
        self.currency = try c.decodeIfPresent(String.self, forKey: .currency)
        self.category = try c.decodeIfPresent(String.self, forKey: .category)
    }
}

struct SessionState: Codable {
    let summary: String?
    let loadedTransactions: [[String: AnyCodable]]?
    let loadedProofs: [[String: AnyCodable]]?
    let validatedTransactions: [[String: AnyCodable]]?
    let discrepancies: [[String: AnyCodable]]?
    let unmatchedTransactions: [[String: AnyCodable]]?
    let unmatchedProofs: [[String: AnyCodable]]?
    let recommendations: [[String: AnyCodable]]?
    let chatHistory: [ChatHistoryEntry]?
}

struct ChatHistoryEntry: Codable {
    let role: String
    let text: String
    let ts: String?
}

struct SessionStateResponse: Codable {
    let sessionId: String
    let state: SessionState?
}
