import Foundation

// Модели Moera Node API. Только нужные клиенту поля, остальное игнорируется.

struct TokenAttributes: Encodable { let login: String; let password: String }
struct TokenInfo: Decodable { let id: String; let token: String }
/// Структура Result: при ошибке нода возвращает её с соответствующим HTTP-статусом.
struct APIFailure: Decodable { let errorCode: String; let message: String? }

struct Profile: Decodable {
    let fullName: String?
    let title: String?
    let bioHtml: String?
}

/// В API тело (body, bodySrc) передаётся строкой с JSON внутри: "{\"text\":\"...\"}".
/// Исключение: формат "application", там строка и есть текст.
struct Body: Codable, Hashable {
    var subject: String?
    var text: String?

    init(subject: String? = nil, text: String?) {
        self.subject = subject
        self.text = text
    }

    private enum Keys: String, CodingKey { case subject, text }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let data = raw.data(using: .utf8),
           let inner = try? JSONDecoder().decode(Inner.self, from: data) {
            subject = inner.subject
            text = inner.text
        } else {
            subject = nil
            text = raw
        }
    }

    func encode(to encoder: Encoder) throws {
        let data = try JSONEncoder().encode(Inner(subject: subject, text: text))
        var container = encoder.singleValueContainer()
        try container.encode(String(decoding: data, as: UTF8.self))
    }

    private struct Inner: Codable { let subject: String?; let text: String? }
}

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
    /// Если пост — копия чужого: нода и id оригинала (комментарии и реакции живут там).
    let receiverName: String?
    let receiverPostingId: String?
    let body: Body
    let createdAt: Int64
    let totalComments: Int?
    /// Примерное число просмотров, видно владельцу (с Moera 0.19).
    let viewCount: Int?
    let media: [MediaAttachment]?
    let reactions: ReactionTotals?
    let clientReaction: ClientReaction?

    var authorDisplayName: String { ownerFullName ?? ownerName }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(createdAt)) }
}

struct Story: Decodable, Identifiable, Hashable {
    let id: String
    let feedName: String
    let storyType: String
    let moment: Int64
    let posting: Posting?
}

struct FeedSlice: Decodable {
    let before: Int64
    let after: Int64
    let stories: [Story]
    let totalInPast: Int
    let totalInFuture: Int
}

struct Comment: Decodable, Identifiable, Hashable {
    let id: String
    let ownerName: String
    let ownerFullName: String?
    let body: Body
    let createdAt: Int64
    let moment: Int64
    /// Комментарий ждёт одобрения автора (премодерация, анонимные комментарии с 0.19).
    let premoderating: Bool?
    let media: [MediaAttachment]?

    var authorDisplayName: String { ownerFullName ?? ownerName }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(createdAt)) }
}

struct CommentsSlice: Decodable {
    let before: Int64
    let after: Int64
    let comments: [Comment]
    let total: Int
}

struct PostingText: Encodable { let bodySrc: Body; let bodySrcFormat: String }
struct CommentText: Encodable { let bodySrc: Body; let bodySrcFormat: String }
struct CommentCreated: Decodable { let comment: Comment; let total: Int }
struct ReactionDescription: Encodable { let negative: Bool; let emoji: Int }
struct ReactionCreated: Decodable { let totals: ReactionTotals? }

/// Набор реакций в духе Facebook (коды emoji Unicode, как в Moera).
enum Reaction: Int, CaseIterable {
    case like = 0x1f44d, love = 0x2764, haha = 0x1f600, wow = 0x1f62e, sad = 0x1f622, angry = 0x1f620

    var symbol: String { String(UnicodeScalar(rawValue).map(Character.init) ?? "👍") }
}

// MARK: Медиа (видео, файлы любых типов, сжатие на сервере — Moera 0.19)

struct MediaAttachment: Decodable, Hashable {
    let media: MediaFile?
    let embedded: Bool
}

struct MediaFile: Decodable, Hashable, Identifiable {
    let id: String
    let path: String
    /// Подписанная прямая ссылка (presigned URL, напр. на S3), живёт ограниченное время.
    let directPath: String?
    let mimeType: String
    let width: Int?
    let height: Int?
    let size: Int
    let duration: Double?
    let title: String?
    /// true — показывать как вложение-файл, а не как картинку/видео.
    let attachment: Bool?
    /// Файл в списке вредоносных (Security Guard).
    let malware: Bool?

    var isImage: Bool { mimeType.hasPrefix("image/") && attachment != true }
    var isVideo: Bool { mimeType.hasPrefix("video/") && attachment != true }

    /// Адрес файла на ноде. TODO: проверить формат на живой ноде.
    func url(node: URL) -> URL? {
        if let directPath {
            return URL(string: directPath, relativeTo: node)?.absoluteURL
        }
        return node.appending(path: "moera/media/\(path)")
    }
}
