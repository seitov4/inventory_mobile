import SwiftUI

@MainActor
struct AIChatView: View {
    @StateObject private var viewModel: AIChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var hasAppeared = false
    @State private var isHistoryPresented = false

    init() {
        _viewModel = StateObject(wrappedValue: AIChatViewModel())
    }

    init(viewModel: AIChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            suggestions
            inputBar
        }
        .background(Color(.systemBackground))
        .navigationTitle(L10n.tr("analytics.ai.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    isInputFocused = false
                    isHistoryPresented = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel(L10n.tr("analytics.ai.history"))

                Button {
                    isInputFocused = false
                    viewModel.createNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel(L10n.tr("analytics.ai.new_chat"))
            }
        }
        .sheet(isPresented: $isHistoryPresented) {
            AIChatHistoryView(viewModel: viewModel, isPresented: $isHistoryPresented)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                hasAppeared = true
            }
        }
        .appLocalized()
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        AIChatBubble(message: message)
                            .id(message.id)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity
                                        .combined(with: .scale(scale: 0.96))
                                        .combined(with: .offset(y: 8)),
                                    removal: .opacity
                                )
                            )
                    }

                    if viewModel.isLoading {
                        AILoadingBubble()
                            .id("ai-loading")
                            .transition(
                                .opacity
                                    .combined(with: .scale(scale: 0.96, anchor: .leading))
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 8)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isLoading) { _, _ in
                scrollToBottom(proxy)
            }
            .animation(.smooth(duration: 0.32), value: viewModel.messages)
            .animation(.smooth(duration: 0.28), value: viewModel.isLoading)
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(viewModel.suggestedQuestions.enumerated()), id: \.element) { index, question in
                    Button {
                        isInputFocused = false
                        viewModel.sendSuggestedQuestion(question)
                    } label: {
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: suggestionIcons[index])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(aiTint)
                                .frame(width: 18)

                            Text(question)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: 190, alignment: .leading)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(AIQuestionButtonStyle())
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    L10n.tr("analytics.ai.placeholder"),
                    text: $viewModel.inputText,
                    axis: .vertical
                )
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.sendCurrentMessage()
                }
                .onChange(of: viewModel.inputText) { _, _ in
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            isInputFocused ? aiTint.opacity(0.35) : Color.clear,
                            lineWidth: 1
                        )
                )
                .animation(.easeOut(duration: 0.2), value: isInputFocused)

                Button {
                    isInputFocused = false
                    viewModel.sendCurrentMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AnalyticsAIPalette.primaryGradient))
                        .shadow(color: aiTint.opacity(0.22), radius: 8, y: 4)
                }
                .buttonStyle(AISendButtonStyle())
                .disabled(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.isLoading
                )
                .opacity(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.isLoading ? 0.5 : 1
                )
                .accessibilityLabel(L10n.tr("analytics.ai.send"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Divider().opacity(0.45)
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private var aiTint: Color {
        Color(red: 110 / 255, green: 71 / 255, blue: 232 / 255)
    }

    private var suggestionIcons: [String] {
        [
            "chart.line.uptrend.xyaxis",
            "cube.box",
            "cart",
            "star",
            "square.grid.2x2"
        ]
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.32)) {
            if viewModel.isLoading {
                proxy.scrollTo("ai-loading", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

private struct AIChatHistoryView: View {
    @ObservedObject var viewModel: AIChatViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    Button {
                        viewModel.selectConversation(conversation.id)
                        isPresented = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(aiTint)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(aiTint.opacity(0.10))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)

                                Text(previewText(for: conversation))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(relativeDate(conversation.updatedAt))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.secondary)

                                if viewModel.selectedConversationId == conversation.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(aiTint)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteConversation(conversation.id)
                        } label: {
                            Label(L10n.tr("analytics.ai.delete_chat"), systemImage: "trash")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.tr("analytics.ai.history"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.tr("analytics.ai.close")) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.createNewConversation()
                        isPresented = false
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel(L10n.tr("analytics.ai.new_chat"))
                }
            }
        }
    }

    private var aiTint: Color {
        Color(red: 110 / 255, green: 71 / 255, blue: 232 / 255)
    }

    private func previewText(for conversation: AIChatConversation) -> String {
        conversation.messages
            .last(where: { $0.role == .user })?
            .content
            .replacingOccurrences(of: "\n", with: " ")
            ?? L10n.tr("analytics.ai.empty_chat")
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct AIChatBubble: View {
    let message: AIChatMessage

    private var aiTint: Color {
        Color(red: 110 / 255, green: 71 / 255, blue: 232 / 255)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 52)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(aiTint)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(aiTint.opacity(0.10)))
            }

            Text(message.content)
                .font(.body)
                .lineSpacing(3)
                .textSelection(.enabled)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            message.role == .user
                                ? AnyShapeStyle(AnalyticsAIPalette.primaryGradient)
                                : AnyShapeStyle(Color(.secondarySystemBackground))
                        )
                )
                .shadow(
                    color: message.role == .user
                        ? aiTint.opacity(0.12)
                        : Color.black.opacity(0.025),
                    radius: 7,
                    y: 3
                )

            if message.role == .assistant {
                Spacer(minLength: 52)
            }
        }
    }
}

private struct AILoadingBubble: View {
    @State private var activeDot = 0

    private var aiTint: Color {
        Color(red: 110 / 255, green: 71 / 255, blue: 232 / 255)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(aiTint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(aiTint.opacity(0.10)))

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(activeDot == index ? 1 : 0.72)
                        .opacity(activeDot == index ? 0.9 : 0.35)
                        .animation(.easeInOut(duration: 0.28), value: activeDot)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            Spacer(minLength: 52)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(320))
                activeDot = (activeDot + 1) % 3
            }
        }
    }
}

private struct AIQuestionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct AISendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(
                .spring(response: 0.24, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}
