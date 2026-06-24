//
//  MyBarDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 19/09/2025.
//

import Foundation
import Vapor

struct MyBarDTO: Content {
    var id: UUID
    var userId: UUID
    var barItems: [BarItemDTO]
    var favoriteCocktails: [String]
    var hiddenCocktails: [HiddenCocktailDTO]
}

extension MyBarDTO {
    init(from myBar: MyBar) {
        self.id = myBar.id!
        self.userId = myBar.user.id!
        self.barItems = myBar.barItems.map {
            BarItemDTO(from: $0)
        }
        self.favoriteCocktails = myBar.favorites
        self.hiddenCocktails = myBar.hidden.map {
            HiddenCocktailDTO(from: $0)
        }
    }
}
