import Foundation

/// Typed access to build configuration. `API_BASE_URL` is injected via
/// xcconfig -> Info.plist; never hardcoded (decision 0004 / api-conventions).
enum AppConfig {
    static var apiBaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            let url = URL(string: raw)
        else {
            fatalError("API_BASE_URL missing/invalid in Info.plist (check xcconfig)")
        }
        return url
    }
}
