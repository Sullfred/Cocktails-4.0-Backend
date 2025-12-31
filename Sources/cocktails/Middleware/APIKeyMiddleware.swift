//
//  APIKeyMiddleware.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 28/12/2025.
//

import Vapor

struct APIKeyMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let expectedKey = Environment.get("COCKTAILS_API_KEY") else {
            req.logger.critical("API key missing from environment")
            throw Abort(.internalServerError)
        }

        guard let providedKey = req.headers.first(name: "x-api-key"),
              providedKey == expectedKey
        else {
            throw Abort(.unauthorized, reason: "Invalid API key")
        }

        return try await next.respond(to: req)
    }
}
