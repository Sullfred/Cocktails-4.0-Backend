//
//  Cocktail.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Vapor
import Fluent

final class Cocktail: Model, @unchecked Sendable {
    static let schema = "cocktails"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "creator")
    var creator: String
    
    @Field(key: "style")
    var style: String   // store as rawValue from the app model
    
    @Field(key: "comment")
    var comment: String
    
    @Field(key: "cocktail_category")
    var cocktailCategory: String  // store as rawValue from the app model
    
    @OptionalField(key: "image_url")
    var imageURL: String?   // store URL/path to image instead of binary data

    // Relationship
    @Children(for: \.$cocktail)
    var ingredients: [Ingredient]

    init() {}

    init(id: UUID? = nil,
         name: String,
         creator: String,
         style: String,
         comment: String,
         cocktailCategory: String,
         imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.creator = creator
        self.style = style
        self.comment = comment
        self.cocktailCategory = cocktailCategory
        self.imageURL = imageURL
    }
}
