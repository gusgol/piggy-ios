import Foundation
import Observation

@Observable
final class ExpensesListViewModel {
    struct DaySection: Identifiable {
        let day: Date
        let expenses: [Expense]
        var id: Date { day }
    }

    // MARK: State
    //
    // Plain stored properties. `@Observable` tracks each one individually, and a view re-renders
    // only when a property its `body` actually read has changed.

    /// Changing the month restarts the expenses listener: the view runs
    /// `.task(id: viewModel.month) { await viewModel.observeExpenses() }`, and SwiftUI cancels
    /// the old task and starts a new one whenever `id` changes.
    /// That's the iOS replacement for `selectedMonth.flatMapLatest { ... }`.
    var month: YearMonth = .now()
    var selectedCategoryID: String?
    var mutationError: String?

    private(set) var expenses: [Expense] = []
    private(set) var categories: [Category] = []
    private(set) var loadState: LoadState = .loading

    // MARK: Derived state
    //
    // Computed from the stored properties above. Observation records that `summary` reads
    // `expenses`, `categories` and `selectedCategoryID`, so views using it update when any of them do.

    var summary: MonthlyExpensesSummary {
        MonthlyExpensesSummary(expenses: expenses, categories: categories, selectedCategoryID: selectedCategoryID)
    }

    /// Visible expenses grouped by calendar day, newest day first (as in Wallet or Mail).
    var daySections: [DaySection] {
        let calendar = Calendar.current
        return Dictionary(grouping: summary.visibleExpenses) { calendar.startOfDay(for: $0.date) }
            .map { DaySection(day: $0.key, expenses: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var isCurrentMonth: Bool { month == .now() }

    // MARK: Dependencies

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository
    private let userSession: UserSession

    init(expenseRepository: any ExpenseRepository, categoryRepository: any CategoryRepository, userSession: UserSession) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.userSession = userSession
    }

    // MARK: Observation (called from the view's `.task`s)

    func observeExpenses() async {
        loadState = .loading
        expenses = []
        do {
            let userId = try userSession.userId
            for try await expenses in expenseRepository.observeExpenses(userId: userId, month: month) {
                self.expenses = expenses
                loadState = .loaded
            }
            // The loop also ends normally when the task is cancelled (month changed, view gone).
        } catch {
            loadState = .failed(message: error.localizedDescription)
        }
    }

    func observeCategories() async {
        do {
            let userId = try userSession.userId
            for try await categories in categoryRepository.observeCategories(userId: userId) {
                self.categories = categories
            }
        } catch {
            // Expenses still work without categories (rows fall back to first letters), so this is
            // non-fatal, matching Android's `.catch { emit(emptyList()) }`.
            categories = []
        }
    }

    // MARK: Intents

    func showPreviousMonth() { month = month.previous }
    func showNextMonth() { month = month.next }
    func showCurrentMonth() { month = .now() }

    /// Throws so the editor sheet can stay open and show the error. On success the live listener
    /// already reflects the change, so nothing needs reloading.
    func save(_ form: ExpenseFormData, editing original: Expense?) async throws {
        if let original {
            let update = ExpenseUpdate(from: original, to: form)
            guard !update.isEmpty else { return }
            try await expenseRepository.updateExpense(expenseId: original.id, update: update)
        } else {
            _ = try await expenseRepository.addExpense(userId: try userSession.userId, form: form)
        }
    }

    /// Used by swipe-to-delete, which has no sheet to report errors in, so this surfaces them as an alert.
    func delete(_ expense: Expense) async {
        do {
            try await expenseRepository.deleteExpense(expenseId: expense.id)
        } catch {
            mutationError = error.localizedDescription
        }
    }

    /// Used by the editor sheet, which shows its own error.
    func deleteFromEditor(_ expense: Expense) async throws {
        try await expenseRepository.deleteExpense(expenseId: expense.id)
    }
}
