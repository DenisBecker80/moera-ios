import SwiftUI

/// Профиль и стена. nodeName == nil — своя нода.
struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    let nodeName: String?
    @State private var profile: Profile?
    @State private var stories: [Story] = []
    @State private var error: String?
    @State private var loading = false

    private var displayName: String {
        if let name = profile?.fullName, !name.isEmpty { return name }
        return session.nodeName ?? "Профиль"
    }

    var body: some View {
        List {
            header
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

            if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error).foregroundStyle(.red)
                    Button("Повторить") { Task { await load() } }
                }
            }

            Section {
                if loading && stories.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if stories.isEmpty && error == nil {
                    Text("Пока нет постов").foregroundStyle(.secondary)
                }
                ForEach(stories) { story in
                    if let posting = story.posting {
                        PostCardView(posting: posting).listRowInsets(EdgeInsets())
                    }
                }
            } header: {
                Text("Посты")
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Выйти") { session.signOut() }
        }
        .refreshable { await load() }
        .task(id: session.token) { await load() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.4)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 140)
            avatar
                .frame(width: 104, height: 104)
                .background(Circle().fill(Color(.systemBackground)))
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 4))
                .padding(.top, -52)
            Text(displayName).font(.title.bold())
            if let name = session.nodeName, profile?.fullName?.isEmpty == false {
                Text("@\(name)").foregroundStyle(.secondary)
            }
            if let title = profile?.title, !title.isEmpty {
                Text(title).font(.subheadline)
            }
            if let bio = profile?.bioHtml, !bio.isEmpty {
                HTMLText(html: bio).font(.subheadline).padding(.horizontal)
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var avatar: some View {
        if let node = session.nodeURL, let url = profile?.avatar?.url(node: node) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                AvatarView(name: displayName, size: 96)
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
        } else {
            AvatarView(name: displayName, size: 96)
        }
    }

    private func load() async {
        guard let api = session.api, !loading else { return }
        loading = true
        defer { loading = false }
        var problems: [String] = []
        do {
            profile = try await api.profile()
        } catch let e where e.isCancellation {
            return
        } catch {
            problems.append("Профиль: \(error.localizedDescription)")
        }
        do {
            stories = try await api.stories(feed: "timeline", before: Int64.max).stories
        } catch let e where e.isCancellation {
            return
        } catch {
            problems.append("Посты: \(error.localizedDescription)")
        }
        error = problems.isEmpty ? nil : problems.joined(separator: "\n")
    }
}
