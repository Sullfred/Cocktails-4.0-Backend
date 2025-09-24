//
//  CreateUser.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 16/09/2025.
//

import Fluent
import Vapor

extension User {
    struct UserMigration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: any Database) async throws {
            try await database.schema("users")
                .id()
                .field("username", .string, .required)
                .field("password_hash", .string, .required)
                .field("add_permission", .bool, .required)
                .field("edit_permission", .bool, .required)
                .field("admin_rights", .bool, .required)
                .unique(on: "username")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
