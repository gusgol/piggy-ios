import SwiftUI

/// Month switcher, the month's total, and the fixed vs. variable split.
struct ExpensesSummarySection: View {
    let month: YearMonth
    let summary: MonthlyExpensesSummary
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onCurrent: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                MonthSwitcher(month: month, onPrevious: onPrevious, onNext: onNext, onCurrent: onCurrent)
                total
                if summary.total > 0 {
                    SpendingSplitView(
                        fixedTotal: summary.fixedTotal,
                        variableTotal: summary.variableTotal,
                        fixedFraction: summary.fixedFraction
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var total: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total spent")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(summary.total, format: .localCurrency)
                .font(.amount(.largeTitle, weight: .bold))
                // Digits roll when the value changes (like the Stocks or Fitness apps).
                .contentTransition(.numericText(value: summary.total))
                .animation(.default, value: summary.total)
            Text("^[\(summary.expenseCount) expense](inflect: true)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

}

/// The "Smart Piggy Insight" from Android, as a simple list section.
struct ExpensesInsightSection: View {
    let insight: MonthlyExpensesSummary.Insight

    var body: some View {
        Section {
            Label {
                Text(message)
                    .font(.subheadline)
            } icon: {
                Image(systemName: "lightbulb.max.fill")
                    .foregroundStyle(.yellow)
            }
        } header: {
            Text("Insight")
        }
    }

    private var message: String {
        switch insight {
        case .allFixed(let amount):
            "All \(amount.formatted(.localCurrency)) spent this month comes from fixed costs."
        case .mostlyFixed(let percentage, let variable):
            "Fixed costs make up \(percentage)% of this month, keeping variable spending to \(variable.formatted(.localCurrency))."
        case .topCategory(let name, let amount, let share, let isVariable):
            isVariable
                ? "\(name) leads your variable spending at \(amount.formatted(.localCurrency)) (\(share)% of this month)."
                : "\(name) is your largest category this month at \(amount.formatted(.localCurrency)) (\(share)% of total)."
        }
    }
}

#Preview {
    let summary = MonthlyExpensesSummary(expenses: [.preview, .previewFixed], categories: [], selectedCategoryID: nil)
    List {
        ExpensesSummarySection(month: .now(), summary: summary,
                               onPrevious: {}, onNext: {}, onCurrent: {})
        if let insight = summary.insight {
            ExpensesInsightSection(insight: insight)
        }
    }
}
