//
//  UserController.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 16/09/2025.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("register", use: register)
        
        // protected
        let protected = users.grouped(User.authenticator())
        protected.post("login", use: login)
        
        // tokenProtected
        let tokenProtected = users.grouped(UserToken.authenticator(), User.guardMiddleware())
        tokenProtected.post("logout", use: logout)
        tokenProtected.delete("me", use: deleteUser)
        tokenProtected.patch("updateUsername", use: updateUsername)
        tokenProtected.patch("updatePassword", use: updatePassword)
    
    }
    
    func register(req: Request) async throws -> HTTPStatus {
        try CreateUserDTO.validate(content: req)
        let dto = try req.content.decode(CreateUserDTO.self)
        
        guard dto.password == dto.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        // Pre-check: Ensure username does not already exist
        if let _ = try await User.query(on: req.db).filter(\.$username == dto.username).first() {
            throw Abort(.conflict, reason: "Username unavailable")
        }

        let user = try User(
            username: dto.username,
            passwordHash: Bcrypt.hash(dto.password),
            addPermission: false,
            editPermissions: false,
            adminRights: false
        )

        do {
            try await user.save(on: req.db)
        } catch {
            throw Abort(.badRequest, reason: "Failed to register user")
        }

        // Create a MyBar instance for the new user
        let userId = try user.requireID()
        let bar = MyBar(userID: userId, barItems: [], favorites: [], deleted: [])
        try await bar.save(on: req.db)

        return .created
    }

    func login(req: Request) async throws -> LoginResponse {
        // Get user from authentication middleware
        let user = try req.auth.require(User.self)

        // Generate token
        let token = try user.generateToken()
        try await token.save(on: req.db)

        // Map the user to the public representation
        let publicUser = user.convertToPublic()

        return LoginResponse(token: token.value, user: publicUser)
    }
    
    func logout(req: Request) async throws -> HTTPStatus {
        let token = try req.auth.require(UserToken.self)
        do {
            try await token.delete(on: req.db)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to delete token")
        }
        
        return .ok
    }

    func deleteUser(req: Request) async throws -> HTTPStatus {
        let token = try req.auth.require(UserToken.self)
        // Get user
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        // Find users bar and delete it if it exist
        if let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first() {
            try await bar.delete(on: req.db)
        }
        
        do {
            try await token.delete(on: req.db)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to delete token")
        }
        
        // Delete user
        try await user.delete(on: req.db)
        
        return .noContent
    }
    
    func updateUsername(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(UserToken.self)
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(UpdateUsernameDTO.self)
        
        // Check if username is already taken
        if let _ = try await User.query(on: req.db).filter(\.$username == dto.newUsername).first() {
            throw Abort(.conflict, reason: "Username unavailable")
        }
        
        // Update and save
        user.username = dto.newUsername
        try await user.save(on: req.db)
        
        return .ok
    }
    
    func updatePassword(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(UserToken.self)
        let user = try req.auth.require(User.self)
        
        // Decode DTO
        let dto = try req.content.decode(UpdatePasswordDTO.self)

        // Verify current password
        guard try Bcrypt.verify(dto.currentPassword, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect")
        }
        
        // Check new password matches confirmation
        guard dto.newPassword == dto.confirmNewPassword else {
            throw Abort(.badRequest, reason: "New passwords did not match")
        }
        
        // Hash and save new password
        user.passwordHash = try Bcrypt.hash(dto.newPassword)
        try await user.save(on: req.db)
        
        return .ok
    }
}
