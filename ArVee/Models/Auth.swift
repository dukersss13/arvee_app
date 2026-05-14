import Foundation

struct AuthUser: Codable {
    let email: String
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
