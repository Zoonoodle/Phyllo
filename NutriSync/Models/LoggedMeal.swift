//
//  LoggedMeal.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// Food group enum for color coding - matches V2 prompt schema
enum FoodGroup: String, CaseIterable, Codable {
    case protein = "Protein"
    case grain = "Grain"
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case dairy = "Dairy"
    case beverage = "Beverage"
    case fatOil = "Fat/Oil"
    case legume = "Legume"
    case nutSeed = "Nut/Seed"
    case condimentSauce = "Condiment/Sauce"
    case sweet = "Sweet"
    case mixed = "Mixed"
    
    static func fromString(_ string: String) -> FoodGroup {
        return FoodGroup(rawValue: string) ?? .mixed
    }
    
    var color: Color {
        switch self {
        case .protein: return Color(hex: "E94B3C") // Soft red
        case .grain: return Color(hex: "DDA15E") // Soft brown
        case .vegetable: return Color(hex: "6AB187") // Soft green
        case .fruit: return Color(hex: "F4A460") // Soft orange
        case .dairy: return Color(hex: "87CEEB") // Soft blue
        case .beverage: return Color(hex: "6FB7E9") // Light blue
        case .fatOil: return Color(hex: "F9D71C") // Soft yellow
        case .legume: return Color(hex: "8B4513") // Dark brown
        case .nutSeed: return Color(hex: "CD853F") // Peru
        case .condimentSauce: return Color(hex: "B19CD9") // Soft purple
        case .sweet: return Color(hex: "FFB6C1") // Light pink
        case .mixed: return Color(hex: "A8A8A8") // Soft gray
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
        let lowercasedName = name.lowercased()
        
        // Check for main food items FIRST (before beverages)
        // This ensures "burger with beer" gets burger icon, not beer icon
        
        // Fast food & sandwiches (high priority for combo meals)
        if lowercasedName.contains("burger") || lowercasedName.contains("cheeseburger") { return "🍔" }
        if lowercasedName.contains("sandwich") { return "🥪" }
        if lowercasedName.contains("hot dog") || lowercasedName.contains("hotdog") { return "🌭" }
        if lowercasedName.contains("pizza") { return "🍕" }
        if lowercasedName.contains("taco") { return "🌮" }
        if lowercasedName.contains("burrito") { return "🌯" }
        if lowercasedName.contains("wrap") { return "🌯" }
        if lowercasedName.contains("fries") || lowercasedName.contains("french fries") { return "🍟" }
        if lowercasedName.contains("nugget") { return "🍗" }
        
        // Fruit combinations
        if lowercasedName.contains("fruit platter") || lowercasedName.contains("fruit plate") || lowercasedName.contains("fruit bowl") { return "🍉" }
        if lowercasedName.contains("fruit salad") { return "🍓" }
        
        // Beverages (check after main foods)
        if lowercasedName.contains("coffee") && !lowercasedName.contains("cake") { return "☕️" }
        if lowercasedName.contains("latte") { return "☕️" }
        if lowercasedName.contains("cappuccino") { return "☕️" }
        if lowercasedName.contains("espresso") { return "☕️" }
        if lowercasedName.contains("americano") { return "☕️" }
        if lowercasedName.contains("macchiato") { return "☕️" }
        if lowercasedName.contains("tea") && !lowercasedName.contains("steak") { return "🍵" }
        if lowercasedName.contains("smoothie") { return "🥤" }
        if lowercasedName.contains("juice") { return "🧃" }
        if lowercasedName.contains("water") { return "💧" }
        if lowercasedName.contains("soda") || lowercasedName.contains("cola") { return "🥤" }
        if lowercasedName.contains("beer") && !lowercasedName.contains("burger") && !lowercasedName.contains("chicken") && !lowercasedName.contains("steak") { return "🍺" }
        if lowercasedName.contains("wine") { return "🍷" }
        
        // Desserts
        if lowercasedName.contains("cake") { return "🍰" }
        if lowercasedName.contains("cheesecake") { return "🍰" }
        if lowercasedName.contains("pie") { return "🥧" }
        if lowercasedName.contains("cookie") { return "🍪" }
        if lowercasedName.contains("brownie") { return "🍫" }
        if lowercasedName.contains("chocolate") { return "🍫" }
        if lowercasedName.contains("ice cream") || lowercasedName.contains("icecream") { return "🍨" }
        if lowercasedName.contains("donut") || lowercasedName.contains("doughnut") { return "🍩" }
        if lowercasedName.contains("muffin") { return "🧁" }
        if lowercasedName.contains("cupcake") { return "🧁" }
        if lowercasedName.contains("candy") { return "🍬" }
        
        // Breakfast items
        if lowercasedName.contains("pancake") { return "🥞" }
        if lowercasedName.contains("waffle") { return "🧇" }
        if lowercasedName.contains("french toast") { return "🍞" }
        if lowercasedName.contains("cereal") { return "🥣" }
        if lowercasedName.contains("oatmeal") || lowercasedName.contains("porridge") { return "🥣" }
        if lowercasedName.contains("egg") { return "🍳" }
        if lowercasedName.contains("bacon") { return "🥓" }
        if lowercasedName.contains("bagel") { return "🥯" }
        if lowercasedName.contains("croissant") { return "🥐" }
        if lowercasedName.contains("toast") { return "🍞" }
        
        // Main proteins
        if lowercasedName.contains("chicken") { return "🍗" }
        if lowercasedName.contains("beef") || lowercasedName.contains("steak") { return "🥩" }
        if lowercasedName.contains("pork") || lowercasedName.contains("ham") { return "🍖" }
        if lowercasedName.contains("fish") || lowercasedName.contains("salmon") || lowercasedName.contains("tuna") { return "🐟" }
        if lowercasedName.contains("shrimp") || lowercasedName.contains("prawn") { return "🦐" }
        if lowercasedName.contains("turkey") { return "🦃" }
        
        // (Duplicates removed - handled earlier with priority)
        
        // Asian food
        if lowercasedName.contains("sushi") { return "🍣" }
        if lowercasedName.contains("ramen") { return "🍜" }
        if lowercasedName.contains("noodle") { return "🍜" }
        if lowercasedName.contains("rice") { return "🍚" }
        if lowercasedName.contains("curry") { return "🍛" }
        if lowercasedName.contains("dumpling") { return "🥟" }
        
        // Italian food
        if lowercasedName.contains("pasta") || lowercasedName.contains("spaghetti") { return "🍝" }
        
        // Salads & vegetables
        if lowercasedName.contains("salad") { return "🥗" }
        if lowercasedName.contains("broccoli") { return "🥦" }
        if lowercasedName.contains("carrot") { return "🥕" }
        if lowercasedName.contains("corn") { return "🌽" }
        if lowercasedName.contains("potato") { return "🥔" }
        if lowercasedName.contains("tomato") { return "🍅" }
        if lowercasedName.contains("cucumber") { return "🥒" }
        if lowercasedName.contains("avocado") { return "🥑" }
        
        // Fruits
        if lowercasedName.contains("apple") { return "🍎" }
        if lowercasedName.contains("banana") { return "🍌" }
        if lowercasedName.contains("orange") { return "🍊" }
        if lowercasedName.contains("strawberr") { return "🍓" }
        if lowercasedName.contains("grape") { return "🍇" }
        if lowercasedName.contains("watermelon") { return "🍉" }
        if lowercasedName.contains("pineapple") { return "🍍" }
        if lowercasedName.contains("mango") { return "🥭" }
        if lowercasedName.contains("peach") { return "🍑" }
        if lowercasedName.contains("berry") || lowercasedName.contains("berries") { return "🫐" }
        
        // Snacks
        if lowercasedName.contains("chip") { return "🍿" }
        if lowercasedName.contains("pretzel") { return "🥨" }
        if lowercasedName.contains("popcorn") { return "🍿" }
        if lowercasedName.contains("cracker") { return "🍘" }
        if lowercasedName.contains("nut") || lowercasedName.contains("almond") || lowercasedName.contains("peanut") { return "🥜" }
        
        // Bread & baked goods
        if lowercasedName.contains("bread") { return "🍞" }
        if lowercasedName.contains("roll") { return "🥖" }
        
        // Dairy
        if lowercasedName.contains("cheese") { return "🧀" }
        if lowercasedName.contains("milk") { return "🥛" }
        if lowercasedName.contains("yogurt") { return "🥣" }
        
        // Soups & bowls
        if lowercasedName.contains("soup") { return "🍲" }
        if lowercasedName.contains("stew") { return "🍲" }
        if lowercasedName.contains("bowl") { return "🥣" }
        
        // Default fallback - plate with utensils
        return "🍽️"
    }
    
    var macroSummary: String {
        "\(protein)P \(fat)F \(carbs)C"
    }
}