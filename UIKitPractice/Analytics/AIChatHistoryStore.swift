import Foundation

protocol AIChatHistoryStoring {
    func loadConversations(for userIdentifier: String) throws -> [AIChatConversation]
    func saveConversations(_ conversations: [AIChatConversation], for userIdentifier: String) throws
}

final class AIChatHistoryStore: AIChatHistoryStoring {
    static let shared = AIChatHistoryStore()

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadConversations(for userIdentifier: String) throws -> [AIChatConversation] {
        let fileURL = historyURL(for: userIdentifier)
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([AIChatConversation].self, from: data)
    }

    func saveConversations(_ conversations: [AIChatConversation], for userIdentifier: String) throws {
        let directoryURL = historyDirectoryURL
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try encoder.encode(conversations)
        try data.write(to: historyURL(for: userIdentifier), options: [.atomic])
    }

    private var historyDirectoryURL: URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("InventiX/AIChat", isDirectory: true)
    }

    private func historyURL(for userIdentifier: String) -> URL {
        let safeIdentifier = Data(userIdentifier.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")

        return historyDirectoryURL.appendingPathComponent("\(safeIdentifier).json")
    }
}
