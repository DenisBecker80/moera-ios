import Foundation

/// Сервер имён Moera: по имени (например, "DenisBecker") находит адрес ноды.
/// JSON-RPC 2.0, https://moera.org/development/naming-api.html
enum NamingAPI {
    static let server = URL(string: "https://naming.moera.org/moera-naming")!

    /// Имя бывает "Name" или "Name_1" (с поколением). Ведущий "@" игнорируется, как в Moera 0.19.
    static func resolve(_ input: String) async throws -> URL {
        var name = input.trimmingCharacters(in: .whitespaces)
        if name.hasPrefix("@") { name.removeFirst() }
        var generation = 0
        if let sep = name.lastIndex(of: "_"), let gen = Int(name[name.index(after: sep)...]) {
            generation = gen
            name = String(name[..<sep])
        }

        var request = URLRequest(url: server)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Call(params: [.string(name), .int(generation)]))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(Response.self, from: data)
        if let error = response.error { throw NamingError.server(error.message ?? "Ошибка сервера имён") }
        guard let uri = response.result?.nodeUri else { throw NamingError.notFound(name) }
        guard let url = URL(string: uri) else { throw NamingError.notFound(name) }
        return url
    }

    private struct Call: Encodable {
        let jsonrpc = "2.0"
        let method = "getCurrent"
        let params: [Param]
        let id = 1
    }

    private enum Param: Encodable {
        case string(String), int(Int)
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .string(let s): try c.encode(s)
            case .int(let i): try c.encode(i)
            }
        }
    }

    private struct Response: Decodable {
        let result: NameInfo?
        let error: RPCError?
    }

    private struct NameInfo: Decodable { let nodeUri: String }
    private struct RPCError: Decodable { let message: String? }
}

enum NamingError: LocalizedError {
    case notFound(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let name): "Имя «\(name)» не найдено. Учтите, что регистр букв важен."
        case .server(let message): message
        }
    }
}
