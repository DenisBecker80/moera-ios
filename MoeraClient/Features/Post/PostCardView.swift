import SwiftUI

struct PostCardView: View {
    @Environment(SessionStore.self) private var session
    @State var posting: Posting
    @State private var showReactions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AvatarView(name: posting.authorDisplayName)
                VStack(alignment: .leading) {
                    Text(posting.authorDisplayName).font(.headline)
                    Text(posting.date, style: .relative).font(.caption).foregroundStyle(.secondary)
                }
            }
            if let subject = posting.body.subject { Text(subject).font(.title3.bold()) }
            if let text = posting.body.text { HTMLText(html: text) }

            HStack {
                if let count = posting.reactions?.positiveCount, count > 0 {
                    Text("👍 \(count)")
                }
                Spacer()
                if let comments = posting.totalComments, comments > 0 {
                    Text("Комментарии: \(comments)")
                }
            }
            .font(.caption).foregroundStyle(.secondary)

            Divider()
            HStack {
                Button { Task { await react(.like) } } label: {
                    Label(posting.clientReaction == nil ? "Нравится" : "Вам нравится",
                          systemImage: posting.clientReaction == nil ? "hand.thumbsup" : "hand.thumbsup.fill")
                }
                .contextMenu {
                    ForEach(Reaction.allCases, id: \.self) { r in
                        Button(r.symbol) { Task { await react(r) } }
                    }
                }
                Spacer()
                NavigationLink { PostDetailView(posting: posting) } label: {
                    Label("Комментировать", systemImage: "bubble.left")
                }
            }
            .buttonStyle(.borderless)
            .font(.subheadline)
        }
        .padding()
    }

    private func react(_ reaction: Reaction) async {
        guard let api = session.api else { return }
        _ = try? await api.react(postingId: posting.id, emoji: reaction.rawValue)
        if let updated = try? await api.posting(id: posting.id) { posting = updated }
    }
}
