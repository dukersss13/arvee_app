import SwiftUI

private let resultsFontScale: CGFloat = 1.05
private let validationCategoryOptions: [String] = [
    "Food",
    "Shopping",
    "Medical",
    "Transport",
    "Utilities",
    "Entertainment",
    "Travel",
    "Health & Fitness",
    "Other",
]

private func scaledResultsFont(_ base: CGFloat) -> CGFloat {
    base * resultsFontScale
}

struct ValidationView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var viewModel: ValidationViewModel
    @Binding var scrollTarget: ResultsSection?
    @State private var isExporting = false
    @State private var showManualMatch = false
    @State private var expandedSections: Set<ResultsSection> = Set(ResultsSection.allCases)
    @State private var selectedRecommendationIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if !sessionVM.hasSession {
                    noSessionPlaceholder
                } else if viewModel.hasResults {
                    resultsView
                } else {
                    emptyResultsPlaceholder
                }
            }
            .arveePageBackground()
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if viewModel.hasResults {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                exportPDF()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.arveeTeal)
                            }
                            .disabled(isExporting)
                            Button {
                                viewModel.clear()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.arveeInkMuted)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showManualMatch) {
                ManualMatchView(viewModel: viewModel)
            }
        }
    }

    // MARK: - No Session

    private var noSessionPlaceholder: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.arveeTealSoft)
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.arveeTealGradient)
                }
                Text("No session active")
                    .font(.arveeHeadline())
                    .foregroundColor(.arveeInk)
                Text("Go to Upload to create a session and run validation.")
                    .font(.subheadline)
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(22)
            .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 20)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
    }

    // MARK: - Empty Results

    private var emptyResultsPlaceholder: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.arveeCoral.opacity(0.08))
                        .frame(width: 88, height: 88)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.arveeCoral)
                }
                Text("No results yet")
                    .font(.arveeHeadline())
                    .foregroundColor(.arveeInk)
                Text("Upload files and run validation from the Upload tab.")
                    .font(.subheadline)
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(22)
            .arveePremiumGlassCard(accent: .arveeCoral, cornerRadius: 20)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // KPI summary row
                    kpiRow
                        .padding(.top, 10)

                    // Validated section
                    collapsibleSection(
                        section: .validated,
                        title: "Validated",
                        count: viewModel.validatedRows.count,
                        accentColor: .arveeTeal,
                        icon: "checkmark.circle.fill",
                        action: ("Download PDF", {
                            exportPDF()
                        })
                    ) {
                        ForEach(viewModel.validatedRows) { row in
                            ResultCardView(
                                row: row,
                                categoryOptions: availableCategoryOptions,
                                isCategoryEditable: true,
                                onCategoryChange: { newCategory in
                                    viewModel.updateValidatedCategory(for: row.id, category: newCategory)
                                },
                                canRemoveAccepted: viewModel.canRemoveAcceptedValidatedRow(row),
                                onRemoveAccepted: {
                                    viewModel.removeAcceptedValidatedRow(rowId: row.id)
                                }
                            )
                        }
                    }

                    if !viewModel.discrepancies.isEmpty {
                        // Discrepancies section
                        collapsibleSection(
                            section: .discrepancies,
                            title: "Discrepancies",
                            count: viewModel.discrepancies.count,
                            accentColor: .arveeCoral,
                            icon: "exclamationmark.triangle.fill"
                        ) {
                            ForEach(Array(viewModel.discrepancies.enumerated()), id: \.element.id) { idx, row in
                                DiscrepancyCardView(row: row) { adjustedAmount, comment in
                                    viewModel.acceptDiscrepancy(at: idx, adjustedAmount: adjustedAmount, comment: comment)
                                }
                            }
                        }
                    }

                    if !viewModel.unmatchedTransactions.isEmpty || !viewModel.unmatchedProofs.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.arveeTeal)
                            Text("Need to pair unmatched transactions and proofs?")
                                .font(.system(size: scaledResultsFont(12), weight: .regular, design: .rounded))
                                .foregroundColor(.arveeInkMuted)
                            Spacer()
                            Button("Manual Match") {
                                showManualMatch = true
                            }
                            .font(.system(size: scaledResultsFont(12), weight: .semibold, design: .rounded))
                            .foregroundColor(.arveeTeal)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .arveeCard(cornerRadius: 12)
                        .padding(.horizontal, 16)
                    }

                    if !viewModel.unmatchedTransactions.isEmpty {
                        // Unmatched Transactions section
                        collapsibleSection(
                            section: .unmatchedTx,
                            title: "Unmatched Transactions",
                            count: viewModel.unmatchedTransactions.count,
                            accentColor: .arveeInkMuted,
                            icon: "doc.questionmark"
                        ) {
                            ForEach(viewModel.unmatchedTransactions) { row in
                                ResultCardView(row: row)
                            }
                        }
                    }

                    if !viewModel.unmatchedProofs.isEmpty {
                        // Unmatched Proofs section
                        collapsibleSection(
                            section: .unmatchedProofs,
                            title: "Unmatched Proofs",
                            count: viewModel.unmatchedProofs.count,
                            accentColor: .arveeInkMuted,
                            icon: "photo.on.rectangle"
                        ) {
                            ForEach(viewModel.unmatchedProofs) { row in
                                ResultCardView(row: row)
                            }
                        }
                    }

                    if !viewModel.recommendations.isEmpty {
                        // Recommendations section
                        collapsibleSection(
                            section: .recommendations,
                            title: "Recommendations",
                            count: viewModel.recommendations.count,
                            accentColor: .arveeTeal,
                            icon: "sparkles",
                            action: (
                                selectedRecommendationIds.isEmpty
                                    ? "Select items"
                                    : "Accept Selected (\(selectedRecommendationIds.count))",
                                {
                                    viewModel.acceptRecommendations(withIds: selectedRecommendationIds)
                                    selectedRecommendationIds.removeAll()
                                }
                            )
                        ) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { idx, row in
                                RecommendationCardView(
                                    row: row,
                                    isSelected: selectedRecommendationIds.contains(row.id),
                                    isAcceptEnabled: selectedRecommendationIds.contains(row.id),
                                    onToggleSelected: {
                                        if selectedRecommendationIds.contains(row.id) {
                                            selectedRecommendationIds.remove(row.id)
                                        } else {
                                            selectedRecommendationIds.insert(row.id)
                                        }
                                    }
                                ) {
                                    guard selectedRecommendationIds.contains(row.id) else { return }
                                    viewModel.acceptRecommendation(at: idx)
                                    selectedRecommendationIds.remove(row.id)
                                }
                            }
                        }

                        Button {
                            viewModel.acceptAllRecommendations()
                            selectedRecommendationIds.removeAll()
                        } label: {
                            Text("Accept All Recommendations")
                                .font(.system(size: scaledResultsFont(12), weight: .semibold, design: .rounded))
                                .foregroundColor(.arveeTeal)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 32)
                }
            }
            .onChange(of: viewModel.recommendations.map(\.id)) { _, ids in
                let availableIds = Set(ids)
                selectedRecommendationIds = selectedRecommendationIds.intersection(availableIds)
            }
            .onChange(of: scrollTarget) { _, target in
                if let target {
                    expandedSections.insert(target)
                    withAnimation {
                        proxy.scrollTo(target.rawValue, anchor: .top)
                    }
                    scrollTarget = nil
                }
            }
        }
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            gradientKpiCard(label: "Validated", value: viewModel.validatedRows.count, accentColor: .arveeTeal, icon: "checkmark.circle.fill")
            gradientKpiCard(label: "Discrepancies", value: viewModel.discrepancies.count, accentColor: .arveeCoral, icon: "exclamationmark.triangle.fill")
            gradientKpiCard(label: "Unmatched Tx", value: viewModel.unmatchedTransactions.count, accentColor: .arveeInkMuted, icon: "doc.questionmark")
            gradientKpiCard(label: "Unmatched Proofs", value: viewModel.unmatchedProofs.count, accentColor: .arveeInkMuted, icon: "photo.on.rectangle")
        }
        .padding(.horizontal, 16)
    }

    private func gradientKpiCard(label: String, value: Int, accentColor: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: scaledResultsFont(10), weight: .semibold, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .tracking(0.5)
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentColor.opacity(0.6))
            }
            Text("\(value)")
                .font(.system(size: scaledResultsFont(28.8), weight: .bold, design: .rounded))
                .foregroundColor(.arveeInk)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .arveePremiumGlassCard(accent: accentColor, cornerRadius: 14)
    }

    private var availableCategoryOptions: [String] {
        validationCategoryOptions
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        section: ResultsSection,
        title: String,
        count: Int,
        accentColor: Color,
        icon: String,
        action: (String, () -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedSections.contains(section) {
                            expandedSections.remove(section)
                        } else {
                            expandedSections.insert(section)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(accentColor)
                        Text(title)
                            .font(.system(size: scaledResultsFont(15), weight: .semibold, design: .rounded))
                            .foregroundColor(.arveeInk)
                        Text("\(count)")
                            .font(.system(size: scaledResultsFont(11), weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(6)
                        Spacer()
                        Image(systemName: expandedSections.contains(section) ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.arveeInkMuted)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                if let action {
                    Button(action: action.1) {
                        Text(action.0)
                            .font(.system(size: scaledResultsFont(12), weight: .semibold, design: .rounded))
                            .foregroundColor(action.0 == "Select items" ? .arveeInkMuted : .arveeTeal)
                    }
                    .buttonStyle(.plain)
                    .disabled(action.0 == "Select items")
                }
            }
            .id(section.rawValue)
            .padding(.horizontal, 16)

            // Content
            if expandedSections.contains(section) {
                if count > 0 {
                    LazyVStack(spacing: 8) {
                        content()
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Export

    private func exportPDF() {
        guard !viewModel.validatedRows.isEmpty else { return }
        isExporting = true
        Task {
            do {
                let rowDicts: [[String: Any]] = viewModel.validatedRows.map { row in
                    row.fields as [String: Any]
                }
                let pdfData = try await APIService.shared.exportPDF(rows: rowDicts)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("validated_transactions.pdf")
                try pdfData.write(to: tempURL)
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
            }
            isExporting = false
        }
    }
}

/// Compact card for displaying a single result row (validated, unmatched, etc.)
struct ResultCardView: View {
    let row: ResultRow
    var categoryOptions: [String] = []
    var isCategoryEditable: Bool = false
    var onCategoryChange: ((String) -> Void)? = nil
    var canRemoveAccepted: Bool = false
    var onRemoveAccepted: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Check for matched pair format (Transaction/Proof columns)
            let hasTxBiz = !row.value(for: "Transaction Business Name").isEmpty
            let hasProofBiz = !row.value(for: "Proof Business Name").isEmpty

            if hasTxBiz || hasProofBiz {
                matchedPairLayout
            } else {
                singleRowLayout
            }
        }
        .padding(12)
        .arveeCard(cornerRadius: 12)
    }

    // Layout for matched pairs (Transaction ↔ Proof)
    private var matchedPairLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Transaction
            HStack {
                Text("TX")
                    .font(.system(size: scaledResultsFont(9), weight: .bold, design: .rounded))
                    .foregroundColor(.arveeTeal)
                    .tracking(0.5)
                Text(row.value(for: "Transaction Business Name"))
                    .font(.system(size: scaledResultsFont(13.2), weight: .medium, design: .rounded))
                    .foregroundColor(.arveeInk)
                    .lineLimit(1)
                Spacer()
                Text(row.value(for: "Transaction Date"))
                    .font(.system(size: scaledResultsFont(12.1), weight: .regular, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                Text(row.value(for: "Transaction Total"))
                    .font(.system(size: scaledResultsFont(13.2), weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.arveeInk)
            }

            // Proof
            HStack {
                Text("PR")
                    .font(.system(size: scaledResultsFont(9), weight: .bold, design: .rounded))
                    .foregroundColor(.arveeCoral)
                    .tracking(0.5)
                Text(row.value(for: "Proof Business Name"))
                    .font(.system(size: scaledResultsFont(13.2), weight: .medium, design: .rounded))
                    .foregroundColor(.arveeInk)
                    .lineLimit(1)
                Spacer()
                Text(row.value(for: "Proof Date"))
                    .font(.system(size: scaledResultsFont(12.1), weight: .regular, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                Text(row.value(for: "Proof Total"))
                    .font(.system(size: scaledResultsFont(13.2), weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.arveeInk)
            }

            if let selectedCategory = unifiedMatchedCategory {
                HStack {
                    Spacer()
                    if isCategoryEditable {
                        Menu {
                            ForEach(editableCategoryOptions(for: selectedCategory), id: \.self) { option in
                                Button(option) {
                                    onCategoryChange?(option)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedCategory)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: scaledResultsFont(9), weight: .semibold))
                            }
                            .font(.system(size: scaledResultsFont(10), weight: .medium, design: .rounded))
                            .foregroundColor(.arveeTeal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.arveeTealSoft)
                            .cornerRadius(4)
                        }
                    } else {
                        categoryChip(selectedCategory)
                    }
                }
            }

            // Status / Reason
            let status = row.value(for: "Result").isEmpty ? row.value(for: "Reason") : row.value(for: "Result")
            if !status.isEmpty || canRemoveAccepted {
                HStack(spacing: 10) {
                    if !status.isEmpty {
                        Text(status)
                            .font(.system(size: scaledResultsFont(10), design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                    if canRemoveAccepted, let onRemoveAccepted {
                        Button {
                            onRemoveAccepted()
                        } label: {
                            Label("Remove", systemImage: "arrow.uturn.backward.circle")
                                .font(.system(size: scaledResultsFont(10), weight: .semibold, design: .rounded))
                                .foregroundColor(.arveeCoral)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func matchedCategory(primary: String, fallback: String) -> String? {
        let primaryValue = row.value(for: primary)
        if !primaryValue.isEmpty {
            return primaryValue
        }
        let fallbackValue = row.value(for: fallback)
        return fallbackValue.isEmpty ? nil : fallbackValue
    }

    private var unifiedMatchedCategory: String? {
        if let primary = matchedCategory(primary: "Category", fallback: "Transaction Category") {
            return primary
        }
        return matchedCategory(primary: "Proof Category", fallback: "")
    }

    private func editableCategoryOptions(for selected: String) -> [String] {
        var options = categoryOptions
        if !options.contains(where: { $0.caseInsensitiveCompare(selected) == .orderedSame }) {
            options.append(selected)
        }
        if options.isEmpty {
            options = [selected]
        }
        return options.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func categoryChip(_ value: String) -> some View {
        Text(value)
            .font(.system(size: scaledResultsFont(10), weight: .medium, design: .rounded))
            .foregroundColor(.arveeTeal)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.arveeTealSoft)
            .cornerRadius(4)
    }

    // Layout for single items (unmatched tx or proof)
    private var singleRowLayout: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                let name = row.value(for: "Business Name").isEmpty
                    ? row.value(for: "business_name")
                    : row.value(for: "Business Name")
                if !name.isEmpty {
                    Text(name)
                        .font(.system(size: scaledResultsFont(15), weight: .semibold, design: .rounded))
                        .foregroundColor(.arveeInk)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    let date = row.value(for: "Date").isEmpty
                        ? row.value(for: "date")
                        : row.value(for: "Date")
                    if !date.isEmpty {
                        Text(date)
                            .font(.system(size: scaledResultsFont(12), weight: .regular, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                    }
                    let category = row.value(for: "Category").isEmpty
                        ? row.value(for: "category")
                        : row.value(for: "Category")
                    if !category.isEmpty {
                        Text(category)
                            .font(.system(size: scaledResultsFont(10), weight: .medium, design: .rounded))
                            .foregroundColor(.arveeTeal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.arveeTealSoft)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            let total = row.value(for: "Total").isEmpty
                ? row.value(for: "total")
                : row.value(for: "Total")
            if !total.isEmpty {
                Text("$\(total)")
                    .font(.system(size: scaledResultsFont(15), weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.arveeInk)
            }
        }
    }
}
