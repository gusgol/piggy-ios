import Foundation

// Android parallel: `sealed interface Screen` in PiggyDestinations.kt.
//
// The tabs (Expenses / Categories / Trends) are not routes here. On Android they're entries
// in one shared back stack; on iOS each tab owns its own NavigationStack, so only the
// screens that get *pushed* need a route.
//
// `Hashable` is required because NavigationStack stores the path as `[AppRoute]` and
// diffs it, which is the same reason Navigation3 keys must be stable and comparable.
enum AppRoute: Hashable {
    case settings
    case importExpenses(initialURLs: [URL] = [])
}
