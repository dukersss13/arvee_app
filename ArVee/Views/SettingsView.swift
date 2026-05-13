import SwiftUI

struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://localhost:7860"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API Base URL", text: $apiBaseURL)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .listRowBackground(Color.arveeSand.opacity(0.3))
                        .onChange(of: apiBaseURL) { _, newValue in
                            APIService.shared.baseURL = newValue
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
        }
    }
}
