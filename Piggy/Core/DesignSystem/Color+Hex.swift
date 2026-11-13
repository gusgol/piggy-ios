import SwiftUI
import UIKit

// Categories store their color as a hex string ("#FFADAD") so both apps can read it.
// These helpers convert between that string and SwiftUI's Color.

nonisolated extension Color {
    /// Parses "#RRGGBB", "RRGGBB" or "#AARRGGBB" (alpha ignored). Returns nil for anything else.
    init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// "#RRGGBB", resolved in sRGB. SwiftUI's Color is an abstract description (it may be dynamic, or
    /// come from an asset), so getting components means resolving it through UIColor first.
    var hexString: String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // ColorPicker can return extended-range values (< 0 or > 1) on wide-gamut displays.
        func byte(_ component: CGFloat) -> Int { Int((min(max(component, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
    }
}
