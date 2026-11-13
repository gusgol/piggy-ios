import SwiftUI
import UIKit

// Android parallel: designsystem/theme/CategoryColors.kt
//
// Unlike the rest of the theme, this has no system equivalent: category colors come from user
// data (each category stores a hex color), so the derivation algorithm is ported as-is.
//
// What *is* translated:
//  - Android needs `isDark` passed in and recomputes on theme change (`remember(..., isDark)`).
//    Here every color in the palette is *dynamic*: it holds both its light and dark value and the
//    system picks one at draw time, like any system color. Callers never check the color scheme.
//  - The grey fallback for unsaturated colors uses system semantic colors (`.secondary`,
//    `secondarySystemFill`) instead of hand-picked neutrals.
//
// Usage:
//   let palette = CategoryColorPalette(colorHex: category.color, categoryName: category.name)
//   Circle().fill(palette.dot)
//   Text(category.name).foregroundStyle(palette.badgeContent).background(palette.badgeContainer, in: .capsule)
nonisolated struct CategoryColorPalette: Hashable, Sendable {
    let dot: Color
    let avatarContainer: Color
    let avatarContent: Color
    let badgeContainer: Color
    let badgeContent: Color
    /// For large chart areas (donut slices, bars): softer than `dot`, which is tuned for small
    /// markers, so a chart full of categories doesn't look garish. iOS-only addition.
    let chart: Color

    init(colorHex: String?, categoryName: String? = nil) {
        let seed = HSL(rgb: Self.parseHex(colorHex) ?? Self.semanticSeed(forName: categoryName))
        let h = seed.h
        let s = seed.s

        // Near-grey seeds would produce muddy tints, so use neutral system colors instead.
        guard s >= 0.12 else {
            dot = .secondary
            avatarContainer = Color(.secondarySystemFill)
            avatarContent = .primary
            badgeContainer = Color(.secondarySystemFill)
            badgeContent = .secondary
            chart = Color(.systemGray3)
            return
        }

        // Light: saturated dot, pale pastel containers, deep text.
        // Dark: brighter dot, translucent tinted containers, light text.
        let lightDeep = HSL(h: h, s: s.clamped(0.62, 0.86), l: 0.30)
        let darkLabel = HSL(h: h, s: s.clamped(0.55, 0.85), l: 0.80)
        let darkTint = HSL(h: h, s: s.clamped(0.50, 0.80), l: 0.58)

        dot = .dynamic(
            light: HSL(h: h, s: s.clamped(0.62, 0.86), l: 0.44).uiColor(),
            dark: HSL(h: h, s: s.clamped(0.55, 0.85), l: 0.68).uiColor()
        )
        avatarContainer = .dynamic(
            light: HSL(h: h, s: s.clamped(0.50, 0.88), l: 0.91).uiColor(),
            dark: darkTint.uiColor(alpha: 0.22)
        )
        avatarContent = .dynamic(light: lightDeep.uiColor(), dark: darkLabel.uiColor())
        badgeContainer = .dynamic(
            light: HSL(h: h, s: s.clamped(0.50, 0.88), l: 0.95).uiColor(),
            dark: darkTint.uiColor(alpha: 0.18)
        )
        badgeContent = .dynamic(light: lightDeep.uiColor(), dark: darkLabel.uiColor())
        chart = .dynamic(
            light: HSL(h: h, s: s.clamped(0.45, 0.70), l: 0.62).uiColor(),
            dark: HSL(h: h, s: s.clamped(0.45, 0.70), l: 0.60).uiColor()
        )
    }

    // MARK: - Seeds

    /// Accepts "#RRGGBB", "RRGGBB", or "#AARRGGBB" (the same forms Android's `toColorInt()` accepts).
    private static func parseHex(_ hex: String?) -> RGB? {
        guard var s = hex?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let value = UInt32(s, radix: 16) else { return nil }
        return RGB(hex: value & 0xFFFFFF)
    }

    /// Fallback when a category has no stored color: guess from its name.
    private static func semanticSeed(forName name: String?) -> RGB {
        let lower = name?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        func has(_ needles: String...) -> Bool { needles.contains { lower.contains($0) } }
        return switch true {
        case has("hous", "rent", "home"): RGB(hex: 0xF43F5E)          // rose
        case has("grocer", "market"): RGB(hex: 0x059669)              // emerald
        case has("din", "food", "restaur"): RGB(hex: 0xD97706)        // amber
        case has("transp", "metro", "car", "bus"): RGB(hex: 0x0284C7) // sky
        case has("util", "bill", "electr"): RGB(hex: 0x0891B2)        // cyan
        case has("coffee", "cafe", "leis"): RGB(hex: 0x854D0E)        // brown
        default: RGB(hex: 0x059669)                                   // emerald (brand)
        }
    }
}

// MARK: - Dynamic color

private extension Color {
    /// A color that resolves per appearance, built the same way system colors like `.label` are:
    /// a UIColor whose value is chosen from the current trait collection at draw time.
    nonisolated static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// MARK: - HSL math
//
// Android uses `ColorUtils.colorToHSL` / `HSLToColor`. UIKit only offers HSB, which is a different
// model (HSB "brightness" ≠ HSL "lightness"), so the conversion is written out to match Android.

private nonisolated struct RGB {
    let r: Double, g: Double, b: Double

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
}

private nonisolated struct HSL {
    /// Hue in degrees, 0..<360
    let h: Double
    /// Saturation, 0...1
    let s: Double
    /// Lightness, 0...1
    let l: Double

    init(h: Double, s: Double, l: Double) { self.h = h; self.s = s; self.l = l }

    init(rgb: RGB) {
        let maxC = max(rgb.r, rgb.g, rgb.b), minC = min(rgb.r, rgb.g, rgb.b)
        let delta = maxC - minC
        l = (maxC + minC) / 2
        guard delta > 0 else { h = 0; s = 0; return }
        s = delta / (1 - abs(2 * l - 1))
        let sector: Double = switch maxC {
        case rgb.r: ((rgb.g - rgb.b) / delta).truncatingRemainder(dividingBy: 6)
        case rgb.g: (rgb.b - rgb.r) / delta + 2
        default: (rgb.r - rgb.g) / delta + 4
        }
        let degrees = sector * 60
        h = degrees < 0 ? degrees + 360 : degrees
    }

    func uiColor(alpha: Double = 1) -> UIColor {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        let (r, g, b): (Double, Double, Double) = switch h {
        case ..<60: (c, x, 0)
        case ..<120: (x, c, 0)
        case ..<180: (0, c, x)
        case ..<240: (0, x, c)
        case ..<300: (x, 0, c)
        default: (c, 0, x)
        }
        return UIColor(red: r + m, green: g + m, blue: b + m, alpha: alpha)
    }
}

private extension Double {
    /// Kotlin's `coerceIn(min, max)`.
    nonisolated func clamped(_ lower: Double, _ upper: Double) -> Double {
        Swift.min(Swift.max(self, lower), upper)
    }
}
