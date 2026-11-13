import Foundation

// Android parallel: core/domain/repository/CategoryRepository.kt
protocol CategoryRepository {
    func observeCategories(userId: String) -> AsyncThrowingStream<[Category], Error>
    func getCategories(userId: String) async throws -> [Category]
    func updateCategory(_ category: Category) async throws
    func addCategory(userId: String, name: String, icon: String, color: String) async throws -> Category
    func deleteCategory(categoryId: String) async throws
}
