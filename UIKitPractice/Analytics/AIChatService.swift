import Foundation

struct AIChatTurn: Codable {
    let role: String
    let content: String
}

protocol AIChatServiceProtocol {
    func generateReply(history: [AIChatTurn], userInput: String) async throws -> String
}

final class MockAIChatService: AIChatServiceProtocol {
    func generateReply(history: [AIChatTurn], userInput: String) async throws -> String {
        try await Task.sleep(nanoseconds: 900_000_000)

        let lower = userInput.lowercased()
        if lower.contains("продаж") || lower.contains("выручк") {
            return L10n.tr("analytics.ai.reply.sales")
        }
        if lower.contains("спрос") || lower.contains("прогноз") {
            return L10n.tr("analytics.ai.reply.demand")
        }
        if lower.contains("сотрудник") || lower.contains("касс") {
            return L10n.tr("analytics.ai.reply.staff")
        }
        return L10n.tr("analytics.ai.reply.default")
    }
}

final class RemoteAIChatService: AIChatServiceProtocol {
    func generateReply(history: [AIChatTurn], userInput: String) async throws -> String {
        // TODO: Connect AI API
        // Example approach:
        // 1) Prepare body with conversation history + userInput.
        // 2) Send request to backend AI endpoint (e.g. POST /ai/chat).
        // 3) Decode and return assistant reply text.
        throw NSError(
            domain: "RemoteAIChatService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "AI API is not connected yet."]
        )
    }
}
