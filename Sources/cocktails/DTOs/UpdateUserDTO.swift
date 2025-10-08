//
//  UpdateUserDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 06/10/2025.
//

import Vapor
import Fluent

// DTOs
struct UpdateUsernameDTO: Content {
    let newUsername: String
}

struct UpdatePasswordDTO: Content {
    let currentPassword: String
    let newPassword: String
    let confirmNewPassword: String
}
