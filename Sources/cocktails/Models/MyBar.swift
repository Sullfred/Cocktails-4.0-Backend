//
//  MyBar.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 19/09/2025.
//

import Vapor
import Fluent

final class MyBar: Model, @unchecked Sendable {
    static let schema = "bars"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "bar_items")
    var barItems: [MyBarItem]
    
    @Field(key: "favorite_cocktails")
    var favorites: [String]
    
    @Field(key: "deleted_cocktails")
    var deleted: [DeletedCocktail]
    
    init() {}
    
    init(id: UUID? = nil,
         userID: UUID,
         barItems: [MyBarItem] = [],
         favorites: [String] = [],
         deleted: [DeletedCocktail] = []) {
        self.id = id
        self.$user.id = userID
        self.barItems = barItems
        self.favorites = favorites
        self.deleted = deleted
    }
}

struct MyBarItem: Codable, Sendable {
    var name: String
    var category: String
}

struct DeletedCocktail: Codable, Sendable {
    var id: String
    var name: String
    var creator: String
    var date: Date
}
