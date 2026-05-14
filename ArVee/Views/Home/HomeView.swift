import SwiftUI

struct HomeView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var validationVM: ValidationViewModel
    @Binding var selectedTab: Int
    @Binding var resultsScrollTarget: ResultsSection?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    homeHeader
                        .padding(.top, 4)

                    // Quick stats (only if validation results exist)
                    if validationVM.hasResults {
                        statsRow
                    }

                    // Action cards
                    actionCards

                    // Validation summary (if results exist)
                    if validationVM.hasResults, let summary = validationVM.summary {
                        Button {
                            resultsScrollTarget = .recommendations
                            withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                        } label: {
                            summaryCard(summary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.bottom, 24)
            }
            .arveePageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Home Header

    private var homeHeader: some View {
        VStack(spacing: 6) {
            Text("ArVee")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.arveeInk)
                .multilineTextAlignment(.center)
            Text("Upload receipts and transactions to quickly verify totals, matches, and discrepancies.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.arveeInkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Session Pill

    private var sessionPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(sessionVM.hasSession ? Color.arveeSuccess : Color.arveeStepPending)
                .frame(width: 8, height: 8)
            if let id = sessionVM.sessionId {
                Text("Session")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.arveeInkMuted)
                Text(id)
                    .font(.arveeMono(.caption2))
                    .foregroundColor(.arveeInk)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("No active session")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.arveeInkMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Stats

    private var statsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    resultsScrollTarget = .validated
                    withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                } label: {
                    ArveeMetricCard(
                        title: "Validated",
                        value: "\(validationVM.validatedRows.count)",
                        icon: "checkmark.circle.fill",
                        accentColor: .arveeTeal
                    )
                    .frame(width: 160)
                }

                Button {
                    resultsScrollTarget = .discrepancies
                    withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                } label: {
                    ArveeMetricCard(
                        title: "Discrepancies",
                        value: "\(validationVM.discrepancies.count)",
                        icon: "exclamationmark.triangle.fill",
                        accentColor: .arveeCoral
                    )
                    .frame(width: 160)
                }

                Button {
                    resultsScrollTarget = .unmatchedTx
                    withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                } label: {
                    ArveeMetricCard(
                        title: "Unmatched",
                        value: "\(validationVM.unmatchedTransactions.count + validationVM.unmatchedProofs.count)",
                        icon: "questionmark.circle",
                        accentColor: .arveeInkMuted
                    )
                    .frame(width: 160)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Action Cards

    private var actionCards: some View {
        VStack(spacing: 12) {
            // Upload & Validate
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 1
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.arveeTealSoft)
                            .frame(width: 52, height: 52)
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.title2)
                            .foregroundColor(.arveeTeal)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Upload & Validate")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.arveeInk)
                        Text("Upload transactions and proofs, then run validation")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.arveeInkMuted)
                }
                .padding(16)
                .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 16)
            }

            // Chat with ArVee
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 3
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.arveeCoral.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.title2)
                            .foregroundColor(.arveeCoral)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Chat with ArVee")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.arveeInk)
                        Text("Ask questions about your spending and finances")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.arveeInkMuted)
                }
                .padding(16)
                .arveePremiumGlassCard(accent: .arveeCoral, cornerRadius: 16)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.arveeTeal)
                Text("LATEST VALIDATION")
                    .font(.arveeEyebrow())
                    .foregroundColor(.arveeInkMuted)
                    .tracking(0.5)
            }
            Text(summary)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.arveeInk)
                .lineLimit(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .arveePremiumGlassCard(accent: .arveeTeal, cornerRadius: 14)
        .padding(.horizontal, 16)
    }
}
