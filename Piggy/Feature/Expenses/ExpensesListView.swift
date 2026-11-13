import SwiftUI

// Placeholder. Built in Phase 2 (Expenses CRUD).
struct ExpensesListView: View {
    var body: some View {
        ContentUnavailableView("Expenses", systemImage: "list.bullet", description: Text("Coming in Phase 2"))
            .navigationTitle("Expenses")
    }
}

#Preview {
    NavigationStack { ExpensesListView() }
}
