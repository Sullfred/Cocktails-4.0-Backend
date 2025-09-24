//
//  LoginResponse.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 23/09/2025.
//

import Vapor
import Fluent

// Wrapper for login response
struct LoginResponse: Content {
    let token: String
    let user: User.Public
}
