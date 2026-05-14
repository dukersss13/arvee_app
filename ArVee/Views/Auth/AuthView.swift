import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image("icon2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.arveeLine, lineWidth: 0.5)
                            )
                            .shadow(color: Color.arveeTeal.opacity(0.2), radius: 14, x: 0, y: 7)

                        Text("Welcome to ArVee")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(.arveeInk)

                        Text("Sign in to sync sessions and validate receipts across devices.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.arveeInkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        Picker("Mode", selection: $viewModel.mode) {
                            ForEach(AuthViewModel.AuthMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: 12) {
                            TextField("Email", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(Color.arveeCardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            SecureField("Password", text: $viewModel.password)
                                .padding(12)
                                .background(Color.arveeCardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            if viewModel.mode == .signup {
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .padding(12)
                                    .background(Color.arveeCardElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.arveeDanger)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                        .disabled(viewModel.isLoading)

                        if viewModel.isGoogleAvailable {
                            HStack {
                                Rectangle()
                                    .fill(Color.arveeLine)
                                    .frame(height: 1)
                                Text("or")
                                    .font(.caption)
                                    .foregroundColor(.arveeInkMuted)
                                Rectangle()
                                    .fill(Color.arveeLine)
                                    .frame(height: 1)
                            }

                            Button {
                                Task { await viewModel.submitGoogle() }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(viewModel.mode == .signup ? "Sign Up with Google" : "Continue with Google")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                }
                                .foregroundColor(.arveeInk)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(Color.arveeLine, lineWidth: 0.7)
                                )
                                .cornerRadius(11)
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(18)
                    .arveeCard(cornerRadius: 18)
                    .padding(.horizontal, 22)
                }
                .padding(.top, 26)
                .padding(.bottom, 18)
            }
            .arveePageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.refreshAuthState()
            }
        }
    }
}
