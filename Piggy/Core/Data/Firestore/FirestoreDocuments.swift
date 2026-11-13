import Foundation
import FirebaseFirestore

// Firestore's Swift SDK integrates with `Codable`: `snapshot.data(as: ExpenseDocument.self)` decodes a
// document and `Firestore.Encoder().encode(doc)` encodes one. Field names come from the property
// names, so these structs *are* the schema. They must match what the Android app writes, since
// both apps share the same database.
//
//   @DocumentID      → filled with the document's ID on decode, skipped on encode
//   @ServerTimestamp → nil on encode means "server, set this to your clock" (FieldValue.serverTimestamp())
//   Date             ↔ Firestore Timestamp, converted automatically
//
// These are kept separate from the domain models (Expense / Category) so that Firebase types never
// leak into views and ViewModels. Swapping the backend would only touch Core/Data.

nonisolated struct ExpenseDocument: Codable {
    @DocumentID var id: String?
    var name: String
    var amount: Double
    var date: Date
    var categoryId: String
    var isFixed: Bool?
    @ServerTimestamp var createdAt: Date?
    var userId: String

    enum Field {
        static let userId = "userId"
        static let name = "name"
        static let amount = "amount"
        static let date = "date"
        static let categoryId = "categoryId"
        static let isFixed = "isFixed"
    }
}

nonisolated struct CategoryDocument: Codable {
    @DocumentID var id: String?
    var name: String
    var icon: String
    var color: String
    @ServerTimestamp var createdAt: Date?
    var userId: String

    enum Field {
        static let userId = "userId"
        static let name = "name"
        static let icon = "icon"
        static let color = "color"
    }
}

// MARK: - Domain mapping

nonisolated extension ExpenseDocument {
    init(form: ExpenseFormData, userId: String) {
        self.init(
            name: form.name,
            amount: form.amount,
            date: form.date,
            categoryId: form.categoryId,
            isFixed: form.isFixed,
            createdAt: nil, // → server timestamp
            userId: userId
        )
    }

    /// nil for a document that hasn't been assigned an ID (never the case for fetched documents).
    var expense: Expense? {
        guard let id else { return nil }
        return Expense(
            id: id,
            name: name,
            amount: amount,
            date: date,
            categoryId: categoryId,
            isFixed: isFixed ?? false,
            createdAt: createdAt ?? .now,
            userId: userId
        )
    }
}

nonisolated extension CategoryDocument {
    var category: Category? {
        guard let id else { return nil }
        return Category(id: id, name: name, createdAt: createdAt ?? .now, userId: userId, icon: icon, color: color)
    }
}

nonisolated extension QuerySnapshot {
    /// Decodes every document, skipping malformed ones instead of failing the whole list
    /// (one bad document written by an old app version shouldn't blank the screen).
    func decoded<Document: Decodable, Model>(_ type: Document.Type, _ toModel: (Document) -> Model?) -> [Model] {
        documents.compactMap { snapshot in
            (try? snapshot.data(as: type)).flatMap(toModel)
        }
    }
}
