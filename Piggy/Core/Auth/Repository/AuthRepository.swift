import Foundation

// Android parallel: core/auth/repository/AuthRepository.kt
//
// `suspend fun signInWithGoogle(idToken): Result<User>` → `async throws -> User`.
// Swift's `throws` already plays the role of Kotlin's `Result`: the caller writes
// `do { let user = try await repo.signInWithGoogle(...) } catch { ... }`,
// which is the equivalent of `result.onSuccess { }.onFailure { }`.
protocol AuthRepository {
    var currentUser: User? { get }

    /// Emits the current user immediately, then on every sign-in / sign-out.
    func authState() -> AsyncStream<User?>

    /// iOS's Google Sign-In SDK hands back both an ID token and an access token, and
    /// Firebase's iOS credential takes both. Android's Credential Manager only gives an ID token.
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> User

    func signOut() throws
}
