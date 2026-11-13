import SwiftUI

/// Add or edit a category: name, emoji, and color, with a live preview at the top.
///
/// Same sheet conventions as ExpenseEditorView (Form + NavigationStack, Cancel/Save in the toolbar,
/// local @State draft). The pickers follow Reminders' list editor: a grid of presets, plus a way to
/// go beyond them (any emoji from the keyboard, any color from the system ColorPicker).
struct CategoryEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(Category)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let category): category.id
            }
        }
    }

    static let maxNameLength = 30

    let mode: Mode
    let onSave: (_ name: String, _ icon: String, _ color: String) async throws -> Void
    let onDelete: (Category) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var customEmoji = ""

    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    init(
        mode: Mode,
        onSave: @escaping (_ name: String, _ icon: String, _ color: String) async throws -> Void,
        onDelete: @escaping (Category) async throws -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _icon = State(initialValue: CategoryPresets.emojis[0])
            _color = State(initialValue: CategoryPresets.colors[0])
        case .edit(let category):
            _name = State(initialValue: category.name)
            _icon = State(initialValue: category.icon)
            _color = State(initialValue: category.color)
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var editingCategory: Category? {
        if case .edit(let category) = mode { return category }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                previewHeader

                Section {
                    TextField("Name", text: $name, prompt: Text("e.g. Subscriptions, Pet Care, Gym"))
                        .textInputAutocapitalization(.words)
                        // Android parallel: `onValueChange = { if (it.length <= 30) name = it }`.
                        // SwiftUI bindings can't reject input, so trim right after the change.
                        .onChange(of: name) { _, newValue in
                            if newValue.count > Self.maxNameLength {
                                name = String(newValue.prefix(Self.maxNameLength))
                            }
                        }
                } footer: {
                    Text("\(name.count)/\(Self.maxNameLength)")
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                emojiSection
                colorSection

                if editingCategory != nil {
                    Section {
                        Button("Delete Category", role: .destructive) { isConfirmingDelete = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(editingCategory == nil ? "New Category" : "Edit Category")
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
                            .disabled(trimmedName.isEmpty)
                    }
                }
            }
            .disabled(isWorking)
            .interactiveDismissDisabled(isWorking)
            .confirmationDialog(
                "Delete \(editingCategory?.name ?? "this category")?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Category", role: .destructive) { delete() }
            } message: {
                Text(CategoryPresets.deleteWarning)
            }
            .alert(
                "Couldn't save",
                isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: Sections

    /// Live preview, like the large avatar at the top of a Contacts card.
    private var previewHeader: some View {
        Section {
            VStack(spacing: 10) {
                CategoryAvatar(icon: icon, name: trimmedName, colorHex: color, size: 80)
                Text(trimmedName.isEmpty ? "Category Name" : trimmedName)
                    .font(.brand(.title3))
                    .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .animation(.default, value: color)
        }
        // A header-style section: no row background, so it floats above the grouped rows.
        .listRowBackground(Color.clear)
    }

    private var emojiSection: some View {
        Section("Icon") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                ForEach(CategoryPresets.emojis, id: \.self) { emoji in
                    Button {
                        icon = emoji
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background {
                                if emoji == icon {
                                    Circle().fill(.tint.opacity(0.18))
                                    Circle().strokeBorder(.tint, lineWidth: 2)
                                }
                            }
                    }
                    // Several buttons in one Form row: `.plain` makes each one handle only its own taps.
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(emoji == icon ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)

            TextField("Or type any emoji", text: $customEmoji)
                .onChange(of: customEmoji) { _, newValue in
                    // A Swift `Character` is a whole grapheme cluster, so `last` returns 🏋️‍♂️ or 👩🏽‍💻 intact,
                    // even though they're made of several Unicode scalars. Kotlin's `String.last()` would
                    // return just the final UTF-16 code unit.
                    guard let last = newValue.last else { return }
                    icon = String(last)
                    if newValue.count > 1 { customEmoji = String(last) }
                }
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36), spacing: 12)], spacing: 12) {
                ForEach(Array(CategoryPresets.colors.enumerated()), id: \.element) { index, hex in
                    Button {
                        color = hex
                    } label: {
                        Circle()
                            .fill(Color(hexString: hex) ?? .gray)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if hex.caseInsensitiveCompare(color) == .orderedSame {
                                    Image(systemName: "checkmark")
                                        .font(.footnote.bold())
                                        .foregroundStyle(.black.opacity(0.65))
                                }
                            }
                            .overlay(Circle().strokeBorder(.primary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color \(index + 1)")
                    .accessibilityAddTraits(hex.caseInsensitiveCompare(color) == .orderedSame ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)

            // The system color picker (grid, spectrum, sliders, eyedropper), shown as a color well.
            ColorPicker(
                "Custom Color",
                selection: Binding(
                    get: { Color(hexString: color) ?? .gray },
                    set: { color = $0.hexString }
                ),
                supportsOpacity: false
            )
        }
    }

    // MARK: Actions

    private func save() {
        let name = trimmedName
        perform { try await onSave(name, icon, color) }
    }

    private func delete() {
        guard let editingCategory else { return }
        perform { try await onDelete(editingCategory) }
    }

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

/// Presets offered by the editor (the same set as Android, minus its duplicates).
nonisolated enum CategoryPresets {
    static let emojis = [
        "🏠", "🍔", "🛒", "🚗", "✈️", "🎬", "💊", "🎁", "👕", "💡", "📞", "🎓",
        "🐶", "🎉", "💼", "💸", "☕️", "🏋️‍♂️", "💅", "🚌", "🧾", "💖", "✨",
    ]

    static let colors = [
        "#FFADAD", "#FFD6A5", "#FDFFB6", "#CAFFBF", "#9BF6FF", "#A0C4FF", "#BDB2FF", "#FFC6FF",
        "#E7E7E7", "#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF", "#B5B9FF", "#FFB5E8",
        "#FF9AA2", "#FFB7B2", "#FFDAC1", "#E2F0CB", "#B5EAD7", "#C7CEEA", "#F3E4EA", "#F4C2C2",
        "#FFD1DC", "#FFABAB", "#FFC3A0", "#FFCCB6",
    ]

    static let deleteWarning = "Its expenses won't be deleted. They'll show under “Other” until you assign them a new category."
}

#Preview("Add") {
    CategoryEditorView(mode: .add, onSave: { _, _, _ in }, onDelete: { _ in })
}

#Preview("Edit") {
    CategoryEditorView(
        mode: .edit(Category(id: "c1", name: "Groceries", createdAt: .now, userId: "u", icon: "🛒", color: "#CAFFBF")),
        onSave: { _, _, _ in },
        onDelete: { _ in }
    )
}
