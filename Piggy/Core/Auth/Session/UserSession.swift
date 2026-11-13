import Foundation

enum UserSessionError: Error {
    case notSignedIn
}

// Android parallel: core/auth/session/UserSession.kt
//
// Provides a centralized way to access the current user's information and session state.
// This simplifies repositories and use cases by removing the need to manually check auth state.
final class UserSession {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    /// The current user, or nil if not authenticated.
    var currentUserOrNull: User? {
        authRepository.currentUser
    }

    /// The current user. Throws if not authenticated.
    ///
    /// Kotlin getters can throw silently. Swift needs an effectful `get throws`, so callers
    /// must write `try session.currentUser`, which makes the failure point visible.
    var currentUser: User {
        get throws {
            guard let user = authRepository.currentUser else { throw UserSessionError.notSignedIn }
            return user
        }
    }

    /// The current user's ID. Throws if not authenticated.
    var userId: String {
        get throws { try currentUser.id }
    }

    /// A stream of the current authentication state.
    ///
    /// This is a computed property, unlike Kotlin's `val authState = repo.authState()`.
    /// A Kotlin cold Flow can be collected any number of times, but an AsyncStream supports
    /// only ONE consumer. So each caller gets a fresh stream, backed by its own listener.
    var authState: AsyncStream<User?> {
        authRepository.authState()
    }

    var isSignedIn: Bool {
        authRepository.currentUser != nil
    }
}
