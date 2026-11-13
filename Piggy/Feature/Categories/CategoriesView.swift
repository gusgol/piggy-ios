import SwiftUI

/// Categories tab: creates the ViewModel from environment dependencies (same pattern as Expenses).
struct CategoriesView: View {
    @Environment(\.categoryRepository) private var categoryRepository
    @Environment(\.userSession) private var userSession

    @State private var viewModel: CategoriesViewModel?

    var body: some View {
        Group {
            if let viewModel {
                CategoriesContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Categories")
        .onAppear {
            if viewModel == nil {
                viewModel = CategoriesViewModel(categoryRepository: categoryRepository, userSession: userSession)
            }
        }
    }
}

private struct CategoriesContent: View {
    @Bindable var viewModel: CategoriesViewModel

    @State private var editor: CategoryEditorView.Mode?
    @State private var pendingDelete: Category?

    var body: some View {
        List {
            ForEach(viewModel.visibleCategories) { category in
                Button {
                    editor = .edit(category)
                } label: {
                    CategoryRow(category: category)
                }
                .tint(.primary)
                .swipeActions {
                    // Deleting a category affects its expenses, so swipe asks for confirmation
                    // instead of deleting immediately (unlike swiping an expense).
                    Button("Delete", systemImage: "trash") {
                        pendingDelete = category
                    }
                    .tint(.red)
                }
            }
        }
        // A search field under the large title. It hides as you scroll, like in Mail or Notes.
        .searchable(text: $viewModel.searchText, prompt: "Search categories")
        .overlay { emptyOrErrorState }
        .animation(.default, value: viewModel.visibleCategories.map(\.id))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Category", systemImage: "plus") { editor = .add }
            }
        }
        .sheet(item: $editor) { mode in
            CategoryEditorView(
                mode: mode,
                onSave: { name, icon, color in
                    let original: Category? = if case .edit(let category) = mode { category } else { nil }
                    try await viewModel.save(name: name, icon: icon, color: color, editing: original)
                },
                onDelete: { category in
                    try await viewModel.deleteFromEditor(category)
                }
            )
        }
        // `presenting:` passes the pending item into the dialog's closures, so the dialog always acts
        // on the category that was swiped, even if the list changes underneath it.
        .confirmationDialog(
            "Delete \(pendingDelete?.name ?? "category")?",
            isPresented: .init(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { category in
            Button("Delete Category", role: .destructive) {
                Task { await viewModel.delete(category) }
            }
        } message: { _ in
            Text(CategoryPresets.deleteWarning)
        }
        .alert(
            "Something went wrong",
            isPresented: .init(get: { viewModel.mutationError != nil }, set: { if !$0 { viewModel.mutationError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationError ?? "")
        }
        .task {
            await viewModel.observeCategories()
        }
    }

    @ViewBuilder
    private var emptyOrErrorState: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView("Couldn't Load Categories", systemImage: "exclamationmark.triangle", description: Text(message))
        case .loaded where viewModel.categories.isEmpty:
            ContentUnavailableView {
                Label("No Categories", systemImage: "tag")
            } description: {
                Text("Categories group your expenses, like Groceries or Rent.")
            } actions: {
                Button("Add Category") { editor = .add }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded where viewModel.visibleCategories.isEmpty:
            // The system's standard "no results" view for search.
            ContentUnavailableView.search(text: viewModel.searchText)
        case .loaded:
            EmptyView()
        }
    }
}

private struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            CategoryAvatar(icon: category.icon, name: category.name, colorHex: category.color)
            Text(category.name)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    List {
        CategoryRow(category: Category(id: "1", name: "Groceries", createdAt: .now, userId: "u", icon: "🛒", color: "#CAFFBF"))
        CategoryRow(category: Category(id: "2", name: "Housing", createdAt: .now, userId: "u", icon: "🏠", color: "#FFADAD"))
    }
}
