//
//  lifeCycleHandler.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 09/09/2025.
//

import Vapor
import Fluent

struct lifeCycleHandler: LifecycleHandler {
    let app: Application
    
    func willBoot(_ app: Application) throws {
        let db = app.db
        
        // only in prod
        // try clearTokens(on: db)
    }

    func didBoot(_ application: Application) throws {
        Task {
            do {
                let cocktailCount = try await Cocktail.query(on: app.db).count()
                let barCount = try await MyBar.query(on: app.db).count()
                let userCount = try await User.query(on: app.db).count()

                guard cocktailCount == 0 && barCount == 0 && userCount == 0 else {
                    app.logger.info("Database not empty. Skipping snapshot restore.")
                    return
                }

                app.logger.info("All tables empty — restoring database from snapshots.")

                // Restore Cocktails table
                try await restoreCocktails()

                // Restore Bars table
                try await restoreBars()

                // Restore Users table
                try await restoreUsers()
            } catch {
                app.logger.error("Failed to import snapshot: \(error)")
            }
        }
    }
    
    func shutdown(_ app: Application) {
        app.logger.info("Starting shutdown")

        let db = app.db
        let eventLoop = app.eventLoopGroup.next()
        let promise = eventLoop.makePromise(of: Void.self)

        Task {
            do {
                try await saveSnapshots(db: db)
                promise.succeed(())
            } catch {
                app.logger.error("Failed to snapshot on shutdown: \(error)")
                promise.fail(error)
            }
        }

        // Wait until snapshots are complete
        do {
            try promise.futureResult.wait()
        } catch {
            app.logger.error("Snapshot wait failed during shutdown: \(error)")
        }

        try? clearTokens(on: db)
        app.logger.info("Shutdown completed.")
    }
}

// Lifecycle helper functions
private extension lifeCycleHandler {
    func saveSnapshots(db: any Database) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Cocktails with ingredients
        let cocktails = try await Cocktail.query(on: db)
            .with(\.$ingredients)
            .all()
        let cocktailsData = try encoder.encode(cocktails)
        writeSnapshot("cocktails", folder: "Cocktails", data: cocktailsData)

        // Bars
        let bars = try await MyBar.query(on: db).all()
        let barsData = try encoder.encode(bars)
        writeSnapshot("bars", folder: "Bars", data: barsData)

        // Users (excluding tokens)
        let users = try await User.query(on: db).all()
        let usersData = try encoder.encode(users)
        writeSnapshot("users", folder: "Users", data: usersData)
    }
    
    func writeSnapshot(_ name: String, folder: String, data: Data) {
        let fm = FileManager.default
        let base = app.directory.resourcesDirectory + "snapshots/"
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let timestamp = dateFormatter.string(from: Date())
        let dir = base + folder + "/"
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let path = dir + "\(name)-\(timestamp).json"
        try? data.write(to: URL(fileURLWithPath: path))
        app.logger.info("Snapshot saved: \(path)")
    }
    
    func latestSnapshot(in folder: String) -> URL? {
        let path = app.directory.resourcesDirectory + "snapshots/\(folder)/"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: path)
            .filter({ $0.hasSuffix(".json") })
            .sorted(),
            let latest = files.last
        else { return nil }

        return URL(fileURLWithPath: path + latest)
    }

    func restoreCocktails() async throws {
        guard let url = latestSnapshot(in: "Cocktails") else {
            app.logger.warning("No Cocktail snapshot found")
            return
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dtos = try decoder.decode([CocktailDTO].self, from: data)

        try await app.db.transaction { db in
            for dto in dtos {
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

                for ing in dto.ingredients {
                    let ingredient = Ingredient(
                        id: ing.id,
                        cocktailID: dto.id,
                        volume: ing.volume,
                        unit: ing.unit,
                        name: ing.name,
                        tag: ing.tag,
                        orderIndex: ing.orderIndex
                    )
                    try await ingredient.create(on: db)
                }
            }
        }

        app.logger.info("Restored \(dtos.count) cocktails from snapshot")
    }

    func restoreBars() async throws {
        guard let url = latestSnapshot(in: "Bars") else {
            app.logger.warning("No Bars snapshot found")
            return
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bars = try decoder.decode([MyBar].self, from: data)

        try await app.db.transaction { db in
            for bar in bars {
                try await bar.create(on: db)
            }
        }

        app.logger.info("Restored \(bars.count) bars from snapshot")
    }

    func restoreUsers() async throws {
        guard let url = latestSnapshot(in: "Users") else {
            app.logger.warning("No Users snapshot found")
            return
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let users = try decoder.decode([User].self, from: data)

        try await app.db.transaction { db in
            for user in users {
                try await user.create(on: db)
            }
        }

        app.logger.info("Restored \(users.count) users from snapshot")
    }
    
    func clearTokens(on db: any Database) throws {
        // Delete all tokens
        UserToken.query(on: db).delete()
        app.logger.info("All user tokens cleared")
    }
}
