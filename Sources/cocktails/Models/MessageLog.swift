//
//  MessageLog.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 21/06/2026.
//
import Vapor
import Fluent

final class MessageLog: Model, @unchecked Sendable, Content {
    static let schema = "messageLog"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_id")
    var userId: UUID?
    
    @Field(key: "user_name")
    var userName: String
    
    @Field(key: "created_date")
    var createdDate: String
    
    @Field(key: "message")
    var message: String
    
    @Field(key: "log_level")
    var logLevel: String
    
    init() { }
    
    init(id: UUID? = nil, userId: UUID? = nil, userName: String = "System", message: String, logLevel: String) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.createdDate = Date.now.ISO8601Format()
        self.message = message
        self.logLevel = logLevel
    }
}
