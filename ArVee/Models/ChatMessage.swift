import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    var isPending: Bool
    var chart: ChartData?
    var topCategories: [CategoryValue]?
    var comparisonTable: ComparisonTable?

    enum Role: String {
        case user, assistant
    }
}

struct ChatAskResponse: Codable {
    let sessionId: String?
    let question: String?
    let answer: String?
    let rowsScanned: Int?
    let toolUsed: Bool?
    let confidence: String?
    let route: String?
    let toolName: String?
    let needsClarification: Bool?
    let chart: ChartData?
    let topCategories: [CategoryValue]?
    let comparisonTable: ComparisonTable?

    enum CodingKeys: String, CodingKey {
        case sessionId, question, answer, rowsScanned, toolUsed
        case confidence, route, toolName, needsClarification
        case chart
        case topCategories = "top_categories"
        case comparisonTable = "comparison_table"
    }
}

struct CategoryValue: Codable, Identifiable {
    var id: String { category }
    let category: String
    let value: Double
}
