import Foundation

/// Central HTTP client for all Flask backend API calls.
final class APIService {
    static let shared = APIService()

    /// Base URL for the Flask backend. Update this to your server address.
    var baseURL = "http://localhost:5000"

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Session

    func createSession() async throws -> String {
        let data = try await post(path: "/api/session/new")
        let response = try decoder.decode(SessionResponse.self, from: data)
        return response.sessionId
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
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try checkHTTPResponse(response, data: data)
        return try decoder.decode(ValidationResponse.self, from: data)
    }

    // MARK: - Chat

    func chatAsk(sessionId: String, message: String) async throws -> ChatAskResponse {
        let payload = ["sessionId": sessionId, "message": message]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await post(path: "/api/chat/ask", body: body, contentType: "application/json")
        return try decoder.decode(ChatAskResponse.self, from: data)
    }

    func chatStreamURL(sessionId: String, message: String) -> (URL, Data) {
        let url = URL(string: "\(baseURL)/api/chat/ask/stream")!
        let payload = ["sessionId": sessionId, "message": message]
        let body = try! JSONSerialization.data(withJSONObject: payload)
        return (url, body)
    }

    // MARK: - Export

    func exportPDF(rows: [[String: Any]]) async throws -> Data {
        let payload = ["rows": rows] as [String: Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await post(path: "/api/export/validated", body: body, contentType: "application/json")
    }

    // MARK: - Helpers

    private func get(path: String) async throws -> Data {
        let url = URL(string: "\(baseURL)\(path)")!
        let (data, response) = try await session.data(from: url)
        try checkHTTPResponse(response, data: data)
        return data
    }

    private func post(
        path: String,
        body: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try checkHTTPResponse(response, data: data)
        return data
    }

    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                message = error
            } else {
                message = "Request failed with status \(http.statusCode)"
            }
            throw APIError.server(statusCode: http.statusCode, message: message)
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
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .server(_, let message):
            return message
        }
    }
}
