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
    
    @Field(key: "add_permission")
    var addPermission: Bool
    
    @Field(key: "edit_permission")
    var editPermissions: Bool
    
    @Field(key: "admin_rights")
    var adminRights: Bool
    
    @OptionalChild(for: \.$user)
    var bar: MyBar?
    
    init() { }

    init(id: UUID? = nil,
         username: String,
         passwordHash: String,
         addPermission: Bool,
         editPermissions: Bool,
         adminRights: Bool) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.addPermission = addPermission
        self.editPermissions = editPermissions
        self.adminRights = adminRights
    }
    
    final class Public: @unchecked Sendable, Content {
        var id: UUID?
        var username: String
        var addPermission: Bool
        var editPermissions: Bool
        var adminRights: Bool

        init(id: UUID?,
             username: String,
             addPermission: Bool,
             editPermissions: Bool,
             adminRights: Bool) {
            self.id = id
            self.username = username
            self.addPermission = addPermission
            self.editPermissions = editPermissions
            self.adminRights = adminRights
        }
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
        return User.Public(id: id, username: username, addPermission: addPermission, editPermissions: editPermissions, adminRights: adminRights)
        }
}


extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> { \.$username }
    static var passwordHashKey: KeyPath<User, Field<String>> { \.$passwordHash }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
