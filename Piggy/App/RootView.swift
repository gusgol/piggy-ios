import SwiftUI

// Android parallel: the `if (user == null) { LoginScreen(); return }` gate at the top of
// PiggyNavigation.
struct RootView: View {
    @Environment(\.userSession) private var userSession

    // The ViewModel is created in `.task` rather than as `@State var vm = RootViewModel(...)`,
    // because the environment (`userSession`) isn't readable until the view is in the
    // hierarchy. That's the trade-off of environment-based DI compared to Hilt's
    // constructor injection.
    @State private var viewModel: RootViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if let user = viewModel.user {
                    MainTabView(user: user)
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.default, value: viewModel?.user?.id)
        .task {
            let viewModel = RootViewModel(userSession: userSession)
            self.viewModel = viewModel
            await viewModel.observeAuthState()
        }
    }
}
