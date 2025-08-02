//
//  MicronutrientData.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import Foundation

// Micronutrient unit types
enum MicronutrientUnit: String {
    case micrograms = "μg"
    case milligrams = "mg"
    case grams = "g"
    case internationalUnits = "IU"
}

// Comprehensive micronutrient data
struct MicronutrientInfo {
    let name: String
    let icon: String
    let unit: MicronutrientUnit
    let dailyTarget: Double  // RDA (Recommended Daily Allowance)
    
    // Common micronutrients with their RDA values
    static let b12 = MicronutrientInfo(name: "B12", icon: "🔋", unit: .micrograms, dailyTarget: 2.4)
    static let iron = MicronutrientInfo(name: "Iron", icon: "💪", unit: .milligrams, dailyTarget: 18.0)
    static let magnesium = MicronutrientInfo(name: "Magnesium", icon: "⚡", unit: .milligrams, dailyTarget: 400.0)
    static let omega3 = MicronutrientInfo(name: "Omega-3", icon: "🧠", unit: .grams, dailyTarget: 1.6)
    static let b6 = MicronutrientInfo(name: "B6", icon: "🎯", unit: .milligrams, dailyTarget: 1.7)
    static let vitaminD = MicronutrientInfo(name: "Vitamin D", icon: "☀️", unit: .internationalUnits, dailyTarget: 800.0)
    static let vitaminC = MicronutrientInfo(name: "Vitamin C", icon: "🍊", unit: .milligrams, dailyTarget: 90.0)
    static let zinc = MicronutrientInfo(name: "Zinc", icon: "🛡️", unit: .milligrams, dailyTarget: 11.0)
    static let potassium = MicronutrientInfo(name: "Potassium", icon: "💧", unit: .milligrams, dailyTarget: 3500.0)
    static let bComplex = MicronutrientInfo(name: "B-Complex", icon: "⚡", unit: .milligrams, dailyTarget: 50.0)
    static let caffeine = MicronutrientInfo(name: "Caffeine", icon: "☕", unit: .milligrams, dailyTarget: 400.0)
    static let lArginine = MicronutrientInfo(name: "L-Arginine", icon: "💪", unit: .grams, dailyTarget: 6.0)
    static let protein = MicronutrientInfo(name: "Protein", icon: "🥩", unit: .grams, dailyTarget: 50.0)
    static let leucine = MicronutrientInfo(name: "Leucine", icon: "💪", unit: .grams, dailyTarget: 2.5)
    static let greenTea = MicronutrientInfo(name: "Green Tea", icon: "🍵", unit: .milligrams, dailyTarget: 200.0)
    static let chromium = MicronutrientInfo(name: "Chromium", icon: "🔥", unit: .micrograms, dailyTarget: 35.0)
    static let lCarnitine = MicronutrientInfo(name: "L-Carnitine", icon: "⚡", unit: .grams, dailyTarget: 2.0)
    static let tryptophan = MicronutrientInfo(name: "Tryptophan", icon: "🌙", unit: .milligrams, dailyTarget: 250.0)
}

// Tracking consumed micronutrients
struct MicronutrientConsumption {
    let info: MicronutrientInfo
    var consumed: Double
    
    var percentage: Double {
        consumed / info.dailyTarget
    }
    
    // Format consumed/target string with unit
    var displayString: String {
        let consumedFormatted: String
        let targetFormatted: String
        
        // Format based on unit type and amount
        switch info.unit {
        case .micrograms:
            consumedFormatted = String(format: "%.1f", consumed)
            targetFormatted = String(format: "%.1f", info.dailyTarget)
        case .milligrams:
            if consumed >= 100 || info.dailyTarget >= 100 {
                consumedFormatted = String(format: "%.0f", consumed)
                targetFormatted = String(format: "%.0f", info.dailyTarget)
            } else {
                consumedFormatted = String(format: "%.1f", consumed)
                targetFormatted = String(format: "%.1f", info.dailyTarget)
            }
        case .grams:
            consumedFormatted = String(format: "%.1f", consumed)
            targetFormatted = String(format: "%.1f", info.dailyTarget)
        case .internationalUnits:
            consumedFormatted = String(format: "%.0f", consumed)
            targetFormatted = String(format: "%.0f", info.dailyTarget)
        }
        
        return "\(consumedFormatted) / \(targetFormatted) \(info.unit.rawValue)"
    }
}

// MARK: - Micronutrient Data Model

struct MicronutrientData: Identifiable {
    let id = UUID()
    let name: String
    let unit: String
    let rda: Double // Recommended Daily Allowance
    
    // Static list of all tracked micronutrients
    static func getAllNutrients() -> [MicronutrientData] {
        return [
            MicronutrientData(name: "Vitamin A", unit: "mcg", rda: 900),
            MicronutrientData(name: "Vitamin C", unit: "mg", rda: 90),
            MicronutrientData(name: "Vitamin D", unit: "IU", rda: 600),
            MicronutrientData(name: "Vitamin E", unit: "mg", rda: 15),
            MicronutrientData(name: "Vitamin K", unit: "mcg", rda: 120),
            MicronutrientData(name: "B1 Thiamine", unit: "mg", rda: 1.2),
            MicronutrientData(name: "B2 Riboflavin", unit: "mg", rda: 1.3),
            MicronutrientData(name: "B3 Niacin", unit: "mg", rda: 16),
            MicronutrientData(name: "B6", unit: "mg", rda: 1.7),
            MicronutrientData(name: "B12", unit: "mcg", rda: 2.4),
            MicronutrientData(name: "Folate", unit: "mcg", rda: 400),
            MicronutrientData(name: "Calcium", unit: "mg", rda: 1000),
            MicronutrientData(name: "Iron", unit: "mg", rda: 18),
            MicronutrientData(name: "Magnesium", unit: "mg", rda: 400),
            MicronutrientData(name: "Zinc", unit: "mg", rda: 11),
            MicronutrientData(name: "Potassium", unit: "mg", rda: 3500),
            MicronutrientData(name: "Omega-3", unit: "g", rda: 1.6),
            MicronutrientData(name: "Fiber", unit: "g", rda: 28)
        ]
    }
}