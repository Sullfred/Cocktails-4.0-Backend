//
//  cocktailParser.swift
//  cocktails
//
//  Created by Daniel Vang Kleist on 09/09/2025.
//

import Foundation

// MARK: - DTOs

struct CocktailRef: Codable {
    var id: UUID
}

struct _IngredientDTO: Codable, Identifiable {
    var id: UUID
    var volume: Double
    var unit: String
    var name: String
    var tag: String?
    var orderIndex: Int
    var cocktail: CocktailRef
}

struct _CocktailDTO: Codable, Identifiable {
    var id: UUID
    var name: String
    var creator: String
    var style: String
    var comment: String
    var cocktailCategory: String
    var imageURL: String? = nil
    var ingredients: [_IngredientDTO]
}

// MARK: - Tagging Helper (copied from Ingredient)

enum IngredientTag: String, Codable, CaseIterable {
    case whiskey, rum, gin, brandy, vodka, tequila
}

extension _IngredientDTO {
    mutating func assignTagBasedOnName() {
        let lowercasedName = name.lowercased()
        let tagKeywords = Self.loadTagKeywords()

        for (tag, keywords) in tagKeywords {
            for keyword in keywords {
                if lowercasedName.contains(keyword) {
                    self.tag = tag.rawValue
                    return
                }
            }
        }
        self.tag = nil
    }

    static func loadTagKeywords() -> [IngredientTag: [String]] {
        guard
            let url = Bundle.main.url(forResource: "IngredientTagKeywords", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let rawDict = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            return [:]
        }
        var result: [IngredientTag: [String]] = [:]
        for (key, keywords) in rawDict {
            if let tag = IngredientTag(rawValue: key) {
                result[tag] = keywords
            }
        }
        return result
    }
}

// MARK: - Conversion Logic

func parseCocktails(from text: String) -> [_CocktailDTO] {
    let blocks = text.split(separator: "\n\n") // assumes cocktails separated by blank line
    var cocktails: [_CocktailDTO] = []

    for block in blocks {
        let lines = block.split(separator: "\n").map { String($0) }
        guard let firstLine = lines.first else { continue }

        let cocktailId = UUID()
        var name = firstLine
        var comment = ""
        var creator = ""
        var style = "Shaken"
        var category = "Other"
        var ingredients: [_IngredientDTO] = []

        var orderIndex = 0

        for line in lines.dropFirst() {
            if line.hasPrefix("-") {
                // Ingredient line: "- 60 ml sloe gin"
                let parts = line.dropFirst(2).split(separator: " ", maxSplits: 2).map { String($0) }
                guard parts.count >= 3 else { continue }
                let volume = Double(parts[0]) ?? 0
                let unit = parts[1]
                let ingredientName = parts[2]

                var ingredient = _IngredientDTO(
                    id: UUID(),
                    volume: volume,
                    unit: unit,
                    name: ingredientName,
                    tag: nil,
                    orderIndex: orderIndex,
                    cocktail: CocktailRef(id: cocktailId)
                )
                ingredient.assignTagBasedOnName()
                ingredients.append(ingredient)
                orderIndex += 1
            } else if line.hasPrefix("comment:") {
                comment = line.replacingOccurrences(of: "comment:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("cocktailCategory:") {
                category = line.replacingOccurrences(of: "cocktailCategory:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("creator:") {
                creator = line.replacingOccurrences(of: "creator:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("style:") {
                style = line.replacingOccurrences(of: "style:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        let cocktail = _CocktailDTO(
            id: cocktailId,
            name: name,
            creator: creator,
            style: style,
            comment: comment,
            cocktailCategory: category,
            ingredients: ingredients
        )
        cocktails.append(cocktail)
    }

    return cocktails
}

// MARK: - Run Example
func runParseCocktails() {
    if let url = Bundle.main.url(forResource: "cocktailsNote", withExtension: "txt"),
       let note = try? String(contentsOf: url, encoding: .utf8) {
        let cocktails = parseCocktails(from: note)
        if let jsonData = try? JSONEncoder().encode(cocktails) {
            // Determine destination URL in user's Documents directory
            let fileManager = FileManager.default
            if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let outputURL = documentsURL.appendingPathComponent("cocktailsOutput.json")
                do {
                    try jsonData.write(to: outputURL)
                    print("Cocktails JSON saved to: \(outputURL.path)")
                } catch {
                    print("Failed to save JSON file: \(error)")
                }
            } else {
                print("Could not locate Documents directory.")
            }
        }
    }
}
