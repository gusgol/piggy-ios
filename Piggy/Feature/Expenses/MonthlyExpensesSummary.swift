import Foundation

/// Everything the Expenses screen derives from one month of raw data: totals, the fixed/variable
/// split, category filter options, the filtered list, and a spending insight.
///
/// Android parallel: `BuildMonthlyExpensesProjectionUseCase` + `MonthlyExpensesProjection`.
///
/// On iOS this is a plain value type with an initializer: pure input in, derived values out.
/// It doesn't need to be an injectable "use case" class, because it has no dependencies to inject.
/// That also makes it trivially unit-testable.
///
/// The ViewModel exposes it as a *computed* property, so Observation recomputes it whenever
/// `expenses`, `categories` or `selectedCategoryID` change. That replaces Android's
/// `combine(...)` of four flows.
nonisolated struct MonthlyExpensesSummary: Hashable, Sendable {
    struct CategoryFilter: Identifiable, Hashable, Sendable {
        let id: String
        let name: String
        let icon: String?
        let colorHex: String?
        let expenseCount: Int
    }

    enum Insight: Hashable, Sendable {
        /// Every expense this month is fixed.
        case allFixed(amount: Double)
        /// Fixed costs dominate (≥ 65%), so variable spending is under control.
        case mostlyFixed(fixedPercentage: Int, variableAmount: Double)
        /// The category with the largest share, among variable expenses when there are any.
        case topCategory(name: String, amount: Double, sharePercentage: Int, isVariable: Bool)
    }

    // Totals cover the whole month, regardless of the category filter.
    let total: Double
    let fixedTotal: Double
    let variableTotal: Double
    /// 0...1
    let fixedFraction: Double
    let expenseCount: Int

    let categoryFilters: [CategoryFilter]
    /// The selected filter, or nil if it no longer matches any category.
    let selectedCategoryID: String?
    /// Expenses after applying the category filter, enriched with category name/icon/color.
    let visibleExpenses: [Expense]
    let insight: Insight?

    init(expenses: [Expense], categories: [Category], selectedCategoryID: String?) {
        fixedTotal = expenses.filter(\.isFixed).reduce(0) { $0 + $1.amount }
        variableTotal = expenses.filter { !$0.isFixed }.reduce(0) { $0 + $1.amount }
        total = fixedTotal + variableTotal
        fixedFraction = total > 0 ? min(max(fixedTotal / total, 0), 1) : 0
        expenseCount = expenses.count

        let categoriesByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let enriched = expenses.enriched(with: categories)

        // Filter options: the user's categories, plus a fallback for expenses that point to a
        // deleted (or not-yet-synced) category. Categories in use come first; the original
        // order is kept within each group, so pills don't jump around when tapped.
        let expensesByCategory = Dictionary(grouping: enriched, by: \.categoryId)
        let known = categories.map {
            CategoryFilter(id: $0.id, name: $0.name, icon: $0.icon, colorHex: $0.color,
                           expenseCount: expensesByCategory[$0.id]?.count ?? 0)
        }
        let orphaned = expensesByCategory
            .filter { id, _ in !id.isEmpty && categoriesByID[id] == nil }
            .sorted { $0.key < $1.key }
            .map { id, items in
                CategoryFilter(id: id, name: items[0].categoryName ?? "Other", icon: items[0].categoryIcon,
                               colorHex: items[0].categoryColor, expenseCount: items.count)
            }
        let all = known + orphaned
        // A local constant, not `self.categoryFilters`: closures can't capture `self` until every
        // stored property is initialized. Swift enforces this at compile time.
        let filters = all.filter { $0.expenseCount > 0 } + all.filter { $0.expenseCount == 0 }
        categoryFilters = filters

        let effectiveSelection = selectedCategoryID.flatMap { id in
            filters.contains { $0.id == id } ? id : nil
        }
        self.selectedCategoryID = effectiveSelection
        visibleExpenses = effectiveSelection.map { id in enriched.filter { $0.categoryId == id } } ?? enriched

        insight = Self.insight(
            for: enriched, total: total, fixedTotal: fixedTotal,
            variableTotal: variableTotal, fixedFraction: fixedFraction
        )
    }

    private static func insight(
        for expenses: [Expense],
        total: Double,
        fixedTotal: Double,
        variableTotal: Double,
        fixedFraction: Double
    ) -> Insight? {
        guard !expenses.isEmpty, total > 0 else { return nil }

        if variableTotal <= 0, fixedTotal > 0 {
            return .allFixed(amount: fixedTotal)
        }
        if fixedFraction >= 0.65 {
            return .mostlyFixed(fixedPercentage: Int((fixedFraction * 100).rounded()), variableAmount: variableTotal)
        }

        func topCategory(of items: [Expense], isVariable: Bool) -> Insight? {
            let totals = Dictionary(grouping: items, by: \.categoryId)
                .mapValues { ($0.reduce(0) { $0 + $1.amount }, $0[0]) }
            guard let (amount, sample) = totals.values.max(by: { $0.0 < $1.0 }), amount > 0 else { return nil }
            let share = min(max(Int((amount / total * 100).rounded()), 1), 100)
            return .topCategory(name: sample.categoryName ?? "Other", amount: amount, sharePercentage: share, isVariable: isVariable)
        }

        return topCategory(of: expenses.filter { !$0.isFixed }, isVariable: true)
            ?? topCategory(of: expenses, isVariable: false)
    }
}
