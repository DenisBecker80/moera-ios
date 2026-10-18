import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { FeedView() }
                .tabItem { Label("Лента", systemImage: "house.fill") }
            NavigationStack { ProfileView(nodeName: nil) }
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            NavigationStack { NotificationsView() }
                .tabItem { Label("Уведомления", systemImage: "bell.fill") }
        }
    }
}
