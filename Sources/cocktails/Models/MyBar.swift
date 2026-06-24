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
    
    @Children(for: \.$bar)
    var barItems: [BarItem]
    
    @Field(key: "favorite_cocktails")
    var favorites: [String]
    
    @Children(for: \.$bar)
    var hidden: [HiddenCocktail]
    
    init() {}
    
    init(id: UUID? = nil,
         userID: UUID,
         favorites: [String] = []) {
        self.id = id
        self.$user.id = userID
        self.favorites = favorites
    }
}


