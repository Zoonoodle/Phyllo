//
//  MicronutrientData.swift
//  NutriSync
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

// MARK: - Context Types

enum NutritionContext {
    case postWorkout(intensity: WorkoutIntensity, timeElapsed: TimeInterval)
    case preSleep(hoursUntilSleep: TimeInterval)
    case morning
    case fasting
    case stressed
    case illness
    
    enum WorkoutIntensity {
        case light
        case moderate
        case intense
    }
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
        // Muted shadcn palette for Performance view consistency
        switch self {
        case .energy: return Color.white.opacity(0.7)
        case .strength: return Color.white.opacity(0.6)
        case .focus: return Color.white.opacity(0.5)
        case .immune: return Color.white.opacity(0.5)
        case .heart: return Color.white.opacity(0.6)
        case .antioxidant: return Color.white.opacity(0.7)
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

// MARK: - Guidance Types

enum NutrientGuidanceLevel {
    case needsMore      // User should increase intake
    case adequate       // User has adequate intake
    case excessive      // User is consuming too much (for anti-nutrients)
    case critical       // Critical warning (very high anti-nutrient)
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
    let guidanceThreshold: Double? // Percentage of RDA to show "needs more" guidance (e.g., 0.5 = 50%)
    
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
    
    // Get guidance level based on consumption
    func getGuidanceLevel(consumed: Double) -> NutrientGuidanceLevel {
        if isAntiNutrient {
            guard let limit = dailyLimit else { return .adequate }
            let percentage = consumed / limit
            
            if percentage < 0.8 {
                return .adequate
            } else if percentage < 1.2 {
                return .excessive
            } else {
                return .critical
            }
        } else {
            // For good nutrients, use guidance threshold
            let threshold = guidanceThreshold ?? 0.5
            let percentage = consumed / averageRDA
            
            if percentage < threshold {
                return .needsMore
            } else {
                return .adequate
            }
        }
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
            guidanceThreshold: 0.4, // Show guidance if below 40% RDA
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.6,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.4,
            alternateNames: ["Vit K", "NutriSyncquinone"]
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.6,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.4,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: 0.5,
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
            guidanceThreshold: nil,
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
            guidanceThreshold: nil,
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
            guidanceThreshold: nil,
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
            guidanceThreshold: nil,
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
            guidanceThreshold: nil,
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
            guidanceThreshold: nil,
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
    
    // Context-aware penalty calculation
    static func calculateContextAwarePenalty(
        nutrientName: String,
        consumed: Double,
        limit: Double,
        severity: MicronutrientInfo.AntiNutrientSeverity,
        contexts: [NutritionContext]
    ) -> Double {
        // Get base penalty
        var penalty = calculateAntiNutrientPenalty(consumed: consumed, limit: limit, severity: severity)
        
        // Apply context-based adjustments
        for context in contexts {
            penalty = adjustPenaltyForContext(
                nutrientName: nutrientName,
                basePenalty: penalty,
                context: context
            )
        }
        
        return max(0, penalty) // Never go negative
    }
    
    // Adjust penalty based on context
    private static func adjustPenaltyForContext(
        nutrientName: String,
        basePenalty: Double,
        context: NutritionContext
    ) -> Double {
        let normalizedName = nutrientName.lowercased()
        
        switch context {
        case .postWorkout(let intensity, let timeElapsed):
            // Reduce sodium penalty post-workout (electrolyte replenishment)
            if normalizedName.contains("sodium") || normalizedName.contains("salt") {
                let reductionFactor: Double
                switch intensity {
                case .light:
                    reductionFactor = 0.8 // 20% reduction
                case .moderate:
                    reductionFactor = 0.6 // 40% reduction
                case .intense:
                    reductionFactor = 0.4 // 60% reduction
                }
                
                // Reduction effect diminishes over time (4 hour window)
                let timeFactor = max(0, 1 - (timeElapsed / (4 * 3600)))
                return basePenalty * (1 - ((1 - reductionFactor) * timeFactor))
            }
            
            // Slight sugar tolerance increase post-workout (glycogen replenishment)
            if normalizedName.contains("sugar") && timeElapsed < 3600 { // Within 1 hour
                return basePenalty * 0.7 // 30% reduction
            }
            
        case .preSleep(let hoursUntilSleep):
            // Increase caffeine penalty before sleep
            if normalizedName.contains("caffeine") {
                if hoursUntilSleep < 6 {
                    // Exponentially worse as bedtime approaches
                    let multiplier = 2.0 - (hoursUntilSleep / 6.0)
                    return basePenalty * multiplier
                }
            }
            
            // Sugar before bed is worse (affects sleep quality)
            if normalizedName.contains("sugar") && hoursUntilSleep < 3 {
                return basePenalty * 1.3 // 30% increase
            }
            
        case .morning:
            // Caffeine is more acceptable in morning
            if normalizedName.contains("caffeine") {
                return basePenalty * 0.5 // 50% reduction
            }
            
        case .fasting:
            // All penalties slightly increased during fasting
            return basePenalty * 1.2 // 20% increase
            
        case .stressed:
            // Caffeine penalty increased when stressed
            if normalizedName.contains("caffeine") {
                return basePenalty * 1.4 // 40% increase
            }
            
        case .illness:
            // Reduce penalties slightly as body needs nutrients
            return basePenalty * 0.8 // 20% reduction
        }
        
        return basePenalty
    }
    
    // Get context-aware recommendations
    static func getContextRecommendations(for contexts: [NutritionContext]) -> [String] {
        var recommendations: [String] = []
        
        for context in contexts {
            switch context {
            case .postWorkout(let intensity, _):
                if intensity == .intense {
                    recommendations.append("Consider electrolyte replenishment - sodium needs are elevated")
                    recommendations.append("Protein intake within 30 minutes optimizes recovery")
                }
            case .preSleep(let hours):
                if hours < 3 {
                    recommendations.append("Avoid caffeine and limit sugar for better sleep quality")
                }
            case .morning:
                recommendations.append("Great time for caffeine and B-vitamins for energy")
            case .fasting:
                recommendations.append("Focus on nutrient-dense foods when breaking fast")
            case .stressed:
                recommendations.append("Prioritize magnesium and B-vitamins for stress management")
            case .illness:
                recommendations.append("Increase vitamin C and zinc intake for immune support")
            }
        }
        
        return recommendations
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