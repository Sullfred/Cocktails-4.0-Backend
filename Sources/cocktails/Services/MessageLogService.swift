//
//  MessageLogService.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 22/06/2026.
//

import Vapor
import Fluent

protocol MessageLogServiceProtocol {
    func info(userId: UUID?, userName: String, message: String, db: any Database) async

    func warning(userId: UUID?, userName: String, message: String, db: any Database) async

    func error(userId: UUID?, userName: String, message: String, db: any Database) async
}

struct MessageLogService: MessageLogServiceProtocol {
    func info(userId: UUID?, userName: String, message: String, db: any Database) async {
        await save(
            userId: userId,
            userName: userName,
            message: message,
            level: "Info",
            db: db
        )
    }

    func warning(userId: UUID?, userName: String, message: String, db: any Database) async {
        await save(
            userId: userId,
            userName: userName,
            message: message,
            level: "Warning",
            db: db
        )
    }

    func error(userId: UUID?, userName: String, message: String, db: any Database) async {
        await save(
            userId: userId,
            userName: userName,
            message: message,
            level: "Error",
            db: db
        )
    }

    private func save(userId: UUID?, userName: String, message: String, level: String, db: any Database) async {
        let log = MessageLog(
            id: UUID(),
            userId: userId ?? nil,
            userName: userName,
            message: message,
            logLevel: level
        )

        try? await log.save(on: db)
    }
}

extension MessageLogService {
    func info(req: Request, message: String) async {
        guard let user = req.auth.get(User.self) else {
            return
        }

        await info(userId: try? user.requireID(), userName: user.username, message: message, db: req.db)
    }
    
    func warning(req: Request, message: String) async {
        guard let user = req.auth.get(User.self) else {
            return
        }
        
        await warning(userId: try? user.requireID(), userName: user.username, message: message, db: req.db)
    }
    
}
