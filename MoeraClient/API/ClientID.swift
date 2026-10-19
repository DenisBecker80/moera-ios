import Foundation

/// Заголовок `Client-ID: <session-id>:<client-id>` (Moera 0.19).
/// session-id живёт до 3 часов, client-id новый при каждом запуске приложения.
enum ClientID {
    private static let launchID = UUID().uuidString.lowercased()

    static var header: String { "\(sessionID()):\(launchID)" }

    private static func sessionID() -> String {
        let defaults = UserDefaults.standard
        let maxAge: TimeInterval = 3 * 60 * 60
        if let id = defaults.string(forKey: "clientSessionID"),
           let created = defaults.object(forKey: "clientSessionCreated") as? Date,
           Date().timeIntervalSince(created) < maxAge {
            return id
        }
        let id = UUID().uuidString.lowercased()
        defaults.set(id, forKey: "clientSessionID")
        defaults.set(Date(), forKey: "clientSessionCreated")
        return id
    }
}
