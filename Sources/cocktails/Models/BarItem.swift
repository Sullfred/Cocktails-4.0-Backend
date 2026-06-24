//
//  MyBarItem.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Vapor
import Fluent

final class BarItem: Model, @unchecked Sendable {
    static let schema = "bar_items"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "bar_id")
    var bar: MyBar
    
    @Field(key: "item_name")
    var name: String
    
    @Field(key: "category")
    var category: BarItemCategory
    
    init() {}
    
    init(id: UUID? = nil,
         barId: UUID,
         name: String,
         category: BarItemCategory) {
        self.id = id
        self.$bar.id = barId
        self.name = name
        self.category = category
    }
}

enum BarItemCategory: String, Codable, CaseIterable {
    case liquor
    case juice
    case bitter
    case mixer
    case sweetener
    case other

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try? container.decode(String.self)
        self = BarItemCategory(rawValue: value ?? "") ?? .other
    }
}

