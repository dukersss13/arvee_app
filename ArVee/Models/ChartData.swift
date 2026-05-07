import Foundation

struct ChartData: Codable {
    let type: String
    let title: String?
    let currency: String?
    let labels: [String]?
    let values: [Double]?
    let x: [String]?
    let series: [ChartSeries]?
    let table: ComparisonTable?
}

struct ChartSeries: Codable, Identifiable {
    var id: String { name }
    let name: String
    let values: [Double]
}

struct ComparisonTable: Codable {
    let columns: [String]?
    let rows: [ComparisonRow]?
}

struct ComparisonRow: Codable, Identifiable {
    var id: String { category }
    let category: String
    let period1: Double?
    let period2: Double?
    let delta: Double?
    let percentChange: Double?

    enum CodingKeys: String, CodingKey {
        case category
        case period1 = "period_1"
        case period2 = "period_2"
        case delta
        case percentChange = "percent_change"
    }
}
