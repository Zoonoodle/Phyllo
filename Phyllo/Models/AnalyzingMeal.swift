//
//  AnalyzingMeal.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import Foundation

struct AnalyzingMeal: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    var windowId: UUID? // Which window this meal will belong to
    let imageData: Data? // Store captured image data
    let voiceDescription: String? // Optional voice description
    
    // Convert to LoggedMeal once analysis is complete
    func toLoggedMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int) -> LoggedMeal {
        LoggedMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            windowId: windowId
        )
    }
}