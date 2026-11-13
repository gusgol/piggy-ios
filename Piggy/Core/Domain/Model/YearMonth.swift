import Foundation

// Android parallel: java.time.YearMonth
//
// Foundation has no YearMonth type, so we write a minimal one. `Comparable` gives us
// `<`, `>`, `...` ranges and `.sorted()` — same as YearMonth implementing Comparable<YearMonth>.
nonisolated struct YearMonth: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    /// 1...12, like `YearMonth.monthValue`
    let month: Int

    init(year: Int, month: Int) {
        precondition((1...12).contains(month), "month must be in 1...12, got \(month)")
        self.year = year
        self.month = month
    }

    /// `YearMonth.from(date)` in the given calendar's time zone (defaults to the device's).
    init(date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month], from: date)
        self.init(year: c.year!, month: c.month!)
    }

    /// `YearMonth.now()`
    static func now(calendar: Calendar = .current) -> YearMonth {
        YearMonth(date: .now, calendar: calendar)
    }

    /// `plusMonths(n)` / `minusMonths(n)` (pass a negative value).
    func adding(months: Int) -> YearMonth {
        let zeroBased = year * 12 + (month - 1) + months
        return YearMonth(year: zeroBased.floorDiv(12), month: zeroBased.floorMod(12) + 1)
    }

    var next: YearMonth { adding(months: 1) }
    var previous: YearMonth { adding(months: -1) }

    /// `atDay(1).atStartOfDay(zone).toInstant()` — inclusive lower bound for Firestore queries.
    func startDate(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    /// Start of the following month — exclusive upper bound for Firestore queries.
    func endDate(calendar: Calendar = .current) -> Date {
        next.startDate(calendar: calendar)
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    /// "2026-11", matching `YearMonth.toString()`
    var description: String {
        String(format: "%04d-%02d", year, month)
    }
}

private extension Int {
    // Swift's `/` and `%` truncate toward zero (like Kotlin's). For negative month offsets
    // we need floor semantics, i.e. Kotlin's `floorDiv` / `mod`.
    func floorDiv(_ d: Int) -> Int { (self - floorMod(d)) / d }
    func floorMod(_ d: Int) -> Int { ((self % d) + d) % d }
}
