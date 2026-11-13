import Foundation
import FirebaseFirestore

/// Firestore-backed `CategoryRepository`. See FirestoreExpenseRepository for the general approach.
final class FirestoreCategoryRepository: CategoryRepository {
    private let collection: CollectionReference

    init(firestore: Firestore = .firestore()) {
        collection = firestore.collection("categories")
    }

    func observeCategories(userId: String) -> AsyncThrowingStream<[Category], Error> {
        query(userId: userId).stream { $0.decoded(CategoryDocument.self, \.category) }
    }

    func getCategories(userId: String) async throws -> [Category] {
        try await query(userId: userId).getDocuments().decoded(CategoryDocument.self, \.category)
    }

    func updateCategory(_ category: Category) async throws {
        typealias Field = CategoryDocument.Field
        try await collection.document(category.id).setData(
            [Field.name: category.name, Field.icon: category.icon, Field.color: category.color],
            merge: true
        )
    }

    func addCategory(userId: String, name: String, icon: String, color: String) async throws -> Category {
        let ref = collection.document()
        let document = CategoryDocument(name: name, icon: icon, color: color, createdAt: nil, userId: userId)
        try await ref.setData(Firestore.Encoder().encode(document))
        return Category(id: ref.documentID, name: name, createdAt: .now, userId: userId, icon: icon, color: color)
    }

    func deleteCategory(categoryId: String) async throws {
        try await collection.document(categoryId).delete()
    }

    private func query(userId: String) -> Query {
        collection
            .whereField(CategoryDocument.Field.userId, isEqualTo: userId)
            .order(by: CategoryDocument.Field.name)
    }
}
