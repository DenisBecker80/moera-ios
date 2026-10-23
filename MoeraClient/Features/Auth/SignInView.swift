import SwiftUI

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @State private var name = ""
    @State private var password = ""
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Имя в Moera", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                    SecureField("Пароль", text: $password)
                        .textContentType(.password)
                } footer: {
                    Text("Имя чувствительно к регистру. Можно ввести и адрес ноды.")
                }
                if let error { Text(error).foregroundStyle(.red) }
                Button(busy ? "Входим…" : "Войти") { Task { await signIn() } }
                    .disabled(busy || name.isEmpty || password.isEmpty)
            }
            .navigationTitle("Moera")
        }
    }

    private func signIn() async {
        busy = true
        defer { busy = false }
        error = nil
        do {
            try await session.signIn(name: name, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
