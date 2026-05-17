import SwiftUI
import SeeTarotFeatures

@main
struct SeeTarotApp: App {
    @State private var auth = SeeTarotApp.makeAuth()

    var body: some Scene {
        WindowGroup {
            RootView(auth: auth)
        }
    }

    @MainActor
    private static func makeAuth() -> AuthStore {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SEE_TAROT_UI_STUB"] == "1" {
            return AppComposition.makeStubAuthStore()
        }
        #endif
        return AppComposition.makeAuthStore(baseURL: AppConfig.apiBaseURL)
    }
}
