import Foundation

// iOS formats values with `FormatStyle`s, which are locale-aware and composable, rather than
// NumberFormat/DateTimeFormatter instances. SwiftUI takes them directly:
//   Text(expense.amount, format: .localCurrency)
//   Text(expense.date, format: .dateTime.day().month())
// and so does TextField, for parsing input.

nonisolated extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    /// The user's local currency, e.g. "R$ 1.234,56" in pt-BR or "$1,234.56" in en-US.
    /// Android parallel: `NumberFormat.getCurrencyInstance()`.
    static var localCurrency: Self {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }
}

nonisolated extension YearMonth {
    /// "November 2026", localized.
    var formatted: String {
        startDate().formatted(.dateTime.month(.wide).year())
    }
}
