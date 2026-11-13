import SwiftUI
import GoogleSignInSwift

// Android parallel: `LoginScreen` (stateful, owns the ViewModel) + `LoginScreenContent`
// (stateless). Same split, same reason: the content view can be previewed without Firebase.
struct LoginView: View {
    @Environment(\.authRepository) private var authRepository
    @State private var viewModel: LoginViewModel?

    var body: some View {
        LoginContent(
            isLoading: viewModel?.isLoading ?? false,
            errorMessage: viewModel?.errorMessage,
            onGoogleSignIn: {
                Task { await viewModel?.signInWithGoogle() }
            },
            onErrorDismiss: { viewModel?.errorMessage = nil }
        )
        .onAppear {
            if viewModel == nil {
                viewModel = LoginViewModel(authRepository: authRepository)
            }
        }
    }
}

struct LoginContent: View {
    let isLoading: Bool
    let errorMessage: String?
    let onGoogleSignIn: () -> Void
    let onErrorDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Piggy")
                    .font(.largeTitle.bold())
                Text("Track where your money goes.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                // Google's official branded button, from GoogleSignInSwift. Its branding
                // guidelines require using their button rather than a custom one.
                GoogleSignInButton(
                    scheme: colorScheme == .dark ? .dark : .light,
                    style: .wide,
                    state: isLoading ? .disabled : .normal,
                    action: onGoogleSignIn
                )
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                }
            }
            .frame(maxWidth: 384)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .alert(
            "Sign-in failed",
            isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { onErrorDismiss() } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

// Android parallel: `@Preview` of `LoginScreenContent`. These previews never touch Firebase.
#Preview("Idle") {
    LoginContent(isLoading: false, errorMessage: nil, onGoogleSignIn: {}, onErrorDismiss: {})
}

#Preview("Loading") {
    LoginContent(isLoading: true, errorMessage: nil, onGoogleSignIn: {}, onErrorDismiss: {})
}
