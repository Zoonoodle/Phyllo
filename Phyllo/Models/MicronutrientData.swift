//
//  MicronutrientData.swift
//  Phyllo
//
//  Comprehensive micronutrient and anti-nutrient database with health impact petal system
//

import Foundation
import SwiftUI

// MARK: - Nutrient Types

enum NutrientType {
    case vitamin
    case mineral
    case other
    case antiNutrient
}

// MARK: - Health Impact Categories

enum HealthImpactPetal: String, CaseIterable {
    case energy = "Energy"
    case strength = "Strength & Recovery"
    case focus = "Focus & Mood"
    case immune = "Immune Defense"
    case heart = "Heart Health"
    case antioxidant = "Antioxidant"
    
    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .strength: return "figure.strengthtraining.traditional"
        case .focus: return "brain.head.profile"
        case .immune: return "shield.fill"
        case .heart: return "heart.fill"
        case .antioxidant: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .energy: return .orange
        case .strength: return .blue
        case .focus: return .purple
        case .immune: return .green
        case .heart: return .red
        case .antioxidant: return .yellow
        }
    }
    
    var displayOrder: Int {
        switch self {
        case .energy: return 0
        case .strength: return 1
        case .focus: return 2
        case .immune: return 3
        case .heart: return 4
        case .antioxidant: return 5
        }
    }
}

// MARK: - Micronutrient Model

struct MicronutrientInfo: Identifiable {
    let id = UUID()
    let name: String
    let type: NutrientType
    let unit: String
    let rdaMale: Double
    let rdaFemale: Double
    let healthImpacts: [HealthImpactPetal]
    let isAntiNutrient: Bool
    let dailyLimit: Double? // For anti-nutrients
    let severity: AntiNutrientSeverity?
    
    var averageRDA: Double {
        (rdaMale + rdaFemale) / 2
    }
    
    // Common name variations for matching
    let alternateNames: [String]
    
    enum AntiNutrientSeverity {
        case high
        case medium
        case low
    }
}

// MARK: - Micronutrient Database

struct MicronutrientData: Identifiable {
    let id = UUID()
    let name: String
    let unit: String
    let rda: Double // Recommended Daily Allowance
    
    // MARK: - Comprehensive Nutrient Database
    
    // Vitamins
    static let vitamins: [MicronutrientInfo] = [
        // B Vitamins (Energy focused)
        MicronutrientInfo(
            name: "Vitamin B1",
            type: .vitamin,
            unit: "mg",
            rdaMale: 1.2,
            rdaFemale: 1.1,
            healthImpacts: [.energy],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Thiamine", "B1", "Thiamin"]
        ),
        MicronutrientInfo(
            name: "Vitamin B2",
            type: .vitamin,
            unit: "mg",
            rdaMale: 1.3,
            rdaFemale: 1.1,
            healthImpacts: [.energy],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Riboflavin", "B2"]
        ),
        MicronutrientInfo(
            name: "Vitamin B3",
            type: .vitamin,
            unit: "mg",
            rdaMale: 16,
            rdaFemale: 14,
            healthImpacts: [.energy, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Niacin", "B3", "Nicotinic acid"]
        ),
        MicronutrientInfo(
            name: "Vitamin B6",
            type: .vitamin,
            unit: "mg",
            rdaMale: 1.3,
            rdaFemale: 1.3,
            healthImpacts: [.energy, .focus],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Pyridoxine", "B6"]
        ),
        MicronutrientInfo(
            name: "Vitamin B12",
            type: .vitamin,
            unit: "mcg",
            rdaMale: 2.4,
            rdaFemale: 2.4,
            healthImpacts: [.energy, .focus],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Cobalamin", "B12", "B-12"]
        ),
        MicronutrientInfo(
            name: "Folate",
            type: .vitamin,
            unit: "mcg",
            rdaMale: 400,
            rdaFemale: 400,
            healthImpacts: [.focus, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Folic Acid", "B9", "Vitamin B9"]
        ),
        
        // Fat-soluble vitamins
        MicronutrientInfo(
            name: "Vitamin A",
            type: .vitamin,
            unit: "mcg",
            rdaMale: 900,
            rdaFemale: 700,
            healthImpacts: [.immune, .antioxidant],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Retinol", "Beta-carotene", "Vit A"]
        ),
        MicronutrientInfo(
            name: "Vitamin C",
            type: .vitamin,
            unit: "mg",
            rdaMale: 90,
            rdaFemale: 75,
            healthImpacts: [.immune, .antioxidant],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Ascorbic acid", "Vit C"]
        ),
        MicronutrientInfo(
            name: "Vitamin D",
            type: .vitamin,
            unit: "mcg",
            rdaMale: 15,
            rdaFemale: 15,
            healthImpacts: [.strength, .focus, .immune],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Vit D", "Cholecalciferol", "D3"]
        ),
        MicronutrientInfo(
            name: "Vitamin E",
            type: .vitamin,
            unit: "mg",
            rdaMale: 15,
            rdaFemale: 15,
            healthImpacts: [.antioxidant, .immune],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Tocopherol", "Vit E"]
        ),
        MicronutrientInfo(
            name: "Vitamin K",
            type: .vitamin,
            unit: "mcg",
            rdaMale: 120,
            rdaFemale: 90,
            healthImpacts: [.strength, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Vit K", "Phylloquinone"]
        )
    ]
    
    // Minerals
    static let minerals: [MicronutrientInfo] = [
        MicronutrientInfo(
            name: "Calcium",
            type: .mineral,
            unit: "mg",
            rdaMale: 1000,
            rdaFemale: 1000,
            healthImpacts: [.strength],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Ca"]
        ),
        MicronutrientInfo(
            name: "Iron",
            type: .mineral,
            unit: "mg",
            rdaMale: 8,
            rdaFemale: 18,
            healthImpacts: [.energy, .focus],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Fe"]
        ),
        MicronutrientInfo(
            name: "Magnesium",
            type: .mineral,
            unit: "mg",
            rdaMale: 420,
            rdaFemale: 320,
            healthImpacts: [.energy, .strength, .focus, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Mg"]
        ),
        MicronutrientInfo(
            name: "Phosphorus",
            type: .mineral,
            unit: "mg",
            rdaMale: 700,
            rdaFemale: 700,
            healthImpacts: [.strength],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["P"]
        ),
        MicronutrientInfo(
            name: "Potassium",
            type: .mineral,
            unit: "mg",
            rdaMale: 3400,
            rdaFemale: 2600,
            healthImpacts: [.energy, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["K"]
        ),
        MicronutrientInfo(
            name: "Zinc",
            type: .mineral,
            unit: "mg",
            rdaMale: 11,
            rdaFemale: 8,
            healthImpacts: [.strength, .immune],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Zn"]
        ),
        MicronutrientInfo(
            name: "Selenium",
            type: .mineral,
            unit: "mcg",
            rdaMale: 55,
            rdaFemale: 55,
            healthImpacts: [.immune, .antioxidant],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Se"]
        )
    ]
    
    // Other Nutrients
    static let otherNutrients: [MicronutrientInfo] = [
        MicronutrientInfo(
            name: "Omega-3",
            type: .other,
            unit: "g",
            rdaMale: 1.6,
            rdaFemale: 1.1,
            healthImpacts: [.focus, .heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["DHA", "EPA", "ALA", "Omega-3 fatty acids"]
        ),
        MicronutrientInfo(
            name: "Fiber",
            type: .other,
            unit: "g",
            rdaMale: 38,
            rdaFemale: 25,
            healthImpacts: [.heart],
            isAntiNutrient: false,
            dailyLimit: nil,
            severity: nil,
            alternateNames: ["Dietary fiber"]
        )
    ]
    
    // Anti-Nutrients
    static let antiNutrients: [MicronutrientInfo] = [
        MicronutrientInfo(
            name: "Sodium",
            type: .antiNutrient,
            unit: "mg",
            rdaMale: 1500, // Adequate intake
            rdaFemale: 1500,
            healthImpacts: [.heart, .strength], // Negative impact
            isAntiNutrient: true,
            dailyLimit: 2300,
            severity: .medium,
            alternateNames: ["Na", "Salt"]
        ),
        MicronutrientInfo(
            name: "Added Sugar",
            type: .antiNutrient,
            unit: "g",
            rdaMale: 0,
            rdaFemale: 0,
            healthImpacts: [.energy, .focus, .immune], // Negative impact
            isAntiNutrient: true,
            dailyLimit: 36, // Male limit, female is 25g
            severity: .high,
            alternateNames: ["Sugar", "Added sugars"]
        ),
        MicronutrientInfo(
            name: "Saturated Fat",
            type: .antiNutrient,
            unit: "g",
            rdaMale: 0,
            rdaFemale: 0,
            healthImpacts: [.heart],
            isAntiNutrient: true,
            dailyLimit: 20,
            severity: .medium,
            alternateNames: ["Sat fat", "Saturated fatty acids"]
        ),
        MicronutrientInfo(
            name: "Trans Fat",
            type: .antiNutrient,
            unit: "g",
            rdaMale: 0,
            rdaFemale: 0,
            healthImpacts: [.heart],
            isAntiNutrient: true,
            dailyLimit: 0,
            severity: .high,
            alternateNames: ["Trans fatty acids", "Trans fats"]
        ),
        MicronutrientInfo(
            name: "Caffeine",
            type: .antiNutrient,
            unit: "mg",
            rdaMale: 0,
            rdaFemale: 0,
            healthImpacts: [.energy, .focus], // Can be positive or negative
            isAntiNutrient: true,
            dailyLimit: 400,
            severity: .low,
            alternateNames: []
        ),
        MicronutrientInfo(
            name: "Cholesterol",
            type: .antiNutrient,
            unit: "mg",
            rdaMale: 0,
            rdaFemale: 0,
            healthImpacts: [.heart],
            isAntiNutrient: true,
            dailyLimit: 300,
            severity: .low,
            alternateNames: []
        )
    ]
    
    // MARK: - Helper Methods
    
    static func getAllMicronutrients() -> [MicronutrientInfo] {
        return vitamins + minerals + otherNutrients + antiNutrients
    }
    
    static func getNutrient(byName name: String) -> MicronutrientInfo? {
        let allNutrients = getAllMicronutrients()
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return allNutrients.first { nutrient in
            let nutrientNameLower = nutrient.name.lowercased()
            let alternateNamesLower = nutrient.alternateNames.map { $0.lowercased() }
            
            return nutrientNameLower == normalizedName ||
                   nutrientNameLower.contains(normalizedName) ||
                   normalizedName.contains(nutrientNameLower) ||
                   alternateNamesLower.contains(normalizedName) ||
                   alternateNamesLower.contains { $0.contains(normalizedName) || normalizedName.contains($0) }
        }
    }
    
    static func getNutrientsForPetal(_ petal: HealthImpactPetal) -> [MicronutrientInfo] {
        return getAllMicronutrients().filter { $0.healthImpacts.contains(petal) }
    }
    
    // Calculate penalty for anti-nutrients
    static func calculateAntiNutrientPenalty(consumed: Double, limit: Double, severity: MicronutrientInfo.AntiNutrientSeverity) -> Double {
        let percentage = consumed / limit
        
        // Safe zone (0-80%)
        if percentage <= 0.8 {
            return 0
        }
        
        // Calculate base penalty based on zone
        var penalty: Double = 0
        
        if percentage <= 1.2 { // Caution zone (80-120%)
            penalty = (percentage - 0.8) * 25 // 0 to 10% penalty
        } else if percentage <= 2.0 { // Excess zone (120-200%)
            penalty = 10 + (percentage - 1.2) * 25 // 10 to 30% penalty
        } else { // Danger zone (200%+)
            penalty = 30
        }
        
        // Apply severity multiplier
        switch severity {
        case .high:
            penalty *= 1.5
        case .medium:
            penalty *= 1.0
        case .low:
            penalty *= 0.7
        }
        
        return min(penalty, 30) // Cap at 30%
    }
    
    // Legacy support - convert to old format
    static func getAllNutrients() -> [MicronutrientData] {
        return getAllMicronutrients()
            .filter { !$0.isAntiNutrient }
            .map { nutrient in
                MicronutrientData(
                    name: nutrient.name,
                    unit: nutrient.unit,
                    rda: nutrient.averageRDA
                )
            }
    }
}

// MARK: - Legacy Support Structures

// Keep for backward compatibility
struct Micronutrient: Identifiable {
    let id = UUID()
    let name: String
    let rda: Double // Recommended Daily Allowance in the base unit
    let unit: String // mg, mcg, etc.
    let dailyTarget: Double // Same as RDA for backward compatibility
    let icon: String // Icon to display
    
    init(name: String, rda: Double, unit: String, icon: String = "💊") {
        self.name = name
        self.rda = rda
        self.unit = unit
        self.dailyTarget = rda
        self.icon = icon
    }
}

// Old micronutrient tracking structure
struct MicronutrientConsumption {
    let info: Micronutrient
    let consumed: Double
    
    var percentage: Double {
        consumed / info.rda
    }
    
    var displayString: String {
        "\(Int(consumed))/\(Int(info.rda))\(info.unit)"
    }
}

// Micronutrient unit types - keeping for compatibility
enum MicronutrientUnit: String {
    case micrograms = "μg"
    case milligrams = "mg"
    case grams = "g"
    case internationalUnits = "IU"
}