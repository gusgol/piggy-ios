//
//  PiggyApp.swift
//  Piggy
//
//  Created by Gustavo on 12/11/26.
//

import SwiftUI
import FirebaseCore

// Android parallel: Firebase auto-initializes via FirebaseInitProvider (a ContentProvider)
// merged into the manifest. On iOS there's no such hook, so we call configure() explicitly
// before any Firebase API is touched. It reads GoogleService-Info.plist from the bundle.
@main
struct PiggyApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
