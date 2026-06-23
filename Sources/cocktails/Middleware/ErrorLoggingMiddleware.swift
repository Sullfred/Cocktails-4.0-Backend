//
//  ErrorLoggingMiddleware.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 22/06/2026.
//

import Vapor

struct ErrorLoggingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            let message = "Error: \(error.localizedDescription), at \(request.url).)"
            await request.application.messageLogs.error(
                userId: nil,
                userName: "System",
                message: message,
                db: request.db
            )

            throw error
        }
    }
}
