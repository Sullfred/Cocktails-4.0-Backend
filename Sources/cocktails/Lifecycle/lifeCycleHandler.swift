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
        let bars = try await MyBar.query(on: db)
            .with(\.$barItems)
            .with(\.$hidden)
            .all()
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
        let cocktails = try decoder.decode([CocktailDTO].self, from: data)

        try await app.db.transaction { db in
            for cocktail in cocktails {
                let _cocktail = Cocktail(
                    id: cocktail.id,
                    name: cocktail.name,
                    creator: cocktail.creator,
                    style: cocktail.style,
                    comment: cocktail.comment,
                    cocktailCategory: cocktail.cocktailCategory,
                    imageURL: cocktail.imageURL
                )
                try await _cocktail.create(on: db)

                for ingredient in _cocktail.ingredients {
                    let _ingredient = Ingredient(
                        id: ingredient.id,
                        cocktailID: _cocktail.id!,
                        volume: ingredient.volume,
                        unit: ingredient.unit,
                        name: ingredient.name,
                        tag: ingredient.tag,
                        orderIndex: ingredient.orderIndex
                    )
                    try await _ingredient.create(on: db)
                }
            }
        }

        app.logger.info("Restored \(cocktails.count) cocktails from snapshot")
    }

    func restoreBars() async throws {
        guard let url = latestSnapshot(in: "Bars") else {
            app.logger.warning("No Bars snapshot found")
            return
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bars = try decoder.decode([MyBarDTO].self, from: data)

        try await app.db.transaction { db in
            for bar in bars {
                let _bar = MyBar(
                    id: bar.id,
                    userID: bar.userId,
                    favorites: bar.favoriteCocktails
                )
                try await _bar.create(on: db)
                
                for barItem in _bar.barItems {
                    let _barItem = BarItem(
                        id: barItem.id,
                        barId: _bar.id!,
                        name: barItem.name,
                        category: barItem.category
                    )
                    try await _barItem.create(on: db)
                }
                
                for hiddenCocktail in _bar.hidden {
                    let _hiddenCocktail = HiddenCocktail(
                        id: hiddenCocktail.id,
                        barId: _bar.id!,
                        cocktailId: hiddenCocktail.cocktailId,
                        name: hiddenCocktail.name,
                        creator: hiddenCocktail.creator,
                        date: hiddenCocktail.date
                    )
                    try await _hiddenCocktail.create(on: db)
                }
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
