import SwiftUI

enum AppTab: Hashable {
    case expenses, categories, trends
}

// Android parallel: HomeScreen + PiggyBottomBar + the tab-switching branch of PiggyNavigation.
//
// Android keeps one back stack and clears it on tab switch. iOS's convention is the
// opposite: each tab keeps its own NavigationStack, so switching tabs and coming back
// preserves where you were.
struct MainTabView: View {
    let user: User

    @State private var selectedTab: AppTab = .expenses

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Expenses", systemImage: "list.bullet", value: .expenses) {
                TabStack(user: user) { ExpensesListView() }
            }
            Tab("Categories", systemImage: "tag", value: .categories) {
                TabStack(user: user) { CategoriesView() }
            }
            Tab("Trends", systemImage: "chart.bar", value: .trends) {
                TabStack(user: user) { TrendsView() }
            }
        }
        // iPhone: floating Liquid Glass tab bar. iPad: adapts to a sidebar.
        .tabViewStyle(.sidebarAdaptable)
    }
}

/// One NavigationStack per tab, with the shared avatar → Settings button and route table.
///
/// Android parallel: the `NavDisplay(entryProvider = { key -> when (key) { ... } })` block.
/// `navigationDestination(for:)` is that `when`, mapping each route to its screen.
private struct TabStack<Root: View>: View {
    let user: User
    @ViewBuilder let root: () -> Root

    // Android parallel: `rememberNavBackStack(...)`. Pushing is `path.append(route)` and
    // popping is `path.removeLast()`, the same operations as `backStack.add` / `removeLastOrNull`.
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            root()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: AppRoute.settings) {
                            AvatarView(url: user.photoURL)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings:
                        SettingsView()
                    case .importExpenses:
                        // Phase 5
                        ContentUnavailableView("Import", systemImage: "square.and.arrow.down")
                    }
                }
        }
    }
}

private struct AvatarView: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
        .frame(width: 28, height: 28)
        .clipShape(.circle)
    }
}
