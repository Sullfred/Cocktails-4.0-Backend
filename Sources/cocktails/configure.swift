import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Allow for sending data of more than 1mb to be able to send images
    app.routes.defaultMaxBodySize = "4mb"

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    //app.migrations.add(Cocktail.CocktailMigration())
    //app.migrations.add(Ingredient.IngredientMigration())
    app.migrations.add(User.UserMigration())
    app.migrations.add(UserToken.TokenMigration())
    app.migrations.add(MyBar.MyBarMigration())
    
    app.logger.logLevel = .debug
    
    app.asyncCommands.use(JsonSnapshotCommand(), as: "jsonsnapshot")
    app.asyncCommands.use(ImportCocktailsCommand(), as: "importcocktails")
    

    // Restore from snapshot if database is empty on startup
    app.lifecycle.use(ImportOnStartupLifecycle(app: app))
    
    // register routes
    try routes(app)
}
