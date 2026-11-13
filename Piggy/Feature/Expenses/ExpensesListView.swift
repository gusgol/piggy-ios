import SwiftUI

/// Expenses tab: creates the ViewModel from environment dependencies, then hands off to the content.
struct ExpensesListView: View {
    @Environment(\.expenseRepository) private var expenseRepository
    @Environment(\.categoryRepository) private var categoryRepository
    @Environment(\.userSession) private var userSession

    @State private var viewModel: ExpensesListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ExpensesListContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Expenses")
        .onAppear {
            if viewModel == nil {
                viewModel = ExpensesListViewModel(
                    expenseRepository: expenseRepository,
                    categoryRepository: categoryRepository,
                    userSession: userSession
                )
            }
        }
    }
}

private struct ExpensesListContent: View {
    // `@Bindable` lets you derive bindings (`$viewModel.selectedCategoryID`) from an
    // @Observable object the view doesn't own. The owner (ExpensesListView) holds it in @State.
    @Bindable var viewModel: ExpensesListViewModel

    @State private var editor: ExpenseEditorView.Mode?

    var body: some View {
        let summary = viewModel.summary

        List {
            ExpensesSummarySection(
                month: viewModel.month,
                isCurrentMonth: viewModel.isCurrentMonth,
                summary: summary,
                onPrevious: viewModel.showPreviousMonth,
                onNext: viewModel.showNextMonth,
                onCurrent: viewModel.showCurrentMonth
            )

            if let insight = summary.insight, summary.selectedCategoryID == nil {
                ExpensesInsightSection(insight: insight)
            }

            ForEach(viewModel.daySections) { section in
                Section {
                    ForEach(section.expenses) { expense in
                        Button {
                            editor = .edit(expense)
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                        // Keeps the row's own colors instead of tinting all its text like a link.
                        .tint(.primary)
                        // Android: delete button inside the editor. iOS: swipe left on the row
                        // (full swipe deletes straight away, as in Mail).
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                Task { await viewModel.delete(expense) }
                            }
                        }
                    }
                } header: {
                    Text(section.day, format: .dateTime.weekday(.wide).day().month(.wide))
                }
            }
        }
        .overlay {
            emptyOrErrorState(summary: summary)
        }
        .animation(.default, value: summary.visibleExpenses.map(\.id))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu(summary: summary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add Expense", systemImage: "plus") {
                    editor = .add
                }
            }
        }
        .sheet(item: $editor) { mode in
            ExpenseEditorView(
                mode: mode,
                categories: viewModel.categories,
                onSave: { form in
                    let original: Expense? = if case .edit(let expense) = mode { expense } else { nil }
                    try await viewModel.save(form, editing: original)
                },
                onDelete: { expense in
                    try await viewModel.deleteFromEditor(expense)
                }
            )
        }
        .alert(
            "Something went wrong",
            isPresented: .init(get: { viewModel.mutationError != nil }, set: { if !$0 { viewModel.mutationError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationError ?? "")
        }
        // Two independent listeners, each tied to the view's lifetime.
        // `id:` restarts the expenses listener whenever the month changes.
        .task(id: viewModel.month) {
            await viewModel.observeExpenses()
        }
        .task {
            await viewModel.observeCategories()
        }
    }

    // MARK: Filter

    /// iOS's standard filter affordance: a toolbar menu holding a Picker. The icon fills in
    /// while a filter is active.
    private func filterMenu(summary: MonthlyExpensesSummary) -> some View {
        Menu {
            Picker("Category", selection: $viewModel.selectedCategoryID) {
                Text("All Categories").tag(String?.none)
                ForEach(summary.categoryFilters) { filter in
                    Text("\(filter.icon ?? "") \(filter.name) (\(filter.expenseCount))")
                        .tag(Optional(filter.id))
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: summary.selectedCategoryID == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    // MARK: Empty, loading & error states

    @ViewBuilder
    private func emptyOrErrorState(summary: MonthlyExpensesSummary) -> some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't Load Expenses", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { viewModel.showCurrentMonth() }
            }
        case .loaded where summary.expenseCount == 0:
            ContentUnavailableView {
                Label("No Expenses", systemImage: "tray")
            } description: {
                Text("No expenses in \(viewModel.month.formatted). Tap + to add one.")
            }
            // Leave room for the summary section so it stays visible above the empty state.
            .padding(.top, 240)
        case .loaded where summary.visibleExpenses.isEmpty:
            ContentUnavailableView {
                Label("No Matching Expenses", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("Nothing in this category this month.")
            } actions: {
                Button("Show All Categories") { viewModel.selectedCategoryID = nil }
            }
            .padding(.top, 240)
        case .loaded:
            EmptyView()
        }
    }
}
