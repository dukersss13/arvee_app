import SwiftUI

struct SettingsView: View {
    private enum BackendProfile: String, CaseIterable {
        case cloudRun
        case local

        var label: String {
            switch self {
            case .cloudRun:
                return "Cloud Run"
            case .local:
                return "Local LAN"
            }
        }
    }

    @AppStorage("apiBaseURL") private var apiBaseURL = APIService.defaultBaseURL
    @AppStorage("backendProfile") private var backendProfileRaw = BackendProfile.cloudRun.rawValue
    @AppStorage("localBackendHost") private var localBackendHost = ""
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isConnected: Bool? = nil
    @State private var isChecking = false
    @State private var healthMessage = "Not checked"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Backend", selection: $backendProfileRaw) {
                        ForEach(BackendProfile.allCases, id: \.rawValue) { profile in
                            Text(profile.label).tag(profile.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: backendProfileRaw) { _, _ in
                        applyBackendProfile()
                    }

                    if activeProfile == .local && !isRunningOnSimulator {
                        TextField("Mac LAN IP or host", text: $localBackendHost)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .onChange(of: localBackendHost) { _, _ in
                                applyBackendProfile()
                            }
                    }

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
                            Text("GCP Backend Status")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(.arveeInk)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.arveeInkMuted)
                            Text(healthMessage)
                                .font(.caption2)
                                .foregroundColor(.arveeInkMuted)
                                .lineLimit(2)
                            Text(apiBaseURL)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.arveeInkMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
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

                    DisclosureGroup("Advanced") {
                        TextField("API Base URL", text: $apiBaseURL)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .onChange(of: apiBaseURL) { _, newValue in
                                let normalized = APIService.normalizedBaseURL(newValue)
                                if normalized != newValue {
                                    apiBaseURL = normalized
                                    return
                                }
                                APIService.shared.setBaseURL(normalized, persist: true)
                                checkHealth()
                            }

                        if showsLocalhostWarning {
                            Text("Using localhost on a physical device will fail. Use your Mac LAN IP, e.g. http://192.168.x.x:7860")
                                .font(.caption)
                                .foregroundColor(.arveeDanger)
                        }
                    }
                    .foregroundColor(.arveeInk)
                    .listRowBackground(Color.arveeSand.opacity(0.3))
                } header: {
                    Text("CONNECTION")
                        .font(.arveeEyebrow())
                        .foregroundColor(.arveeInkMuted)
                        .tracking(1)
                }

                Section {
                    if let email = authViewModel.authenticatedEmail {
                        HStack {
                            Text("Signed In")
                                .foregroundColor(.arveeInk)
                            Spacer()
                            Text(email)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.arveeInkMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .listRowBackground(Color.arveeSand.opacity(0.3))

                        Button(role: .destructive) {
                            authViewModel.logout()
                        } label: {
                            Text("Log Out")
                        }
                        .listRowBackground(Color.arveeSand.opacity(0.3))
                    }
                } header: {
                    Text("ACCOUNT")
                        .font(.arveeEyebrow())
                        .foregroundColor(.arveeInkMuted)
                        .tracking(1)
                }

                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.arveeInk)
                        Spacer()
                        Text("1.1.0")
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
                let normalized = APIService.normalizedBaseURL(apiBaseURL)
                if normalized != apiBaseURL {
                    apiBaseURL = normalized
                }
                APIService.shared.setBaseURL(normalized, persist: true)
                hydrateLocalHost(from: normalized)
                if activeProfile == .local {
                    applyBackendProfile()
                }
                checkHealth()
            }
        }
    }

    private var statusColor: Color {
        guard let connected = isConnected else { return .arveeInkMuted }
        return connected ? .arveeSuccess : .arveeDanger
    }

    private var statusText: String {
        if isChecking { return "Checking" }
        if isConnected == nil { return "Not checked" }
        return (isConnected ?? false) ? "Online" : "Offline"
    }

    private var activeProfile: BackendProfile {
        BackendProfile(rawValue: backendProfileRaw) ?? .cloudRun
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
            await MainActor.run {
                apiBaseURL = APIService.shared.activeBaseURL
                healthMessage = result.message
                isConnected = result.isConnected
                isChecking = false
            }
        }
    }

    private func applyBackendProfile() {
        let selected = activeProfile
        switch selected {
        case .cloudRun:
            let target = APIService.normalizedBaseURL(APIService.defaultBaseURL)
            apiBaseURL = target
            APIService.shared.setBaseURL(target, persist: true)
            healthMessage = "Using managed Cloud Run backend."

        case .local:
            let hostInput = resolvedLocalHostInput()
            guard !hostInput.isEmpty else {
                isConnected = nil
                healthMessage = "Enter your Mac LAN IP for Local LAN mode."
                return
            }
            let target = APIService.localBaseURL(host: hostInput)
            guard !target.isEmpty else {
                isConnected = nil
                healthMessage = "Invalid local host."
                return
            }
            apiBaseURL = target
            APIService.shared.setBaseURL(target, persist: true)
            healthMessage = "Using local backend at \(target)."
        }

        checkHealth()
    }

    private func resolvedLocalHostInput() -> String {
        if isRunningOnSimulator {
            return "localhost"
        }
        return localBackendHost.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hydrateLocalHost(from urlString: String) {
        guard let components = URLComponents(string: urlString),
              let host = components.host,
              !host.isEmpty,
              host != "localhost",
              host != "127.0.0.1"
        else {
            return
        }
        localBackendHost = host
    }
    }
}
