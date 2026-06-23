//
//  MessageLogMigration.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 21/06/2026.
//

import Vapor
import Fluent

extension MessageLog {
    struct MessageLogMigration: AsyncMigration {
        var name: String { "CreateMessageLog" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("messageLog")
                .id()
                .field("user_id", .uuid)
                .field("user_name", .string, .required)
                .field("created_date", .string, .required)
                .field("message", .string)
                .field("log_level", .string)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("messageLog").delete()
        }
    }
}
