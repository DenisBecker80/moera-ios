import SwiftUI

struct PostDetailView: View {
    @Environment(SessionStore.self) private var session
    let posting: Posting
    @State private var comments: [Comment] = []
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            List {
                PostCardView(posting: posting).listRowInsets(EdgeInsets())
                ForEach(comments) { comment in
                    HStack(alignment: .top) {
                        AvatarView(name: comment.authorDisplayName, size: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.authorDisplayName).font(.subheadline.bold())
                            if let text = comment.body.text { HTMLText(html: text) }
                            if let media = comment.media { MediaGridView(attachments: media) }
                            if comment.premoderating == true {
                                Text("На модерации").font(.caption2).foregroundStyle(.orange)
                            }
                            Text(comment.date, style: .relative).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            HStack {
                TextField("Написать комментарий…", text: $draft).textFieldStyle(.roundedBorder)
                Button("Отпр.") { Task { await send() } }.disabled(draft.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Пост")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard let api = session.api else { return }
        comments = (try? await api.comments(postingId: posting.id, before: Int64.max, limit: 50))?
            .comments.sorted { $0.moment < $1.moment } ?? []
    }

    private func send() async {
        guard let api = session.api else { return }
        if (try? await api.createComment(postingId: posting.id, text: draft)) != nil {
            draft = ""
            await load()
        }
    }
}
