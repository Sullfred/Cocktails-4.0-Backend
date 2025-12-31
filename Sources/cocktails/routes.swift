import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("ping") { req in
        return "pong"
    }

    try app.register(collection: CocktailController())
    try app.register(collection: UserController())
    try app.register(collection: MyBarController())
}
