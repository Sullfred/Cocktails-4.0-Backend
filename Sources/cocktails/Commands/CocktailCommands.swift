//
//  CocktailCommands.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 16/11/2025.
//

import Vapor
import Fluent

struct JsonSnapshotCommand: AsyncCommand {
    struct Signature: CommandSignature {}
    var help: String = "Takes a JSON snapshot of all cocktails and ingredients"

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        let db = app.db
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let snapshotFile = "Resources/snapshots/Cocktails/cocktails-json-\(timestamp).json"

        // Query all cocktails with ingredients
        let cocktails = try await Cocktail.query(on: db)
            .with(\.$ingredients)
            .all()

        // Prepare encoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(cocktails)

        // Ensure the directory exists
        let url = URL(fileURLWithPath: snapshotFile)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Write the file
        try data.write(to: url)

        context.console.info("JSON snapshot saved to \(snapshotFile)")
    }
}

struct SnapshotCommand: AsyncCommand {
    struct Signature: CommandSignature {}
    var help: String = "Takes a snapshot of the PostgreSQL cocktails database"

    func run(using context: CommandContext, signature: Signature) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let snapshotFile = "Resources/snapshots/cocktails-\(timestamp).sql"

        // Get pg_dump path from environment or default
        let pgDumpPath = Environment.get("PG_DUMP_PATH") ?? "/usr/bin/pg_dump"
        guard FileManager.default.isExecutableFile(atPath: pgDumpPath) else {
            context.console.error("pg_dump not found at \(pgDumpPath)")
            return
        }

        // Get DB info from environment variables
        let dbUser = Environment.get("DATABASE_USERNAME") ?? "user"
        let dbPass = Environment.get("DATABASE_PASSWORD") ?? "password"
        let dbHost = Environment.get("DATABASE_HOST") ?? "localhost"
        let dbPort = Environment.get("DATABASE_PORT") ?? "5432"
        let dbName = Environment.get("DATABASE_NAME") ?? "cocktails"
        let connString = "postgresql://\(dbUser):\(dbPass)@\(dbHost):\(dbPort)/\(dbName)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: pgDumpPath)
        process.arguments = ["--dbname=\(connString)", "-f", snapshotFile]

        try process.run()
        process.waitUntilExit()

        context.console.info("Snapshot saved to \(snapshotFile)")
    }
}


struct ImportCocktailsCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Option(name: "file", help: "Path to cocktails JSON file")
        var file: String?
    }
    
    var help: String {
        "Import cocktails from a JSON file into the database"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application

        let filePath = signature.file ?? app.directory.resourcesDirectory + "snapshots/Cocktails/cocktailsOutput.json"
        let url = URL(fileURLWithPath: filePath)

        guard let data = try? Data(contentsOf: url) else {
            context.console.error("Could not read file at \(filePath)")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys

        let cocktailDTOs: [CocktailDTO]
        do {
            cocktailDTOs = try decoder.decode([CocktailDTO].self, from: data)
        } catch {
            context.console.error("Failed to decode cocktails JSON: \(error)")
            return
        }

        try await app.db.transaction { db in
            for dto in cocktailDTOs {
                let cocktail = Cocktail(
                    id: dto.id,
                    name: dto.name,
                    creator: dto.creator,
                    style: dto.style,
                    comment: dto.comment,
                    cocktailCategory: dto.cocktailCategory,
                    imageURL: dto.imageURL
                )
                try await cocktail.create(on: db)

                for ingredientDTO in dto.ingredients {
                    let ingredient = Ingredient(
                        id: ingredientDTO.id,
                        cocktailID: dto.id,
                        volume: ingredientDTO.volume,
                        unit: ingredientDTO.unit,
                        name: ingredientDTO.name,
                        tag: ingredientDTO.tag,
                        orderIndex: ingredientDTO.orderIndex
                    )
                    try await ingredient.create(on: db)
                }
            }
        }

        context.console.info("Successfully imported \(cocktailDTOs.count) cocktails from \(filePath)")
    }
}
