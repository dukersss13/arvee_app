import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isStreaming = false
    @Published var errorMessage: String?

    private var sseClient: SSEClient?
    private let api = APIService.shared

    func sendMessage(sessionId: String) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMsg = ChatMessage(
            role: .user, text: text, isPending: false,
            chart: nil, topCategories: nil, comparisonTable: nil
        )
        messages.append(userMsg)
        inputText = ""

        let assistantMsg = ChatMessage(
            role: .assistant, text: "", isPending: true,
            chart: nil, topCategories: nil, comparisonTable: nil
        )
        messages.append(assistantMsg)
        let assistantIndex = messages.count - 1

        isStreaming = true
        errorMessage = nil

        let (url, body) = api.chatStreamURL(sessionId: sessionId, message: text)
        let client = SSEClient()
        self.sseClient = client

        client.onToken = { [weak self] token in
            guard let self = self else { return }
            self.messages[assistantIndex].text += token
        }

        client.onDone = { [weak self] response in
            guard let self = self else { return }
            self.messages[assistantIndex].isPending = false

            // Prefer streamed text over response.answer since tokens already accumulated
            if self.messages[assistantIndex].text.isEmpty, let answer = response.answer {
                self.messages[assistantIndex].text = answer
            }

            self.messages[assistantIndex].chart = response.chart
            self.messages[assistantIndex].topCategories = response.topCategories

            // Comparison table can come from the chart or from the top-level field
            if let table = response.comparisonTable {
                self.messages[assistantIndex].comparisonTable = table
            } else if let table = response.chart?.table {
                self.messages[assistantIndex].comparisonTable = table
            }

            self.isStreaming = false
            self.sseClient = nil
        }

        client.onError = { [weak self] msg in
            guard let self = self else { return }
            self.messages[assistantIndex].isPending = false
            self.messages[assistantIndex].text = "Error: \(msg)"
            self.isStreaming = false
            self.sseClient = nil
        }

        client.start(url: url, body: body)
    }

    func cancelStream() {
        sseClient?.cancel()
        sseClient = nil
        isStreaming = false
        if let last = messages.indices.last, messages[last].isPending {
            messages[last].isPending = false
        }
    }

    func clear() {
        cancelStream()
        messages = []
        errorMessage = nil
    }
}
