//
//  HiddenCocktailDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Fluent
import Vapor

struct HiddenCocktailDTO: Codable, Identifiable, Content {
    let id: UUID
    let cocktailId: String
    let name: String
    let creator: String
    let date: Date
}

extension HiddenCocktailDTO {
    init(from hiddenCocktail: HiddenCocktail) {
        self.id = hiddenCocktail.id!
        self.cocktailId = hiddenCocktail.cocktailId
        self.name = hiddenCocktail.name
        self.creator = hiddenCocktail.creator
        self.date = hiddenCocktail.date
    }
}
