import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mode: AuthMode = .login
    @Published var isAuthenticated = APIService.shared.isAuthenticated
    @Published var authenticatedEmail = APIService.shared.authenticatedEmail

    private let api = APIService.shared

    enum AuthMode: String, CaseIterable, Identifiable {
        case login = "Login"
        case signup = "Sign Up"

        var id: String { rawValue }
    }

    func refreshAuthState() {
        isAuthenticated = api.isAuthenticated
        authenticatedEmail = api.authenticatedEmail
    }

    func submit() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pwd = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty, normalizedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard pwd.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        if mode == .signup && pwd != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            if mode == .signup {
                _ = try await api.signUp(email: normalizedEmail, password: pwd)
            } else {
                _ = try await api.login(email: normalizedEmail, password: pwd)
            }
            refreshAuthState()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        api.clearAuthSession()
        refreshAuthState()
        password = ""
        confirmPassword = ""
    }
}
