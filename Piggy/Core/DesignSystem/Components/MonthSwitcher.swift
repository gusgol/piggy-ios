import SwiftUI

/// ‹ November 2026 ›. Tapping the title jumps back to the current month.
/// Shared by Expenses and Trends.
struct MonthSwitcher: View {
    let month: YearMonth
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onCurrent: () -> Void

    private var isCurrentMonth: Bool { month == .now() }

    var body: some View {
        HStack {
            Button("Previous Month", systemImage: "chevron.left", action: onPrevious)
                .labelStyle(.iconOnly)
            Spacer()
            // Not `.disabled` on the current month: disabled buttons render dimmed, and the title
            // would look inactive.
            Button(action: onCurrent) {
                Text(month.formatted)
                    .font(.headline)
            }
            .accessibilityHint(isCurrentMonth ? "" : "Shows the current month")
            Spacer()
            Button("Next Month", systemImage: "chevron.right", action: onNext)
                .labelStyle(.iconOnly)
        }
        // Inside a List row, a tap would otherwise trigger *every* button in the row.
        // `.borderless` makes each button handle only its own taps.
        .buttonStyle(.borderless)
    }
}

#Preview {
    List {
        MonthSwitcher(month: .now(), onPrevious: {}, onNext: {}, onCurrent: {})
    }
}
