import SwiftUI
import UIKit

/// Typography tokens. Every token scales with Dynamic Type through its `textStyle`.
/// Families are bundled and registered by `FontRegistrar`.
enum DSFont: CaseIterable {
    case screenTitle, emptyTitle, greeting, tagline
    case rowTitle, rowDescription, inputText, smartInput, smartExample
    case chipTag, chipOption, pill, button, toast, stepCount, count, sectionLabel, softButton, swipeAction, suggestPill

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
        case .tagline: Spec(family: "Caveat", size: 24, weight: .regular, isItalic: false, textStyle: .title2)
        case .rowTitle: Spec(family: "Bricolage Grotesque", size: 16, weight: .semibold, isItalic: false, textStyle: .body)
        case .rowDescription: Spec(family: "Bricolage Grotesque", size: 14, weight: .regular, isItalic: false, textStyle: .subheadline)
        case .inputText: Spec(family: "Bricolage Grotesque", size: 16, weight: .regular, isItalic: false, textStyle: .body)
        case .smartInput: Spec(family: "Bricolage Grotesque", size: 20, weight: .regular, isItalic: false, textStyle: .title3)
        case .smartExample: Spec(family: "Bricolage Grotesque", size: 15, weight: .regular, isItalic: false, textStyle: .callout)
        case .chipTag, .stepCount: Spec(family: "Outfit", size: 12, weight: .semibold, isItalic: false, textStyle: .caption)
        case .sectionLabel: Spec(family: "DM Mono", size: 12, weight: .medium, isItalic: false, textStyle: .caption)
        case .softButton: Spec(family: "Outfit", size: 15, weight: .semibold, isItalic: false, textStyle: .callout)
        case .swipeAction, .suggestPill: Spec(family: "Outfit", size: 13, weight: .semibold, isItalic: false, textStyle: .footnote)
        case .count: Spec(family: "DM Mono", size: 12, weight: .regular, isItalic: false, textStyle: .caption)
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

/// Optical-size support. Bricolage Grotesque ships as a variable font whose `opsz` axis defaults to 96
/// (the display cut), which renders thin and soft at body sizes. SwiftUI's `Font.custom` cannot set
/// variation axes, so these tokens are built through UIKit with `opsz` matched to the point size.
extension DSFont {
    static let opticalSizeRange: ClosedRange<CGFloat> = 12...96

    var usesOpticalSize: Bool { spec.family == "Bricolage Grotesque" }

    /// The `opsz` value for a rendered point size, kept inside the font's axis range.
    static func opticalSize(forPointSize size: CGFloat) -> CGFloat {
        min(max(size, opticalSizeRange.lowerBound), opticalSizeRange.upperBound)
    }

    /// The `wght` axis value for a SwiftUI weight (the other variable families get it through `.weight`).
    var variationWeight: CGFloat {
        switch spec.weight {
        case .ultraLight: 200
        case .thin: 200
        case .light: 300
        case .medium: 500
        case .semibold: 600
        case .bold: 700
        case .heavy, .black: 800
        default: 400
        }
    }

    private var uiTextStyle: UIFont.TextStyle {
        switch spec.textStyle ?? .body {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }

    /// A UIKit font scaled for `category` with `opsz` and `wght` set. Falls back to the plain family font
    /// when the bundled file is unavailable.
    func uiFont(for category: UIContentSizeCategory) -> UIFont {
        Self.registerFonts
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        let size = UIFontMetrics(forTextStyle: uiTextStyle).scaledValue(for: spec.size, compatibleWith: traits)
        guard let base = UIFont(name: spec.family, size: size) else { return .systemFont(ofSize: size) }
        let opsz = 0x6F70737A, wght = 0x77676874
        let variation: [Int: CGFloat] = [opsz: Self.opticalSize(forPointSize: size), wght: variationWeight]
        let descriptor = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute"): variation,
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension DynamicTypeSize {
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

private struct DSFontModifier: ViewModifier {
    let token: DSFont
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if token.usesOpticalSize {
            content.font(Font(token.uiFont(for: dynamicTypeSize.uiContentSizeCategory)))
        } else {
            content.font(token.font)
        }
    }
}

extension View {
    func dsFont(_ token: DSFont) -> some View { modifier(DSFontModifier(token: token)) }
}
