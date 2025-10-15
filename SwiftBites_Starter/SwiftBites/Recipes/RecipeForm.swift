import SwiftUI
import PhotosUI
import SwiftData

struct RecipeForm: View {
    enum Mode: Hashable {
        case add
        case edit(Recipe)
    }

    // MARK: - Environment
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Mode / state
    let mode: Mode

    @State private var name: String = ""
    @State private var summary: String = ""
    @State private var serving: Int = 1
    @State private var time: Int = 5
    @State private var instructions: String = ""
    @State private var selectedCategory: Category?
    @State private var ingredients: [RecipeIngredient] = []
    @State private var imageItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isIngredientsPickerPresented = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    private let title: String

    init(mode: Mode, preselectedCategory: Category? = nil) {
        self.mode = mode
        self._selectedCategory = State(initialValue: preselectedCategory)

        switch mode {
        case .add:
            title = "Add Recipe"
        case .edit(let recipe):
            title = "Edit \(recipe.name)"
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Form {
                        imageSection(width: geometry.size.width)
                        nameSection
                        summarySection
                        categorySection
                        servingAndTimeSection
                        ingredientsSection
                        instructionsSection
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                if case .edit(let recipe) = mode {
                    deleteButtonSection(recipe: recipe)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadDataIfNeeded)
            .onChange(of: imageItem) { _, _ in
                Task {
                    self.imageData = try? await imageItem?.loadTransferable(type: Data.self)
                }
            }
            .sheet(isPresented: $isIngredientsPickerPresented) {
                ingredientPicker()
            }
            .alert("Delete Recipe", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if case .edit(let recipe) = mode {
                        delete(recipe: recipe)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this recipe? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Sections & Subviews

    private func imageSection(width: CGFloat) -> some View {
        Section {
            PhotosPicker(selection: $imageItem, matching: .images) {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width)
                        .clipped()
                        .listRowInsets(EdgeInsets())
                        .frame(maxWidth: .infinity, minHeight: 200, idealHeight: 200, maxHeight: 200, alignment: .center)
                } else {
                    Label("Select Image", systemImage: "photo")
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            }

            if imageData != nil {
                Button(role: .destructive) {
                    imageData = nil
                } label: {
                    Text("Remove Image")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Margherita Pizza", text: $name)
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            TextField("Delicious blend of fresh basil, mozzarella, and tomato on a crispy crust.", text: $summary, axis: .vertical)
                .lineLimit(3...5)
        }
    }

    @Query(sort: \Category.name, order: .forward) private var categories: [Category]

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $selectedCategory) {
                Text("None").tag(nil as Category?)
                ForEach(categories) { cat in
                    Text(cat.name).tag(cat as Category?)
                }
            }
        }
    }

    private var servingAndTimeSection: some View {
        Section {
            HStack {
                Text("Servings: \(serving) person\(serving == 1 ? "" : "s")")
                Spacer()
                Stepper("", value: $serving, in: 1...100) {_ in 
                    EmptyView()
                }
                .labelsHidden()
            }
            HStack {
                Text("Time: \(time) minutes")
                Spacer()
                Stepper("", value: $time, in: 1...600, step: 1) {_ in 
                    EmptyView()
                }
                .labelsHidden()
            }
        }
        .monospacedDigit()
    }

    @ViewBuilder
    private var ingredientsSection: some View {
        Section("Ingredients") {
            if ingredients.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label("No Ingredients", systemImage: "list.clipboard")
                    },
                    description: {
                        Text("Recipe ingredients will appear here.")
                    },
                    actions: {
                        Button("Add Ingredient") {
                            isIngredientsPickerPresented = true
                        }
                    }
                )
            } else {
                ForEach(ingredients) { rel in
                    HStack {
                        Text(rel.ingredient?.name ?? "Unknown")
                            .bold()
                            .layoutPriority(2)
                        Spacer()
                        TextField("Quantity", text: Binding(
                            get: { rel.quantity },
                            set: { newVal in rel.quantity = newVal }
                        ))
                        .multilineTextAlignment(.trailing)
                        .layoutPriority(1)
                    }
                }
                .onDelete(perform: deleteIngredients)

                Button("Add Ingredient") {
                    isIngredientsPickerPresented = true
                }
            }
        }
    }

    private var instructionsSection: some View {
        Section("Instructions") {
            TextField(
                """
                1. Preheat the oven to 475°F (245°C).
                2. Roll out the dough on a floured surface.
                3. ...
                """,
                text: $instructions,
                axis: .vertical
            )
            .lineLimit(8...12)
        }
    }

    // MARK: - Delete Button Section (Bottom of Screen)
    private func deleteButtonSection(recipe: Recipe) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Recipe")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }

    private var deleteButton: some View {
        EmptyView()
    }

    // MARK: - Ingredient picker view
    private func ingredientPicker() -> some View {
        IngredientsView { selected in
            let newRelation = RecipeIngredient(ingredient: selected, quantity: "")
            ingredients.append(newRelation)
        }
    }

    // MARK: - Load / Save / Delete

    private func loadDataIfNeeded() {
        if case .edit(let recipe) = mode {
            name = recipe.name
            summary = recipe.summary
            serving = recipe.serving
            time = recipe.time
            instructions = recipe.instructions
            selectedCategory = recipe.category
            imageData = recipe.imageData
            ingredients = Array(recipe.ingredients)
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a name."
            return
        }

        switch mode {
        case .add:
            let newRecipe = Recipe(
                name: name,
                summary: summary,
                serving: serving,
                time: time,
                instructions: instructions,
                category: selectedCategory,
                ingredients: ingredients,
                imageData: imageData
            )
            context.insert(newRecipe)

        case .edit(let recipe):
            recipe.name = name
            recipe.summary = summary
            recipe.serving = serving
            recipe.time = time
            recipe.instructions = instructions
            recipe.category = selectedCategory
            recipe.imageData = imageData

            recipe.ingredients.removeAll()
            for rel in ingredients {
                recipe.ingredients.append(rel)
            }
        }

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func delete(recipe: Recipe) {
        context.delete(recipe)
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        withAnimation {
            ingredients.remove(atOffsets: offsets)
        }
    }
}
