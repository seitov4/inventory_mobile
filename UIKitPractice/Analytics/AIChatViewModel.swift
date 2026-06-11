import Combine
import Foundation

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIChatMessage]
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var conversationId: String?

    let suggestedQuestions: [String]

    private let service: AIChatServiceProtocol

    convenience init() {
        self.init(service: AIChatService())
    }

    init(service: AIChatServiceProtocol) {
        self.service = service
        messages = [
            AIChatMessage(
                role: .assistant,
                content: L10n.tr("analytics.ai.greeting")
            )
        ]
        suggestedQuestions = [
            L10n.tr("analytics.ai.suggestion.sales_today"),
            L10n.tr("analytics.ai.suggestion.low_stock"),
            L10n.tr("analytics.ai.suggestion.restock"),
            L10n.tr("analytics.ai.suggestion.top_products"),
            L10n.tr("analytics.ai.suggestion.sales_category")
        ]
    }

    func sendCurrentMessage() {
        send(inputText)
    }

    func sendSuggestedQuestion(_ question: String) {
        send(question)
    }

    private func send(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        guard text.count <= 1_000 else {
            errorMessage = L10n.tr("analytics.ai.error.too_long")
            return
        }

        messages.append(AIChatMessage(role: .user, content: text))
        inputText = ""
        errorMessage = nil
        isLoading = true

        AppAnalytics.shared.track(.aiChatMessageSent, properties: [
            "text_length": .int(text.count),
            "has_conversation_id": .bool(conversationId != nil)
        ])

        Task { [weak self] in
            guard let self else { return }

            do {
                let data = try await service.sendMessage(text, conversationId: conversationId)
                conversationId = data.conversationId ?? conversationId
                messages.append(AIChatMessage(role: .assistant, content: data.answer))
                isLoading = false

                AppAnalytics.shared.track(.aiChatReplyReceived, properties: [
                    "reply_length": .int(data.answer.count)
                ])
            } catch {
                let safeMessage = safeMessage(for: error)
                errorMessage = safeMessage
                messages.append(AIChatMessage(role: .assistant, content: safeMessage))
                isLoading = false

                AppAnalytics.shared.track(.aiChatReplyFailed, properties: [
                    "error_type": .string(String(describing: type(of: error)))
                ])
            }
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
