//
//  CreateCocktail.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Vapor
import Fluent

extension Cocktail {
    struct CocktailMigration: Migration {
        func prepare(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("cocktails")
                .id()
                .field("name", .string, .required)
                .field("creator", .string, .required)
                .field("style", .string, .required)
                .field("comment", .string, .required)
                .field("cocktail_category", .string, .required)
                .field("image_url", .string)
                .create()
        }
        
        func revert(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("cocktails").delete()
        }
    }
}
