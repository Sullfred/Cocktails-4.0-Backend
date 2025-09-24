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
        
        cocktails.get(use: index)
        cocktails.post(use: create)
        cocktails.get(":id", use: get)
        cocktails.put(":id", use: update)
        cocktails.delete(":id", use: delete)
        cocktails.post(":id", "image", use: uploadImage)
        cocktails.delete(":id", "image", use: deleteImage)
    }

    // Fetch all cocktails, eager-load ingredients
    func index(req: Request) async throws -> [CocktailDTO] {
        let cocktails = try await Cocktail.query(on: req.db)
            .with(\.$ingredients)
            .all()
        return cocktails.map { CocktailDTO(from: $0) }
    }

    // Create a new cocktail + its ingredients
    func create(req: Request) async throws -> CocktailDTO {
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
        return CocktailDTO(from: saved)
    }

    // Get a cocktail by ID
    func get(req: Request) async throws -> CocktailDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let cocktail = try await Cocktail.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$ingredients)
            .first()
        else {
            throw Abort(.notFound)
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
            throw Abort(.notFound)
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
        return CocktailDTO(from: saved)
    }

    // Delete a cocktail
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self),
              let cocktail = try await Cocktail.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        // Delete related ingredients before the cocktail to not violate foreign key constraints
        let ingredients = try await Ingredient.query(on: req.db)
            .filter(\.$cocktail.$id == cocktail.requireID())
            .all()
        for ingr in ingredients {
            try await ingr.delete(on: req.db)
        }
        try await cocktail.delete(on: req.db)
        return .noContent
    }
    
    // Upload an image for a cocktail
    func uploadImage(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self),
              let cocktail = try await Cocktail.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        struct ImageUpload: Content {
            var file: File
        }

        let upload = try req.content.decode(ImageUpload.self)
        let imagesDirectory = req.application.directory.publicDirectory + "Images/"
        let filename = "\(UUID().uuidString).jpg"
        let fullPath = imagesDirectory + filename

        // Ensure Images directory exists
        try FileManager.default.createDirectory(
            atPath: imagesDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        try await req.fileio.writeFile(upload.file.data, at: fullPath)

        cocktail.imageURL = "/Images/\(filename)"
        try await cocktail.save(on: req.db)

        return .ok
    }
}

    // Delete an image for a cocktail
    func deleteImage(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self),
              let cocktail = try await Cocktail.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        if let imageURL = cocktail.imageURL {
            let path = req.application.directory.publicDirectory + imageURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            cocktail.imageURL = nil
            try await cocktail.save(on: req.db)
        }

        return .noContent
    }
