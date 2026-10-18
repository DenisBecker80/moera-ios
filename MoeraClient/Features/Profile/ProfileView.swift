import SwiftUI

/// Профиль и стена. nodeName == nil — своя нода.
struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    let nodeName: String?
    @State private var profile: Profile?
    @State private var stories: [Story] = []

    var body: some View {
        List {
            VStack(spacing: 8) {
                Rectangle().fill(Color.blue.opacity(0.3)).frame(height: 140)
                AvatarView(name: profile?.fullName ?? "?", size: 96).offset(y: -48).padding(.bottom, -48)
                Text(profile?.fullName ?? "").font(.title.bold())
                if let title = profile?.title { Text(title).foregroundStyle(.secondary) }
            }
            .listRowInsets(EdgeInsets())
            ForEach(stories) { story in
                if let posting = story.posting {
                    PostCardView(posting: posting).listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Профиль")
        .toolbar {
            Button("Выйти") { session.signOut() }
        }
        .task { await load() }
    }

    private func load() async {
        guard let api = session.api else { return }
        profile = try? await api.profile()
        stories = (try? await api.stories(feed: "timeline", before: Int64.max))?.stories ?? []
    }
}
