import Foundation

enum ConversationLayout: String, CaseIterable {
    case grid
    case list
    case select
}

struct ConversationSummary: Identifiable, Hashable, Codable {
    let id: UUID
    let updatedAt: Date
    let title: String
    let preview: String
    let thumbnailSymbol: String?
    let cardHeight: CGFloat
}

@MainActor
final class ConversationHistoryStore: ObservableObject {
    @Published private(set) var conversations: [ConversationSummary]
    @Published var layout: ConversationLayout {
        didSet { UserDefaults.standard.set(layout.rawValue, forKey: Self.layoutKey) }
    }

    private static let layoutKey = "conversationHistoryLayout"
    private let persistenceURL: URL
    private var archivedConversations: [ConversationSummary]

    init(defaults: UserDefaults = .standard) {
        AppDirectories.prepare()
        layout = ConversationLayout(rawValue: defaults.string(forKey: Self.layoutKey) ?? "") ?? .grid
        persistenceURL = AppDirectories.privateSupport.appendingPathComponent("conversation-history.json")
        if let saved = Self.load(from: persistenceURL) {
            conversations = saved.active
            archivedConversations = saved.archived
            return
        }

        let now = Date()
        conversations = [
            ConversationSummary(id: UUID(), updatedAt: now.addingTimeInterval(-40 * 60), title: "Build a focused study plan", preview: "Let’s make a realistic plan for the week and keep the sessions short enough to stay consistent.", thumbnailSymbol: "book.closed.fill", cardHeight: 228),
            ConversationSummary(id: UUID(), updatedAt: now.addingTimeInterval(-3 * 60 * 60), title: "Ideas for Sameer AI", preview: "A private assistant should feel calm, personal, and completely in your control.", thumbnailSymbol: nil, cardHeight: 174),
            ConversationSummary(id: UUID(), updatedAt: now.addingTimeInterval(-26 * 60 * 60), title: "Summarise meeting notes", preview: "Here are the decisions, open questions, and the next three actions from this discussion.", thumbnailSymbol: "doc.text.fill", cardHeight: 205),
            ConversationSummary(id: UUID(), updatedAt: now.addingTimeInterval(-2 * 24 * 60 * 60), title: "Weekend trip ideas", preview: "A quiet two-day plan with good food, a scenic walk, and no rushed schedule.", thumbnailSymbol: "mountain.2.fill", cardHeight: 232),
            ConversationSummary(id: UUID(), updatedAt: now.addingTimeInterval(-4 * 24 * 60 * 60), title: "Explain this topic simply", preview: "A clear explanation with examples and no unnecessary jargon.", thumbnailSymbol: nil, cardHeight: 165)
        ]
        archivedConversations = []
        persist()
    }

    func delete(ids: Set<UUID>) {
        conversations.removeAll { ids.contains($0.id) }
        archivedConversations.removeAll { ids.contains($0.id) }
        persist()
    }

    func archive(ids: Set<UUID>) {
        let selected = conversations.filter { ids.contains($0.id) }
        archivedConversations.append(contentsOf: selected)
        conversations.removeAll { ids.contains($0.id) }
        persist()
    }

    func addConversation(from prompt: String, attachmentCount: Int) {
        let title = String(prompt.prefix(52))
        let attachmentDetail = attachmentCount == 0 ? "" : " \(attachmentCount) attachment\(attachmentCount == 1 ? "" : "s") added."
        let summary = ConversationSummary(
            id: UUID(),
            updatedAt: .now,
            title: title,
            preview: "Your private message is saved locally. On-device model replies will appear here soon.\(attachmentDetail)",
            thumbnailSymbol: attachmentCount > 0 ? "paperclip" : nil,
            cardHeight: attachmentCount > 0 ? 218 : 176
        )
        conversations.insert(summary, at: 0)
        persist()
    }

    private struct SavedHistory: Codable {
        let active: [ConversationSummary]
        let archived: [ConversationSummary]
    }

    private static func load(from url: URL) -> SavedHistory? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedHistory.self, from: data)
    }

    private func persist() {
        let snapshot = SavedHistory(active: conversations, archived: archivedConversations)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: persistenceURL, options: .atomic)
    }
}

@MainActor
final class ConversationSelection: ObservableObject {
    @Published var selectedIDs: Set<UUID> = []

    func toggle(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    func clear() { selectedIDs.removeAll() }
}
