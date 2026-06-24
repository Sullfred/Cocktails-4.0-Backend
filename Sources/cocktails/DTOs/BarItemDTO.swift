//
//  BarItemDTO.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 24/06/2026.
//

import Fluent
import Vapor

struct BarItemDTO: Codable, Identifiable, Content {
    let id: UUID
    let name: String
    let category: BarItemCategory
}

extension BarItemDTO {
    init(from barItem: BarItem) {
        self.id = barItem.id!
        self.name = barItem.name
        self.category = barItem.category
    }
}
