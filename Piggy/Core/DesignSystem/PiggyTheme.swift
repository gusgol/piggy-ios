import SwiftUI
import UIKit

// MARK: - Android → iOS theme translation
//
// Compose themes the app through one `PiggyTheme { }` wrapper that provides a full Material
// color scheme, type scale and shapes. iOS has no equivalent wrapper. The system already provides
// semantic colors, text styles and spacing that adapt to light/dark, Dynamic Type, accessibility
// settings and Liquid Glass. An iOS theme only adds what's genuinely *brand*.
//
// COLOR
// | Android (Material 3)              | iOS                                                          |
// |-----------------------------------|--------------------------------------------------------------|
// | primary                           | AccentColor asset → app-wide tint; use `.tint` in code        |
// | onPrimary                         | `.white` on a `.tint` fill (or a prominent button style)      |
// | secondary (rose)                  | `BrandRose` asset → `.brandRose` (no system equivalent)       |
// | error                             | `.red` (system red; also `Button(role: .destructive)`)        |
// | onSurface / onBackground          | `.primary`        (foregroundStyle hierarchy)                 |
// | onSurfaceVariant                  | `.secondary`                                                  |
// | outline / subtle text             | `.tertiary`                                                   |
// | surface / background              | system default (`.background`); don't override                |
// | surfaceContainer* / cards         | `List`/`Form` grouped rows, or `.background(.fill.quaternary)` |
// |                                   | / `Color(.secondarySystemGroupedBackground)`                  |
// | outlineVariant / dividers         | `Divider()` / `Color(.separator)`                             |
// | dark scheme                       | automatic: system and asset colors are dynamic               |
//
// TYPOGRAPHY (see Font+Brand.swift)
// | Android token          | iOS                                         |
// |------------------------|---------------------------------------------|
// | displayCurrency        | `.amount(.largeTitle, weight: .bold)`       |
// | displayCurrencyMobile  | `.amount(.title, weight: .bold)`            |
// | headlineLg             | `.brand(.title2)`                           |
// | headlineMd             | `.brand(.title3, weight: .semibold)`        |
// | titleSm                | `.headline`                                 |
// | currencyItem           | `.amount(.headline)` / `.headline.monospacedDigit()` |
// | bodyMd                 | `.body` (or `.subheadline` for denser rows) |
// | bodySm                 | `.footnote`                                 |
// | badgeLabel             | `.caption.weight(.semibold)`                |
// | labelCaps              | `.caption2.weight(.bold)` + `.textCase(.uppercase)`. List section headers already do this |
// | letterSpacing / lineHeight | none: Apple tunes them per text style |
//
// SHAPE & SPACING
// | Android                     | iOS                                                              |
// |-----------------------------|------------------------------------------------------------------|
// | RoundedCornerShape(n.dp)    | `RoundedRectangle(cornerRadius: n, style: .continuous)` (squircle) |
// | CircleShape on a pill       | `Capsule()` / `.capsule`                                          |
// | PiggySpacing.margin etc.    | `.padding()` (system default), `List`/`Form` insets, `.contentMargins` |
// | Shape tokens on buttons     | `.buttonStyle(.borderedProminent)` / `.glassProminent`, `.buttonBorderShape` |
//
// CATEGORY COLORS: no system equivalent (user data). See CategoryColors.swift.

enum PiggyTheme {
    /// Navigation bar titles are rendered by UIKit's UINavigationBar, not SwiftUI, so they ignore
    /// `.font(...)`. UIKit's `appearance()` proxy is the supported way to restyle them.
    /// Only the title fonts are set, which leaves the system's Liquid Glass bar untouched.
    ///
    /// Call once at launch.
    static func configureAppearance() {
        let navBar = UINavigationBar.appearance()
        navBar.largeTitleTextAttributes = [
            .font: scaledBrandFont(weight: .bold, style: .largeTitle),
        ]
        navBar.titleTextAttributes = [
            .font: scaledBrandFont(weight: .semibold, style: .headline),
        ]
    }

    /// UIKit's equivalent of `Font.custom(_:size:relativeTo:)`, scaling with Dynamic Type.
    private static func scaledBrandFont(weight: Font.Weight, style: Font.TextStyle) -> UIFont {
        let size = BrandFont.defaultSize(for: style)
        let base = UIFont(name: BrandFont.postScriptName(for: weight), size: size) ?? .systemFont(ofSize: size)
        let uiStyle: UIFont.TextStyle = style == .largeTitle ? .largeTitle : .headline
        return UIFontMetrics(forTextStyle: uiStyle).scaledFont(for: base)
    }
}
