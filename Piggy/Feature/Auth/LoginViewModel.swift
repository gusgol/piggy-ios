import Foundation
import Observation

// Android parallel: feature/auth/LoginViewModel.kt
//
// Android's `LoginUiState(isLoading, error)` data class plus `MutableStateFlow` collapses into
// plain stored properties. `@Observable` makes each one individually observable, so there's
// no need to bundle them into one state object and `copy()` it on every change.
@Observable
final class LoginViewModel {
    private(set) var isLoading = false
    var errorMessage: String?

    private let authRepository: any AuthRepository
    private let googleSignInLauncher: GoogleSignInLauncher

    init(authRepository: any AuthRepository, googleSignInLauncher: GoogleSignInLauncher = .init()) {
        self.authRepository = authRepository
        self.googleSignInLauncher = googleSignInLauncher
    }

    // Android uses `fun signIn() { viewModelScope.launch { ... } }`. Here the function is
    // `async`, and the View starts the Task. The work is identical; only who owns the
    // coroutine/Task differs.
    //
    // On success there's nothing to do: RootView's auth listener sees the new user and swaps
    // to MainTabView. That's the same single-source-of-truth flow as Android's `user == null` gate.
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        // `defer` runs when the scope exits, by any path. It's like Kotlin's `try { } finally { }`.
        defer { isLoading = false }

        do {
            let tokens = try await googleSignInLauncher.signIn()
            _ = try await authRepository.signInWithGoogle(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken
            )
        } catch GoogleSignInLauncherError.canceled {
            // Don't show an error if the user just canceled.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
