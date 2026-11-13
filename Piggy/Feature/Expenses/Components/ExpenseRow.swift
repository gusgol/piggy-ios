import SwiftUI

/// One expense in the list: category avatar, name, category (+ "Fixed"), and amount.
///
/// Built from standard pieces so it behaves like a system list row: Dynamic Type, VoiceOver,
/// swipe actions and selection highlight all come from `List`.
struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            CategoryAvatar(icon: expense.categoryIcon, name: expense.categoryName, colorHex: expense.categoryColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(expense.categoryName ?? "Uncategorized")
                    if expense.isFixed {
                        Text("·")
                        Text("Fixed")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(expense.amount, format: .localCurrency)
                .font(.body.monospacedDigit())
        }
        // Read as one element: "Groceries run, Groceries, Fixed, R$ 120,00".
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
extension Expense {
    static let preview = Expense(
        id: "1", name: "Whole Foods Market", amount: 84.32, date: .now, categoryId: "c1",
        isFixed: false, createdAt: .now, userId: "u",
        categoryName: "Groceries", categoryIcon: "🛒", categoryColor: "#059669"
    )
    static let previewFixed = Expense(
        id: "2", name: "Rent", amount: 1850, date: .now, categoryId: "c2",
        isFixed: true, createdAt: .now, userId: "u",
        categoryName: "Housing", categoryIcon: "🏠", categoryColor: "#F43F5E"
    )
}
#endif

#Preview {
    List {
        ExpenseRow(expense: .preview)
        ExpenseRow(expense: .previewFixed)
    }
}
