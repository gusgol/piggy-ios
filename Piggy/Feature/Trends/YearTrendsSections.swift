import SwiftUI
import Charts

/// Year view: 12 months of spending (optionally for one category), with an average line, then a
/// month-by-month list that drills into the Month view.
struct YearTrendsSections: View {
    @Bindable var viewModel: TrendsViewModel

    var body: some View {
        let trends = viewModel.yearTrends

        Section {
            Picker("Category", selection: $viewModel.yearCategoryID) {
                Text("All Categories").tag(String?.none)
                ForEach(trends.categoryOptions) { option in
                    Text("\(option.icon ?? "") \(option.name)").tag(Optional(option.id))
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Statistic(title: "Last 12 months", value: trends.total, prominent: true)
                    Spacer()
                    Statistic(title: "Monthly average", value: trends.average, prominent: false)
                }

                if viewModel.loadState == .loading && trends.total == 0 {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                } else if case .failed(let message) = viewModel.loadState {
                    ContentUnavailableView("Couldn't Load Trends", systemImage: "exclamationmark.triangle", description: Text(message))
                } else if trends.total == 0 {
                    ContentUnavailableView("No Spending", systemImage: "chart.bar", description: Text("Nothing recorded in the last 12 months."))
                } else {
                    MonthlyBarChart(trends: trends)
                        .frame(height: 220)
                }
            }
            .padding(.vertical, 4)
        }

        if trends.total > 0 {
            Section {
                ForEach(trends.months.reversed()) { month in
                    Button {
                        viewModel.open(month.month)
                    } label: {
                        HStack {
                            Text(month.month.formatted)
                            Spacer()
                            Text(month.total, format: .localCurrency)
                                .monospacedDigit()
                                .foregroundStyle(month.total > 0 ? .primary : .tertiary)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .tint(.primary)
                    .accessibilityHint("Shows this month's breakdown")
                }
            } header: {
                Text("By Month")
            }
        }
    }
}

private struct Statistic: View {
    let title: LocalizedStringKey
    let value: Double
    let prominent: Bool

    var body: some View {
        VStack(alignment: prominent ? .leading : .trailing, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value, format: .localCurrency)
                .font(prominent ? .amount(.title, weight: .bold) : .amount(.title3))
                // Amounts must never wrap ("R$" alone on one line). Shrink a little instead.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText(value: value))
                .animation(.default, value: value)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MonthlyBarChart: View {
    let trends: YearTrends

    @State private var selectedDate: Date?

    private var selectedMonth: YearTrends.MonthTotal? {
        guard let selectedDate else { return nil }
        let month = YearMonth(date: selectedDate)
        return trends.months.first { $0.month == month }
    }

    /// Bars use the selected category's color, or the app's accent for all categories.
    private var barColor: Color {
        guard let category = trends.selectedCategory else { return Color(.accent) }
        return CategoryColorPalette(colorHex: category.colorHex, categoryName: category.name).chart
    }

    var body: some View {
        let selected = selectedMonth

        Chart {
            ForEach(trends.months) { month in
                BarMark(
                    x: .value("Month", month.date, unit: .month),
                    y: .value("Amount", month.total)
                )
                .foregroundStyle(barColor.gradient)
                .cornerRadius(4)
                .opacity(selected == nil || selected?.id == month.id ? 1 : 0.4)
                .accessibilityLabel(month.month.formatted)
                .accessibilityValue(Text(month.total, format: .localCurrency))
            }

            // Average line, as in Screen Time and Health.
            if trends.average > 0, selected == nil {
                RuleMark(y: .value("Average", trends.average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .top, alignment: .leading) {
                        Text("avg")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
            }

            if let selected {
                RuleMark(x: .value("Month", selected.date, unit: .month))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .zIndex(-1)
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selected.month.formatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selected.total, format: .localCurrency)
                                .font(.amount(.headline))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: .rect(cornerRadius: 10, style: .continuous))
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                // Single-letter month labels (J F M A …) fit 12 bars on a phone, as in Health.
                AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
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
        .animation(.default, value: trends.selectedCategory?.id)
    }
}
