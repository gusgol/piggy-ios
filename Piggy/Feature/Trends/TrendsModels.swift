import SwiftUI

// Chart-ready data for the Trends screens. These are pure values built from expenses + categories,
// so they can be computed properties on the ViewModel (and unit-tested without Firebase).
//
// Android parallel: ObserveMonthlyTrendsUseCase / ObserveYearlyTrendsUseCase. Swift Charts plots
// collections of Identifiable values directly, so there's no separate "UI model" mapping layer
// like Android's TrendsData → CurrentTrendsUiState.

// MARK: - Month

nonisolated struct MonthTrends: Sendable {
    struct CategoryTotal: Identifiable, Sendable {
        let id: String
        let name: String
        let icon: String?
        let colorHex: String?
        let total: Double
        /// 0...1 of the month's total.
        let share: Double
        /// Newest first.
        let expenses: [Expense]

        var palette: CategoryColorPalette { CategoryColorPalette(colorHex: colorHex, categoryName: name) }
    }

    /// One bar segment: a category's spending on one day.
    struct DailyAmount: Identifiable, Sendable {
        let day: Date
        let categoryID: String
        let categoryName: String
        let colorHex: String?
        let amount: Double
        var id: String { "\(day.timeIntervalSince1970)-\(categoryID)" }
    }

    let month: YearMonth
    let total: Double
    let expenseCount: Int
    /// Largest first.
    let categories: [CategoryTotal]
    let daily: [DailyAmount]
    /// Total per day, for the selection callout.
    let dailyTotals: [Date: Double]

    init(month: YearMonth, expenses: [Expense], categories allCategories: [Category], calendar: Calendar = .current) {
        let expenses = expenses.enriched(with: allCategories)
        self.month = month
        total = expenses.reduce(0) { $0 + $1.amount }
        expenseCount = expenses.count

        let total = self.total
        categories = Dictionary(grouping: expenses, by: \.categoryId)
            .map { id, items in
                let categoryTotal = items.reduce(0) { $0 + $1.amount }
                return CategoryTotal(
                    id: id,
                    name: items[0].categoryName ?? "Other",
                    icon: items[0].categoryIcon,
                    colorHex: items[0].categoryColor,
                    total: categoryTotal,
                    share: total > 0 ? categoryTotal / total : 0,
                    expenses: items.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.total > $1.total }

        struct DayCategory: Hashable { let day: Date; let categoryID: String }
        daily = Dictionary(grouping: expenses) { DayCategory(day: calendar.startOfDay(for: $0.date), categoryID: $0.categoryId) }
            .map { key, items in
                DailyAmount(
                    day: key.day, categoryID: key.categoryID,
                    categoryName: items[0].categoryName ?? "Other", colorHex: items[0].categoryColor,
                    amount: items.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { ($0.day, $0.categoryName) < ($1.day, $1.categoryName) }

        dailyTotals = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
}

// MARK: - Year

nonisolated struct YearTrends: Sendable {
    struct MonthTotal: Identifiable, Sendable {
        let month: YearMonth
        let total: Double
        var id: YearMonth { month }
        /// Charts plot dates, not YearMonths: the first day of the month.
        var date: Date { month.startDate() }
    }

    struct CategoryOption: Identifiable, Sendable {
        let id: String
        let name: String
        let icon: String?
        let colorHex: String?
    }

    /// Oldest first, always 12 entries (months without spending are 0).
    let months: [MonthTotal]
    let total: Double
    /// Average over months that had any spending, so a new user's empty early months
    /// don't drag it down.
    let average: Double
    /// Categories with spending in the range, largest first.
    let categoryOptions: [CategoryOption]
    let selectedCategory: CategoryOption?

    init(endingAt lastMonth: YearMonth, expenses: [Expense], categories: [Category], categoryID: String?) {
        let expenses = expenses.enriched(with: categories)

        categoryOptions = Dictionary(grouping: expenses, by: \.categoryId)
            .map { id, items in (CategoryOption(id: id, name: items[0].categoryName ?? "Other", icon: items[0].categoryIcon, colorHex: items[0].categoryColor), items.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
        let selectedCategory = categoryOptions.first { $0.id == categoryID }
        self.selectedCategory = selectedCategory

        let filtered = selectedCategory.map { selected in expenses.filter { $0.categoryId == selected.id } } ?? expenses
        let totalsByMonth = Dictionary(grouping: filtered) { YearMonth(date: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        months = (0..<12).reversed().map { offset in
            let month = lastMonth.adding(months: -offset)
            return MonthTotal(month: month, total: totalsByMonth[month] ?? 0)
        }
        total = months.reduce(0) { $0 + $1.total }
        let activeMonths = months.filter { $0.total > 0 }.count
        average = activeMonths > 0 ? total / Double(activeMonths) : 0
    }
}
