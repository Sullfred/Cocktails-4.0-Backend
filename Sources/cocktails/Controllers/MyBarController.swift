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
        mybar.delete("items", ":name", use: removeItem)
        mybar.post("favorites", ":cocktailID", use: addFavorite)
        mybar.delete("favorites", ":cocktailID", use: removeFavorite)
        mybar.post("removed", use: addRemoved)
        mybar.delete("removed", ":cocktailID", use: deleteRemoved)
    }

    // Fetch the authenticated user's MyBar
    func getMyBar(req: Request) async throws -> MyBarDTO {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user")
        }

        let dto = MyBarDTO(
            id: try bar.requireID(),
            userId: userId,
            barItems: bar.barItems.map{ MyBarItemDTO(name: $0.name, category: $0.category) },
            favoriteCocktails: bar.favorites,
            deletedCocktails: bar.deleted.map{ RemovedCocktailDTO(id: $0.id, name: $0.name, creator: $0.creator, date: $0.date) }
        )

        return dto
    }

    // Add an item to the authenticated user's MyBar
    func addItem(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        let dto = try req.content.decode(MyBarItemDTO.self)
        
        
        let newItem = MyBarItem(name: dto.name, category: dto.category)

        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found")
        }

        bar.barItems.append(newItem)
        try await bar.save(on: req.db)
        
        return .ok
    }

    // Remove an item from the authenticated user's MyBar by name
    func removeItem(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "Missing item name")
        }

        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user")
        }

        bar.barItems.removeAll { $0.name == name }
        try await bar.save(on: req.db)
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
            throw Abort(.notFound)
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
            throw Abort(.notFound) }

        // Removed cocktailID from favorites
        bar.favorites.removeAll { $0 == cocktailID }
        try await bar.save(on: req.db)
        return .ok
    }

    // Add a cocktail to removed list
    func addRemoved(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()

        // problem with decoding - find out why
        let dto = try req.content.decode(RemovedCocktailDTO.self)

        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound)
        }

        let deleted = DeletedCocktail(
            id: dto.id,
            name: dto.name,
            creator: dto.creator,
            date: dto.date
        )
        
        bar.deleted.append(deleted)
        try await bar.save(on: req.db)
        return .ok
    }

    func deleteRemoved(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        guard let cocktailID = req.parameters.get("cocktailID")
        else {
            throw Abort(.badRequest)
        }
        print(cocktailID)
        
        // Find users bar
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound)
        }
        print("bar found")

        bar.deleted.removeAll { $0.id == cocktailID }
        try await bar.save(on: req.db)
        print("success")
        
        return .ok
    }
}
