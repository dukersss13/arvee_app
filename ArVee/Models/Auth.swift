import Foundation

struct AuthUser: Codable {
    let email: String
    let provider: String?
    let name: String?
    let picture: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: AuthUser
}

struct AuthMePayload: Codable {
    let id: String?
    let email: String?
}

struct AuthMeResponse: Codable {
    let user: AuthMePayload
}

struct GoogleAuthConfigResponse: Codable {
    let enabled: Bool
    let clientId: String
    let iosClientId: String?
    let redirectScheme: String

    /// Returns the best client ID for an iOS native OAuth flow.
    /// Prefers the dedicated iOS client ID when available.
    var effectiveClientId: String {
        if let ios = iosClientId, !ios.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ios
        }
        return clientId
    }

    /// Redirect scheme derived from the iOS client ID (reversed client ID).
    /// Falls back to the backend-provided ``redirectScheme``.
    var effectiveRedirectScheme: String {
        if let ios = iosClientId, !ios.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ios.components(separatedBy: ".").reversed().joined(separator: ".")
        }
        return redirectScheme
    }
}
