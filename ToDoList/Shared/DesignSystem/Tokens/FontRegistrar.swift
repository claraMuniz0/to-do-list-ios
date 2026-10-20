import CoreText
import Foundation

/// Registers the bundled font files at runtime, so no Info.plist `UIAppFonts` entry is needed.
/// All five families are SIL OFL; license texts live in `docs/licenses/fonts`.
enum FontRegistrar {
    /// Base names of the `.ttf` files in the bundle; a name missing from the bundle is reported as a failure by `registerAll`.
    static let fontFileNames = [
        "Fraunces", "Fraunces-Italic", "BricolageGrotesque", "Outfit", "Caveat",
        "DMMono-Regular", "DMMono-Medium",
    ]

    /// Returns the names of files that could not be registered. A font that is already registered
    /// (e.g. a second call) is not a failure.
    @discardableResult
    static func registerAll(in bundle: Bundle = .main) -> [String] {
        fontFileNames.filter { name in
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { return true }
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { return false }
            guard let cfError = error?.takeRetainedValue() else { return true }
            return CFErrorGetCode(cfError) != CTFontManagerError.alreadyRegistered.rawValue
        }
    }
}
