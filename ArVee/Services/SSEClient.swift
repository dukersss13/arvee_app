import Foundation

/// Lightweight Server-Sent Events client for streaming chat responses.
final class SSEClient: NSObject, URLSessionDataDelegate {
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""

    var onToken: ((String) -> Void)?
    var onProgress: ((String, Int?) -> Void)?
    var onDone: ((ChatAskResponse) -> Void)?
    var onError: ((String) -> Void)?

    func start(url: URL, body: Data) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = body

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        self.task = session?.dataTask(with: request)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        while let newlineRange = buffer.range(of: "\n\n") {
            let chunk = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])
            parseSSEChunk(chunk)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            onError?("Connection error: \(error.localizedDescription)")
        }
    }

    // MARK: - Parsing

    private func parseSSEChunk(_ chunk: String) {
        var event = ""
        var data = ""

        for line in chunk.components(separatedBy: "\n") {
            if line.hasPrefix("event: ") {
                event = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                data = String(line.dropFirst(6))
            }
        }

        switch event {
        case "progress":
            if let json = parseJSON(data) {
                let stage = (json["stage"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let percent = json["percent"] as? Int
                onProgress?((stage?.isEmpty == false ? stage : "Working on your request...") ?? "Working on your request...", percent)
            } else {
                onProgress?("Working on your request...", nil)
            }
        case "token":
            if let json = parseJSON(data), let token = json["token"] as? String {
                onToken?(token)
            }
        case "done":
            if let jsonData = data.data(using: .utf8) {
                do {
                    let response = try JSONDecoder().decode(ChatAskResponse.self, from: jsonData)
                    onDone?(response)
                } catch {
                    // Fallback: extract just the answer
                    if let json = parseJSON(data), let answer = json["answer"] as? String {
                        let fallback = ChatAskResponse(
                            sessionId: json["sessionId"] as? String,
                            question: nil, answer: answer, rowsScanned: nil,
                            toolUsed: nil, confidence: nil, route: nil,
                            toolName: nil, needsClarification: nil,
                            chart: nil, topCategories: nil, comparisonTable: nil,
                            quickReplies: json["quickReplies"] as? [String]
                        )
                        onDone?(fallback)
                    }
                }
            }
        case "error":
            if let json = parseJSON(data), let msg = json["error"] as? String {
                onError?(msg)
            } else {
                onError?(data)
            }
        default:
            break
        }
    }

    private func parseJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

/// Server-Sent Events client for streaming validation progress and final results.
final class ValidationSSEClient: NSObject, URLSessionDataDelegate {
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""

    var onProgress: ((String, Int?) -> Void)?
    var onDone: ((ValidationResponse) -> Void)?
    var onError: ((String) -> Void)?

    func start(url: URL, body: Data, contentType: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = body

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        self.task = session?.dataTask(with: request)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        while let newlineRange = buffer.range(of: "\n\n") {
            let chunk = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])
            parseSSEChunk(chunk)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            onError?("Connection error: \(error.localizedDescription)")
        }
    }

    private func parseSSEChunk(_ chunk: String) {
        var event = ""
        var data = ""

        for line in chunk.components(separatedBy: "\n") {
            if line.hasPrefix("event: ") {
                event = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                data = String(line.dropFirst(6))
            }
        }

        switch event {
        case "progress":
            if let json = parseJSON(data) {
                let stage = (json["stage"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let percent = json["percent"] as? Int
                onProgress?((stage?.isEmpty == false ? stage : "Validating...") ?? "Validating...", percent)
            } else {
                onProgress?("Validating...", nil)
            }
        case "done":
            guard let jsonData = data.data(using: .utf8) else { return }
            do {
                let response = try JSONDecoder().decode(ValidationResponse.self, from: jsonData)
                onDone?(response)
            } catch {
                onError?("Could not decode validation response: \(error.localizedDescription)")
            }
        case "error":
            if let json = parseJSON(data), let message = json["error"] as? String {
                onError?(message)
            } else {
                onError?(data)
            }
        default:
            break
        }
    }

    private func parseJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
