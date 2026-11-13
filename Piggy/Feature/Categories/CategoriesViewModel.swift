import Foundation
import Observation

@Observable
final class CategoriesViewModel {
    private(set) var categories: [Category] = []
    private(set) var loadState: LoadState = .loading
    var searchText = ""
    var mutationError: String?

    /// Backs `.searchable`. `localizedStandardContains` is what Finder and Files use: case- and
    /// diacritic-insensitive, so "cafe" finds "Café".
    var visibleCategories: [Category] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return categories }
        return categories.filter { $0.name.localizedStandardContains(query) }
    }

    private let categoryRepository: any CategoryRepository
    private let userSession: UserSession

    init(categoryRepository: any CategoryRepository, userSession: UserSession) {
        self.categoryRepository = categoryRepository
        self.userSession = userSession
    }

    func observeCategories() async {
        loadState = .loading
        do {
            let userId = try userSession.userId
            for try await categories in categoryRepository.observeCategories(userId: userId) {
                self.categories = categories
                loadState = .loaded
            }
        } catch {
            loadState = .failed(message: error.localizedDescription)
        }
    }

    func save(name: String, icon: String, color: String, editing original: Category?) async throws {
        if let original {
            var updated = original
            updated.name = name
            updated.icon = icon
            updated.color = color
            guard updated != original else { return }
            try await categoryRepository.updateCategory(updated)
        } else {
            _ = try await categoryRepository.addCategory(userId: try userSession.userId, name: name, icon: icon, color: color)
        }
    }

    /// From swipe-to-delete, so errors go to an alert on the list.
    func delete(_ category: Category) async {
        do {
            try await categoryRepository.deleteCategory(categoryId: category.id)
        } catch {
            mutationError = error.localizedDescription
        }
    }

    /// From the editor sheet, which shows its own error.
    func deleteFromEditor(_ category: Category) async throws {
        try await categoryRepository.deleteCategory(categoryId: category.id)
    }
}
