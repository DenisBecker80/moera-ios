import SwiftUI

struct ComposePostView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    let onPosted: () -> Void
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                TextEditor(text: $text).padding(.horizontal)
                if let error { Text(error).foregroundStyle(.red).padding() }
            }
            .navigationTitle("Новый пост")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Опубликовать") { Task { await post() } }.disabled(text.isEmpty)
                }
            }
        }
    }

    private func post() async {
        guard let api = session.api else { return }
        do {
            _ = try await api.createPosting(text: text)
            onPosted()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
