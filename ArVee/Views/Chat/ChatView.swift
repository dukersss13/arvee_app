import SwiftUI

struct ChatView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var inputFocused: Bool

    private let suggestions = [
        "How much did I spend on food?",
        "What's my top spending category?",
        "Show my top 5 categories",
        "Chart my spending this month",
    ]

    var body: some View {
        NavigationStack {
            Group {
                if !sessionVM.hasSession {
                    noSessionPlaceholder
                } else if viewModel.messages.isEmpty {
                    welcomeView
                } else {
                    chatContent
                }
            }
            .arveePageBackground()
            .navigationTitle("ArVee Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if sessionVM.hasSession {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.clear()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.arveeInkMuted)
                        }
                        .disabled(viewModel.messages.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - No Session

    private var noSessionPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.arveeInkMuted)
            Text("Start a session to chat with ArVee")
                .font(.arveeHeadline())
                .foregroundColor(.arveeInk)
            Text("Go to the Session tab to create or load one.")
                .font(.subheadline)
                .foregroundColor(.arveeInkMuted)
        }
    }

    // MARK: - Welcome View (session active, no messages)

    private var welcomeView: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                StatusBanner(message: error, type: .error)
            }

            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.arveeTealGradient)

                Text("Hi, I'm ArVee!")
                    .font(.arveeBrand(24))
                    .foregroundColor(.arveeInk)

                Text("I'm here to help with your finances.\nTry asking me:")
                    .font(.subheadline)
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.inputText = suggestion
                            send()
                        } label: {
                            Text(suggestion)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.arveeTeal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.arveeTeal.opacity(0.07))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.arveeTeal.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Divider().overlay(Color.arveeLine)
            inputBar
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                StatusBanner(message: error, type: .error)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.messages.last?.text) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            Divider().overlay(Color.arveeLine)
            inputBar
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask ArVee about your spending...", text: $viewModel.inputText, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .lineLimit(1...5)
                .focused($inputFocused)
                .onSubmit {
                    send()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.arveeCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.arveeLine, lineWidth: 0.5)
                )

            if viewModel.isStreaming {
                Button {
                    viewModel.cancelStream()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.arveeDanger)
                }
            } else {
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.arveeTealGradient)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.arveeSand.opacity(0.5))
    }

    private func send() {
        guard let sessionId = sessionVM.sessionId else { return }
        viewModel.sendMessage(sessionId: sessionId)
        inputFocused = false
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}
