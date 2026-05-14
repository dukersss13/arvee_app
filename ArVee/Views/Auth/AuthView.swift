import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome to ArVee")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.arveeInk)

                Text("Sign in to sync your sessions securely across devices.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(AuthViewModel.AuthMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(Color.arveeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $viewModel.password)
                        .padding(12)
                        .background(Color.arveeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if viewModel.mode == .signup {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .padding(12)
                            .background(Color.arveeCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 24)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.arveeDanger)
                        .padding(.horizontal, 24)
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Text(viewModel.mode == .signup ? "Create Account" : "Login")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.arveeTeal)
                .padding(.horizontal, 24)
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(.top, 20)
            .arveePageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.refreshAuthState()
            }
        }
    }
}
