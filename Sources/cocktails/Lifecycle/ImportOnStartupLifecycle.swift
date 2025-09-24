//
//  ImportOnStartupLifecycle.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 09/09/2025.
//

import Vapor
import Fluent

struct ImportOnStartupLifecycle: LifecycleHandler {
    let app: Application

    func didBoot(_ application: Application) throws {
        Task {
            do {
                let count = try await Cocktail.query(on: app.db).count()
                if count == 0 {
                    let resourcesDir = app.directory.resourcesDirectory + "snapshots/"
                    let files = try FileManager.default.contentsOfDirectory(atPath: resourcesDir)
                        .filter { $0.hasPrefix("cocktails-json-") && $0.hasSuffix(".json") }
                        .sorted() // Use newest file

                    guard let latest = files.last else {
                        app.logger.warning("No snapshot JSON files found at \(resourcesDir)")
                        return
                    }

                    let filePath = resourcesDir + latest
                    app.logger.info("Database empty, importing from snapshot \(latest)")

                    let url = URL(fileURLWithPath: filePath)
                    let data = try Data(contentsOf: url)

                    let decoder = JSONDecoder()
                    let cocktailDTOs = try decoder.decode([CocktailDTO].self, from: data)

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

                    app.logger.info("Imported \(cocktailDTOs.count) cocktails from \(latest)")
                } else {
                    app.logger.info("Cocktail database already has \(count) entries, skipping import")
                }
            } catch {
                app.logger.error("Failed to check or import snapshot: \(error)")
            }
        }
    }
}
