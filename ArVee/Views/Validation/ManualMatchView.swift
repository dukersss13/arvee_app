import SwiftUI

/// Sheet for manually matching unmatched transactions with unmatched proofs.
struct ManualMatchView: View {
    @ObservedObject var viewModel: ValidationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTxIndex: Int?
    @State private var selectedProofIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                            .font(.caption)
                            .foregroundColor(.arveeTeal)
                        Text("Select one unmatched transaction and one unmatched proof, then tap Match.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.arveeTealSoft)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    // Unmatched Transactions
                    selectableSection(
                        title: "Unmatched Transactions",
                        count: viewModel.unmatchedTransactions.count,
                        rows: viewModel.unmatchedTransactions,
                        selectedIndex: $selectedTxIndex
                    )

                    // Unmatched Proofs
                    selectableSection(
                        title: "Unmatched Proofs",
                        count: viewModel.unmatchedProofs.count,
                        rows: viewModel.unmatchedProofs,
                        selectedIndex: $selectedProofIndex
                    )

                    // Match button
                    Button {
                        guard let txIdx = selectedTxIndex, let proofIdx = selectedProofIndex else { return }
                        viewModel.manualMatch(transactionIndex: txIdx, proofIndex: proofIdx)
                        selectedTxIndex = nil
                        selectedProofIndex = nil
                        if viewModel.unmatchedTransactions.isEmpty && viewModel.unmatchedProofs.isEmpty {
                            dismiss()
                        }
                    } label: {
                        Label("Match Selected Pair", systemImage: "link")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(ArveePrimaryButtonStyle())
                    .disabled(selectedTxIndex == nil || selectedProofIndex == nil)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .arveePageBackground()
            .navigationTitle("Manual Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.arveeTeal)
                }
            }
        }
    }

    private func selectableSection(
        title: String,
        count: Int,
        rows: [ResultRow],
        selectedIndex: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.arveeInk)
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.arveeTeal)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.arveeTealSoft)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 16)

            if rows.isEmpty {
                Text("None remaining")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .padding(.horizontal, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                        selectableCard(row: row, isSelected: selectedIndex.wrappedValue == idx) {
                            selectedIndex.wrappedValue = selectedIndex.wrappedValue == idx ? nil : idx
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func selectableCard(row: ResultRow, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .arveeTeal : .arveeInkMuted)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.value(for: "Business Name").isEmpty
                         ? row.value(for: "business_name")
                         : row.value(for: "Business Name"))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.arveeInk)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        let date = row.value(for: "Date").isEmpty
                            ? row.value(for: "date")
                            : row.value(for: "Date")
                        if !date.isEmpty {
                            Text(date)
                                .font(.caption)
                                .foregroundColor(.arveeInkMuted)
                        }
                    }
                }

                Spacer()

                let total = row.value(for: "Total").isEmpty
                    ? row.value(for: "total")
                    : row.value(for: "Total")
                if !total.isEmpty {
                    Text("$\(total)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundColor(.arveeInk)
                }
            }
            .padding(12)
            .background(isSelected ? Color.arveeTealSoft : Color.arveeCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.arveeTeal : Color.arveeLine, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
