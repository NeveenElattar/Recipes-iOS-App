import SwiftUI
import SwiftData

struct CategoryForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var categoryToEdit: Category?

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $name)
            }
            .navigationTitle(categoryToEdit == nil ? "Add Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let category = categoryToEdit {
                    name = category.name
                }
            }
        }
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let categoryToEdit {
            // Editing existing
            categoryToEdit.name = trimmedName
        } else {
            // Adding new
            let newCategory = Category(name: trimmedName)
            context.insert(newCategory)
        }

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save category: \(error)")
        }
    }
}
