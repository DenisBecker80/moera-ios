import Foundation

// Модели Moera Node API. Только нужные клиенту поля, остальное игнорируется.

struct Credentials: Encodable { let login: String; let password: String }
struct TokenInfo: Decodable { let token: String }
struct APIFailure: Decodable { let errorCode: String?; let message: String? }

struct Profile: Decodable {
    let fullName: String?
    let title: String?
    let bioHtml: String?
}

struct Body: Codable, Hashable {
    let subject: String?
    let text: String?
}

struct BodySrc: Encodable { let text: String }

struct ReactionTotal: Decodable, Hashable {
    let emoji: Int
    let total: Int?
}

struct ReactionTotals: Decodable, Hashable {
    let positive: [ReactionTotal]?
    let negative: [ReactionTotal]?

    var positiveCount: Int { positive?.compactMap(\.total).reduce(0, +) ?? 0 }
}

struct ClientReaction: Decodable, Hashable {
    let negative: Bool
    let emoji: Int
}

struct Posting: Decodable, Identifiable, Hashable {
    let id: String
    let ownerName: String
    let ownerFullName: String?
    let body: Body
    let createdAt: Int64
    let totalComments: Int?
    let reactions: ReactionTotals?
    let clientReaction: ClientReaction?

    var authorDisplayName: String { ownerFullName ?? ownerName }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(createdAt)) }
}

struct Story: Decodable, Identifiable, Hashable {
    let id: String
    let storyType: String
    let moment: Int64
    let posting: Posting?
}

struct FeedSlice: Decodable {
    let before: Int64
    let after: Int64
    let stories: [Story]
}

struct Comment: Decodable, Identifiable, Hashable {
    let id: String
    let ownerName: String
    let ownerFullName: String?
    let body: Body
    let createdAt: Int64
    let moment: Int64

    var authorDisplayName: String { ownerFullName ?? ownerName }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(createdAt)) }
}

struct CommentsSlice: Decodable {
    let before: Int64
    let after: Int64
    let comments: [Comment]
}

struct PostingText: Encodable { let bodySrc: BodySrc; let bodySrcFormat: String }
struct CommentText: Encodable { let bodySrc: BodySrc; let bodySrcFormat: String }
struct CommentCreated: Decodable { let comment: Comment }
struct ReactionDescription: Encodable { let negative: Bool; let emoji: Int }
struct ReactionCreated: Decodable { let totals: ReactionTotals? }

/// Набор реакций в духе Facebook (коды emoji Unicode, как в Moera).
enum Reaction: Int, CaseIterable {
    case like = 0x1f44d, love = 0x2764, haha = 0x1f600, wow = 0x1f62e, sad = 0x1f622, angry = 0x1f620

    var symbol: String { String(UnicodeScalar(rawValue).map(Character.init) ?? "👍") }
}
