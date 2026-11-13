import Foundation
import Observation

// Android parallel: HomeViewModel's `user: StateFlow<User?>`.
//
// `@Observable` replaces the whole `_state` / `asStateFlow()` / `collectAsStateWithLifecycle()`
// chain. SwiftUI records which properties `body` reads and re-renders only when those
// properties change.
@Observable
final class RootViewModel {
    /// `private(set)` is the Swift equivalent of exposing a read-only `StateFlow` while
    /// keeping a private `MutableStateFlow`.
    private(set) var user: User?

    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
        // Firebase restores a persisted session synchronously during configure(), so this
        // is already correct on launch and the login screen doesn't flash.
        self.user = userSession.currentUserOrNull
    }

    /// Android parallel: `authState.stateIn(viewModelScope, ...)`.
    ///
    /// Called from the view's `.task { }`. That Task is tied to the view's lifetime (like
    /// `viewModelScope` / `repeatOnLifecycle`), so the loop ends and the Firebase listener is
    /// removed automatically when the view goes away.
    func observeAuthState() async {
        for await user in userSession.authState {
            self.user = user
        }
    }
}
