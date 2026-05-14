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
    let redirectScheme: String
}
