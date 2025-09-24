//
//  CocktailDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Foundation
import Fluent
import Vapor

struct CocktailDTO: Codable, Identifiable, Content {
    let id: UUID
    let name: String
    let creator: String
    let style: String
    let comment: String
    let cocktailCategory: String
    let imageURL: String?
    let ingredients: [IngredientDTO]
}

extension CocktailDTO {
    init(from cocktail: Cocktail) {
        self.id = cocktail.id!
        self.name = cocktail.name
        self.creator = cocktail.creator
        self.style = cocktail.style
        self.comment = cocktail.comment
        self.cocktailCategory = cocktail.cocktailCategory
        self.imageURL = cocktail.imageURL
        self.ingredients = cocktail.ingredients.map { IngredientDTO(from: $0) }
    }
}
