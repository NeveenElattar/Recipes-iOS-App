import SwiftUI
import SwiftData

struct RecipesView: View {
    @State private var query = ""
    @State private var sortOption: SortOption = .name
    @State private var showAddRecipeForm = false
    @State private var selectedRecipeToEdit: Recipe?
    
    enum SortOption {
        case name, servingAsc, servingDesc, timeAsc, timeDesc
    }
    
    var body: some View {
        RecipesContentView(
            searchQuery: query,
            sortOption: sortOption,
            showAddRecipeForm: $showAddRecipeForm,
            selectedRecipeToEdit: $selectedRecipeToEdit
        ) {
            sortMenu
        }
        .searchable(text: $query, prompt: "Search")
    }
    
    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu("Sort", systemImage: "arrow.up.arrow.down") {
            Button("Name") { sortOption = .name }
            Button("Serving (low → high)") { sortOption = .servingAsc }
            Button("Serving (high → low)") { sortOption = .servingDesc }
            Button("Time (short → long)") { sortOption = .timeAsc }
            Button("Time (long → short)") { sortOption = .timeDesc }
        }
    }
}

// MARK: - Content View with #Predicate filtering
private struct RecipesContentView<SortMenuView: View>: View {
    @Environment(\.modelContext) private var context
    
    let searchQuery: String
    let sortOption: RecipesView.SortOption
    @Binding var showAddRecipeForm: Bool
    @Binding var selectedRecipeToEdit: Recipe?
    let sortMenu: SortMenuView
    
    @Query private var filteredRecipes: [Recipe]
    @Query private var allRecipes: [Recipe]
    
    init(
        searchQuery: String,
        sortOption: RecipesView.SortOption,
        showAddRecipeForm: Binding<Bool>,
        selectedRecipeToEdit: Binding<Recipe?>,
        @ViewBuilder sortMenu: () -> SortMenuView
    ) {
        self.searchQuery = searchQuery
        self.sortOption = sortOption
        _showAddRecipeForm = showAddRecipeForm
        _selectedRecipeToEdit = selectedRecipeToEdit
        self.sortMenu = sortMenu()
        
        // Use #Predicate to filter recipes
        if searchQuery.isEmpty {
            let predicate = #Predicate<Recipe> { _ in
                true
            }
            _filteredRecipes = Query(filter: predicate, sort: [SortDescriptor(\Recipe.name)])
        } else {
            let predicate = #Predicate<Recipe> { recipe in
                recipe.name.localizedStandardContains(searchQuery) ||
                recipe.summary.localizedStandardContains(searchQuery)
            }
            _filteredRecipes = Query(filter: predicate, sort: [SortDescriptor(\Recipe.name)])
        }
        
        _allRecipes = Query(sort: [SortDescriptor(\Recipe.name)])
    }
    
    private var sortedRecipes: [Recipe] {
        sortRecipes(filteredRecipes)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        sortMenu
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddRecipeForm = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddRecipeForm) {
                    RecipeForm(mode: .add)
                }
                .sheet(item: $selectedRecipeToEdit) { recipe in
                    RecipeForm(mode: .edit(recipe))
                }
        }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        let recipesToShow = sortedRecipes
        
        if allRecipes.isEmpty {
            emptyView
        } else if recipesToShow.isEmpty {
            emptySearchView
        } else {
            list(for: recipesToShow)
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("No Recipes", systemImage: "list.clipboard")
            },
            description: {
                Text("Recipes you add will appear here.")
            },
            actions: {
                Button("Add Recipe") {
                    showAddRecipeForm = true
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
    
    // MARK: - Empty Search View
    private var emptySearchView: some View {
        ContentUnavailableView(
            label: {
                Label("No Results", systemImage: "magnifyingglass")
            },
            description: {
                Text("No recipes match '\(searchQuery)'")
            }
        )
    }
    
    // MARK: - Recipe List
    private func list(for recipes: [Recipe]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(recipes) { recipe in
                    RecipeCell(recipe: recipe) { selectedRecipe in
                        selectedRecipeToEdit = selectedRecipe
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Sorting Logic
    private func sortRecipes(_ recipes: [Recipe]) -> [Recipe] {
        switch sortOption {
        case .name:
            return recipes.sorted { $0.name < $1.name }
        case .servingAsc:
            return recipes.sorted { $0.serving < $1.serving }
        case .servingDesc:
            return recipes.sorted { $0.serving > $1.serving }
        case .timeAsc:
            return recipes.sorted { $0.time < $1.time }
        case .timeDesc:
            return recipes.sorted { $0.time > $1.time }
        }
    }
}
