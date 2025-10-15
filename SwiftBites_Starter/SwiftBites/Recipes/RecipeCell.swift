import SwiftUI

struct RecipeCell: View {
    let recipe: Recipe
    var onEdit: (Recipe) -> Void = { _ in }

    // MARK: - Body

    var body: some View {
        Button {
            onEdit(recipe)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                recipeImage
                recipeInfo
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var recipeImage: some View {
        Group {
            if let data = recipe.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("recipePlaceholder")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recipeInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.name)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(recipe.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let category = recipe.category {
                    tag(title: category.name, icon: "tag")
                }
                tag(title: "\(recipe.time) m", icon: "clock")
                tag(title: "\(recipe.serving) People", icon: "person")
            }
            .padding(.top, 4)
        }
        .padding()
    }

    // MARK: - Helpers

    private func tag(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Color.accentColor.opacity(0.15))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}
