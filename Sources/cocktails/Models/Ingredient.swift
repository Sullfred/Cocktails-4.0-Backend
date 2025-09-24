//
//  Ingredient.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//
import Vapor
import Fluent

final class Ingredient: Model, @unchecked Sendable {
    static let schema = "ingredients"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "cocktail_id")
    var cocktail: Cocktail

    @Field(key: "volume")
    var volume: Double

    @Field(key: "unit")
    var unit: String   // store as rawValue

    @Field(key: "name")
    var name: String

    @OptionalField(key: "tag")
    var tag: String?

    @Field(key: "order_index")
    var orderIndex: Int

    init() {}

    init(id: UUID? = nil,
         cocktailID: UUID,
         volume: Double,
         unit: String,
         name: String,
         tag: String? = nil,
         orderIndex: Int) {
        self.id = id
        self.$cocktail.id = cocktailID
        self.volume = volume
        self.unit = unit
        self.name = name
        self.tag = tag
        self.orderIndex = orderIndex
    }
}
