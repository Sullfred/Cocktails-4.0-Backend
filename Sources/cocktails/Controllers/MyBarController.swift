//
//  MyBarController.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 20/09/2025.
//


import Vapor
import Fluent

struct MyBarController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let mybar = routes.grouped(UserToken.authenticator(), User.guardMiddleware())
            .grouped("mybar")
        
        mybar.get(use: getMyBar)
        mybar.post("items", use: addItem)
        mybar.delete("items", ":id", use: removeItem)
        mybar.post("favorites", ":cocktailID", use: addFavorite)
        mybar.delete("favorites", ":cocktailID", use: removeFavorite)
        mybar.post("removed", use: addRemoved)
        mybar.delete("removed", ":id", use: deleteRemoved)
    }

    // Fetch the authenticated user's MyBar
    func getMyBar(req: Request) async throws -> MyBarDTO {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$barItems)
            .with(\.$hidden)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user: \(user.username)")
        }

        return MyBarDTO(from: bar)
    }

    // Add an item to the authenticated user's MyBar
    func addItem(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        let dto = try req.content.decode(BarItemDTO.self)

        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user: \(user.username)")
        }
        
        let newItem = BarItem(
            id: dto.id,
            barId: try bar.requireID(),
            name: dto.name,
            category: dto.category
        )

        try await newItem.save(on: req.db)
        
        return .ok
    }

    func removeItem(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(User.self)
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
                
        guard let item = try await BarItem.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "Item with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }

        try await item.delete(on: req.db)
        return .ok
    }

    // Add a cocktail to favorites
    func addFavorite(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()

        guard let cocktailID = req.parameters.get("cocktailID")
        else {
            throw Abort(.badRequest)
        }

        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user: \(user.username)")
        }

        // Add cocktailID to favorites
        if !bar.favorites.contains(cocktailID) {
            bar.favorites.append(cocktailID)
            try await bar.save(on: req.db)
        }
        return .ok
    }

    // Remove a cocktail from favorites
    func removeFavorite(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        guard let cocktailID = req.parameters.get("cocktailID")
        else {
            throw Abort(.badRequest)
        }
        
        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user: \(user.username)")
        }

        // Removed cocktailID from favorites
        bar.favorites.removeAll { $0 == cocktailID }
        try await bar.save(on: req.db)
        return .ok
    }

    // Add a cocktail to removed list
    func addRemoved(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        let dto = try req.content.decode(HiddenCocktailDTO.self)

        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user: \(user.username)")
        }

        let hidden = HiddenCocktail(
            id: dto.id,
            barId: try bar.requireID(),
            cocktailId: dto.cocktailId,
            name: dto.name,
            creator: dto.creator,
            date: dto.date
        )
        
        try await hidden.save(on: req.db)
        return .ok
    }

    func deleteRemoved(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(User.self)
        
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        
        guard let hidden = try await HiddenCocktail.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }

        try await hidden.delete(on: req.db)
        
        return .ok
    }
}
