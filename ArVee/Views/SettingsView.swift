import SwiftUI

struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://localhost:7860"
    @State private var isConnected: Bool? = nil
    @State private var isChecking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Connection status row
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            if isChecking {
                                ProgressView()
                                    .controlSize(.mini)
                                    .tint(.arveeTeal)
                            } else {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Backend Status")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(.arveeInk)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.arveeInkMuted)
                        }
                        Spacer()
                        Button {
                            checkHealth()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.arveeTeal)
                        }
                        .disabled(isChecking)
                    }
                    .listRowBackground(Color.arveeSand.opacity(0.3))

                    TextField("API Base URL", text: $apiBaseURL)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .listRowBackground(Color.arveeSand.opacity(0.3))
                        .onChange(of: apiBaseURL) { _, newValue in
                            APIService.shared.baseURL = newValue
                            checkHealth()
                        }
                } header: {
                    Text("CONNECTION")
                        .font(.arveeEyebrow())
                        .foregroundColor(.arveeInkMuted)
                        .tracking(1)
                }

                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.arveeInk)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.arveeInkMuted)
                    }
                    .listRowBackground(Color.arveeSand.opacity(0.3))
                } header: {
                    Text("ABOUT")
                        .font(.arveeEyebrow())
                        .foregroundColor(.arveeInkMuted)
                        .tracking(1)
                }
            }
            .scrollContentBackground(.hidden)
            .arveePageBackground()
            .navigationTitle("Settings")
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                checkHealth()
            }
        }
    }

    private var statusColor: Color {
        guard let connected = isConnected else { return .arveeInkMuted }
        return connected ? .arveeSuccess : .arveeDanger
    }

    private var statusText: String {
        if isChecking { return "Checking..." }
        guard let connected = isConnected else { return "Not checked" }
        return connected ? "Connected" : "Disconnected"
    }

    private func checkHealth() {
        isChecking = true
        Task {
            let result = await APIService.shared.healthCheck()
            isConnected = result
            isChecking = false
        }
    }
}
