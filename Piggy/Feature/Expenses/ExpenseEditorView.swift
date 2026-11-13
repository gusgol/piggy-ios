import SwiftUI

/// Add or edit an expense, presented as a sheet.
///
/// Android parallel: ExpenseEditorBottomSheet. The iOS form conventions used here:
/// - `NavigationStack` + `Form` inside a `.sheet`, so the system handles keyboard avoidance,
///   scrolling, row styling, and the grabber/detents.
/// - Cancel (`.cancellationAction`) and Save (`.confirmationAction`) in the toolbar. The system
///   places them correctly and makes Save bold.
/// - Form state lives in local `@State`. A simple form doesn't need its own ViewModel; the caller
///   supplies async `onSave` / `onDelete` closures and the sheet only handles input and validation.
struct ExpenseEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(Expense)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let expense): expense.id
            }
        }
    }

    let mode: Mode
    let categories: [Category]
    let onSave: (ExpenseFormData) async throws -> Void
    let onDelete: (Expense) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var amountText: String
    @State private var date: Date
    @State private var categoryID: String?
    @State private var isFixed: Bool

    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    // Android parallel: FocusRequester. Lets the sheet put the cursor in the amount field on open.
    @FocusState private var focusedField: Field?
    private enum Field { case amount, name }

    init(
        mode: Mode,
        categories: [Category],
        onSave: @escaping (ExpenseFormData) async throws -> Void,
        onDelete: @escaping (Expense) async throws -> Void
    ) {
        self.mode = mode
        self.categories = categories
        self.onSave = onSave
        self.onDelete = onDelete

        // `State(initialValue:)` seeds @State from init parameters. It only takes effect the
        // first time the view appears; later inits with new values are ignored, which is what
        // you want for a draft form.
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _amountText = State(initialValue: "")
            _date = State(initialValue: .now)
            _categoryID = State(initialValue: categories.first?.id)
            _isFixed = State(initialValue: false)
        case .edit(let expense):
            _name = State(initialValue: expense.name)
            _amountText = State(initialValue: expense.amount.formatted(.number.grouping(.never).precision(.fractionLength(0...2))))
            _date = State(initialValue: expense.date)
            _categoryID = State(initialValue: expense.categoryId)
            _isFixed = State(initialValue: expense.isFixed)
        }
    }

    // MARK: Validation

    /// Parses with the user's locale, so "12,50" works in pt-BR and "12.50" in en-US.
    private var amount: Double? {
        guard let value = try? Double(amountText, format: .number), value > 0 else { return nil }
        return value
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var form: ExpenseFormData? {
        guard let amount, !trimmedName.isEmpty, let categoryID else { return nil }
        return ExpenseFormData(name: trimmedName, amount: amount, date: date, categoryId: categoryID, isFixed: isFixed)
    }

    private var editingExpense: Expense? {
        if case .edit(let expense) = mode { return expense }
        return nil
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Locale.current.currencySymbol ?? "$")
                            .font(.amount(.title2))
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .font(.amount(.largeTitle, weight: .bold))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .accessibilityLabel("Amount")
                    }
                }

                Section {
                    TextField("Name", text: $name, prompt: Text("e.g. Groceries, Metro pass"))
                        .focused($focusedField, equals: .name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)

                    if categories.isEmpty {
                        LabeledContent("Category", value: "No categories yet")
                    } else {
                        Picker("Category", selection: $categoryID) {
                            ForEach(categories) { category in
                                Text("\(category.icon) \(category.name)")
                                    .tag(Optional(category.id))
                            }
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } footer: {
                    if categories.isEmpty {
                        Text("Create a category in the Categories tab first.")
                    }
                }

                Section {
                    Toggle("Fixed expense", isOn: $isFixed)
                } footer: {
                    Text("A recurring bill, like rent or utilities.")
                }

                if editingExpense != nil {
                    Section {
                        Button("Delete Expense", role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(editingExpense == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isWorking {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(form == nil)
                    }
                }
            }
            .disabled(isWorking)
            // Swipe-to-dismiss would silently drop a half-written expense. Block it while saving.
            .interactiveDismissDisabled(isWorking)
            .confirmationDialog("Delete this expense?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Expense", role: .destructive) { delete() }
            } message: {
                Text("This can't be undone.")
            }
            .alert(
                "Couldn't save",
                isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if editingExpense == nil { focusedField = .amount }
            }
        }
    }

    // MARK: Actions

    private func save() {
        guard let form else { return }
        perform { try await onSave(form) }
    }

    private func delete() {
        guard let editingExpense else { return }
        perform { try await onDelete(editingExpense) }
    }

    /// Runs the operation, keeping the sheet open (with the error) if it fails.
    private func perform(_ operation: @escaping () async throws -> Void) {
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await operation()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview("Add") {
    ExpenseEditorView(
        mode: .add,
        categories: [
            Category(id: "c1", name: "Groceries", createdAt: .now, userId: "u", icon: "🛒", color: "#059669"),
            Category(id: "c2", name: "Housing", createdAt: .now, userId: "u", icon: "🏠", color: "#F43F5E"),
        ],
        onSave: { _ in },
        onDelete: { _ in }
    )
}

#Preview("Edit") {
    ExpenseEditorView(
        mode: .edit(.previewFixed),
        categories: [Category(id: "c2", name: "Housing", createdAt: .now, userId: "u", icon: "🏠", color: "#F43F5E")],
        onSave: { _ in },
        onDelete: { _ in }
    )
}
