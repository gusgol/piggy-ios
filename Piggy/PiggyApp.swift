//
//  PiggyApp.swift
//  Piggy
//
//  Created by Gustavo on 12/11/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

// Android parallel: Firebase auto-initializes via FirebaseInitProvider (a ContentProvider)
// merged into the manifest. On iOS there's no such hook, so we call configure() explicitly
// before any Firebase API is touched. It reads GoogleService-Info.plist from the bundle.
@main
struct PiggyApp: App {
    init() {
        FirebaseApp.configure()

        // Google Sign-In needs the OAuth client ID. It would otherwise look for a `GIDClientID`
        // key in Info.plist. Reading it from Firebase's options keeps GoogleService-Info.plist
        // as the single source of truth (Android reads `default_web_client_id`, generated
        // from google-services.json, for the same purpose).
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        PiggyTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // App-wide brand tint, the iOS counterpart of Material's `primary`. Buttons,
                // links, toggles, the selected tab and `.tint` fills all read it from the
                // environment. In principle the AccentColor asset is applied automatically
                // (build setting ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME), but in this
                // toolchain `Color.accentColor` still resolved to system blue, so it's set
                // explicitly. `.accent` is the symbol Xcode generates for the AccentColor asset.
                .tint(Color(.accent))
                // Hands the `com.googleusercontent.apps...` redirect back to the SDK.
                // This is why the URL scheme had to be registered in Info.plist.
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
