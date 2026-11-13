import Foundation
import Observation

@Observable
final class TrendsViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case month, year
        var id: Self { self }
        var title: String {
            switch self {
            case .month: "Month"
            case .year: "Year"
            }
        }
    }

    /// What the view's listener depends on. Changing either restarts it via `.task(id:)`.
    struct ListenerKey: Equatable {
        let mode: Mode
        let month: YearMonth
    }

    var mode: Mode = .month
    var month: YearMonth = .now()
    var yearCategoryID: String?

    private(set) var monthExpenses: [Expense] = []
    private(set) var yearExpenses: [Expense] = []
    private(set) var categories: [Category] = []
    private(set) var loadState: LoadState = .loading

    var listenerKey: ListenerKey { ListenerKey(mode: mode, month: month) }

    /// The 12 months ending with the current one.
    var yearRange: (first: YearMonth, last: YearMonth) {
        let last = YearMonth.now()
        return (last.adding(months: -11), last)
    }

    var monthTrends: MonthTrends {
        MonthTrends(month: month, expenses: monthExpenses, categories: categories)
    }

    var yearTrends: YearTrends {
        YearTrends(endingAt: yearRange.last, expenses: yearExpenses, categories: categories, categoryID: yearCategoryID)
    }

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository
    private let userSession: UserSession

    init(expenseRepository: any ExpenseRepository, categoryRepository: any CategoryRepository, userSession: UserSession) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.userSession = userSession
    }

    // MARK: Listeners

    /// Observes whatever the current mode needs. Only one expenses listener runs at a time.
    func observeExpenses() async {
        loadState = .loading
        do {
            let userId = try userSession.userId
            switch mode {
            case .month:
                for try await expenses in expenseRepository.observeExpenses(userId: userId, month: month) {
                    monthExpenses = expenses
                    loadState = .loaded
                }
            case .year:
                let range = yearRange
                let stream = expenseRepository.observeExpensesForRange(
                    userId: userId, startMonthInclusive: range.first, endMonthExclusive: range.last.next
                )
                for try await expenses in stream {
                    yearExpenses = expenses
                    loadState = .loaded
                }
            }
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
            categories = [] // Non-fatal: charts fall back to "Other" and name-based colors.
        }
    }

    // MARK: Intents

    func showPreviousMonth() { month = month.previous }
    func showNextMonth() { month = month.next }
    func showCurrentMonth() { month = .now() }

    /// From the Year view's month list: drill into that month.
    func open(_ month: YearMonth) {
        self.month = month
        mode = .month
    }
}
