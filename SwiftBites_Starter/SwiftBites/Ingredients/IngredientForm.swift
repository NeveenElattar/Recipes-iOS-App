import SwiftUI
import SwiftData

struct IngredientForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Binding var ingredient: Ingredient?
    
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ingredient name", text: $name)
            }
            .navigationTitle(ingredient == nil ? "New Ingredient" : "Edit Ingredient")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if ingredient != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            deleteIngredient()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveIngredient()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing = ingredient {
                    name = existing.name
                }
            }
        }
    }

    private func saveIngredient() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let existing = ingredient {
            existing.name = trimmed
        } else {
            let newIngredient = Ingredient(name: trimmed)
            context.insert(newIngredient)
        }

        try? context.save()
        dismiss()
    }

    private func deleteIngredient() {
        if let existing = ingredient {
            context.delete(existing)
            try? context.save()
        }
        dismiss()
    }
}
