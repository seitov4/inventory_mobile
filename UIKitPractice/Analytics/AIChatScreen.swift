import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers

struct AIChatMessage: Identifiable, Equatable {
    let id: UUID = UUID()
    let text: String
    let isUser: Bool
    let createdAt: Date = .now
}

struct AIChatAttachment: Identifiable, Equatable {
    enum Kind {
        case photo
        case file
    }

    let id: UUID = UUID()
    let name: String
    let kind: Kind
}

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIChatMessage] = [
        AIChatMessage(
            text: "Привет! Я AI-помощник InventiX. Могу подсказать идеи для роста выручки, анализ категорий и прогноз спроса.",
            isUser: false
        )
    ]
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var pendingAttachments: [AIChatAttachment] = []

    private let service: AIChatServiceProtocol
    private var turns: [AIChatTurn] = [
        .init(role: "assistant", content: "Привет! Я AI-помощник InventiX. Могу подсказать идеи для роста выручки, анализ категорий и прогноз спроса.")
    ]

    init(service: AIChatServiceProtocol = MockAIChatService()) {
        self.service = service
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!text.isEmpty || !pendingAttachments.isEmpty), !isTyping else { return }

        let attachmentSuffix = pendingAttachments.isEmpty
            ? ""
            : "\n\nВложения: \(pendingAttachments.map(\.name).joined(separator: ", "))"
        let userTextForChat = text.isEmpty ? "Отправлены вложения." : text
        let presentedText = userTextForChat + attachmentSuffix

        messages.append(AIChatMessage(text: presentedText, isUser: true))
        turns.append(.init(role: "user", content: presentedText))
        inputText = ""
        pendingAttachments.removeAll()
        isTyping = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let reply = try await self.service.generateReply(history: self.turns, userInput: text)
                self.turns.append(.init(role: "assistant", content: reply))
                self.messages.append(AIChatMessage(text: reply, isUser: false))
                self.isTyping = false
            } catch {
                self.messages.append(AIChatMessage(text: "Не удалось получить ответ AI. Попробуйте снова.", isUser: false))
                self.isTyping = false
            }
        }
    }

    func addPhotoAttachment(name: String) {
        pendingAttachments.append(.init(name: name, kind: .photo))
    }

    func addFileAttachment(name: String) {
        pendingAttachments.append(.init(name: name, kind: .file))
    }

    func removeAttachment(_ attachment: AIChatAttachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }
}

struct AIChatScreen: View {
    @StateObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.001)
            messagesList
            inputBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Помощник")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, maxSelectionCount: 5, matching: .images)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item, .pdf, .plainText, .json, .image],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                viewModel.addFileAttachment(name: url.lastPathComponent)
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            for (index, item) in items.enumerated() {
                let extensionHint = item.supportedContentTypes.first?.preferredFilenameExtension?.uppercased() ?? "IMG"
                viewModel.addPhotoAttachment(name: "Фото \(index + 1).\(extensionHint)")
            }
            selectedPhotos.removeAll()
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        AIChatBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isTyping {
                        AITypingBubble()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isTyping) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if !viewModel.pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.pendingAttachments) { attachment in
                            HStack(spacing: 6) {
                                Image(systemName: attachment.kind == .photo ? "photo" : "doc")
                                Text(attachment.name)
                                    .lineLimit(1)
                                Button {
                                    viewModel.removeAttachment(attachment)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            HStack(spacing: 10) {
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Фото", systemImage: "photo")
                    }

                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Файл", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }

                TextField("Напишите запрос по аналитике...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                Button {
                    viewModel.send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AnalyticsAIPalette.primaryGradient))
                }
                .disabled((viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.pendingAttachments.isEmpty) || viewModel.isTyping)
                .opacity((viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.pendingAttachments.isEmpty) ? 0.6 : 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let last = viewModel.messages.last else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                if viewModel.isTyping {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        } else {
            if viewModel.isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

private struct AIChatBubble: View {
    let message: AIChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 44) }
            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isUser ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(message.isUser ? AnyShapeStyle(AnalyticsAIPalette.primaryGradient) : AnyShapeStyle(Color(.secondarySystemBackground)))
                )
            if !message.isUser { Spacer(minLength: 44) }
        }
    }
}

private struct AITypingBubble: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.25))
                    .offset(x: -60 + phase * 120)
                    .mask(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            )
            Spacer(minLength: 44)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

