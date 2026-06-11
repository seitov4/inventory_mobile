import Foundation

struct AIChatRequest: Encodable {
    let message: String
    let conversationId: String?

    enum CodingKeys: String, CodingKey {
        case message
        case conversationId = "conversation_id"
    }
}

struct AIChatResponse: Decodable {
    let success: Bool
    let data: AIChatData?
    let message: String?
}

struct AIChatData: Decodable {
    let answer: String
    let conversationId: String?
    let usedTools: [String]?

    enum CodingKeys: String, CodingKey {
        case answer
        case conversationId = "conversation_id"
        case usedTools = "used_tools"
    }
}

struct AIChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: AIChatRole
    let content: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: AIChatRole,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

enum AIChatRole: Equatable {
    case user
    case assistant
}
