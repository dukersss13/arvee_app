import SwiftUI

struct ChatView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var inputFocused: Bool
    @State private var welcomeScale: CGFloat = 0.6
    @State private var showingQuickSuggestions = false

    private let suggestions = [
        "How much did I spend on food?",
        "What's my top spending category?",
        "Show my top 5 categories",
        "Chart my spending this month",
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.messages.isEmpty || showingQuickSuggestions {
                    welcomeView
                } else {
                    chatContent
                }
            }
            .arveePageBackground()
            .navigationTitle("ArVee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.arveePaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.messages.isEmpty && !showingQuickSuggestions {
                        Button {
                            inputFocused = false
                            showingQuickSuggestions = true
                        } label: {
                            Label("Suggestions", systemImage: "chevron.backward")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.arveeTeal)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.clear()
                        showingQuickSuggestions = false
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.arveeInkMuted)
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            .task {
                await sessionVM.ensureSession()
            }
        }
    }

    // MARK: - Welcome View (session active, no messages)

    private var welcomeView: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                StatusBanner(message: error, type: .error)
            }

            ScrollView {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.arveeTealSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.arveeTealGradient)
                    }
                    .scaleEffect(welcomeScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                            welcomeScale = 1.0
                        }
                    }

                    Text("Hi, I'm ArVee!")
                        .font(.arveeBrand(24))
                        .foregroundColor(.arveeInk)

                    Text("I'm here to help with your finances.\nTry asking me:")
                        .font(.subheadline)
                        .foregroundColor(.arveeInkMuted)
                        .multilineTextAlignment(.center)

                    // Pill-style suggestion chips
                    FlowLayout(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.inputText = suggestion
                                send()
                            } label: {
                                Text(suggestion)
                            }
                            .buttonStyle(ArveePillButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .top)
            }

            Divider().overlay(Color.arveeLine)
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .padding(.horizontal, 6)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.messages.last?.text) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Quick replies after last assistant message
            if !viewModel.isStreaming,
               let replies = viewModel.messages.last?.quickReplies,
               !replies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(replies, id: \.self) { reply in
                            Button {
                                viewModel.inputText = reply
                                send()
                            } label: {
                                Text(reply)
                            }
                            .buttonStyle(ArveePillButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Color.arveePaper.opacity(0.95))
            }

            Divider().overlay(Color.arveeLine)
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .padding(.vertical, 10)
                .background(Color.arveeCardElevated)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.arveeLine, lineWidth: 0.5)
                )
                .shadow(color: Color.arveeInk.opacity(0.04), radius: 4, x: 0, y: 2)

            if inputFocused {
                Button {
                    inputFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.arveeInkMuted)
                }
                .accessibilityLabel("Collapse keyboard")
            }

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
        .background(Color.arveePaper.opacity(0.95))
    }

    private func send() {
        guard let sessionId = sessionVM.sessionId else { return }
        showingQuickSuggestions = false
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

// MARK: - Flow Layout (wrapping horizontal layout for pill chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
