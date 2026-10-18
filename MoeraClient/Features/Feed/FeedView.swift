import SwiftUI

struct FeedView: View {
    @Environment(SessionStore.self) private var session
    @State private var stories: [Story] = []
    @State private var before: Int64?
    @State private var error: String?
    @State private var composing = false

    var body: some View {
        List {
            Button { composing = true } label: {
                HStack {
                    AvatarView(name: "Я", size: 36)
                    Text("Что у вас нового?").foregroundStyle(.secondary)
                    Spacer()
                }
            }
            ForEach(stories) { story in
                if let posting = story.posting {
                    PostCardView(posting: posting)
                        .listRowInsets(EdgeInsets())
                        .onAppear { if story == stories.last { Task { await loadMore() } } }
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .listStyle(.plain)
        .navigationTitle("Лента")
        .refreshable { await reload() }
        .task { if stories.isEmpty { await reload() } }
        .sheet(isPresented: $composing) {
            ComposePostView { Task { await reload() } }
        }
    }

    private func reload() async {
        before = nil
        stories = []
        await loadMore()
    }

    private func loadMore() async {
        guard let api = session.api, before != Int64.min else { return }
        do {
            let slice = try await api.stories(feed: "news", before: before ?? Int64.max)
            stories += slice.stories
            before = slice.stories.isEmpty ? Int64.min : slice.after
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
