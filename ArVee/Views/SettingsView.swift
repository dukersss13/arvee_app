import SwiftUI

struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://192.168.4.21:7860"
    @State private var isConnected: Bool? = nil
    @State private var isChecking = false
    @State private var statusMessage = "Not checked"

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
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed != newValue {
                                apiBaseURL = trimmed
                                return
                            }
                            APIService.shared.baseURL = trimmed
                            checkHealth()
                        }

                    if showsLocalhostWarning {
                        Text("Using localhost on a physical device will fail. Use your Mac LAN IP, e.g. http://192.168.x.x:7860")
                            .font(.caption)
                            .foregroundColor(.arveeDanger)
                            .listRowBackground(Color.arveeSand.opacity(0.3))
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
                APIService.shared.baseURL = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
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
        if isConnected == nil { return "Not checked" }
        return statusMessage
    }

    private var showsLocalhostWarning: Bool {
        !isRunningOnSimulator &&
        (apiBaseURL.contains("localhost") || apiBaseURL.contains("127.0.0.1"))
    }

    private var isRunningOnSimulator: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }

    private func checkHealth() {
        isChecking = true
        Task {
            let result = await APIService.shared.healthCheck()
            isConnected = result.isConnected
            statusMessage = result.message
            isChecking = false
        }
    }
}
