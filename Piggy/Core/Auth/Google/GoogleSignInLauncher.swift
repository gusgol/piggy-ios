import UIKit
import GoogleSignIn

nonisolated struct GoogleTokens: Sendable {
    let idToken: String
    let accessToken: String
}

enum GoogleSignInLauncherError: LocalizedError {
    /// The user closed the Google sheet. Not a real error; the UI should stay silent.
    case canceled
    case noPresentingViewController
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .canceled: "Sign-in was canceled."
        case .noPresentingViewController: "Couldn't show the Google sign-in screen."
        case .missingIDToken: "Google didn't return an ID token."
        }
    }
}

// Android parallel: core/auth/google/GoogleSignInLauncher.kt (Credential Manager).
//
// Runs the interactive Google flow and returns tokens. It knows nothing about Firebase;
// AuthRepository turns the tokens into a Firebase session.
//
// Android's launcher takes an `Activity` because Credential Manager needs a UI context.
// Google's iOS SDK needs a UIViewController for the same reason, but SwiftUI views don't
// own one. Instead of threading one through, the launcher finds the top-most view
// controller of the active window itself.
struct GoogleSignInLauncher {
    func signIn() async throws -> GoogleTokens {
        guard let presenter = Self.topViewController() else {
            throw GoogleSignInLauncherError.noPresentingViewController
        }

        let result: GIDSignInResult
        do {
            // The ObjC `signInWithPresentingViewController:completion:` is imported into Swift
            // as `async throws` automatically. Swift does this for any ObjC method whose last
            // parameter is a completion handler, much like a hand-written
            // `suspendCancellableCoroutine` wrapper in Kotlin.
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch let error as GIDSignInError where error.code == .canceled {
            // Android parallel: `catch (e: GetCredentialCancellationException)`
            throw GoogleSignInLauncherError.canceled
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInLauncherError.missingIDToken
        }
        return GoogleTokens(idToken: idToken, accessToken: result.user.accessToken.tokenString)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
