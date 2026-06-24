//
//  DeletedCocktail.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Vapor
import Fluent

final class HiddenCocktail: Model, @unchecked Sendable {
    static let schema = "hidden_cocktails"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "bar_id")
    var bar: MyBar
    
    @Field(key: "cocktail_id")
    var cocktailId: String
    
    @Field(key: "cocktail_name")
    var name: String
    
    @Field(key: "cocktail_creator")
    var creator: String
    
    @Field(key: "date")
    var date: Date
    
    init() {}
    
    init(id: UUID? = nil,
         barId: UUID,
         cocktailId: String,
         name: String,
         creator: String,
         date: Date) {
        self.id = id
        self.$bar.id = barId
        self.cocktailId = cocktailId
        self.name = name
        self.creator = creator
        self.date = date
    }
}
