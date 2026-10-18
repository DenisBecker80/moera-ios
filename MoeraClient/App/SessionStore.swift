import Foundation
import Observation

@Observable
final class SessionStore {
    private(set) var nodeURL: URL?
    private(set) var token: String?

    var isSignedIn: Bool { nodeURL != nil && token != nil }

    var api: NodeAPI? {
        guard let nodeURL else { return nil }
        return NodeAPI(baseURL: nodeURL, token: token)
    }

    init() {
        if let url = UserDefaults.standard.url(forKey: "nodeURL") {
            nodeURL = url
            token = Keychain.read("token")
        }
    }

    func signIn(nodeURL: URL, login: String, password: String) async throws {
        let api = NodeAPI(baseURL: nodeURL, token: nil)
        let result = try await api.createToken(login: login, password: password)
        Keychain.save("token", result.token)
        UserDefaults.standard.set(nodeURL, forKey: "nodeURL")
        self.nodeURL = nodeURL
        self.token = result.token
    }

    func signOut() {
        Keychain.delete("token")
        UserDefaults.standard.removeObject(forKey: "nodeURL")
        nodeURL = nil
        token = nil
    }
}
