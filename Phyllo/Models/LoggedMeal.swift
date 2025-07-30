//
//  LoggedMeal.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

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