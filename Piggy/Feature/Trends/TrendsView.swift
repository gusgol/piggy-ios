import SwiftUI

/// Trends tab: Month and Year views behind a segmented control.
struct TrendsView: View {
    @Environment(\.expenseRepository) private var expenseRepository
    @Environment(\.categoryRepository) private var categoryRepository
    @Environment(\.userSession) private var userSession

    @State private var viewModel: TrendsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                TrendsContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Trends")
        .onAppear {
            if viewModel == nil {
                viewModel = TrendsViewModel(
                    expenseRepository: expenseRepository,
                    categoryRepository: categoryRepository,
                    userSession: userSession
                )
            }
        }
    }
}

private struct TrendsContent: View {
    @Bindable var viewModel: TrendsViewModel

    var body: some View {
        List {
            // Android parallel: PrimaryTabRow. iOS switches between views of the *same* data with a
            // segmented control (Health's D/W/M/Y, Calendar's Day/Week/Month), not tabs.
            Section {
                Picker("Period", selection: $viewModel.mode) {
                    ForEach(TrendsViewModel.Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            switch viewModel.mode {
            case .month:
                MonthTrendsSections(viewModel: viewModel)
            case .year:
                YearTrendsSections(viewModel: viewModel)
            }
        }
        .animation(.default, value: viewModel.mode)
        // The listeners live on the List, not on the sections inside it. List rows are created
        // lazily and discarded when scrolled off screen, so a `.task` attached to a row would be
        // cancelled mid-scroll. The List itself lives as long as the screen.
        .task(id: viewModel.listenerKey) {
            await viewModel.observeExpenses()
        }
        .task {
            await viewModel.observeCategories()
        }
    }
}
