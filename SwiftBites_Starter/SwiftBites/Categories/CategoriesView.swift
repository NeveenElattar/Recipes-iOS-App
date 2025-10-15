import SwiftUI
import SwiftData

struct CategoriesView: View {
    @State private var query = ""
    @State private var showCategoryForm = false
    @State private var showRecipeForm = false
    @State private var selectedCategory: Category?
    @State private var categoryForNewRecipe: Category?
    @State private var selectedRecipeToEdit: Recipe?
    
    var body: some View {
        CategoriesContentView(
            searchQuery: query,
            showCategoryForm: $showCategoryForm,
            showRecipeForm: $showRecipeForm,
            selectedCategory: $selectedCategory,
            categoryForNewRecipe: $categoryForNewRecipe,
            selectedRecipeToEdit: $selectedRecipeToEdit
        )
        .searchable(text: $query, prompt: "Search categories")
    }
}

// MARK: - Content View with #Predicate filtering
private struct CategoriesContentView: View {
    @Environment(\.modelContext) private var context
    
    let searchQuery: String
    @Binding var showCategoryForm: Bool
    @Binding var showRecipeForm: Bool
    @Binding var selectedCategory: Category?
    @Binding var categoryForNewRecipe: Category?
    @Binding var selectedRecipeToEdit: Recipe?
    
    @Query private var filteredCategories: [Category]
    @Query(sort: [SortDescriptor(\Category.name)]) private var allCategories: [Category]
    
    init(
        searchQuery: String,
        showCategoryForm: Binding<Bool>,
        showRecipeForm: Binding<Bool>,
        selectedCategory: Binding<Category?>,
        categoryForNewRecipe: Binding<Category?>,
        selectedRecipeToEdit: Binding<Recipe?>
    ) {
        self.searchQuery = searchQuery
        _showCategoryForm = showCategoryForm
        _showRecipeForm = showRecipeForm
        _selectedCategory = selectedCategory
        _categoryForNewRecipe = categoryForNewRecipe
        _selectedRecipeToEdit = selectedRecipeToEdit
        
        // Use #Predicate to filter categories
        if searchQuery.isEmpty {
            let predicate = #Predicate<Category> { _ in
                true
            }
            _filteredCategories = Query(filter: predicate, sort: [SortDescriptor(\Category.name)])
        } else {
            let predicate = #Predicate<Category> { category in
                category.name.localizedStandardContains(searchQuery)
            }
            _filteredCategories = Query(filter: predicate, sort: [SortDescriptor(\Category.name)])
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allCategories.isEmpty {
                    emptyView
                } else if filteredCategories.isEmpty {
                    emptySearchView
                } else {
                    listView
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedCategory = nil
                        showCategoryForm = true
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            // MARK: - Category Form Sheet
            .sheet(isPresented: $showCategoryForm) {
                CategoryForm(categoryToEdit: selectedCategory)
            }
            // MARK: - Recipe Form Sheet (Add)
            .sheet(isPresented: $showRecipeForm) {
                if let category = categoryForNewRecipe {
                    RecipeForm(mode: .add, preselectedCategory: category)
                        .onDisappear {
                            categoryForNewRecipe = nil
                        }
                } else {
                    RecipeForm(mode: .add)
                }
            }
            // MARK: - Recipe Form Sheet (Edit)
            .sheet(item: $selectedRecipeToEdit) { recipe in
                RecipeForm(mode: .edit(recipe))
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("No Categories", systemImage: "folder.badge.plus")
            },
            description: {
                Text("Add a category to start organizing your recipes.")
            },
            actions: {
                Button("Add Category") {
                    selectedCategory = nil
                    showCategoryForm = true
                }
                .buttonBorderShape(.roundedRectangle)
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
                Text("No categories match '\(searchQuery)'")
            }
        )
    }
    
    // MARK: - List View
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredCategories) { category in
                    CategorySection(
                        category: category,
                        onEdit: { categoryToEdit in
                            selectedCategory = categoryToEdit
                            showCategoryForm = true
                        },
                        onAddRecipe: { category in
                            categoryForNewRecipe = category
                            showRecipeForm = true
                        },
                        onSelectRecipe: { recipe in
                            selectedRecipeToEdit = recipe
                        }
                    )
                }
            }
            .padding()
        }
    }
}
