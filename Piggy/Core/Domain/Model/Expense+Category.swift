import Foundation

nonisolated extension Array where Element == Expense {
    /// Copies each expense's category name, icon, and color onto it (expense documents only store
    /// `categoryId`). Expenses whose category no longer exists are left as they are.
    ///
    /// Android does this inside the repository by combining the expenses and categories flows.
    /// Here, screens already observe both lists, so joining them is a pure function they call.
    func enriched(with categories: [Category]) -> [Expense] {
        let categoriesByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return map { expense in
            guard let category = categoriesByID[expense.categoryId] else { return expense }
            var copy = expense
            copy.categoryName = category.name
            copy.categoryIcon = category.icon
            copy.categoryColor = category.color
            return copy
        }
    }
}
