import SwiftUI
import Charts

/// Month view: total + category donut, daily stacked bars, and a per-category breakdown.
///
/// Android draws both charts by hand on a Compose Canvas (`drawArc`, `drawRect`). Swift Charts
/// describes them declaratively instead: you list *marks* (SectorMark, BarMark, RuleMark) bound to
/// data, and the framework handles layout, axes, animation, Dark Mode, and accessibility (VoiceOver
/// reads each mark, and Audio Graphs come for free).
struct MonthTrendsSections: View {
    let viewModel: TrendsViewModel

    var body: some View {
        let trends = viewModel.monthTrends

        Section {
            VStack(spacing: 16) {
                MonthSwitcher(
                    month: viewModel.month,
                    onPrevious: viewModel.showPreviousMonth,
                    onNext: viewModel.showNextMonth,
                    onCurrent: viewModel.showCurrentMonth
                )
                if trends.total > 0 {
                    CategoryDonutChart(trends: trends)
                        .frame(height: 240)
                } else if viewModel.loadState == .loaded {
                    ContentUnavailableView("No Spending", systemImage: "chart.pie", description: Text("Nothing recorded in \(viewModel.month.formatted)."))
                } else if case .failed(let message) = viewModel.loadState {
                    ContentUnavailableView("Couldn't Load Trends", systemImage: "exclamationmark.triangle", description: Text(message))
                } else {
                    ProgressView().frame(height: 240)
                }
            }
            .padding(.vertical, 4)
        }

        if trends.total > 0 {
            Section {
                DailySpendingChart(trends: trends)
                    .frame(height: 200)
                    .padding(.vertical, 8)
            } header: {
                Text("Daily Spending")
            }

            Section {
                ForEach(trends.categories) { category in
                    CategoryBreakdownRow(category: category)
                }
            } header: {
                Text("By Category")
            }
        }
    }
}

// MARK: - Donut

private struct CategoryDonutChart: View {
    let trends: MonthTrends

    /// Set by `.chartAngleSelection` while the user touches the chart. It holds a position along the
    /// *data* axis (0...total), not an angle in degrees.
    @State private var selectedValue: Double?

    private var selectedCategory: MonthTrends.CategoryTotal? {
        guard let selectedValue else { return nil }
        var cumulative = 0.0
        for category in trends.categories {
            cumulative += category.total
            if selectedValue <= cumulative { return category }
        }
        return nil
    }

    var body: some View {
        let selected = selectedCategory

        Chart(trends.categories) { category in
            SectorMark(
                angle: .value("Amount", category.total),
                innerRadius: .ratio(0.64),
                outerRadius: .ratio(selected?.id == category.id ? 1 : 0.94),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(category.palette.chart)
            .opacity(selected == nil || selected?.id == category.id ? 1 : 0.35)
            .accessibilityLabel(category.name)
            .accessibilityValue(Text(category.total, format: .localCurrency))
        }
        .chartAngleSelection(value: $selectedValue)
        .overlay {
            // The donut's hole shows the total, or the touched category.
            VStack(spacing: 2) {
                if let selected {
                    Text("\(selected.icon ?? "") \(selected.name)")
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(selected.total, format: .localCurrency)
                        .font(.amount(.title2, weight: .bold))
                    Text(selected.share, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(trends.total, format: .localCurrency)
                        .font(.amount(.title2, weight: .bold))
                    Text("^[\(trends.expenseCount) expense](inflect: true)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 140)
            .minimumScaleFactor(0.7)
            .allowsHitTesting(false)
        }
        .animation(.snappy, value: selected?.id)
    }
}

// MARK: - Daily stacked bars

private struct DailySpendingChart: View {
    let trends: MonthTrends

    /// Set by `.chartXSelection` while the user drags across the chart.
    @State private var selectedDate: Date?

    private var selectedDay: Date? {
        selectedDate.map { Calendar.current.startOfDay(for: $0) }
    }

    var body: some View {
        Chart {
            ForEach(trends.daily) { item in
                // Bars sharing the same x value stack automatically.
                BarMark(
                    x: .value("Day", item.day, unit: .day),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(CategoryColorPalette(colorHex: item.colorHex, categoryName: item.categoryName).chart)
                .opacity(selectedDay == nil || selectedDay == item.day ? 1 : 0.4)
                .accessibilityLabel(Text("\(item.categoryName), \(item.day.formatted(.dateTime.day().month()))"))
                .accessibilityValue(Text(item.amount, format: .localCurrency))
            }

            if let selectedDay {
                RuleMark(x: .value("Day", selectedDay, unit: .day))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .zIndex(-1)
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        DayCallout(day: selectedDay, total: trends.dailyTotals[selectedDay] ?? 0)
                    }
            }
        }
        .chartXScale(domain: trends.month.startDate()...trends.month.endDate())
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .localCurrency.precision(.fractionLength(0)))
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
    }
}

private struct DayCallout: View {
    let day: Date
    let total: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(total, format: .localCurrency)
                .font(.amount(.headline))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: .rect(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Category breakdown

/// Android parallel: the expandable CategoryDetailCard. iOS's built-in equivalent is DisclosureGroup,
/// which inside a List gets the standard chevron, animation, and VoiceOver "expanded/collapsed" state.
private struct CategoryBreakdownRow: View {
    let category: MonthTrends.CategoryTotal

    var body: some View {
        DisclosureGroup {
            ForEach(category.expenses) { expense in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(expense.name)
                            .lineLimit(1)
                        Text(expense.date, format: .dateTime.day().month(.abbreviated))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(expense.amount, format: .localCurrency)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        } label: {
            HStack(spacing: 12) {
                CategoryAvatar(icon: category.icon, name: category.name, colorHex: category.colorHex, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                    Text("^[\(category.expenses.count) expense](inflect: true)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(category.total, format: .localCurrency)
                        .monospacedDigit()
                    Text(category.share, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.secondary) // Neutral chevron instead of the accent color.
    }
}
