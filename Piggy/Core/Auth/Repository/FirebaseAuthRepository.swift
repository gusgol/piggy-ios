import Foundation
import FirebaseAuth
import GoogleSignIn

// Android parallel: core/auth/repository/FirebaseAuthRepository.kt
//
// Name clash: FirebaseAuth also exports a type called `User`. Swift resolves an unqualified
// `User` to *this* module's type first, so `User` below is ours and Firebase's is spelled
// `FirebaseAuth.User`. (Kotlin avoids this because Firebase's is named `FirebaseUser`.)
final class FirebaseAuthRepository: AuthRepository {
    private let auth: Auth

    // Android parallel: `@Inject constructor(private val firebaseAuth: FirebaseAuth)`.
    // The default argument stands in for `@Provides fun provideFirebaseAuth()`.
    init(auth: Auth = .auth()) {
        self.auth = auth
    }

    var currentUser: User? {
        auth.currentUser.map(User.init(firebaseUser:))
    }

    // Android parallel: `callbackFlow { addAuthStateListener(...); awaitClose { remove... } }`
    //
    //   callbackFlow { }        → AsyncStream { continuation in }
    //   trySend(value)          → continuation.yield(value)
    //   awaitClose { cleanup }  → continuation.onTermination = { _ in cleanup }
    //
    // onTermination runs when the consuming Task is cancelled (e.g. the view's `.task`
    // ends because the view disappeared), just like awaitClose runs when the collector's
    // coroutine is cancelled.
    func authState() -> AsyncStream<User?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, firebaseUser in
                continuation.yield(firebaseUser.map(User.init(firebaseUser:)))
            }
            continuation.onTermination = { [auth] _ in
                auth.removeStateDidChangeListener(handle)
            }
        }
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> User {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        // Firebase's iOS SDK has native async APIs, so there's no `.await()` bridge
        // like kotlinx-coroutines-play-services.
        let result = try await auth.signIn(with: credential)
        return User(firebaseUser: result.user)
    }

    func signOut() throws {
        // Unlike Android's helper, GIDSignIn.signOut() can't fail, so there's no
        // try/catch fallback here.
        GIDSignIn.sharedInstance.signOut()
        try auth.signOut()
    }
}

// Android parallel: `private fun FirebaseUser.toUser(): User`.
// Swift's convention for "convert X to Y" is an initializer on Y.
private extension User {
    init(firebaseUser: FirebaseAuth.User) {
        self.init(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified
        )
    }
}
