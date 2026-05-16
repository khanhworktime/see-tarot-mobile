import SwiftUI
import SeeTarotFeatures

@main
struct SeeTarotApp: App {
    var body: some Scene {
        WindowGroup {
            // Phase 05 swaps this for RootView(authStore:) with DI + bootstrap.
            FoundationRootView()
        }
    }
}
