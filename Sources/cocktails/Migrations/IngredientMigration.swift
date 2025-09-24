//
//  CreateIngredient.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Vapor
import Fluent

extension Ingredient {
    struct IngredientMigration: Migration {
        func prepare(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("ingredients")
                .id()
                .field("cocktail_id", .uuid, .required, .references("cocktails", "id"))
                .field("volume", .double, .required)
                .field("unit", .string, .required)
                .field("name", .string, .required)
                .field("tag", .string)
                .field("order_index", .int, .required)
                .create()
        }
        
        func revert(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("ingredients").delete()
        }
    }
}
