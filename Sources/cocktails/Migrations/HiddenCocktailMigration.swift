//
//  HiddenCocktailMigration.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Vapor
import Fluent

extension HiddenCocktail {
    struct HiddenCocktailMigration: AsyncMigration {
        var name: String { "CreateHiddenCocktails" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("hidden_cocktail")
                .id()
                .field("bar_id", .uuid, .required, .references("bars", "id"))
                .field("cocktail_id", .string)
                .field("cocktail_name", .string)
                .field("cocktail_creator", .string)
                .field("date", .date)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("hidden_cocktails").delete()
        }
    }
}
