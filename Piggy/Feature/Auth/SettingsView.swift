import SwiftUI

// Minimal version: just enough to sign out (plan's verification step 5).
// SettingsViewModel, the profile header, and error states come in Phase 6.
struct SettingsView: View {
    @Environment(\.authRepository) private var authRepository
    @State private var signOutError: Error?

    var body: some View {
        List {
            Section {
                Button("Sign Out", role: .destructive) {
                    do {
                        // RootView's auth listener sees the change and swaps to LoginView.
                        // No navigation call needed, just like Android's `user == null` gate.
                        try authRepository.signOut()
                    } catch {
                        signOutError = error
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert(
            "Couldn't sign out",
            isPresented: .init(get: { signOutError != nil }, set: { if !$0 { signOutError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(signOutError?.localizedDescription ?? "")
        }
    }
}
