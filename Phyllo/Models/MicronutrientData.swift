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