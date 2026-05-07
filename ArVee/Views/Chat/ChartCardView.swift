import SwiftUI
import Charts

struct ChartCardView: View {
    let chart: ChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = chart.title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }

            Group {
                switch chart.type {
                case "bar":
                    barChart
                case "grouped_bar":
                    groupedBarChart
                case "pie":
                    pieChart
                default:
                    Text("Unsupported chart type: \(chart.type)")
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Bar Chart

    @ViewBuilder
    private var barChart: some View {
        if let labels = chart.labels, let values = chart.values {
            Chart {
                ForEach(Array(zip(labels, values)), id: \.0) { label, value in
                    BarMark(
                        x: .value("Category", label),
                        y: .value("Amount", value)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(currencyLabel(v))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
        }
    }

    // MARK: - Grouped Bar Chart

    @ViewBuilder
    private var groupedBarChart: some View {
        if let categories = chart.x, let series = chart.series {
            Chart {
                ForEach(series) { s in
                    ForEach(Array(zip(categories, s.values)), id: \.0) { cat, val in
                        BarMark(
                            x: .value("Category", cat),
                            y: .value("Amount", val)
                        )
                        .foregroundStyle(by: .value("Period", s.name))
                        .cornerRadius(4)
                        .position(by: .value("Period", s.name))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(currencyLabel(v))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartLegend(position: .top)
        }
    }

    // MARK: - Pie Chart

    @ViewBuilder
    private var pieChart: some View {
        if let labels = chart.labels, let values = chart.values {
            Chart {
                ForEach(Array(zip(labels, values)), id: \.0) { label, value in
                    SectorMark(
                        angle: .value("Amount", value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", label))
                    .cornerRadius(4)
                }
            }
            .chartLegend(position: .bottom, spacing: 8)
        }
    }

    // MARK: - Helpers

    private func currencyLabel(_ value: Double) -> String {
        let symbol = chart.currency ?? "$"
        if value >= 1000 {
            return "\(symbol)\(String(format: "%.0f", value))"
        }
        return "\(symbol)\(String(format: "%.2f", value))"
    }
}
