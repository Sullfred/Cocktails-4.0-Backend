//
//  PermissionMiddleware.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 17/10/2025.
//

import Vapor

// Middleware for ensuring guest permission
struct RequireGuestRoleMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try request.auth.require(User.self)
        guard user.role == .guest || user.role == .admin else {
            throw Abort(.forbidden, reason: "You do not have permission for this action")
        }
        return try await next.respond(to: request)
    }
}

// Middleware for ensuring creator permission
struct RequireCreatorRoleMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try request.auth.require(User.self)
        guard user.role == .creator || user.role == .admin else {
            throw Abort(.forbidden, reason: "You do not have permission for this action")
        }
        return try await next.respond(to: request)
    }
}

// Middleware for ensuring admin rights
struct RequireAdminRoleMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try request.auth.require(User.self)
        guard user.role == .admin else {
            throw Abort(.forbidden, reason: "You must be an admin to perform this action.")
        }
        return try await next.respond(to: request)
    }
}
