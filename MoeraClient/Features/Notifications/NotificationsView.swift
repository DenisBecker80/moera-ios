import SwiftUI

struct NotificationsView: View {
    var body: some View {
        ContentUnavailableView("Пока пусто", systemImage: "bell",
                               description: Text("Уведомления появятся на следующем этапе."))
            .navigationTitle("Уведомления")
    }
}
