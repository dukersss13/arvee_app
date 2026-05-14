import SwiftUI
import Charts

struct ChartCardView: View {
    let chart: ChartData
    var allowExpand: Bool = true
    var chartHeight: CGFloat = 240

    @State private var selectedCategory: String?
    @State private var selectedPieAmount: Double?
    @State private var showExpandedChart = false

    private struct GroupedBarPoint: Identifiable {
        let id: String
        let category: String
        let amount: Double
        let periodName: String
        let seriesIndex: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                if let title = chart.title {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.arveeInk)
                }

                Spacer(minLength: 0)

                if allowExpand {
                    Button {
                        showExpandedChart = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.arveeTeal)
                            .padding(8)
                            .background(Color.arveeTealSoft.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Expand chart")
                }
            }

            Text("Tap chart to show exact values")
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundColor(.arveeInkMuted)

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
                        .foregroundColor(.arveeInkMuted)
                }
            }
            .frame(height: chartHeight)
            .overlay(alignment: .top) {
                if let summary = selectionSummary {
                    selectionOverlay(summary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .arveeCard(cornerRadius: 12)
        .sheet(isPresented: $showExpandedChart) {
            ChartDetailView(chart: chart)
        }
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
                    .foregroundStyle(Color.arveeTeal.gradient)
                    .cornerRadius(4)
                    .opacity(selectedCategory == nil || selectedCategory == label ? 1.0 : 0.45)
                    .annotation(position: .top, alignment: .center) {
                        if selectedCategory == label {
                            valueTag(currencyLabel(value))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedCategory)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(currencyLabel(v))
                                .font(.caption2)
                                .foregroundColor(.arveeInkMuted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.arveeLine)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.arveeInkMuted)
                }
            }
        }
    }

    // MARK: - Grouped Bar Chart

    @ViewBuilder
    private var groupedBarChart: some View {
        let points = groupedBarPoints
        if !points.isEmpty {
            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value("Category", point.category),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(
                        Color.arveeChartPalette[point.seriesIndex % Color.arveeChartPalette.count]
                    )
                    .cornerRadius(4)
                    .position(by: .value("Period", point.periodName))
                    .opacity(selectedCategory == nil || selectedCategory == point.category ? 1.0 : 0.45)
                    .annotation(position: .top, alignment: .center) {
                        if selectedCategory == point.category {
                            valueTag(currencyLabel(point.amount))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedCategory)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(currencyLabel(v))
                                .font(.caption2)
                                .foregroundColor(.arveeInkMuted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.arveeLine)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.arveeInkMuted)
                }
            }
            .chartLegend(position: .top)
            .chartForegroundStyleScale(range: Color.arveeChartPalette)
        }
    }

    // MARK: - Pie Chart

    @ViewBuilder
    private var pieChart: some View {
        if let labels = chart.labels, let values = chart.values {
            Chart {
                ForEach(Array(zip(labels, values).enumerated()), id: \.element.0) { idx, pair in
                    SectorMark(
                        angle: .value("Amount", pair.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color.arveeChartPalette[idx % Color.arveeChartPalette.count])
                    .cornerRadius(4)
                    .opacity(selectedPieIndex(for: values) == nil || selectedPieIndex(for: values) == idx ? 1.0 : 0.45)
                }
            }
            .chartAngleSelection(value: $selectedPieAmount)
            .chartLegend(position: .bottom, spacing: 8)
            .chartForegroundStyleScale(
                domain: labels,
                range: Array(Color.arveeChartPalette.prefix(labels.count))
            )
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

    private var selectionSummary: String? {
        switch chart.type {
        case "bar":
            guard
                let labels = chart.labels,
                let values = chart.values,
                let selectedCategory,
                let idx = labels.firstIndex(of: selectedCategory),
                values.indices.contains(idx)
            else {
                return nil
            }
            return "\(selectedCategory): \(currencyLabel(values[idx]))"
        case "grouped_bar":
            guard
                let categories = chart.x,
                let series = chart.series,
                let selectedCategory,
                let idx = categories.firstIndex(of: selectedCategory)
            else {
                return nil
            }
            let segments = series.compactMap { item -> String? in
                guard item.values.indices.contains(idx) else { return nil }
                return "\(item.name) \(currencyLabel(item.values[idx]))"
            }
            guard !segments.isEmpty else { return nil }
            return "\(selectedCategory): \(segments.joined(separator: " · "))"
        case "pie":
            guard
                let labels = chart.labels,
                let values = chart.values,
                let idx = selectedPieIndex(for: values),
                labels.indices.contains(idx),
                values.indices.contains(idx)
            else {
                return nil
            }
            return "\(labels[idx]): \(currencyLabel(values[idx]))"
        default:
            return nil
        }
    }

    private func selectedPieIndex(for values: [Double]) -> Int? {
        guard let selectedPieAmount else { return nil }
        let total = values.reduce(0, +)
        guard total > 0 else { return nil }

        let normalizedAmount = selectedPieAmount.truncatingRemainder(dividingBy: total)
        let probe = normalizedAmount < 0 ? (normalizedAmount + total) : normalizedAmount

        var runningTotal = 0.0
        for (idx, value) in values.enumerated() {
            let next = runningTotal + value
            if probe >= runningTotal && probe < next {
                return idx
            }
            runningTotal = next
        }
        return nil
    }

    private func valueTag(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundColor(.arveeInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.arveePaper.opacity(0.95))
            )
    }

    private func selectionOverlay(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundColor(.arveeTeal)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.arveeTealSoft.opacity(0.35))
            )
    }

    private var groupedBarPoints: [GroupedBarPoint] {
        guard let categories = chart.x, let series = chart.series else {
            return []
        }

        var points: [GroupedBarPoint] = []
        points.reserveCapacity(categories.count * series.count)

        for (seriesIndex, item) in series.enumerated() {
            let valueCount = min(categories.count, item.values.count)
            for idx in 0..<valueCount {
                let category = categories[idx]
                points.append(
                    GroupedBarPoint(
                        id: "\(item.id)-\(idx)-\(category)",
                        category: category,
                        amount: item.values[idx],
                        periodName: item.name,
                        seriesIndex: seriesIndex
                    )
                )
            }
        }

        return points
    }
}

private struct ChartDetailView: View {
    let chart: ChartData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ChartCardView(chart: chart, allowExpand: false, chartHeight: 360)
                    .padding(16)
            }
            .arveePageBackground()
            .navigationTitle(chart.title ?? "Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.arveeTeal)
                }
            }
        }
    }
}
