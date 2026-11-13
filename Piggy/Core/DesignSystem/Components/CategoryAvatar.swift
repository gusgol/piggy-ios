import SwiftUI

/// A category's emoji (or its first letter) in a tinted circle.
/// Shared by Expenses and, later, Categories.
struct CategoryAvatar: View {
    let icon: String?
    let name: String?
    let colorHex: String?
    var size: CGFloat = 40

    var body: some View {
        let palette = CategoryColorPalette(colorHex: colorHex, categoryName: name)
        Text(label)
            .font(.system(size: size * 0.45))
            .foregroundStyle(palette.avatarContent)
            .frame(width: size, height: size)
            .background(palette.avatarContainer, in: .circle)
            // VoiceOver reads the row's text instead; the emoji alone isn't meaningful.
            .accessibilityHidden(true)
    }

    private var label: String {
        if let icon, !icon.trimmingCharacters(in: .whitespaces).isEmpty { return icon }
        return name?.first.map { String($0).uppercased() } ?? "?"
    }
}

#Preview {
    HStack {
        CategoryAvatar(icon: "🛒", name: "Groceries", colorHex: "#059669")
        CategoryAvatar(icon: "🏠", name: "Housing", colorHex: "#F43F5E")
        CategoryAvatar(icon: nil, name: "Transport", colorHex: nil)
        CategoryAvatar(icon: "☕️", name: "Coffee", colorHex: "#854D0E", size: 56)
    }
    .padding()
}
