//
//  FoodSuggestion.swift
//  NutriSync
//
//  AI-generated food suggestions for meal windows
//

import Foundation
import FirebaseFirestore

// MARK: - Food Suggestion Model

struct FoodSuggestion: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String                    // "Greek Yogurt with Berries"
    let calories: Int                   // 150
    let protein: Double                 // 15.0
    let carbs: Double                   // 20.0
    let fat: Double                     // 5.0
    let foodGroup: FoodGroup            // For emoji/icon mapping

    // Scoring (Phase 5)
    var predictedScore: Double?         // 0-10 scale predicted health score
    var scoreFactors: [SuggestionScoreFactor]?  // Factors contributing to score

    // Recipe (Phase 6)
    var recipe: RecipeInfo?             // Linked recipe from trusted source
    var portions: [IngredientPortion]?  // Ingredient portions for the meal

    // Detail sheet content
    let reasoningShort: String          // One-liner for card: "High protein for recovery"
    let reasoningDetailed: String       // Full explanation of why this suggestion
    let howYoullFeel: String            // Experiential benefit description
    let supportsGoal: String            // Connection to user's primary goal

    // Metadata
    let generatedAt: Date
    let basedOnMacroGap: MacroGap?      // What gap this fills

    // MARK: - Computed Properties

    var macroSummary: String {
        "\(calories) cal \u{2022} \(Int(protein))g P \u{2022} \(Int(carbs))g C \u{2022} \(Int(fat))g F"
    }

    /// Smart emoji based on food name - uses shared FoodEmojiMapper
    var emoji: String {
        FoodEmojiMapper.emoji(for: name)
    }

    // MARK: - Firestore

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "foodGroup": foodGroup.rawValue,
            "reasoningShort": reasoningShort,
            "reasoningDetailed": reasoningDetailed,
            "howYoullFeel": howYoullFeel,
            "supportsGoal": supportsGoal,
            "generatedAt": Timestamp(date: generatedAt)
        ]

        if let gap = basedOnMacroGap {
            data["basedOnMacroGap"] = gap.toFirestore()
        }

        // Phase 5: Scoring
        if let score = predictedScore {
            data["predictedScore"] = score
        }
        if let factors = scoreFactors {
            data["scoreFactors"] = factors.map { $0.toFirestore() }
        }

        // Phase 6: Recipe
        if let recipe = recipe {
            data["recipe"] = recipe.toFirestore()
        }
        if let portions = portions {
            data["portions"] = portions.map { $0.toFirestore() }
        }

        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> FoodSuggestion? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let calories = data["calories"] as? Int,
              let protein = data["protein"] as? Double,
              let carbs = data["carbs"] as? Double,
              let fat = data["fat"] as? Double,
              let foodGroupRaw = data["foodGroup"] as? String,
              let foodGroup = FoodGroup(rawValue: foodGroupRaw),
              let reasoningShort = data["reasoningShort"] as? String,
              let reasoningDetailed = data["reasoningDetailed"] as? String,
              let howYoullFeel = data["howYoullFeel"] as? String,
              let supportsGoal = data["supportsGoal"] as? String
        else { return nil }

        // Handle Date from Firestore Timestamp
        let generatedAt: Date
        if let timestamp = data["generatedAt"] as? Timestamp {
            generatedAt = timestamp.dateValue()
        } else if let date = data["generatedAt"] as? Date {
            generatedAt = date
        } else {
            generatedAt = Date()
        }

        let macroGap = (data["basedOnMacroGap"] as? [String: Any]).flatMap { MacroGap.fromFirestore($0) }

        // Phase 5: Scoring
        let predictedScore = data["predictedScore"] as? Double
        let scoreFactors: [SuggestionScoreFactor]? = (data["scoreFactors"] as? [[String: Any]])?.compactMap {
            SuggestionScoreFactor.fromFirestore($0)
        }

        // Phase 6: Recipe
        let recipe = (data["recipe"] as? [String: Any]).flatMap { RecipeInfo.fromFirestore($0) }
        let portions: [IngredientPortion]? = (data["portions"] as? [[String: Any]])?.compactMap {
            IngredientPortion.fromFirestore($0)
        }

        var suggestion = FoodSuggestion(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            foodGroup: foodGroup,
            reasoningShort: reasoningShort,
            reasoningDetailed: reasoningDetailed,
            howYoullFeel: howYoullFeel,
            supportsGoal: supportsGoal,
            generatedAt: generatedAt,
            basedOnMacroGap: macroGap
        )
        suggestion.predictedScore = predictedScore
        suggestion.scoreFactors = scoreFactors
        suggestion.recipe = recipe
        suggestion.portions = portions
        return suggestion
    }
}

// MARK: - FoodGroup Extensions for Suggestions

extension FoodGroup {
    /// Emoji representation for food suggestion cards
    var emoji: String {
        switch self {
        case .protein: return "🍗"
        case .dairy: return "🥛"
        case .grain: return "🌾"
        case .vegetable: return "🥬"
        case .fruit: return "🍎"
        case .fatOil: return "🥑"
        case .legume: return "🫘"
        case .beverage: return "🍵"
        case .nutSeed: return "🥜"
        case .condimentSauce: return "🧂"
        case .sweet: return "🍰"
        case .mixed: return "🍽️"
        }
    }

    /// SF Symbol icon for food suggestion detail sheets
    var suggestionIcon: String {
        switch self {
        case .protein: return "fork.knife"
        case .dairy: return "cup.and.saucer.fill"
        case .grain: return "leaf.fill"
        case .vegetable: return "carrot.fill"
        case .fruit: return "apple.logo"
        case .fatOil: return "drop.fill"
        case .legume: return "leaf.circle.fill"
        case .beverage: return "mug.fill"
        case .nutSeed: return "tree.fill"
        case .condimentSauce: return "drop.circle.fill"
        case .sweet: return "birthday.cake.fill"
        case .mixed: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Macro Gap

struct MacroGap: Codable, Hashable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let primaryGap: String  // "protein", "carbs", "fat", or "balanced"

    func toFirestore() -> [String: Any] {
        [
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "primaryGap": primaryGap
        ]
    }

    static func fromFirestore(_ data: [String: Any]) -> MacroGap? {
        guard let calories = data["calories"] as? Int,
              let protein = data["protein"] as? Double,
              let carbs = data["carbs"] as? Double,
              let fat = data["fat"] as? Double,
              let primaryGap = data["primaryGap"] as? String
        else { return nil }

        return MacroGap(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            primaryGap: primaryGap
        )
    }
}

// MARK: - Suggestion Score Factor

/// A factor contributing to the suggestion's predicted score
struct SuggestionScoreFactor: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String                // "Protein balance", "Fiber boost", etc.
    let contribution: Double        // +1.2 or -0.5
    var detail: String?             // "Adds 48g to fill your gap"

    init(name: String, contribution: Double, detail: String? = nil) {
        self.id = UUID()
        self.name = name
        self.contribution = contribution
        self.detail = detail
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "contribution": contribution
        ]
        if let detail = detail {
            data["detail"] = detail
        }
        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> SuggestionScoreFactor? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let contribution = data["contribution"] as? Double
        else { return nil }

        return SuggestionScoreFactor(
            name: name,
            contribution: contribution,
            detail: data["detail"] as? String
        )
    }
}

// MARK: - Recipe Info (Phase 6)

/// Recipe information from trusted sources
struct RecipeInfo: Codable, Hashable {
    let source: RecipeSource
    let url: URL
    let imageUrl: URL?
    let prepTime: Int?      // minutes
    let cookTime: Int?      // minutes
    let difficulty: Difficulty?
    let instructions: [String]?
    let nutritionVerified: Bool

    enum Difficulty: String, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }

    /// Total time in minutes
    var totalTime: Int? {
        guard let prep = prepTime, let cook = cookTime else {
            return prepTime ?? cookTime
        }
        return prep + cook
    }

    /// Formatted time string
    var timeString: String? {
        guard let total = totalTime else { return nil }
        if total < 60 {
            return "\(total) min"
        }
        let hours = total / 60
        let mins = total % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "source": source.toFirestore(),
            "url": url.absoluteString,
            "nutritionVerified": nutritionVerified
        ]
        if let imageUrl = imageUrl {
            data["imageUrl"] = imageUrl.absoluteString
        }
        if let prepTime = prepTime {
            data["prepTime"] = prepTime
        }
        if let cookTime = cookTime {
            data["cookTime"] = cookTime
        }
        if let difficulty = difficulty {
            data["difficulty"] = difficulty.rawValue
        }
        if let instructions = instructions {
            data["instructions"] = instructions
        }
        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> RecipeInfo? {
        guard let sourceData = data["source"] as? [String: Any],
              let source = RecipeSource.fromFirestore(sourceData),
              let urlString = data["url"] as? String,
              let url = URL(string: urlString)
        else { return nil }

        let imageUrl = (data["imageUrl"] as? String).flatMap { URL(string: $0) }
        let difficulty = (data["difficulty"] as? String).flatMap { Difficulty(rawValue: $0) }
        let instructions = data["instructions"] as? [String]

        return RecipeInfo(
            source: source,
            url: url,
            imageUrl: imageUrl,
            prepTime: data["prepTime"] as? Int,
            cookTime: data["cookTime"] as? Int,
            difficulty: difficulty,
            instructions: instructions,
            nutritionVerified: data["nutritionVerified"] as? Bool ?? false
        )
    }
}

/// Recipe source information
struct RecipeSource: Codable, Hashable {
    let name: String        // "Serious Eats", "Budget Bytes"
    let domain: String      // "seriouseats.com"
    let trustLevel: Int     // 1-5 (5 = most trusted)

    func toFirestore() -> [String: Any] {
        [
            "name": name,
            "domain": domain,
            "trustLevel": trustLevel
        ]
    }

    static func fromFirestore(_ data: [String: Any]) -> RecipeSource? {
        guard let name = data["name"] as? String,
              let domain = data["domain"] as? String,
              let trustLevel = data["trustLevel"] as? Int
        else { return nil }

        return RecipeSource(name: name, domain: domain, trustLevel: trustLevel)
    }
}

/// Ingredient portion for recipe display
struct IngredientPortion: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let unit: String
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?

    init(name: String, amount: Double, unit: String, calories: Int? = nil, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    var displayString: String {
        if amount == floor(amount) {
            return "\(Int(amount)) \(unit)"
        }
        return String(format: "%.1f %@", amount, unit)
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "amount": amount,
            "unit": unit
        ]
        if let calories = calories { data["calories"] = calories }
        if let protein = protein { data["protein"] = protein }
        if let carbs = carbs { data["carbs"] = carbs }
        if let fat = fat { data["fat"] = fat }
        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> IngredientPortion? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let amount = data["amount"] as? Double,
              let unit = data["unit"] as? String
        else { return nil }

        var portion = IngredientPortion(
            name: name,
            amount: amount,
            unit: unit,
            calories: data["calories"] as? Int,
            protein: data["protein"] as? Double,
            carbs: data["carbs"] as? Double,
            fat: data["fat"] as? Double
        )
        return portion
    }
}

// MARK: - Suggestion Status

enum SuggestionStatus: String, Codable {
    case pending = "pending"           // Future window, not yet generated
    case generating = "generating"     // Currently being generated
    case ready = "ready"               // Suggestions available
    case failed = "failed"             // Generation failed
}
