import Foundation
import Darwin

/// Central HTTP client for all Flask backend API calls.
final class APIService {
    static let shared = APIService()
    static let defaultBaseURL = "https://arvee-backend-5hqe7uiuka-uc.a.run.app"

    private enum StorageKeys {
        static let apiBaseURL = "apiBaseURL"
        static let authToken = "authToken"
        static let authEmail = "authEmail"
    }

    /// Base URL for the Flask backend. Update this to your server address.
    var baseURL = APIService.defaultBaseURL {
        didSet {
            baseURL = Self.normalizedBaseURL(baseURL)
        }
    }

    var authToken: String? {
        UserDefaults.standard.string(forKey: StorageKeys.authToken)
    }

    var authenticatedEmail: String? {
        UserDefaults.standard.string(forKey: StorageKeys.authEmail)
    }

    var isAuthenticated: Bool {
        guard let token = authToken else { return false }
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let session: URLSession
    private let discoverySession: URLSession
    private let decoder: JSONDecoder
    private let discoveryTimeout: TimeInterval = 0.45

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = false

        let discoveryConfig = URLSessionConfiguration.ephemeral
        discoveryConfig.timeoutIntervalForRequest = discoveryTimeout
        discoveryConfig.timeoutIntervalForResource = discoveryTimeout
        discoveryConfig.waitsForConnectivity = false

        self.session = URLSession(configuration: config)
        self.discoverySession = URLSession(configuration: discoveryConfig)
        self.decoder = JSONDecoder()
        if let saved = UserDefaults.standard.string(forKey: StorageKeys.apiBaseURL), !saved.isEmpty {
            self.baseURL = saved
        } else {
            self.baseURL = APIService.defaultBaseURL
        }
        self.baseURL = Self.normalizedBaseURL(self.baseURL)
    }

    func setAuthSession(token: String, email: String) {
        UserDefaults.standard.set(token, forKey: StorageKeys.authToken)
        UserDefaults.standard.set(email, forKey: StorageKeys.authEmail)
    }

    func clearAuthSession() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.authToken)
        UserDefaults.standard.removeObject(forKey: StorageKeys.authEmail)
    }

    private func applyAuthHeaders(_ request: inout URLRequest) {
        if let token = authToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let email = authenticatedEmail, !email.isEmpty {
            request.setValue(email, forHTTPHeaderField: "X-User-Id")
        }
    }

    static func normalizedBaseURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased()
        else {
            return trimmed
        }

        let isLocalHost = host == "localhost" || host == "127.0.0.1"
        let isPrivateIPv4 =
            host.hasPrefix("10.") ||
            host.hasPrefix("192.168.") ||
            host.hasPrefix("172.16.") ||
            host.hasPrefix("172.17.") ||
            host.hasPrefix("172.18.") ||
            host.hasPrefix("172.19.") ||
            host.hasPrefix("172.20.") ||
            host.hasPrefix("172.21.") ||
            host.hasPrefix("172.22.") ||
            host.hasPrefix("172.23.") ||
            host.hasPrefix("172.24.") ||
            host.hasPrefix("172.25.") ||
            host.hasPrefix("172.26.") ||
            host.hasPrefix("172.27.") ||
            host.hasPrefix("172.28.") ||
            host.hasPrefix("172.29.") ||
            host.hasPrefix("172.30.") ||
            host.hasPrefix("172.31.")

        if scheme == "https" && (isLocalHost || isPrivateIPv4) {
            components.scheme = "http"
            return components.string ?? trimmed
        }

        return trimmed
    }

    // MARK: - Session

    /// Check if the backend is reachable and return a diagnostic message.
    func healthCheck() async -> HealthCheckResult {
        let trimmed = Self.normalizedBaseURL(baseURL)
        baseURL = trimmed
        guard URL(string: "\(trimmed)/api/health") != nil else {
            return HealthCheckResult(
                isConnected: false,
                message: "Invalid API URL format."
            )
        }

        do {
            var request = URLRequest(url: try makeURL(path: "/api/health"))
            request.httpMethod = "GET"
            request.timeoutInterval = 12
            applyAuthHeaders(&request)

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 12
            config.timeoutIntervalForResource = 12
            config.waitsForConnectivity = false

            let fastSession = URLSession(configuration: config)
            let (data, response) = try await fastSession.data(for: request)
            try checkHTTPResponse(response, data: data)
            return HealthCheckResult(isConnected: true, message: "Connected")
        } catch let error as URLError {
            switch error.code {
            case .cannotFindHost, .dnsLookupFailed:
                return HealthCheckResult(
                    isConnected: false,
                    message: "Cannot resolve host. Use your Mac LAN IP on a physical device."
                )
            case .cannotConnectToHost, .networkConnectionLost:
                return HealthCheckResult(
                    isConnected: false,
                    message: "Cannot reach backend. Check backend.py, URL, and port 7860."
                )
            case .timedOut:
                return HealthCheckResult(
                    isConnected: false,
                    message: "Connection timed out."
                )
            case .appTransportSecurityRequiresSecureConnection:
                return HealthCheckResult(
                    isConnected: false,
                    message: "HTTP blocked by iOS security policy."
                )
            default:
                return HealthCheckResult(
                    isConnected: false,
                    message: "Network error: \(error.localizedDescription)"
                )
            }
        } catch let APIError.server(statusCode, message, _) {
            return HealthCheckResult(
                isConnected: false,
                message: "Backend reachable (\(statusCode)) but returned: \(message)"
            )
        } catch {
            return HealthCheckResult(
                isConnected: false,
                message: "Connection failed: \(error.localizedDescription)"
            )
        }
    }

    func createSession() async throws -> String {
        let data = try await post(path: "/api/session/new")
        let response = try decoder.decode(SessionResponse.self, from: data)
        return response.sessionId
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws -> AuthResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await post(path: "/api/auth/signup", body: body)
        let response = try decoder.decode(AuthResponse.self, from: data)
        setAuthSession(token: response.token, email: response.user.email)
        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await post(path: "/api/auth/login", body: body)
        let response = try decoder.decode(AuthResponse.self, from: data)
        setAuthSession(token: response.token, email: response.user.email)
        return response
    }

    func getCurrentUser() async throws -> AuthMeResponse {
        let data = try await get(path: "/api/auth/me")
        return try decoder.decode(AuthMeResponse.self, from: data)
    }

    func getGoogleAuthConfig() async throws -> GoogleAuthConfigResponse {
        var request = URLRequest(url: try makeURL(path: "/api/auth/google/config"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 12
        config.waitsForConnectivity = false

        let fastSession = URLSession(configuration: config)
        let (data, response) = try await fastSession.data(for: request)
        try checkHTTPResponse(response, data: data)
        return try decoder.decode(GoogleAuthConfigResponse.self, from: data)
    }

    func loginWithGoogle(idToken: String) async throws -> AuthResponse {
        let payload = ["idToken": idToken]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await post(path: "/api/auth/google/token", body: body)
        let response = try decoder.decode(AuthResponse.self, from: data)
        setAuthSession(token: response.token, email: response.user.email)
        return response
    }

    func loadSessionInputs(sessionId: String) async throws -> SessionInputsResponse {
        let data = try await get(path: "/api/session/\(sessionId)")
        return try decoder.decode(SessionInputsResponse.self, from: data)
    }

    func loadSessionState(sessionId: String) async throws -> SessionState? {
        let data = try await get(path: "/api/session/\(sessionId)/state")
        let response = try decoder.decode(SessionStateResponse.self, from: data)
        return response.state
    }

    func saveSessionState(sessionId: String, state: [String: Any]) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["state": state])
        _ = try await post(path: "/api/session/\(sessionId)/save", body: body)
    }

    // MARK: - Validation

    func validate(
        sessionId: String,
        transactionFiles: [FilePayload],
        proofFiles: [FilePayload]
    ) async throws -> ValidationResponse {
        let boundary = UUID().uuidString
        var body = Data()

        appendField(&body, name: "sessionId", value: sessionId, boundary: boundary)

        for file in transactionFiles {
            appendFile(&body, name: "transactions", file: file, boundary: boundary)
        }
        for file in proofFiles {
            appendFile(&body, name: "proofs", file: file, boundary: boundary)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "\(baseURL)/api/validate")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(&request)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try checkHTTPResponse(response, data: data)
        return try decoder.decode(ValidationResponse.self, from: data)
    }

    func validateStreamRequest(
        sessionId: String,
        transactionFiles: [FilePayload],
        proofFiles: [FilePayload]
    ) -> (url: URL, body: Data, contentType: String, headers: [String: String]) {
        let boundary = UUID().uuidString
        var body = Data()

        appendField(&body, name: "sessionId", value: sessionId, boundary: boundary)

        for file in transactionFiles {
            appendFile(&body, name: "transactions", file: file, boundary: boundary)
        }
        for file in proofFiles {
            appendFile(&body, name: "proofs", file: file, boundary: boundary)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var headers: [String: String] = [:]
        if let token = authToken, !token.isEmpty {
            headers["Authorization"] = "Bearer \(token)"
        }
        if let email = authenticatedEmail, !email.isEmpty {
            headers["X-User-Id"] = email
        }

        return (
            url: URL(string: "\(baseURL)/api/validate/stream")!,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            headers: headers
        )
    }

    // MARK: - Chat

    func chatAsk(sessionId: String, message: String) async throws -> ChatAskResponse {
        let payload = ["sessionId": sessionId, "message": message]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await post(path: "/api/chat/ask", body: body, contentType: "application/json")
        return try decoder.decode(ChatAskResponse.self, from: data)
    }

    func chatStreamURL(sessionId: String, message: String) -> (URL, Data, [String: String]) {
        let url = URL(string: "\(baseURL)/api/chat/ask/stream")!
        let payload = ["sessionId": sessionId, "message": message]
        let body = try! JSONSerialization.data(withJSONObject: payload)
        var headers: [String: String] = [:]
        if let token = authToken, !token.isEmpty {
            headers["Authorization"] = "Bearer \(token)"
        }
        if let email = authenticatedEmail, !email.isEmpty {
            headers["X-User-Id"] = email
        }
        return (url, body, headers)
    }

    // MARK: - Export

    func exportPDF(rows: [[String: Any]]) async throws -> Data {
        let payload = ["rows": rows] as [String: Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await post(path: "/api/export/validated", body: body, contentType: "application/json")
    }

    // MARK: - Helpers

    private func get(path: String) async throws -> Data {
        var request = URLRequest(url: try makeURL(path: path))
        request.httpMethod = "GET"
        applyAuthHeaders(&request)
        do {
            let (data, response) = try await session.data(for: request)
            try checkHTTPResponse(response, data: data)
            return data
        } catch {
            let originalBaseURL = baseURL
            let defaultURL = Self.normalizedBaseURL(Self.defaultBaseURL)

            // If a stale custom URL is saved, fall back to the production default first.
            if shouldAttemptAutoDiscovery(error), originalBaseURL != defaultURL {
                do {
                    baseURL = defaultURL
                    var fallbackRequest = URLRequest(url: try makeURL(path: path))
                    fallbackRequest.httpMethod = "GET"
                    applyAuthHeaders(&fallbackRequest)
                    let (fallbackData, fallbackResponse) = try await session.data(for: fallbackRequest)
                    try checkHTTPResponse(fallbackResponse, data: fallbackData)
                    return fallbackData
                } catch {
                    baseURL = originalBaseURL
                }
            }

            guard shouldAttemptAutoDiscovery(error),
                  let discoveredURL = await discoverBackendBaseURL(),
                  discoveredURL != baseURL
            else {
                throw error
            }

            baseURL = discoveredURL
            var retryRequest = URLRequest(url: try makeURL(path: path))
            retryRequest.httpMethod = "GET"
            applyAuthHeaders(&retryRequest)
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            try checkHTTPResponse(retryResponse, data: retryData)
            return retryData
        }
    }

    private func post(
        path: String,
        body: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> Data {
        var request = URLRequest(url: try makeURL(path: path))
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(&request)
        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)
            try checkHTTPResponse(response, data: data)
            return data
        } catch {
            let originalBaseURL = baseURL
            let defaultURL = Self.normalizedBaseURL(Self.defaultBaseURL)

            // If a stale custom URL is saved, fall back to the production default first.
            if shouldAttemptAutoDiscovery(error), originalBaseURL != defaultURL {
                do {
                    baseURL = defaultURL
                    var fallbackRequest = URLRequest(url: try makeURL(path: path))
                    fallbackRequest.httpMethod = "POST"
                    fallbackRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    applyAuthHeaders(&fallbackRequest)
                    fallbackRequest.httpBody = body
                    let (fallbackData, fallbackResponse) = try await session.data(for: fallbackRequest)
                    try checkHTTPResponse(fallbackResponse, data: fallbackData)
                    return fallbackData
                } catch {
                    baseURL = originalBaseURL
                }
            }

            guard shouldAttemptAutoDiscovery(error),
                  let discoveredURL = await discoverBackendBaseURL(),
                  discoveredURL != baseURL
            else {
                throw error
            }

            baseURL = discoveredURL
            var retryRequest = URLRequest(url: try makeURL(path: path))
            retryRequest.httpMethod = "POST"
            retryRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(&retryRequest)
            retryRequest.httpBody = body
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            try checkHTTPResponse(retryResponse, data: retryData)
            return retryData
        }
    }

    private func makeURL(path: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL(baseURL)
        }
        return url
    }

    private func shouldAttemptAutoDiscovery(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .cannotFindHost,
             .dnsLookupFailed,
             .cannotConnectToHost,
             .networkConnectionLost,
             .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func discoverBackendBaseURL() async -> String? {
        guard let localIP = localIPv4Address() else { return nil }
        let octets = localIP.split(separator: ".")
        guard octets.count == 4 else { return nil }

        let subnetPrefix = "\(octets[0]).\(octets[1]).\(octets[2])"
        let localHost = localIP

        let currentPort = URLComponents(string: baseURL)?.port ?? 7860
        let candidates = candidateHosts(in: subnetPrefix, excluding: localHost)

        return await withTaskGroup(of: String?.self, returning: String?.self) { group in
            for host in candidates {
                group.addTask {
                    let candidateURL = "http://\(host):\(currentPort)"
                    let reachable = await self.probeHealth(baseURL: candidateURL)
                    return reachable ? candidateURL : nil
                }
            }

            for await result in group {
                if let found = result {
                    group.cancelAll()
                    return found
                }
            }
            return nil
        }
    }

    private func candidateHosts(in prefix: String, excluding localHost: String) -> [String] {
        var hosts: [String] = []
        var seen = Set<String>()

        // Favor common gateway and developer-machine suffixes first.
        let prioritySuffixes = [1, 2, 10, 20, 21, 30, 40, 50, 54, 100, 200, 254]
        for suffix in prioritySuffixes {
            let host = "\(prefix).\(suffix)"
            if host != localHost && !seen.contains(host) {
                seen.insert(host)
                hosts.append(host)
            }
        }

        for suffix in 1...254 {
            let host = "\(prefix).\(suffix)"
            if host != localHost && !seen.contains(host) {
                seen.insert(host)
                hosts.append(host)
            }
        }

        return hosts
    }

    private func probeHealth(baseURL: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = discoveryTimeout

        do {
            let (data, response) = try await discoverySession.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return false
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return status.lowercased() == "ok"
            }

            return true
        } catch {
            return false
        }
    }

    private func localIPv4Address() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name == "en1" || name == "pdp_ip0" else { continue }

            var addr = interface.ifa_addr.pointee
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            let result = getnameinfo(
                &addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostBuffer,
                socklen_t(hostBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            if result == 0 {
                address = String(cString: hostBuffer)
                if name == "en0" {
                    break
                }
            }
        }

        return address
    }

    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let message: String
            let errorClass: String?
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                message = error
                errorClass = json["errorClass"] as? String
            } else {
                message = "Request failed with status \(http.statusCode)"
                errorClass = nil
            }
            throw APIError.server(
                statusCode: http.statusCode,
                message: message,
                errorClass: errorClass
            )
        }
    }

    // MARK: - Multipart Helpers

    private func appendField(_ body: inout Data, name: String, value: String, boundary: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    private func appendFile(_ body: inout Data, name: String, file: FilePayload, boundary: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(file.data)
        body.append("\r\n".data(using: .utf8)!)
    }
}

struct FilePayload {
    let filename: String
    let data: Data
    let mimeType: String
}

enum APIError: LocalizedError {
    case server(statusCode: Int, message: String, errorClass: String?)
    case invalidURL(String)

    var backendErrorClass: String? {
        switch self {
        case .server(_, _, let errorClass):
            return errorClass
        case .invalidURL:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _):
            return message
        case .invalidURL(let url):
            return "Invalid API URL: \(url)"
        }
    }
}

struct HealthCheckResult {
    let isConnected: Bool
    let message: String
}
