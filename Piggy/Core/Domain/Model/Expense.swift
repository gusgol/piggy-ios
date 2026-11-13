import Foundation

// Android parallel: core/domain/model/Expense.kt
//
// `data class` → `struct`. Swift structs are value types (copied on assignment), so you get
// Kotlin's `copy()` semantics for free: `var e2 = e1; e2.name = "x"` never mutates `e1`.
// `Hashable` gives you `equals`/`hashCode`; `Identifiable` lets SwiftUI `List`/`ForEach`
// diff rows by `id` (like `key = { it.id }` in a LazyColumn).
//
// `java.time.Instant` → `Foundation.Date`. Despite the name, `Date` is a point in time
// (seconds since reference date), with no time zone — exactly what `Instant` is.
//
// `nonisolated` opts out of this target's default MainActor isolation so the model can be
// created on a background thread (e.g. inside a Firestore snapshot listener).
nonisolated struct Expense: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var amount: Double
    var date: Date
    var categoryId: String
    var isFixed: Bool
    let createdAt: Date
    let userId: String
    // Optional denormalized category fields for easier display
    var categoryName: String? = nil
    var categoryIcon: String? = nil
    var categoryColor: String? = nil
}

/// Shape for creating a new expense.
nonisolated struct ExpenseFormData: Hashable, Sendable {
    var name: String
    var amount: Double
    var date: Date
    var categoryId: String
    var isFixed: Bool
}

/// Partial update for an expense. Only non-nil fields will be updated.
nonisolated struct ExpenseUpdate: Hashable, Sendable {
    var name: String? = nil
    var amount: Double? = nil
    var date: Date? = nil
    var categoryId: String? = nil
    var isFixed: Bool? = nil
    var categoryName: String? = nil // allow updating denormalized field when category changes
}

nonisolated extension ExpenseUpdate {
    /// Only the fields that differ between the original and the edited form.
    init(from original: Expense, to form: ExpenseFormData) {
        self.init(
            name: form.name == original.name ? nil : form.name,
            amount: form.amount == original.amount ? nil : form.amount,
            date: form.date == original.date ? nil : form.date,
            categoryId: form.categoryId == original.categoryId ? nil : form.categoryId,
            isFixed: form.isFixed == original.isFixed ? nil : form.isFixed
        )
    }

    var isEmpty: Bool {
        name == nil && amount == nil && date == nil && categoryId == nil && isFixed == nil
    }
}
