import SwiftUI

@main
struct MoeraClientApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isSignedIn {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .environment(session)
        }
    }
}
