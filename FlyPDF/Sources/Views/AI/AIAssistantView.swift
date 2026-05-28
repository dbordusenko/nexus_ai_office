import SwiftUI

// MARK: - AI Orb (Floating)

struct AIOrb: View {
    @State private var pulse = false
    @State private var glow = false
    @State private var showChat = false
    let document: FlyDocument?

    var body: some View {
        Button {
            FlyHaptic.medium()
            withAnimation(FlySpring.bouncy) {
                showChat = true
            }
        } label: {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FlyColor.electricBlue.opacity(0.28), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 44
                        )
                    )
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: pulse)

                // Inner glow
                Circle()
                    .fill(FlyColor.brandGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: FlyColor.electricBlue.opacity(glow ? 0.7 : 0.35), radius: glow ? 24 : 14, y: 4)

                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(glow ? 1.12 : 0.92)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            pulse = true
            glow = true
        }
        .sheet(isPresented: $showChat) {
            AIChatView(document: document)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(FlyRadius.xl)
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThickMaterial)
        }
    }
}

// MARK: - AI Chat View

struct AIChatView: View {
    let document: FlyDocument?
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @FocusState private var inputFocused: Bool
    @State private var appeared = false

    private let suggestions: [String] = [
        "Summarize this",
        "Key highlights",
        "Any red flags?",
        "Key dates",
        "Explain in simple terms",
        "Export to Excel"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            chatHeader

            Divider().opacity(0.4)

            // MARK: Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Welcome card
                        if messages.isEmpty {
                            AIWelcomeCard(document: document)
                                .padding(.top, FlySpacing.lg)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ForEach(messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // Streaming bubble
                        if isStreaming {
                            if streamingText.isEmpty {
                                TypingIndicator()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, FlySpacing.lg)
                                    .id("typing")
                            } else {
                                ChatBubble(message: ChatMessage(role: .assistant, text: streamingText))
                                    .id("streaming")
                            }
                        }

                        Color.clear.frame(height: 8).id("bottom")
                    }
                    .padding(.horizontal, FlySpacing.lg)
                    .padding(.vertical, FlySpacing.sm)
                    .animation(FlySpring.standard, value: messages.count)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(FlySpring.snappy) {
                        proxy.scrollTo("bottom")
                    }
                }
                .onChange(of: isStreaming) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            Divider().opacity(0.4)

            // MARK: Suggestions
            if messages.isEmpty {
                SuggestionsRow(suggestions: suggestions) { s in
                    send(s)
                }
                .padding(.vertical, FlySpacing.sm)
            }

            // MARK: Input
            chatInput
                .padding(.horizontal, FlySpacing.md)
                .padding(.vertical, FlySpacing.sm)
                .padding(.bottom, FlySpacing.sm)
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Orb
            ZStack {
                Circle()
                    .fill(FlyColor.brandGradient)
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .flyShadowBlue()

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(FlyFont.body(16))
                    .fontWeight(.semibold)
                    .foregroundStyle(FlyColor.label)

                if let doc = document {
                    Text(doc.name)
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.secondaryLabel)
                        .lineLimit(1)
                } else {
                    Text("Powered by Claude")
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.secondaryLabel)
                }
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(FlyColor.tertiaryLabel)
            }
            .buttonStyle(.flyPress)
        }
        .padding(.horizontal, FlySpacing.lg)
        .padding(.vertical, FlySpacing.md)
    }

    // MARK: - Input Bar

    private var chatInput: some View {
        HStack(spacing: 10) {
            // Mic
            Button {
                FlyHaptic.light()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(FlyColor.silver)
                    .frame(width: 40, height: 40)
                    .flyGlass(cornerRadius: FlyRadius.md)
            }
            .buttonStyle(.flyPress)

            // Text field
            HStack {
                TextField("Ask anything about this PDF…", text: $inputText, axis: .vertical)
                    .font(FlyFont.body())
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { if !inputText.isEmpty { send(inputText) } }
            }
            .padding(.horizontal, FlySpacing.md)
            .padding(.vertical, 10)
            .flyGlass(cornerRadius: FlyRadius.md)

            // Send
            Button {
                guard !inputText.isEmpty else { return }
                send(inputText)
            } label: {
                Circle()
                    .fill(inputText.isEmpty ? FlyColor.secondaryBg : FlyColor.brandGradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(inputText.isEmpty ? FlyColor.silver : .white)
                    }
                    .flyShadowBlue()
            }
            .buttonStyle(.flyPress)
            .disabled(inputText.isEmpty || isStreaming)
            .animation(FlySpring.snappy, value: inputText.isEmpty)
        }
    }

    // MARK: - Send Logic

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        FlyHaptic.light()
        inputText = ""

        withAnimation(FlySpring.standard) {
            messages.append(ChatMessage(role: .user, text: trimmed))
            isStreaming = true
            streamingText = ""
        }

        // Simulate streaming response
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            let response = mockResponse(for: trimmed)
            await streamResponse(response)
        }
    }

    private func streamResponse(_ text: String) async {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        for (i, word) in words.enumerated() {
            try? await Task.sleep(nanoseconds: 40_000_000)
            await MainActor.run {
                withAnimation {
                    streamingText += (i == 0 ? "" : " ") + word
                }
            }
        }
        await MainActor.run {
            withAnimation(FlySpring.standard) {
                messages.append(ChatMessage(role: .assistant, text: streamingText))
                isStreaming = false
                streamingText = ""
                FlyHaptic.success()
            }
        }
    }

    private func mockResponse(for query: String) -> String {
        let q = query.lowercased()
        switch true {
        case q.contains("summarize") || q.contains("summary"):
            return "This is a \(document?.pages ?? 12)-page document. Key points: the content covers financial performance for Q4, showing 23% YoY revenue growth to $4.2M. EBITDA improved to 18%, and SaaS revenue now represents 67% of total revenue. Notable risks include customer concentration (top 3 = 41% of ARR)."
        case q.contains("date") || q.contains("deadline"):
            return "Key dates found: Contract effective date — January 1, 2026. Payment due — Net 30 from invoice date. Renewal clause — automatically renews on December 31, 2026 unless 60-day notice given."
        case q.contains("red flag") || q.contains("risk"):
            return "⚠️ Found 2 potential concerns: (1) Automatic renewal clause on page 6 with only 60-day opt-out window. (2) Unlimited liability clause on page 4 — recommend legal review before signing."
        case q.contains("excel") || q.contains("table") || q.contains("export"):
            return "I found 3 tables in this document. I can extract them to Excel format. Would you like all tables or a specific one? Pages: 8, 14, and 19."
        default:
            return "Based on my analysis of this document, \(document.map { "'\($0.name)'" } ?? "your PDF") contains relevant information about that topic. Would you like me to go deeper on any specific section, or shall I create a summary card?"
        }
    }
}

// MARK: - AI Welcome Card

struct AIWelcomeCard: View {
    let document: FlyDocument?
    @State private var animate = false

    var body: some View {
        VStack(spacing: FlySpacing.md) {
            // Orb
            ZStack {
                Circle()
                    .fill(FlyColor.brandGradient)
                    .frame(width: 64, height: 64)
                    .scaleEffect(animate ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animate)

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .flyShadowBlue()

            VStack(spacing: 6) {
                if let doc = document {
                    Text("I've analyzed\n'\(doc.name)'")
                        .font(FlyFont.subheading(18))
                        .foregroundStyle(FlyColor.label)
                        .multilineTextAlignment(.center)

                    Text("\(doc.pages) pages · \(doc.formattedSize) · \(doc.type.rawValue)")
                        .font(FlyFont.caption())
                        .foregroundStyle(FlyColor.secondaryLabel)
                } else {
                    Text("Ask me anything")
                        .font(FlyFont.subheading(18))
                        .foregroundStyle(FlyColor.label)

                    Text("I can summarize, analyze, translate,\nand extract data from your PDFs.")
                        .font(FlyFont.caption())
                        .foregroundStyle(FlyColor.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FlySpacing.xl)
        .flyGlass(cornerRadius: FlyRadius.xl, tint: FlyColor.electricBlue)
        .flyShadowSoft()
        .onAppear { animate = true }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(FlyColor.brandGradient)
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            Text(message.text)
                .font(FlyFont.body(15))
                .foregroundStyle(message.role == .user ? .white : FlyColor.label)
                .padding(.horizontal, FlySpacing.md)
                .padding(.vertical, 10)
                .background {
                    if message.role == .user {
                        RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                            .fill(FlyColor.brandGradient)
                    } else {
                        RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                                    .strokeBorder(FlyColor.separator.opacity(0.4), lineWidth: 0.5)
                            }
                    }
                }
                .flyShadowSoft()

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(FlyColor.silver)
                    .frame(width: 7, height: 7)
                    .scaleEffect(animate ? 1.25 : 0.75)
                    .opacity(animate ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.14),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous))
        .onAppear { animate = true }
    }
}

// MARK: - Suggestions Row

struct SuggestionsRow: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button(s) {
                        onSelect(s)
                        FlyHaptic.light()
                    }
                    .font(FlyFont.caption(13))
                    .foregroundStyle(FlyColor.electricBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(FlyColor.electricBlue.opacity(0.1), in: Capsule())
                    .overlay(Capsule().strokeBorder(FlyColor.electricBlue.opacity(0.2), lineWidth: 1))
                    .buttonStyle(.flyPress(scale: 0.95))
                }
            }
            .padding(.horizontal, FlySpacing.lg)
        }
    }
}
