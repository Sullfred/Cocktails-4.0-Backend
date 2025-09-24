//
//  UserDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 17/09/2025.
//

import Fluent
import Vapor

struct CreateUserDTO: Content {
    var username: String
    var password: String
    var confirmPassword: String
}

extension CreateUserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
