//
//  User.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 15/09/2025.
//

import Vapor
import Fluent

final class User: Model, @unchecked Sendable, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "role")
    var role: UserRole
    
    @OptionalChild(for: \.$user)
    var bar: MyBar?
    
    init() { }

    init(id: UUID? = nil,
         username: String,
         passwordHash: String,
         role: UserRole) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.role = role
    }
    
    final class Public: @unchecked Sendable, Content {
        var id: UUID?
        var username: String
        var role: UserRole

        init(id: UUID?,
             username: String,
             role: UserRole) {
            self.id = id
            self.username = username
            self.role = role
        }
    }
}

enum UserRole: String, Codable, Content {
    case guest
    case creator
    case admin
    
    // if unrecognised role we default to guest
    init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try? container.decode(String.self)
            self = UserRole(rawValue: value ?? "") ?? .guest
        }
}


extension User {
    func generateToken() throws -> UserToken {
            try .init(
                value: [UInt8].random(count: 16).base64,
                userID: self.requireID()
            )
        }
    func convertToPublic() -> User.Public {
        return User.Public(id: id, username: username, role: role)
        }
}


extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> { \.$username }
    static var passwordHashKey: KeyPath<User, Field<String>> { \.$passwordHash }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
