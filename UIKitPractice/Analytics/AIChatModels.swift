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

struct AIChatMessage: Identifiable, Equatable, Codable {
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

enum AIChatRole: String, Equatable, Codable {
    case user
    case assistant
}

struct AIChatConversation: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var messages: [AIChatMessage]
    var backendConversationId: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        messages: [AIChatMessage],
        backendConversationId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.backendConversationId = backendConversationId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
