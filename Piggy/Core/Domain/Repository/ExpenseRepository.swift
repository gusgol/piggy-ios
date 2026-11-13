import Foundation

// Android parallel: core/domain/repository/ExpenseRepository.kt
//
// - `interface` → `protocol`
// - `fun observe…(): Flow<List<Expense>>` → `AsyncThrowingStream<[Expense], Error>`.
//   Consumed with `for try await expenses in repo.observeExpenses(...)`, which is the
//   equivalent of `flow.collect { }`. Cancelling the consuming Task stops the stream
//   (like cancelling the collecting coroutine).
// - `suspend fun` → `async throws`. Kotlin exceptions are unchecked; Swift makes you
//   mark (`throws`) and acknowledge (`try`) every failure point.
protocol ExpenseRepository {
    func observeExpenses(
        userId: String,
        month: YearMonth,
        categoryId: String?
    ) -> AsyncThrowingStream<[Expense], Error>

    /// Observe expenses from the start month through the month before the exclusive end month.
    func observeExpensesForRange(
        userId: String,
        startMonthInclusive: YearMonth,
        endMonthExclusive: YearMonth
    ) -> AsyncThrowingStream<[Expense], Error>

    func getExpenses(
        userId: String,
        month: YearMonth,
        categoryId: String?
    ) async throws -> [Expense]

    /// Fetch expenses once from the start month through the month before the exclusive end month.
    func getExpensesForRange(
        userId: String,
        startMonthInclusive: YearMonth,
        endMonthExclusive: YearMonth
    ) async throws -> [Expense]

    func addExpense(userId: String, form: ExpenseFormData) async throws -> Expense

    func addExpenses(userId: String, forms: [ExpenseFormData]) async throws -> [Expense]

    func updateExpense(expenseId: String, update: ExpenseUpdate) async throws

    func deleteExpense(expenseId: String) async throws
}

// Protocol requirements can't declare default argument values (Kotlin interfaces can).
// The idiomatic workaround is an extension with overloads that forward the default.
extension ExpenseRepository {
    func observeExpenses(
        userId: String,
        month: YearMonth
    ) -> AsyncThrowingStream<[Expense], Error> {
        observeExpenses(userId: userId, month: month, categoryId: nil)
    }

    func getExpenses(userId: String, month: YearMonth) async throws -> [Expense] {
        try await getExpenses(userId: userId, month: month, categoryId: nil)
    }
}
