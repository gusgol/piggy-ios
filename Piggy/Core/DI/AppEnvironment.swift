import SwiftUI

// Android parallel: Hilt's SingletonComponent. These are AuthModule.kt + DataModule.kt
// collapsed into one place.
//
// Why a container instead of `@Entry var x = FirebaseAuthRepository()` directly:
// `@Entry` expands to an EnvironmentKey whose `defaultValue` is a *computed* property.
// Its initializer expression runs again on every read that has no override, so you'd get
// a new repository (and a new auth listener) each time. Hilt's `@Singleton` has no
// equivalent pitfall. A `static let` is lazily created exactly once, and it's
// thread-safe, so the container gives us the singleton scope back.
//
// Laziness also matters for ordering. `Auth.auth()` crashes if `FirebaseApp.configure()`
// hasn't run yet. `PiggyApp.init()` runs first, and nothing touches `live` before a view
// reads the environment.
final class AppDependencies {
    static let live = AppDependencies()

    let authRepository: any AuthRepository
    let userSession: UserSession
    // expenseRepository / categoryRepository are added in Phase 2, along with their
    // Firestore implementations.

    private init() {
        let authRepository = FirebaseAuthRepository()
        self.authRepository = authRepository
        self.userSession = UserSession(authRepository: authRepository)
    }
}

// Android parallel: `@Binds abstract fun bindAuthRepository(impl): AuthRepository`
//
// Views read these with `@Environment(\.authRepository) private var authRepository`.
// Tests and previews override them with `.environment(\.authRepository, FakeAuthRepository())`,
// like `@TestInstallIn` or `CompositionLocalProvider`.
//
// Previews: Firebase isn't configured in the preview canvas, so any preview of a view that
// reads these keys must override them with a fake.
extension EnvironmentValues {
    @Entry var authRepository: any AuthRepository = AppDependencies.live.authRepository
    @Entry var userSession: UserSession = AppDependencies.live.userSession
}
