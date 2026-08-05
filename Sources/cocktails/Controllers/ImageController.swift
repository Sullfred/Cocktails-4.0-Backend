//
//  ImageController.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Vapor
import Fluent

struct ImageController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let image = routes.grouped("image")
        
        image.get(":id", "image", use: getImage)
        
        
        let protected = image.grouped(UserToken.authenticator(), RequireCreatorRoleMiddleware())
        
        protected.post(":id", "image", use: uploadImage)
        protected.put(":id", "image", use: updateImage)
        protected.delete(":id", "image", use: deleteImage)
    }
    
    // Get the image for a cocktail
    func getImage(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let cocktail = try await Cocktail.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }
        guard let imageURL = cocktail.imageURL else {
            throw Abort(.notFound, reason: "Image for cocktail: \(cocktail.name) was not found")
        }
        
        let trimmedPath = imageURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fullPath = req.application.directory.publicDirectory + trimmedPath
        
        let fileURL = URL(fileURLWithPath: fullPath)
        let fileExtension = fileURL.pathExtension.lowercased()

        let mediaType: HTTPMediaType = {
            switch fileExtension {
            case "png":
                return .png
            case "jpg", "jpeg":
                return .jpeg
            case "webp":
                return HTTPMediaType(type: "image", subType: "webp")
            default:
                return HTTPMediaType(type: "application", subType: "octet-stream")
            }
        }()

        var headers = HTTPHeaders()
        headers.contentType = mediaType
        
        guard FileManager.default.fileExists(atPath: fullPath) else {
            throw Abort(.notFound)
        }
        
        let image = try await req.fileio.asyncStreamFile(at: fullPath)
        return Response(status: .ok, headers: headers, body: image.body)
    }
    
    // Upload an image for a cocktail
    func uploadImage(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        
        guard let cocktail = try await Cocktail.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }

        struct ImageUpload: Content {
            var file: File
        }

        let upload = try req.content.decode(ImageUpload.self)
        guard upload.file.contentType?.type == "image" else {
            throw Abort(.unsupportedMediaType)
        }
        let imagesDirectory = req.application.directory.publicDirectory + "Images/"
        let ext = upload.file.extension ?? "jpg"
        let filename = "\(UUID().uuidString).\(ext)"
        let fullPath = imagesDirectory + filename

        try await req.fileio.writeFile(upload.file.data, at: fullPath)

        cocktail.imageURL = "/Images/\(filename)"
        try await cocktail.save(on: req.db)
        
        await req.application.messageLogs.info(req: req, message: "Uploaded cocktail Image for '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")

        return .ok
    }
    
    // Update an image for a cocktail
    func updateImage(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        
        guard let cocktail = try await Cocktail.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }

        struct ImageUpload: Content {
            var file: File
        }

        let upload = try req.content.decode(ImageUpload.self)
        let imagesDirectory = req.application.directory.publicDirectory + "Images/"
        
        let filename: String
        if let existingURL = cocktail.imageURL,
           let lastComponent = existingURL.split(separator: "/").last {
            filename = String(lastComponent)
        } else {
            filename = "\(UUID().uuidString).jpg"
        }

        let fullPath = imagesDirectory + filename

        // Write new image to disk
        try await req.fileio.writeFile(upload.file.data, at: fullPath)

        // Update cocktail with new image path
        cocktail.imageURL = "/Images/\(filename)"
        try await cocktail.save(on: req.db)
        
        await req.application.messageLogs.info(req: req, message: "Updated cocktail Image for '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")

        return .ok
    }
    
    // Delete an image for a cocktail
    func deleteImage(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        
        guard let cocktail = try await Cocktail.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "Cocktail with ID: \(req.parameters.get("id") ?? "No ID") was not found")
        }

        if let imageURL = cocktail.imageURL {
            let path = req.application.directory.publicDirectory + imageURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
        }

        cocktail.imageURL = nil
        try await cocktail.save(on: req.db)
        
        await req.application.messageLogs.info(req: req, message: "Deleted cocktail Image for '\(cocktail.name)' : \(cocktail.id?.uuidString ?? "No Id found")")

        return .noContent
    }
}
