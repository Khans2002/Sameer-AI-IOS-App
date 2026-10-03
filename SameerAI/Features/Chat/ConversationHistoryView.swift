import SwiftUI

struct ConversationHistoryView: View {
    @EnvironmentObject private var history: ConversationHistoryStore
    @StateObject private var selection = ConversationSelection()
    let searchQuery: String
    let onOpen: (ConversationSummary) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Group {
                    if filteredConversations.isEmpty {
                        ContentUnavailableView("No conversations", systemImage: "bubble.left.and.bubble.right", description: Text("Start a new private conversation when a model is installed."))
                            .padding(.top, 90)
                    } else if history.layout == .list || history.layout == .select {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredConversations) { conversation in
                                conversationCard(conversation, listStyle: true)
                            }
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredConversations) { conversation in
                                conversationCard(conversation, listStyle: false)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .animation(.snappy, value: history.layout)
                .animation(.snappy, value: history.conversations)
            }

            if history.layout == .select {
                selectionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func conversationCard(_ conversation: ConversationSummary, listStyle: Bool) -> some View {
        Button {
            if history.layout == .select { selection.toggle(conversation.id) } else { onOpen(conversation) }
        } label: {
            ConversationCard(
                conversation: conversation,
                isSelected: selection.selectedIDs.contains(conversation.id),
                listStyle: listStyle,
                isSelectionMode: history.layout == .select
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(history.layout == .select ? "Selects this conversation" : "Opens this conversation")
    }

    private var filteredConversations: [ConversationSummary] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return history.conversations }
        return history.conversations.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.preview.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Text("\(selection.selectedIDs.count) selected")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Archive") {
                history.archive(ids: selection.selectedIDs)
                selection.clear()
            }
            .disabled(selection.selectedIDs.isEmpty)
            Button(role: .destructive) {
                history.delete(ids: selection.selectedIDs)
                selection.clear()
            } label: { Image(systemName: "trash") }
            .disabled(selection.selectedIDs.isEmpty)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(SameerTheme.elevated)
    }
}

private struct ConversationCard: View {
    let conversation: ConversationSummary
    let isSelected: Bool
    let listStyle: Bool
    let isSelectionMode: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if listStyle, let symbol = conversation.thumbnailSymbol {
                thumbnail(symbol)
                    .frame(width: 54, height: 54)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(SameerTheme.secondary)
                    Spacer()
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? SameerTheme.gold : SameerTheme.secondary)
                    }
                }

                if !listStyle, let symbol = conversation.thumbnailSymbol {
                    thumbnail(symbol)
                        .frame(height: 66)
                }

                Text(conversation.title)
                    .font(.headline)
                    .foregroundStyle(SameerTheme.white)
                    .lineLimit(listStyle ? 1 : 2)
                Text(conversation.preview)
                    .font(.caption)
                    .foregroundStyle(SameerTheme.secondary)
                    .lineLimit(listStyle ? 2 : 4)
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: listStyle ? 92 : conversation.cardHeight, alignment: .topLeading)
        .background(isSelected ? SameerTheme.gold.opacity(0.16) : SameerTheme.elevated.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? SameerTheme.gold.opacity(0.9) : .white.opacity(0.07), lineWidth: isSelected ? 1.5 : 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
    }

    private func thumbnail(_ symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [SameerTheme.blue.opacity(0.5), SameerTheme.gold.opacity(0.46), SameerTheme.graphite], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(SameerTheme.white)
        }
    }
}
