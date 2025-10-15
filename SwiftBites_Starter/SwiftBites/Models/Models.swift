//
//  Models.swift
//  SwiftBites
//
//  Created by Neveen ElAttar on 12/10/2025.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .nullify, inverse: \Recipe.category) var recipes: [Recipe]? = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class Ingredient {
    @Attribute(.unique) var name: String
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class RecipeIngredient {
    var quantity: String
    @Relationship(deleteRule: .nullify) var ingredient: Ingredient?
    var recipe: Recipe?
    
    init(ingredient: Ingredient?, quantity: String = "") {
        self.ingredient = ingredient
        self.quantity = quantity
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var name: String
    var summary: String
    var serving: Int
    var time: Int
    var instructions: String
    var imageData: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe) var ingredients: [RecipeIngredient] = []
    @Relationship(deleteRule: .nullify) var category: Category?
    
    init(
        name: String,
        summary: String = "",
        serving: Int = 1,
        time: Int = 5,
        instructions: String = "",
        category: Category? = nil,
        ingredients: [RecipeIngredient] = [],
        imageData: Data? = nil
    ) {
        self.name = name
        self.summary = summary
        self.serving = serving
        self.time = time
        self.instructions = instructions
        self.category = category
        self.ingredients = ingredients
        self.imageData = imageData
    }
}
