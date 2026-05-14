import Foundation
import AuthenticationServices
import CryptoKit
import Security
import UIKit

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
    @Published var isGoogleAvailable = false

    private let api = APIService.shared
    private var activeWebSession: ASWebAuthenticationSession?
    private let webAuthPresentationProvider = PresentationContextProvider()

    enum AuthMode: String, CaseIterable, Identifiable {
        case login = "Login"
        case signup = "Sign Up"

        var id: String { rawValue }
    }

    func refreshAuthState() {
        isAuthenticated = api.isAuthenticated
        authenticatedEmail = api.authenticatedEmail
        Task {
            await refreshGoogleAvailability()
        }
    }

    func refreshGoogleAvailability() async {
        do {
            let config = try await api.getGoogleAuthConfig()
            isGoogleAvailable = config.enabled
        } catch {
            isGoogleAvailable = false
        }
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
        let confirmPwd = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .signup && pwd != confirmPwd {
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

    func submitGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let config = try await withTimeout(seconds: 12) {
                try await self.api.getGoogleAuthConfig()
            }
            guard config.enabled, !config.clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw GoogleAuthError.notConfigured
            }

            let idToken = try await getGoogleIDToken(
                clientId: config.clientId,
                redirectScheme: config.redirectScheme
            )
            _ = try await withTimeout(seconds: 20) {
                try await self.api.loginWithGoogle(idToken: idToken)
            }
            refreshAuthState()
        } catch let error as GoogleAuthError {
            if case .timedOut = error {
                activeWebSession?.cancel()
                activeWebSession = nil
            }
            errorMessage = error.localizedDescription
        } catch let error as APIError {
            switch error {
            case .server(_, let message):
                errorMessage = message
            case .invalidURL:
                errorMessage = "Google sign-in could not reach the backend. Check API Base URL in Settings."
            }
        } catch let error as NSError
            where error.domain == ASWebAuthenticationSessionError.errorDomain
                && error.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            errorMessage = "Google sign-in was canceled."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func getGoogleIDToken(clientId: String, redirectScheme: String) async throws -> String {
        let verifier = Self.randomBase64URL(length: 32)
        let challenge = Self.pkceCodeChallenge(from: verifier)
        let state = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let redirectURI = "\(redirectScheme)://oauth2redirect/google"

        var authURLComponents = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        authURLComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "select_account")
        ]

        guard let authURL = authURLComponents?.url else {
            throw GoogleAuthError.invalidAuthorizationURL
        }

        let callbackURL = try await startWebAuthentication(url: authURL, callbackScheme: redirectScheme)
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw GoogleAuthError.invalidCallback
        }

        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        if let oauthError = query["error"], !oauthError.isEmpty {
            throw GoogleAuthError.oauthError(oauthError)
        }

        guard query["state"] == state else {
            throw GoogleAuthError.invalidState
        }
        guard let code = query["code"], !code.isEmpty else {
            throw GoogleAuthError.missingCode
        }

        return try await exchangeCodeForIDToken(
            code: code,
            clientId: clientId,
            redirectURI: redirectURI,
            codeVerifier: verifier
        )
    }

    private func startWebAuthentication(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.activeWebSession = nil

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: GoogleAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self.webAuthPresentationProvider
            session.prefersEphemeralWebBrowserSession = true
            self.activeWebSession = session

            if !session.start() {
                self.activeWebSession = nil
                continuation.resume(throwing: GoogleAuthError.unableToStart)
            }
        }
    }

    private func exchangeCodeForIDToken(
        code: String,
        clientId: String,
        redirectURI: String,
        codeVerifier: String
    ) async throws -> String {
        guard let tokenURL = URL(string: "https://oauth2.googleapis.com/token") else {
            throw GoogleAuthError.invalidTokenURL
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: codeVerifier)
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleAuthError.invalidTokenResponse
        }

        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Token exchange failed"
            throw GoogleAuthError.oauthError(message)
        }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let idToken = object["id_token"] as? String,
            !idToken.isEmpty
        else {
            throw GoogleAuthError.invalidTokenResponse
        }

        return idToken
    }

    private static func randomBase64URL(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let data = Data(bytes)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func pkceCodeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let data = Data(digest)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                let nanos = UInt64(seconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanos)
                throw GoogleAuthError.timedOut
            }

            guard let first = try await group.next() else {
                throw GoogleAuthError.timedOut
            }
            group.cancelAll()
            return first
        }
    }
}

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

private enum GoogleAuthError: LocalizedError {
    case notConfigured
    case invalidAuthorizationURL
    case invalidTokenURL
    case unableToStart
    case invalidCallback
    case invalidState
    case missingCode
    case invalidTokenResponse
    case timedOut
    case oauthError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google sign-in isn't available for this server yet."
        case .invalidAuthorizationURL:
            return "Could not start Google login."
        case .invalidTokenURL:
            return "Google token endpoint is invalid."
        case .unableToStart:
            return "Could not present Google login."
        case .invalidCallback:
            return "Google login callback was invalid."
        case .invalidState:
            return "Google login state check failed. Please try again."
        case .missingCode:
            return "Google did not return an authorization code."
        case .invalidTokenResponse:
            return "Google login succeeded, but token parsing failed."
        case .timedOut:
            return "Google sign-in timed out. Check your network and backend URL, then try again."
        case .oauthError(let message):
            return "Google login failed: \(message)"
        }
    }
}
