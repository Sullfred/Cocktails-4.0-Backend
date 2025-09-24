//
//  IngredientDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Foundation
import Fluent
import Vapor

struct IngredientDTO: Codable, Identifiable, Content {
    let id: UUID
    let volume: Double
    let unit: String
    let name: String
    let tag: String?
    let orderIndex: Int
}

extension IngredientDTO {
    init(from ingredient: Ingredient) {
        self.id = ingredient.id!
        self.volume = ingredient.volume
        self.unit = ingredient.unit
        self.name = ingredient.name
        self.tag = ingredient.tag
        self.orderIndex = ingredient.orderIndex
    }
}

