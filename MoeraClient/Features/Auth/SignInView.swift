import SwiftUI

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @State private var node = ""
    @State private var login = "admin"
    @State private var password = ""
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Нода") {
                    TextField("https://my.moera.blog", text: $node)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                Section("Вход") {
                    TextField("Логин", text: $login).textInputAutocapitalization(.never)
                    SecureField("Пароль", text: $password)
                }
                if let error { Text(error).foregroundStyle(.red) }
                Button(busy ? "Входим…" : "Войти") { Task { await signIn() } }
                    .disabled(busy || node.isEmpty || password.isEmpty)
            }
            .navigationTitle("Moera")
        }
    }

    private func signIn() async {
        guard let url = URL(string: node.hasPrefix("http") ? node : "https://\(node)") else {
            error = "Неверный адрес ноды"; return
        }
        busy = true; defer { busy = false }
        do {
            try await session.signIn(nodeURL: url, login: login, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
