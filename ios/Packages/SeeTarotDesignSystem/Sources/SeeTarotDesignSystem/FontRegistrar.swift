import CoreText
import Foundation
import os

/// Registers Cinzel and Lora `.ttf` font files from the SPM resource bundle
/// at runtime via Core Text. Call once at app launch before any view renders.
///
/// `UIAppFonts` in `Info.plist` is a belt-and-suspenders fallback; the primary
/// load path is this registrar because fonts live in `Bundle.module` (SPM
/// resource bundle), not the main app bundle.
///
/// M1-A: `registerAll()` is `@MainActor` — it is always called from the app's
/// main-thread initialiser (`SeeTarotApp.init`). The annotation documents and
/// enforces this contract, preventing unsynchronised access to `isRegistered`.
public enum FontRegistrar {

    // MARK: - Public

    /// Registers all bundled fonts. Safe to call multiple times — subsequent
    /// calls are no-ops once all fonts have registered successfully.
    ///
    /// M1-A: `@MainActor` ensures the `isRegistered` flag is only ever read
    /// and written on the main actor, making it free of data races.
    @MainActor
    public static func registerAll() {
        guard !isRegistered else { return }
        let bundle = Bundle.module
        let fontNames = ["Cinzel.ttf", "Lora.ttf"]
        // M2-A: Only mark registered when ALL fonts succeed. A partial failure
        // leaves the flag false so a later retry (e.g. after a packaging fix)
        // can re-attempt. Failures are surfaced via os.Logger at .error so they
        // are visible in Console.app in production builds.
        var allSucceeded = true
        for name in fontNames {
            let ok = register(filename: name, in: bundle)
            if !ok { allSucceeded = false }
        }
        if allSucceeded { isRegistered = true }
    }

    // MARK: - Private

    // M1-A: `@MainActor`-isolated — accessed only from `registerAll()`.
    private static var isRegistered = false

    private static let logger = Logger(subsystem: "com.seetarot.designsystem",
                                       category: "FontRegistrar")

    /// Attempts to register one font file.
    /// - Returns: `true` if the file was registered (or was already registered);
    ///            `false` on any failure (missing file or CoreText error).
    @discardableResult
    private static func register(filename: String, in bundle: Bundle) -> Bool {
        guard let url = bundle.url(forResource: filename, withExtension: nil) else {
            // Font file missing from bundle — packaging error.
            assertionFailure("[FontRegistrar] Missing font file: \(filename)")
            logger.error("[FontRegistrar] Missing font file: \(filename, privacy: .public)")
            return false
        }
        var cfError: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &cfError)
        if !registered, let error = cfError?.takeRetainedValue() {
            let code = CFErrorGetCode(error)
            // Code 105 = kCTFontManagerErrorAlreadyRegistered — treat as success.
            if code == 105 { return true }
            // M2-A: Use os.Logger at .error — visible in Console.app in production.
            // Do NOT crash; system fonts remain available as graceful fallback.
            logger.error("[FontRegistrar] Registration failed for \(filename, privacy: .public): \(error, privacy: .public)")
            return false
        }
        return true
    }
}
