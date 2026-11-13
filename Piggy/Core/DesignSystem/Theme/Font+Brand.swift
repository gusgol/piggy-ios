import SwiftUI

// iOS typography follows Apple's built-in text styles:
//   .largeTitle .title .title2 .title3 .headline .body .callout .subheadline .footnote .caption .caption2
// Each has a size, weight, line height and letter spacing that Apple tunes per size, and each
// scales with Dynamic Type. You rarely adjust tracking or line height by hand.
//
// So body copy uses the system font directly: `.font(.body)`, `.font(.footnote)`. No wrapper needed.
//
// The brand typeface (Plus Jakarta Sans) has no system equivalent, so it's kept only where it
// carries the brand: titles and money amounts. `relativeTo:` ties it to an Apple text style,
// so it still scales with Dynamic Type.
//
// Usage:
//   Text("Expenses").font(.brand(.largeTitle))
//   Text(total, format: .currency(code: "BRL")).font(.amount(.largeTitle))
extension Font {
    /// Plus Jakarta Sans at the given text style's default size, scaling with Dynamic Type.
    static func brand(_ style: TextStyle, weight: Weight = .bold) -> Font {
        .custom(BrandFont.postScriptName(for: weight), size: BrandFont.defaultSize(for: style), relativeTo: style)
    }

    /// Brand font with tabular (fixed-width) digits, so amounts line up in columns.
    /// Android parallel: `fontFeatureSettings = "tnum"`.
    static func amount(_ style: TextStyle, weight: Weight = .semibold) -> Font {
        brand(style, weight: weight).monospacedDigit()
    }
}

nonisolated enum BrandFont {
    /// Only these four weights are bundled (see Resources/Fonts and `UIAppFonts` in Info.plist).
    static func postScriptName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: "PlusJakartaSans-Bold"
        case .semibold: "PlusJakartaSans-SemiBold"
        case .medium: "PlusJakartaSans-Medium"
        default: "PlusJakartaSans-Regular"
        }
    }

    /// Apple's default point sizes for each text style, at the default ("Large") Dynamic Type setting.
    static func defaultSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}
