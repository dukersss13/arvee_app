import Foundation

/// SSE client dedicated to streamed validation progress and completion payloads.
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
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        self.task = session?.dataTask(with: request)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
        task = nil
        session = nil
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
                onProgress?((stage?.isEmpty == false ? stage : "Validating your files...") ?? "Validating your files...", percent)
            } else {
                onProgress?("Validating your files...", nil)
            }
        case "done":
            guard let jsonData = data.data(using: .utf8) else {
                onError?("Invalid validation response payload.")
                return
            }
            do {
                let response = try JSONDecoder().decode(ValidationResponse.self, from: jsonData)
                onDone?(response)
            } catch {
                onError?("Failed to decode validation response.")
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
