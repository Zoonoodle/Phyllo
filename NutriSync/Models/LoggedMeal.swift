//
//  LoggedMeal.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// Food group enum for color coding
enum FoodGroup: String, CaseIterable {
    case protein = "Protein"
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case grain = "Grain"
    case dairy = "Dairy"
    case fat = "Fat"
    case sauce = "Sauce"
    case other = "Other"
    
    static func fromString(_ string: String) -> FoodGroup {
        return FoodGroup(rawValue: string) ?? .other
    }
    
    var color: Color {
        switch self {
        case .protein: return Color(hex: "E94B3C") // Soft red
        case .vegetable: return Color(hex: "6AB187") // Soft green
        case .fruit: return Color(hex: "F4A460") // Soft orange
        case .grain: return Color(hex: "DDA15E") // Soft brown
        case .dairy: return Color(hex: "87CEEB") // Soft blue
        case .fat: return Color(hex: "F9D71C") // Soft yellow
        case .sauce: return Color(hex: "B19CD9") // Soft purple
        case .other: return Color(hex: "A8A8A8") // Soft gray
        }
    }
}

struct MealIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double
    let unit: String // "oz", "g", "cup", "tbsp", etc.
    let foodGroup: FoodGroup
    
    // Optional nutrition data per ingredient
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    
    // Display string for the ingredient
    var displayString: String {
        let quantityStr = quantity.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", quantity) : String(format: "%.1f", quantity)
        return "\(name) \(quantityStr)\(unit)"
    }
}

struct LoggedMeal: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let timestamp: Date
    var windowId: UUID? // Which window this meal belongs to
    
    // Micronutrient data - Dictionary of nutrient name to amount consumed
    var micronutrients: [String: Double] = [:]
    
    // Ingredients that make up this meal
    var ingredients: [MealIngredient] = []
    
    // Image data for the meal
    var imageData: Data? = nil
    
    // Clarifications applied to adjust nutrition (key: clarificationType, value: option text)
    var appliedClarifications: [String: String] = [:]
    
    // Computed properties
    var emoji: String {
        // Simple emoji selection based on meal name
        if name.lowercased().contains("smoothie") { return "🥤" }
        if name.lowercased().contains("salad") { return "🥗" }
        if name.lowercased().contains("chicken") { return "🍗" }
        if name.lowercased().contains("egg") { return "🍳" }
        if name.lowercased().contains("waffle") { return "🧇" }
        if name.lowercased().contains("strawberr") { return "🍓" }
        if name.lowercased().contains("cucumber") { return "🥒" }
        return "🍽️"
    }
    
    var macroSummary: String {
        "\(protein)P \(fat)F \(carbs)C"
    }
}