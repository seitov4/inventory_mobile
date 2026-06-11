import Combine
import Foundation

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published private(set) var conversations: [AIChatConversation] = []
    @Published private(set) var selectedConversationId: UUID?
    @Published var messages: [AIChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var conversationId: String?

    let suggestedQuestions: [String]

    private let service: AIChatServiceProtocol
    private let historyStore: AIChatHistoryStoring
    private let userIdentifier: String

    convenience init() {
        self.init(service: AIChatService())
    }

    init(
        service: AIChatServiceProtocol,
        historyStore: AIChatHistoryStoring? = nil,
        userIdentifier: String? = nil
    ) {
        self.service = service
        self.historyStore = historyStore ?? AIChatHistoryStore.shared
        self.userIdentifier = userIdentifier ?? UserSessionManager.shared.currentUserIdentifier
        suggestedQuestions = [
            L10n.tr("analytics.ai.suggestion.sales_today"),
            L10n.tr("analytics.ai.suggestion.low_stock"),
            L10n.tr("analytics.ai.suggestion.restock"),
            L10n.tr("analytics.ai.suggestion.top_products"),
            L10n.tr("analytics.ai.suggestion.sales_category")
        ]

        loadHistory()
    }

    var selectedConversationTitle: String {
        selectedConversation?.title ?? L10n.tr("analytics.ai.new_chat")
    }

    func sendCurrentMessage() {
        send(inputText)
    }

    func sendSuggestedQuestion(_ question: String) {
        send(question)
    }

    func createNewConversation() {
        guard !isLoading else { return }

        if let emptyConversation = conversations.first(where: { conversation in
            !conversation.messages.contains(where: { $0.role == .user })
        }) {
            selectConversation(emptyConversation.id)
            return
        }

        let conversation = makeEmptyConversation()
        conversations.insert(conversation, at: 0)
        selectConversation(conversation.id)
        persistHistory()
    }

    func selectConversation(_ id: UUID) {
        guard let conversation = conversations.first(where: { $0.id == id }) else { return }

        selectedConversationId = id
        messages = conversation.messages
        conversationId = conversation.backendConversationId
        inputText = ""
        errorMessage = nil
    }

    func deleteConversation(_ id: UUID) {
        guard !isLoading else { return }

        conversations.removeAll { $0.id == id }

        if conversations.isEmpty {
            let conversation = makeEmptyConversation()
            conversations = [conversation]
        }

        if selectedConversationId == id {
            selectConversation(conversations[0].id)
        }

        persistHistory()
    }

    private var selectedConversation: AIChatConversation? {
        guard let selectedConversationId else { return nil }
        return conversations.first(where: { $0.id == selectedConversationId })
    }

    private func loadHistory() {
        var loadErrorMessage: String?

        do {
            conversations = try historyStore
                .loadConversations(for: userIdentifier)
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            conversations = []
            loadErrorMessage = L10n.tr("analytics.ai.history_load_error")
        }

        if conversations.isEmpty {
            conversations = [makeEmptyConversation()]
        }

        selectConversation(conversations[0].id)
        errorMessage = loadErrorMessage
    }

    private func makeEmptyConversation() -> AIChatConversation {
        AIChatConversation(
            title: L10n.tr("analytics.ai.new_chat"),
            messages: [
                AIChatMessage(
                    role: .assistant,
                    content: L10n.tr("analytics.ai.greeting")
                )
            ]
        )
    }

    private func send(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        guard text.count <= 1_000 else {
            errorMessage = L10n.tr("analytics.ai.error.too_long")
            return
        }

        guard let activeConversationId = selectedConversationId else { return }

        updateTitleIfNeeded(with: text, for: activeConversationId)
        append(AIChatMessage(role: .user, content: text), to: activeConversationId)
        inputText = ""
        errorMessage = nil
        isLoading = true
        persistHistory()

        let backendConversationId = conversation(with: activeConversationId)?.backendConversationId

        AppAnalytics.shared.track(.aiChatMessageSent, properties: [
            "text_length": .int(text.count),
            "has_conversation_id": .bool(backendConversationId != nil)
        ])

        Task { [weak self] in
            guard let self else { return }

            do {
                let data = try await service.sendMessage(text, conversationId: backendConversationId)
                updateBackendConversationId(data.conversationId, for: activeConversationId)
                append(AIChatMessage(role: .assistant, content: data.answer), to: activeConversationId)
                isLoading = false
                persistHistory()

                AppAnalytics.shared.track(.aiChatReplyReceived, properties: [
                    "reply_length": .int(data.answer.count)
                ])
            } catch {
                let safeMessage = safeMessage(for: error)
                errorMessage = safeMessage
                append(AIChatMessage(role: .assistant, content: safeMessage), to: activeConversationId)
                isLoading = false
                persistHistory()

                AppAnalytics.shared.track(.aiChatReplyFailed, properties: [
                    "error_type": .string(String(describing: type(of: error)))
                ])
            }
        }
    }

    private func conversation(with id: UUID) -> AIChatConversation? {
        conversations.first(where: { $0.id == id })
    }

    private func append(_ message: AIChatMessage, to conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        conversations[index].messages.append(message)
        conversations[index].updatedAt = Date()
        refreshSelectedConversationIfNeeded(conversationId)
    }

    private func updateTitleIfNeeded(with text: String, for conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }),
              !conversations[index].messages.contains(where: { $0.role == .user }) else { return }

        let singleLine = text.replacingOccurrences(of: "\n", with: " ")
        conversations[index].title = String(singleLine.prefix(42))
    }

    private func updateBackendConversationId(_ id: String?, for conversationId: UUID) {
        guard let id,
              let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        conversations[index].backendConversationId = id
        conversations[index].updatedAt = Date()
        refreshSelectedConversationIfNeeded(conversationId)
    }

    private func refreshSelectedConversationIfNeeded(_ id: UUID) {
        guard selectedConversationId == id,
              let conversation = conversation(with: id) else { return }

        messages = conversation.messages
        self.conversationId = conversation.backendConversationId
    }

    private func persistHistory() {
        conversations.sort { $0.updatedAt > $1.updatedAt }

        do {
            try historyStore.saveConversations(conversations, for: userIdentifier)
        } catch {
            errorMessage = L10n.tr("analytics.ai.history_save_error")
        }
    }

    private func safeMessage(for error: Error) -> String {
        guard let serviceError = error as? AIChatServiceError else {
            return L10n.tr("analytics.ai.error.unavailable")
        }

        switch serviceError {
        case .invalidMessage:
            return L10n.tr("analytics.ai.error.invalid_message")
        case .unauthorized:
            return L10n.tr("analytics.ai.error.session_expired")
        case .forbidden:
            return L10n.tr("analytics.ai.error.forbidden")
        case .rateLimited:
            return L10n.tr("analytics.ai.error.rate_limited")
        case .unavailable:
            return L10n.tr("analytics.ai.error.unavailable")
        }
    }
}
