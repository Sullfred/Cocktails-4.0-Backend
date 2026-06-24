//
//  BarItemMigration.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Vapor
import Fluent

extension BarItem {
    struct BarItemMigration: AsyncMigration {
        var name: String { "CreateBarItems" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("bar_items")
                .id()
                .field("bar_id", .uuid, .required, .references("bars", "id"))
                .field("item_name", .string)
                .field("category", .string, .required)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("bar_items").delete()
        }
    }
}
