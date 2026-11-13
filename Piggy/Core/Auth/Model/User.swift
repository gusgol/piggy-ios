import Foundation

// Android parallel: core/auth/model/User.kt
//
// `photoUrl: String?` → `photoURL: URL?`. Using URL directly means `AsyncImage(url:)` can take
// it as-is later. Swift's API guidelines spell acronyms in uppercase (`URL`, `ID` in type names).
nonisolated struct User: Identifiable, Hashable, Sendable {
    let id: String
    var email: String?
    var displayName: String?
    var photoURL: URL?
    var isEmailVerified: Bool = false
}
