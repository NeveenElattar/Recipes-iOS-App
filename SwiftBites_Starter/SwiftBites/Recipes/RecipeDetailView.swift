//
//  RecipeDetailView.swift
//  SwiftBites
//
//  Created by Neveen ElAttar on 12/10/2025.
//


import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    var onEdit: (Recipe) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header Image
                ZStack(alignment: .bottomLeading) {
                    recipeHeaderImage
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(recipe.name)
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text(recipe.summary)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        .padding()
                        .shadow(radius: 5)
                    }
                }

                // MARK: - Tags
                HStack(spacing: 8) {
                    if let category = recipe.category {
                        tag(title: category.name, icon: "tag")
                    }
                    tag(title: "\(recipe.time)m", icon: "clock")
                    tag(title: "\(recipe.serving)p", icon: "person")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider().padding(.horizontal)

                // MARK: - Ingredients Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.title2.bold())
                        .padding(.bottom, 2)

                    let ingredientArray = Array(recipe.ingredients)
                    if ingredientArray.isEmpty {
                        Text("No ingredients listed.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(ingredientArray) { ing in
                            HStack {
                                Text("• \(ing.ingredient?.name ?? "Unnamed")")
                                Spacer()
                                Text(ing.quantity)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Divider().padding(.vertical, 12)

                // MARK: - Instructions Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.title2.bold())
                        .padding(.bottom, 2)

                    if recipe.instructions.isEmpty {
                        Text("No instructions available.")
                            .foregroundColor(.secondary)
                    } else {
                        Text(recipe.instructions)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    onEdit(recipe)
                }
            }
        }
    }

    // MARK: - Subviews

    private var recipeHeaderImage: some View {
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
    }

    private func tag(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}
