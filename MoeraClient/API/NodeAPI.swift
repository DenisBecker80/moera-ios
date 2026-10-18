import Foundation

/// Клиент к Moera Node API (`/moera/api/...`).
struct NodeAPI {
    let baseURL: URL
    let token: String?

    private var decoder: JSONDecoder { JSONDecoder() }

    // MARK: Auth

    func createToken(login: String, password: String) async throws -> TokenInfo {
        try await send("POST", "tokens", body: Credentials(login: login, password: password))
    }

    // MARK: Profile

    func profile() async throws -> Profile {
        try await send("GET", "profile")
    }

    // MARK: Feeds

    /// feedName: "news" — лента подписок, "timeline" — своя стена.
    func stories(feed: String, before: Int64? = nil, limit: Int = 20) async throws -> FeedSlice {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let before { query.append(URLQueryItem(name: "before", value: String(before))) }
        return try await send("GET", "feeds/\(feed)/stories", query: query)
    }

    // MARK: Postings

    func posting(id: String) async throws -> Posting {
        try await send("GET", "postings/\(id)")
    }

    func createPosting(text: String) async throws -> Posting {
        try await send("POST", "postings", body: PostingText(bodySrc: BodySrc(text: text), bodySrcFormat: "markdown"))
    }

    // MARK: Comments

    func comments(postingId: String, before: Int64? = nil, limit: Int = 20) async throws -> CommentsSlice {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let before { query.append(URLQueryItem(name: "before", value: String(before))) }
        return try await send("GET", "postings/\(postingId)/comments", query: query)
    }

    func createComment(postingId: String, text: String) async throws -> CommentCreated {
        try await send("POST", "postings/\(postingId)/comments",
                       body: CommentText(bodySrc: BodySrc(text: text), bodySrcFormat: "markdown"))
    }

    // MARK: Reactions

    func react(postingId: String, emoji: Int, negative: Bool = false) async throws -> ReactionCreated {
        try await send("POST", "postings/\(postingId)/reactions",
                       body: ReactionDescription(negative: negative, emoji: emoji))
    }

    // MARK: Transport

    private func send<T: Decodable>(_ method: String, _ path: String,
                                    query: [URLQueryItem] = []) async throws -> T {
        try await send(method, path, query: query, body: Optional<Empty>.none)
    }

    private func send<T: Decodable, B: Encodable>(_ method: String, _ path: String,
                                                  query: [URLQueryItem] = [], body: B?) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: "moera/api/\(path)"),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let failure = try? decoder.decode(APIFailure.self, from: data)
            throw APIError.server(status: http.statusCode, message: failure?.message)
        }
        return try decoder.decode(T.self, from: data)
    }
}

private struct Empty: Codable {}

enum APIError: LocalizedError {
    case badResponse
    case server(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .badResponse: "Некорректный ответ сервера"
        case let .server(status, message): message ?? "Ошибка сервера (\(status))"
        }
    }
}
