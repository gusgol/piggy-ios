import Foundation
import FirebaseFirestore

/// Firestore-backed `ExpenseRepository`.
///
/// One class talks to Firestore directly. Android splits this into a RemoteDataSource and a
/// Repository that mostly forwards calls; on iOS that extra layer isn't conventional unless
/// there's a second data source (e.g. a SwiftData cache) to coordinate.
///
/// Every write is `async throws`, which Swift generates automatically from the Objective-C SDK's
/// `completion:` methods. The `await` resumes once the server acknowledges the write. Meanwhile
/// Firestore's local cache updates any live listener *immediately* (latency compensation), so the
/// list changes before the save finishes.
final class FirestoreExpenseRepository: ExpenseRepository {
    private static let batchLimit = 500
    private let collection: CollectionReference

    init(firestore: Firestore = .firestore()) {
        collection = firestore.collection("expenses")
    }

    // MARK: Reads

    func observeExpenses(userId: String, month: YearMonth, categoryId: String?) -> AsyncThrowingStream<[Expense], Error> {
        query(userId: userId, from: month.startDate(), to: month.endDate(), categoryId: categoryId)
            .stream { $0.decoded(ExpenseDocument.self, \.expense) }
    }

    func observeExpensesForRange(
        userId: String,
        startMonthInclusive: YearMonth,
        endMonthExclusive: YearMonth
    ) -> AsyncThrowingStream<[Expense], Error> {
        precondition(startMonthInclusive < endMonthExclusive, "The start month must be before the exclusive end month.")
        return query(userId: userId, from: startMonthInclusive.startDate(), to: endMonthExclusive.startDate(), categoryId: nil)
            .stream { $0.decoded(ExpenseDocument.self, \.expense) }
    }

    func getExpenses(userId: String, month: YearMonth, categoryId: String?) async throws -> [Expense] {
        try await query(userId: userId, from: month.startDate(), to: month.endDate(), categoryId: categoryId)
            .getDocuments()
            .decoded(ExpenseDocument.self, \.expense)
    }

    func getExpensesForRange(
        userId: String,
        startMonthInclusive: YearMonth,
        endMonthExclusive: YearMonth
    ) async throws -> [Expense] {
        precondition(startMonthInclusive < endMonthExclusive, "The start month must be before the exclusive end month.")
        return try await query(userId: userId, from: startMonthInclusive.startDate(), to: endMonthExclusive.startDate(), categoryId: nil)
            .getDocuments()
            .decoded(ExpenseDocument.self, \.expense)
    }

    // MARK: Writes

    func addExpense(userId: String, form: ExpenseFormData) async throws -> Expense {
        let ref = collection.document()
        let document = ExpenseDocument(form: form, userId: userId)
        try await ref.setData(Firestore.Encoder().encode(document))
        return Expense(
            id: ref.documentID, name: form.name, amount: form.amount, date: form.date,
            categoryId: form.categoryId, isFixed: form.isFixed, createdAt: .now, userId: userId
        )
    }

    func addExpenses(userId: String, forms: [ExpenseFormData]) async throws -> [Expense] {
        var created: [Expense] = []
        // Firestore batches are atomic but capped at 500 writes.
        for start in stride(from: 0, to: forms.count, by: Self.batchLimit) {
            let chunk = forms[start..<min(start + Self.batchLimit, forms.count)]
            let batch = collection.firestore.batch()
            for form in chunk {
                let ref = collection.document()
                try batch.setData(from: ExpenseDocument(form: form, userId: userId), forDocument: ref)
                created.append(Expense(
                    id: ref.documentID, name: form.name, amount: form.amount, date: form.date,
                    categoryId: form.categoryId, isFixed: form.isFixed, createdAt: .now, userId: userId
                ))
            }
            try await batch.commit()
        }
        return created
    }

    func updateExpense(expenseId: String, update: ExpenseUpdate) async throws {
        typealias Field = ExpenseDocument.Field
        var fields: [String: Any] = [:]
        if let name = update.name { fields[Field.name] = name }
        if let amount = update.amount { fields[Field.amount] = amount }
        if let date = update.date { fields[Field.date] = Timestamp(date: date) }
        if let categoryId = update.categoryId { fields[Field.categoryId] = categoryId }
        if let isFixed = update.isFixed { fields[Field.isFixed] = isFixed }
        guard !fields.isEmpty else { return }

        try await collection.document(expenseId).updateData(fields)
    }

    func deleteExpense(expenseId: String) async throws {
        try await collection.document(expenseId).delete()
    }

    // MARK: Query

    /// Expenses in `[start, end)`, newest first. The (userId, date) composite index already exists,
    /// since the Android app runs the same query.
    private func query(userId: String, from start: Date, to end: Date, categoryId: String?) -> Query {
        typealias Field = ExpenseDocument.Field
        var query = collection
            .whereField(Field.userId, isEqualTo: userId)
            .whereField(Field.date, isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField(Field.date, isLessThan: Timestamp(date: end))
            .order(by: Field.date, descending: true)
        if let categoryId, !categoryId.isEmpty {
            query = query.whereField(Field.categoryId, isEqualTo: categoryId)
        }
        return query
    }
}
