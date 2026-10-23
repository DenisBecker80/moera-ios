import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private(set) var nodeURL: URL?
    private(set) var token: String?
    /// Имя, под которым вошли (например, "DenisBecker").
    private(set) var nodeName: String?

    var isSignedIn: Bool { nodeURL != nil && token != nil }

    var api: NodeAPI? {
        guard let nodeURL else { return nil }
        return NodeAPI(baseURL: nodeURL, token: token)
    }

    init() {
        if let url = UserDefaults.standard.url(forKey: "nodeURL") {
            nodeURL = url
            token = Keychain.read("token")
            nodeName = UserDefaults.standard.string(forKey: "nodeName")
        }
    }

    /// Вход как на сайте Moera: имя (или адрес ноды) и пароль.
    /// У ноды одна учётная запись владельца с логином "admin".
    func signIn(name: String, password: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let nodeURL: URL
        if trimmed.contains(".") || trimmed.hasPrefix("http") {
            guard let url = URL(string: trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)") else {
                throw NamingError.notFound(trimmed)
            }
            nodeURL = NodeAPI.root(of: url)
        } else {
            nodeURL = NodeAPI.root(of: try await NamingAPI.resolve(trimmed))
        }
        let login = "admin"
        let api = NodeAPI(baseURL: nodeURL, token: nil)
        let result = try await api.createToken(login: login, password: password)
        Keychain.save("token", result.token)
        UserDefaults.standard.set(nodeURL, forKey: "nodeURL")
        UserDefaults.standard.set(trimmed, forKey: "nodeName")
        self.nodeName = trimmed
        self.nodeURL = nodeURL
        self.token = result.token
    }

    func signOut() {
        Keychain.delete("token")
        UserDefaults.standard.removeObject(forKey: "nodeURL")
        UserDefaults.standard.removeObject(forKey: "nodeName")
        nodeName = nil
        nodeURL = nil
        token = nil
    }
}
