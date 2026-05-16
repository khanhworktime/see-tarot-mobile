import SwiftUI
import SeeTarotFeatures

@main
struct SeeTarotApp: App {
    @State private var auth = AppComposition.makeAuthStore(
        baseURL: AppConfig.apiBaseURL)

    var body: some Scene {
        WindowGroup {
            RootView(auth: auth)
        }
    }
}
