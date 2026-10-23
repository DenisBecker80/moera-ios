import SwiftUI

struct FeedView: View {
    @Environment(SessionStore.self) private var session
    @State private var stories: [Story] = []
    @State private var before: Int64?
    @State private var reachedEnd = false
    @State private var loading = false
    @State private var loadedOnce = false
    @State private var error: String?
    @State private var composing = false

    var body: some View {
        List {
            Button { composing = true } label: {
                HStack {
                    AvatarView(name: session.nodeName ?? "Я", size: 36)
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
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error).foregroundStyle(.red)
                    Button("Повторить") { Task { await reload() } }
                }
            } else if loadedOnce && stories.isEmpty {
                ContentUnavailableView("Лента пуста", systemImage: "newspaper",
                                       description: Text("Здесь появятся посты тех, на кого вы подписаны."))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Лента")
        .refreshable { await reload() }
        .task(id: session.token) { await reload() }
        .sheet(isPresented: $composing) {
            ComposePostView { Task { await reload() } }
        }
    }

    private func reload() async {
        before = nil
        reachedEnd = false
        await loadMore(replacing: true)
    }

    private func loadMore(replacing: Bool = false) async {
        guard let api = session.api, !reachedEnd, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let slice = try await api.stories(feed: "news", before: before ?? Int64.max)
            stories = replacing ? slice.stories : stories + slice.stories
            before = slice.after
            reachedEnd = slice.stories.isEmpty || slice.after <= Int64.min
            error = nil
            loadedOnce = true
        } catch let e where e.isCancellation {
            // экран перерисовался — попробуем при следующем появлении
        } catch {
            self.error = error.localizedDescription
            loadedOnce = true
        }
    }
}
