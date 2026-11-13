import Foundation

// Android parallel: core/domain/model/Category.kt
nonisolated struct Category: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    let createdAt: Date
    let userId: String
    var icon: String
    var color: String
}
