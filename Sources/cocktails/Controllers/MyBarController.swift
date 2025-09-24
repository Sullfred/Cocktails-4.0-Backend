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
        mybar.post("favorites", use: addFavorite)
        mybar.delete("favorites", ":cocktailID", use: removeFavorite)
        mybar.post("deleted", use: addDeleted)
        mybar.delete("deleted", ":cocktailID", use: removeDeleted)
    }

    // Fetch the authenticated user's MyBar
    func getMyBar(req: Request) async throws -> MyBarDTO {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        guard let bar = try await MyBar.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user")
        }

        let dto = MyBarDTO(id: try bar.requireID(),
                           barItems: bar.barItems.map{MyBarItemDTO(name: $0.name, category: $0.category)},
                           favoriteCocktails: bar.favorites,
                           deletedCocktails: bar.deleted.map{DeletedCocktailDTO(id: $0.id, name: $0.name, creator: $0.creator, date: $0.date)})
        
        return dto
    }

    // Add an item to the authenticated user's MyBar
    func addItem(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        let newItem = try req.content.decode(MyBarItem.self)

        guard let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first()
        else {
            throw Abort(.notFound, reason: "MyBar not found for user")
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
        struct FavoriteRequest: Content { let cocktailID: String }

        let favorite = try req.content.decode(FavoriteRequest.self)

        guard let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first()
        else { throw Abort(.notFound) }

        if !bar.favorites.contains(favorite.cocktailID) {
            bar.favorites.append(favorite.cocktailID)
            try await bar.save(on: req.db)
        }
        return .ok
    }

    func removeFavorite(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let cocktailID = req.parameters.get("cocktailID") else {
            throw Abort(.badRequest)
        }
        guard let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first()
        else { throw Abort(.notFound) }

        bar.favorites.removeAll { $0 == cocktailID }
        try await bar.save(on: req.db)
        return .ok
    }

    // Add a cocktail to deleted list
    func addDeleted(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        struct DeletedRequest: Content { let cocktailID: String; let name: String; let creator: String?; let date: Date? }

        let deleted = try req.content.decode(DeletedRequest.self)

        guard let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first()
        else { throw Abort(.notFound) }

        bar.deleted.append(DeletedCocktail(id: deleted.cocktailID, name: deleted.name, creator: deleted.creator ?? "", date: deleted.date ?? Date()))
        try await bar.save(on: req.db)
        return .ok
    }

    func removeDeleted(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let cocktailID = req.parameters.get("cocktailID") else {
            throw Abort(.badRequest)
        }
        guard let bar = try await MyBar.query(on: req.db).filter(\.$user.$id == userId).first()
        else { throw Abort(.notFound) }

        bar.deleted.removeAll { $0.id == cocktailID }
        try await bar.save(on: req.db)
        return .ok
    }
}
