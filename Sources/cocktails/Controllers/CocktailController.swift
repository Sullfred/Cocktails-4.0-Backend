//
//  CocktailController.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 27/08/2025.
//

import Vapor
import Fluent

struct CocktailController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let cocktails = routes.grouped("cocktails")
        
        // Basic routes
        cocktails.get(use: getAll)
        cocktails.get(":id", use: getCocktail)
        
        // Protected routes - ensure valid userToken and permissions
        let tokenProtected = cocktails.grouped(UserToken.authenticator())
        
        let creatorProtected = tokenProtected.grouped(RequireCreatorRoleMiddleware())
        creatorProtected.post(use: createCocktail)
        creatorProtected.put(":id", use: update)
        
        let adminProtected = tokenProtected.grouped(RequireAdminRoleMiddleware())
        adminProtected.delete(":id", use: deleteCocktail)
        
    }

    // Fetch all cocktails, eager-load ingredients
    func getAll(req: Request) async throws -> [CocktailDTO] {
        let cocktails = try await Cocktail.query(on: req.db)
            .with(\.$ingredients)
            .all()
        return cocktails.map { CocktailDTO(from: $0) }
    }

    // Create a new cocktail + its ingredients
    func createCocktail(req: Request) async throws -> CocktailDTO {
        let dto = try req.content.decode(CocktailDTO.self)
        
        let cocktail = Cocktail(
            id: dto.id,
            name: dto.name,
            creator: dto.creator,
            style: dto.style,
            comment: dto.comment,
            cocktailCategory: dto.cocktailCategory,
            imageURL: dto.imageURL
        )
        
        try await cocktail.save(on: req.db)

        for ingrDTO in dto.ingredients {
            let ingredient = Ingredient(
                cocktailID: try cocktail.requireID(),
                volume: ingrDTO.volume,
                unit: ingrDTO.unit,
                name: ingrDTO.name,
                tag: ingrDTO.tag,
                orderIndex: ingrDTO.orderIndex
            )
            try await ingredient.save(on: req.db)
        }

        guard let saved = try await Cocktail.query(on: req.db)
            .filter(\.$id == cocktail.requireID())
            .with(\.$ingredients)
            .first()
        else {
            throw Abort(.internalServerError)
        }
        
        await req.application.messageLogs.info(req: req, message: "Created cocktail '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")
        
        return CocktailDTO(from: saved)
    }

    // Get a cocktail by ID
    func getCocktail(req: Request) async throws -> CocktailDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let cocktail = try await Cocktail.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$ingredients)
            .first()
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }
        return CocktailDTO(from: cocktail)
    }

    // Update cocktail + ingredients
    func update(req: Request) async throws -> CocktailDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let dto = try req.content.decode(CocktailDTO.self)
        guard let cocktail = try await Cocktail.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$ingredients)
            .first()
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }
        
        cocktail.name = dto.name
        cocktail.creator = dto.creator
        cocktail.style = dto.style
        cocktail.comment = dto.comment
        cocktail.cocktailCategory = dto.cocktailCategory
        cocktail.imageURL = dto.imageURL
        try await cocktail.save(on: req.db)

        // Remove old ingredients
        for ingr in cocktail.ingredients {
            try await ingr.delete(on: req.db)
        }
        // Add new ones
        for ingrDTO in dto.ingredients {
            let ingredient = Ingredient(
                cocktailID: try cocktail.requireID(),
                volume: ingrDTO.volume,
                unit: ingrDTO.unit,
                name: ingrDTO.name,
                tag: ingrDTO.tag,
                orderIndex: ingrDTO.orderIndex
            )
            try await ingredient.save(on: req.db)
        }

        guard let saved = try await Cocktail.query(on: req.db)
            .filter(\.$id == cocktail.requireID())
            .with(\.$ingredients)
            .first()
        else {
            throw Abort(.internalServerError)
        }
        
        await req.application.messageLogs.info(req: req, message: "Updated cocktail '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")
        
        return CocktailDTO(from: saved)
    }

    // Delete a cocktail
    func deleteCocktail(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let cocktail = try await Cocktail.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }
        // Delete related ingredients before the cocktail to not violate foreign key constraints
        let ingredients = try await Ingredient.query(on: req.db)
            .filter(\.$cocktail.$id == cocktail.requireID())
            .all()
        for ingr in ingredients {
            try await ingr.delete(on: req.db)
        }
        
        try await cocktail.delete(on: req.db)
        
        await req.application.messageLogs.warning(req: req, message: "Deleted cocktail '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")
        
        return .noContent
    }
}
