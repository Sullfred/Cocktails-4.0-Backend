//
//  UserCommands.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 16/11/2025.
//

import Vapor
import Fluent

struct AssignAdminCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Argument(name: "username", help: "Username of the user to assign admin role")
        var username: String
    }
    var help: String = "Assigns admin role to a user by username"

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        let db = app.db
        guard let user = try await User.query(on: db).filter(\.$username == signature.username).first() else {
            context.console.error("User not found: \(signature.username)")
            return
        }

        user.role = .admin
        try await user.save(on: db)
        
        context.console.info("Assigned admin role to \(user.username)")
    }
}
