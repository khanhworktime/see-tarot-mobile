import CoreText
import Foundation

/// Registers Cinzel and Lora `.ttf` font files from the SPM resource bundle
/// at runtime via Core Text. Call once at app launch before any view renders.
///
/// `UIAppFonts` in `Info.plist` is a belt-and-suspenders fallback; the primary
/// load path is this registrar because fonts live in `Bundle.module` (SPM
/// resource bundle), not the main app bundle.
public enum FontRegistrar {

    // MARK: - Public

    /// Registers all bundled fonts. Safe to call multiple times — subsequent
    /// calls are no-ops once registration is confirmed.
    public static func registerAll() {
        guard !isRegistered else { return }
        let bundle = Bundle.module
        let fontNames = ["Cinzel.ttf", "Lora.ttf"]
        for name in fontNames {
            register(filename: name, in: bundle)
        }
        isRegistered = true
    }

    // MARK: - Private

    private static var isRegistered = false

    private static func register(filename: String, in bundle: Bundle) {
        guard let url = bundle.url(forResource: filename, withExtension: nil) else {
            // Font file missing from bundle — this is a packaging error.
            assertionFailure("[FontRegistrar] Missing font file: \(filename)")
            return
        }
        var error: Unmanaged<CFError>?
        // CTFontManagerRegisterFontsForURL returns false if already registered;
        // that is not an error — idempotent by design.
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if let error = error?.takeRetainedValue() {
            // Log but do not crash — system fonts remain as fallback.
            print("[FontRegistrar] Registration skipped for \(filename): \(error)")
        }
    }
}
