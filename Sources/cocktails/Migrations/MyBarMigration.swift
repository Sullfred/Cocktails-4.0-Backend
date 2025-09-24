//
//  MyBarMigration.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 19/09/2025.
//

import Vapor
import Fluent

extension MyBar {
    struct MyBarMigration: AsyncMigration {
        var name: String { "CreateBars" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("bars")
                .id()
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("bar_items", .array(of: .json), .required)
                .field("favorite_cocktails", .array(of: .string), .required)
                .field("deleted_cocktails", .array(of: .json), .required)
                .unique(on: "user_id")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("bars").delete()
        }
    }
}
