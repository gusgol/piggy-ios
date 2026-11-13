import SwiftUI

// Placeholder. Built in Phase 3 (Categories).
struct CategoriesView: View {
    var body: some View {
        ContentUnavailableView("Categories", systemImage: "tag", description: Text("Coming in Phase 3"))
            .navigationTitle("Categories")
    }
}

#Preview {
    NavigationStack { CategoriesView() }
}
