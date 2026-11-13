import SwiftUI

/// Fixed vs. variable spending as a segmented capacity bar with a legend underneath, modeled on
/// Settings → General → iPhone Storage.
///
///   [████████████████ fixed ████████████████][████ variable ████]
///   ● Fixed                 ● Variable
///   R$ 1.603,83             R$ 1.042,49
///   61%                     39%
struct SpendingSplitView: View {
    let fixedTotal: Double
    let variableTotal: Double
    /// 0...1
    let fixedFraction: Double

    // The generated asset symbol, not `Color.accentColor` (which resolved to system blue here,
    // see PiggyApp).
    private static let fixedColor = Color(.accent)
    private static let variableColor = Color.mint

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SegmentedBar(fraction: fixedFraction, leading: Self.fixedColor, trailing: Self.variableColor)
                .frame(height: 10)
                .accessibilityHidden(true) // The legend below carries the same information.

            HStack(alignment: .top, spacing: 16) {
                LegendItem(title: "Fixed", color: Self.fixedColor, amount: fixedTotal, share: fixedFraction)
                LegendItem(title: "Variable", color: Self.variableColor, amount: variableTotal, share: 1 - fixedFraction)
            }
        }
    }
}

/// Two capsule segments sized by `fraction`, with a small gap between them. Segments shrink to
/// nothing (with no stray gap) when one side is zero.
private struct SegmentedBar: View {
    let fraction: Double
    let leading: Color
    let trailing: Color

    private let gap: CGFloat = 3

    var body: some View {
        // GeometryReader is the escape hatch when a layout depends on the container's size, here
        // to turn a fraction into a width. Prefer stacks and frames when they can express the layout.
        GeometryReader { proxy in
            let hasBoth = fraction > 0 && fraction < 1
            let available = proxy.size.width - (hasBoth ? gap : 0)
            HStack(spacing: hasBoth ? gap : 0) {
                Capsule()
                    .fill(leading.gradient)
                    .frame(width: available * fraction)
                Capsule()
                    .fill(trailing.gradient)
                    .frame(width: available * (1 - fraction))
            }
        }
        .animation(.spring(duration: 0.5), value: fraction)
    }
}

private struct LegendItem: View {
    let title: LocalizedStringKey
    let color: Color
    let amount: Double
    let share: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(amount, format: .localCurrency)
                .font(.amount(.title3))
                .contentTransition(.numericText(value: amount))
                .animation(.default, value: amount)
            Text(share, format: .percent.precision(.fractionLength(0)))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // VoiceOver: "Fixed, R$ 1.603,83, 61%"
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        Section {
            SpendingSplitView(fixedTotal: 1603.83, variableTotal: 1042.49, fixedFraction: 0.606)
                .padding(.vertical, 4)
        }
        Section {
            SpendingSplitView(fixedTotal: 1200, variableTotal: 0, fixedFraction: 1)
                .padding(.vertical, 4)
        }
    }
}
