import SwiftUI

/// Typography tokens. Every token scales with Dynamic Type through its `textStyle`.
/// Families are bundled and registered by `FontRegistrar`.
enum DSFont: CaseIterable {
    case screenTitle, emptyTitle, greeting
    case rowTitle, rowDescription, inputText
    case chipTag, chipOption, pill, button, toast, stepCount

    struct Spec: Equatable {
        let family: String
        let size: CGFloat
        let weight: Font.Weight
        let isItalic: Bool
        let textStyle: Font.TextStyle?
    }

    /// Several tokens share a spec (`chipTag`/`stepCount`, `chipOption`/`pill`) on purpose: they are separate tokens so each can change without affecting the other.
    var spec: Spec {
        switch self {
        case .screenTitle: Spec(family: "Fraunces", size: 36, weight: .semibold, isItalic: true, textStyle: .largeTitle)
        case .emptyTitle: Spec(family: "Fraunces", size: 26, weight: .bold, isItalic: false, textStyle: .title)
        case .greeting: Spec(family: "Caveat", size: 24, weight: .semibold, isItalic: false, textStyle: .title2)
        case .rowTitle: Spec(family: "Bricolage Grotesque", size: 16, weight: .semibold, isItalic: false, textStyle: .body)
        case .rowDescription: Spec(family: "Bricolage Grotesque", size: 14, weight: .regular, isItalic: false, textStyle: .subheadline)
        case .inputText: Spec(family: "Bricolage Grotesque", size: 16, weight: .regular, isItalic: false, textStyle: .body)
        case .chipTag, .stepCount: Spec(family: "Outfit", size: 12, weight: .semibold, isItalic: false, textStyle: .caption)
        case .chipOption, .pill: Spec(family: "Outfit", size: 14, weight: .semibold, isItalic: false, textStyle: .subheadline)
        case .button: Spec(family: "Outfit", size: 17, weight: .semibold, isItalic: false, textStyle: .headline)
        case .toast: Spec(family: "Outfit", size: 15, weight: .semibold, isItalic: false, textStyle: .callout)
        }
    }

    /// Registers the bundled files once, lazily, so previews (which skip the App init) get them too.
    private static let registerFonts: Void = { FontRegistrar.registerAll() }()

    /// Falls back to `.body` scaling when `textStyle` is nil. Reading it registers the fonts first, so call sites never need to.
    var font: Font {
        Self.registerFonts
        let spec = spec
        let base = Font.custom(spec.family, size: spec.size, relativeTo: spec.textStyle ?? .body).weight(spec.weight)
        return spec.isItalic ? base.italic() : base
    }
}

extension View {
    func dsFont(_ token: DSFont) -> some View { font(token.font) }
}
