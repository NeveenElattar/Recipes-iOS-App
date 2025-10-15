import SwiftUI
import SwiftData

struct IngredientsView: View {
    typealias Selection = (Ingredient) -> Void

    let selection: Selection?

    @State private var searchText = ""
    @State private var selectedIngredientForEdit: Ingredient?
    @State private var showForm = false

    init(selection: Selection? = nil) {
        self.selection = selection
    }

    var body: some View {
        IngredientsContentView(
            searchQuery: searchText,
            selection: selection,
            selectedIngredientForEdit: $selectedIngredientForEdit,
            showForm: $showForm
        )
        .searchable(text: $searchText, prompt: "Search ingredients")
    }
}

// MARK: - Content View with #Predicate filtering
private struct IngredientsContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let searchQuery: String
    let selection: IngredientsView.Selection?
    @Binding var selectedIngredientForEdit: Ingredient?
    @Binding var showForm: Bool
    
    @Query private var filteredIngredients: [Ingredient]
    @Query(sort: [SortDescriptor(\Ingredient.name)]) private var allIngredients: [Ingredient]
    
    init(
        searchQuery: String,
        selection: IngredientsView.Selection?,
        selectedIngredientForEdit: Binding<Ingredient?>,
        showForm: Binding<Bool>
    ) {
        self.searchQuery = searchQuery
        self.selection = selection
        _selectedIngredientForEdit = selectedIngredientForEdit
        _showForm = showForm
        
        // Use #Predicate to filter ingredients
        if searchQuery.isEmpty {
            let predicate = #Predicate<Ingredient> { _ in
                true
            }
            _filteredIngredients = Query(filter: predicate, sort: [SortDescriptor(\Ingredient.name)])
        } else {
            let predicate = #Predicate<Ingredient> { ingredient in
                ingredient.name.localizedStandardContains(searchQuery)
            }
            _filteredIngredients = Query(filter: predicate, sort: [SortDescriptor(\Ingredient.name)])
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allIngredients.isEmpty {
                    if selection == nil {
                        emptyIngredientsView
                    } else {
                        Text("No ingredients available")
                            .foregroundStyle(.secondary)
                    }
                } else if filteredIngredients.isEmpty {
                    emptySearchView
                } else {
                    ingredientsList
                }
            }
            .navigationTitle("Ingredients")
            .toolbar {
                if selection == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedIngredientForEdit = nil
                            showForm = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                IngredientForm(ingredient: $selectedIngredientForEdit)
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyIngredientsView: some View {
        ContentUnavailableView(
            label: {
                Label("No Ingredients", systemImage: "carrot")
            },
            description: {
                Text("Add ingredients to start building your recipes.")
            },
            actions: {
                Button("Add Ingredient") {
                    selectedIngredientForEdit = nil
                    showForm = true
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
    
    private var emptySearchView: some View {
        ContentUnavailableView(
            label: {
                Label("No Results", systemImage: "magnifyingglass")
            },
            description: {
                Text("No ingredients match '\(searchQuery)'")
            }
        )
    }
    
    // MARK: - Ingredients List
    private var ingredientsList: some View {
        List {
            ForEach(filteredIngredients) { ingredient in
                row(for: ingredient)
            }
            .onDelete(perform: selection == nil ? deleteIngredients : nil)
        }
    }

    @ViewBuilder
    private func row(for ingredient: Ingredient) -> some View {
        if let selection = selection {
            Button {
                selection(ingredient)
                dismiss()
            } label: {
                Text(ingredient.name)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                selectedIngredientForEdit = ingredient
                showForm = true
            } label: {
                Text(ingredient.name)
            }
            .buttonStyle(.plain)
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        guard selection == nil else { return }

        for index in offsets {
            let ingredient = filteredIngredients[index]
            context.delete(ingredient)
        }
        try? context.save()
    }
}
