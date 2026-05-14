import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isStreaming = false
    @Published var errorMessage: String?
    @Published var processingStage: String?
    @Published var processingPercent: Int?

    private var sseClient: SSEClient?
    private let api = APIService.shared
    private var stateSyncHandler: ((String) async -> Void)?
    private var bufferingTask: Task<Void, Never>?

    private let whimsicalBufferMessages = [
        "Let me peek into your receipts...",
        "Crunching the numbers with sparkle dust...",
        "Shuffling pennies and spreadsheets...",
        "One moment while I chase the totals...",
        "Brewing a fresh spending snapshot...",
    ]

    func setStateSyncHandler(_ handler: @escaping (String) async -> Void) {
        stateSyncHandler = handler
    }

    func sendMessage(sessionId: String) async {
        guard !isStreaming else { return }

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if let stateSyncHandler {
            await stateSyncHandler(sessionId)
        }

        let userMsg = ChatMessage(
            role: .user, text: text, isPending: false,
            chart: nil, topCategories: nil, comparisonTable: nil,
            quickReplies: nil
        )
        messages.append(userMsg)
        inputText = ""

        let placeholder = whimsicalBufferMessages.randomElement() ?? "Let me look into it..."

        let assistantMsg = ChatMessage(
            role: .assistant, text: placeholder, isPending: true,
            chart: nil, topCategories: nil, comparisonTable: nil,
            quickReplies: nil
        )
        messages.append(assistantMsg)
        let assistantIndex = messages.count - 1

        isStreaming = true
        errorMessage = nil
        processingStage = "Working on your request..."
        processingPercent = 0

        startBufferingUpdates(for: assistantIndex)

        let (url, body) = api.chatStreamURL(sessionId: sessionId, message: text)
        let client = SSEClient()
        self.sseClient = client

        client.onToken = { [weak self] token in
            guard let self = self else { return }
            guard self.messages.indices.contains(assistantIndex) else { return }
            self.stopBufferingUpdates()
            if self.messages[assistantIndex].text == placeholder {
                self.messages[assistantIndex].text = ""
            }
            self.messages[assistantIndex].text += token
        }

        client.onProgress = { [weak self] stage, percent in
            guard let self = self else { return }
            self.processingStage = stage
            self.processingPercent = percent
        }

        client.onDone = { [weak self] response in
            guard let self = self else { return }
            guard self.messages.indices.contains(assistantIndex) else {
                self.isStreaming = false
                self.processingStage = nil
                self.processingPercent = nil
                self.sseClient = nil
                return
            }
            self.stopBufferingUpdates()
            self.messages[assistantIndex].isPending = false

            // If no tokens were streamed, use answer payload instead of placeholder text.
            if self.messages[assistantIndex].text == placeholder {
                self.messages[assistantIndex].text = response.answer ?? "I found some results for you."
            } else if self.messages[assistantIndex].text.isEmpty, let answer = response.answer {
                self.messages[assistantIndex].text = answer
            }

            self.messages[assistantIndex].chart = response.chart
            self.messages[assistantIndex].topCategories = response.topCategories
            self.messages[assistantIndex].quickReplies = response.quickReplies

            // Comparison table can come from the chart or from the top-level field
            if let table = response.comparisonTable {
                self.messages[assistantIndex].comparisonTable = table
            } else if let table = response.chart?.table {
                self.messages[assistantIndex].comparisonTable = table
            }

            self.isStreaming = false
            self.processingStage = nil
            self.processingPercent = nil
            self.sseClient = nil
        }

        client.onError = { [weak self] msg in
            guard let self = self else { return }
            guard self.messages.indices.contains(assistantIndex) else {
                self.isStreaming = false
                self.processingStage = nil
                self.processingPercent = nil
                self.sseClient = nil
                return
            }
            self.stopBufferingUpdates()
            self.messages[assistantIndex].isPending = false
            self.messages[assistantIndex].text = "Error: \(msg)"
            self.isStreaming = false
            self.processingStage = nil
            self.processingPercent = nil
            self.sseClient = nil
        }

        client.start(url: url, body: body)
    }

    func cancelStream() {
        sseClient?.cancel()
        sseClient = nil
        stopBufferingUpdates()
        isStreaming = false
        processingStage = nil
        processingPercent = nil
        if let last = messages.indices.last, messages[last].isPending {
            messages[last].isPending = false
            if messages[last].text.isEmpty || isBufferingMessage(messages[last].text) {
                messages[last].text = "No problem. I stopped that request. Ask me anything else when you're ready."
            }
        }
    }

    func clear() {
        cancelStream()
        messages = []
        errorMessage = nil
    }

    private func startBufferingUpdates(for assistantIndex: Int) {
        stopBufferingUpdates()
        bufferingTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                guard !Task.isCancelled else { return }
                guard self.isStreaming, self.messages.indices.contains(assistantIndex) else { return }
                if !self.messages[assistantIndex].isPending {
                    return
                }

                // Keep the pending assistant bubble feeling alive before first tokens arrive.
                if self.messages[assistantIndex].text.isEmpty || self.isBufferingMessage(self.messages[assistantIndex].text) {
                    self.messages[assistantIndex].text = self.whimsicalBufferMessages.randomElement() ?? "Working on your request..."
                }
            }
        }
    }

    private func stopBufferingUpdates() {
        bufferingTask?.cancel()
        bufferingTask = nil
    }

    private func isBufferingMessage(_ text: String) -> Bool {
        whimsicalBufferMessages.contains(text) || text == "Working on your request..."
    }
}
