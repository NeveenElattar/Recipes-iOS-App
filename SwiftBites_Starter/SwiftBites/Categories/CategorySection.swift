import SwiftUI
import SwiftData

struct CategorySection: View {
    @Environment(\.modelContext) private var context
    let category: Category
    var onEdit: (Category) -> Void
    var onAddRecipe: (Category) -> Void
    var onSelectRecipe: (Recipe) -> Void = { _ in } 

    var body: some View {
        Section {
            if category.recipes?.isEmpty ?? true {
                emptyView
            } else {
                recipeList
            }
        } header: {
            headerView
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text(category.name)
                .font(.title2)
                .bold()
            Spacer()
            Button("Add Recipe") {
                onAddRecipe(category)
            }
            .buttonStyle(.borderedProminent)
            Button("Edit") {
                onEdit(category)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Recipe List
    private var recipeList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(category.recipes ?? []) { recipe in
                    RecipeCell(recipe: recipe) { selectedRecipe in
                        onSelectRecipe(selectedRecipe)
                    }
                    .frame(width: 280, height: 220)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("No Recipes", systemImage: "list.clipboard")
            },
            description: {
                Text("Recipes you add in this category will appear here.")
            },
            actions: {
                Button("Add Recipe") {
                    onAddRecipe(category)
                }
                .buttonBorderShape(.roundedRectangle)
                .buttonStyle(.bordered)
            }
        )
        .padding(.vertical, 20)
    }
}
