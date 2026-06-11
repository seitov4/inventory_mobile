import Foundation

protocol AIChatServiceProtocol {
    func sendMessage(_ message: String, conversationId: String?) async throws -> AIChatData
}

enum AIChatServiceError: Error {
    case invalidMessage
    case unauthorized
    case forbidden
    case rateLimited
    case unavailable
}

final class AIChatService: AIChatServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func sendMessage(_ message: String, conversationId: String?) async throws -> AIChatData {
        let request = AIChatRequest(message: message, conversationId: conversationId)

        do {
            let response: AIChatResponse = try await apiClient.request(
                endpoint: "ai/chat",
                method: "POST",
                body: request
            )

            guard response.success, let data = response.data else {
                throw AIChatServiceError.unavailable
            }

            return data
        } catch let error as AIChatServiceError {
            throw error
        } catch let error as AppError {
            switch error {
            case .unauthorized:
                throw AIChatServiceError.unauthorized
            case .forbidden:
                throw AIChatServiceError.forbidden
            case .server(let statusCode, _):
                switch statusCode {
                case 400:
                    throw AIChatServiceError.invalidMessage
                case 401:
                    throw AIChatServiceError.unauthorized
                case 403:
                    throw AIChatServiceError.forbidden
                case 429:
                    throw AIChatServiceError.rateLimited
                default:
                    throw AIChatServiceError.unavailable
                }
            default:
                throw AIChatServiceError.unavailable
            }
        } catch {
            throw AIChatServiceError.unavailable
        }
    }
}
