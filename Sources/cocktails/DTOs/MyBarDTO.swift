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
    var barItems: [MyBarItemDTO]
    var favoriteCocktails: [String]
    var deletedCocktails: [DeletedCocktailDTO]
}

struct MyBarItemDTO: Content {
    var name: String
    var category: String
}

struct DeletedCocktailDTO: Content {
    var id: String
    var name: String
    var creator: String
    var date: Date
}
