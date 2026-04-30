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
            return "За последние 7 дней просадка обычно связана с 1-2 категориями. Рекомендую проверить маржинальность «Напитки», запустить акцию 2+1 на slow-moving SKU и повторно оценить конверсию через 3 дня."
        }
        if lower.contains("спрос") || lower.contains("прогноз") {
            return "По текущему тренду спроса стоит увеличить закуп по топ-20 SKU на 12-15% перед выходными. Для снижения out-of-stock приоритет: напитки, снеки, молочная группа."
        }
        if lower.contains("сотрудник") || lower.contains("касс") {
            return "Попробуйте сравнить продажи по сменам и средний чек по кассирам. Часто рост дает скрипт апсейла и контроль очередей в часы пик."
        }
        return "Могу помочь с идеями по выручке, ассортименту, сезонности, акциям и прогнозу спроса. Напишите, какой показатель хотите улучшить."
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

