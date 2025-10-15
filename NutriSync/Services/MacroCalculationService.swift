//
//  MacroCalculationService.swift
//  NutriSync
//
//  Created on 10/15/25.
//  Single source of truth for all macro calculations
//

import Foundation

// MARK: - Macro Profile

/// Represents a user's macro nutrient distribution profile
struct MacroProfile: Codable, Equatable {
    let proteinPercentage: Double  // 0.0 - 1.0
    let carbPercentage: Double
    let fatPercentage: Double
    let goal: UserGoals.Goal
    let isCustomized: Bool

    // MARK: - Initialization

    init(proteinPercentage: Double, carbPercentage: Double, fatPercentage: Double, goal: UserGoals.Goal, isCustomized: Bool = false) {
        self.proteinPercentage = proteinPercentage
        self.carbPercentage = carbPercentage
        self.fatPercentage = fatPercentage
        self.goal = goal
        self.isCustomized = isCustomized
    }

    // MARK: - Calculations

    /// Calculate macro grams from total calories
    func calculateGrams(calories: Int) -> (protein: Int, carbs: Int, fat: Int) {
        let proteinCalories = Double(calories) * proteinPercentage
        let carbCalories = Double(calories) * carbPercentage
        let fatCalories = Double(calories) * fatPercentage

        return (
            protein: Int(proteinCalories / 4),  // 4 cal/g protein
            carbs: Int(carbCalories / 4),        // 4 cal/g carbs
            fat: Int(fatCalories / 9)            // 9 cal/g fat
        )
    }

    // MARK: - Validation

    /// Validates that percentages add up to 100%
    func validate() -> Bool {
        let total = proteinPercentage + carbPercentage + fatPercentage
        return abs(total - 1.0) < 0.01  // Allow for small floating point errors
    }

    /// Get total percentage (for debugging)
    var totalPercentage: Double {
        proteinPercentage + carbPercentage + fatPercentage
    }

    // MARK: - Display Helpers

    var proteinPercentageInt: Int {
        Int(proteinPercentage * 100)
    }

    var carbPercentageInt: Int {
        Int(carbPercentage * 100)
    }

    var fatPercentageInt: Int {
        Int(fatPercentage * 100)
    }
}

// MARK: - Macro Calculation Service

/// Centralized service for all macro calculations
/// Replaces scattered logic across GoalCalculationService, OnboardingCompletionViewModel, etc.
enum MacroCalculationService {

    // MARK: - Goal-Specific Profiles

    /// Research-backed macro profiles for each goal type
    /// Based on current nutrition science for optimal results
    static let profiles: [UserGoals.Goal: MacroProfile] = [
        // Weight Loss: Higher protein (preserves muscle, increases satiety)
        // Higher fat (satiety), moderate-low carbs
        .loseWeight: MacroProfile(
            proteinPercentage: 0.35,
            carbPercentage: 0.30,
            fatPercentage: 0.35,
            goal: .loseWeight
        ),

        // Build Muscle: Moderate-high protein, higher carbs (energy for training)
        // Lower fat to allocate more calories to protein/carbs
        .buildMuscle: MacroProfile(
            proteinPercentage: 0.30,
            carbPercentage: 0.45,
            fatPercentage: 0.25,
            goal: .buildMuscle
        ),

        // Improve Performance: High carbs (fuel), moderate protein
        // Lower fat to maximize carb intake
        .improvePerformance: MacroProfile(
            proteinPercentage: 0.25,
            carbPercentage: 0.50,
            fatPercentage: 0.25,
            goal: .improvePerformance
        ),

        // Better Sleep: Higher fat and moderate protein (satiety, blood sugar stability)
        // Lower carbs to reduce insulin spikes before bed
        .betterSleep: MacroProfile(
            proteinPercentage: 0.30,
            carbPercentage: 0.35,
            fatPercentage: 0.35,
            goal: .betterSleep
        ),

        // Overall Health: Balanced approach
        .overallHealth: MacroProfile(
            proteinPercentage: 0.30,
            carbPercentage: 0.40,
            fatPercentage: 0.30,
            goal: .overallHealth
        ),

        // Maintain Weight: Balanced approach
        .maintainWeight: MacroProfile(
            proteinPercentage: 0.30,
            carbPercentage: 0.40,
            fatPercentage: 0.30,
            goal: .maintainWeight
        )
    ]

    // MARK: - Window-Specific Distributions

    /// Window purposes for macro distribution
    enum WindowPurpose: String {
        case preWorkout
        case postWorkout
        case metabolicBoost
        case sustainedEnergy
        case sleepOptimization
        case focusBoost
        case recovery
    }

    /// Recommended macro distributions for each window purpose
    /// These override daily ratios to optimize for specific physiological needs
    /// Format: (protein %, carbs %, fat %)
    static let windowDistributions: [WindowPurpose: (protein: Double, carbs: Double, fat: Double)] = [
        // Pre-Workout: High carbs for fuel, low fat to avoid digestion issues
        .preWorkout: (protein: 0.20, carbs: 0.60, fat: 0.20),

        // Post-Workout: High protein for recovery, high carbs for glycogen replenishment
        .postWorkout: (protein: 0.40, carbs: 0.45, fat: 0.15),

        // Metabolic Boost (Morning): Balanced to kickstart metabolism
        .metabolicBoost: (protein: 0.30, carbs: 0.40, fat: 0.30),

        // Sustained Energy (Midday): Balanced with slight carb preference
        .sustainedEnergy: (protein: 0.25, carbs: 0.45, fat: 0.30),

        // Sleep Optimization (Evening): Low carbs to avoid insulin spikes, higher fat for satiety
        .sleepOptimization: (protein: 0.30, carbs: 0.25, fat: 0.45),

        // Focus Boost: Balanced for cognitive function
        .focusBoost: (protein: 0.30, carbs: 0.40, fat: 0.30),

        // Recovery: Higher protein for repair
        .recovery: (protein: 0.35, carbs: 0.40, fat: 0.25)
    ]

    // MARK: - Profile Retrieval

    /// Get the recommended profile for a goal
    static func getProfile(for goal: UserGoals.Goal) -> MacroProfile {
        return profiles[goal] ?? profiles[.overallHealth]!
    }

    /// Get window-specific macro distribution
    static func getWindowDistribution(for purpose: WindowPurpose) -> (protein: Double, carbs: Double, fat: Double) {
        return windowDistributions[purpose] ?? (protein: 0.30, carbs: 0.40, fat: 0.30)
    }

    // MARK: - Validation

    /// Validation errors
    enum MacroValidationError: Error, LocalizedError {
        case percentagesDontAddUp(total: Double)
        case negativePercentages
        case extremeRatios(field: String, value: Double)

        var errorDescription: String? {
            switch self {
            case .percentagesDontAddUp(let total):
                return "Macro percentages must add up to 100% (currently \(Int(total * 100))%)"
            case .negativePercentages:
                return "Macro percentages cannot be negative"
            case .extremeRatios(let field, let value):
                return "\(field) percentage (\(Int(value * 100))%) is outside healthy range"
            }
        }
    }

    /// Validate a custom macro profile
    static func validate(profile: MacroProfile) -> Result<Void, MacroValidationError> {
        // Check for negative values
        if profile.proteinPercentage < 0 || profile.carbPercentage < 0 || profile.fatPercentage < 0 {
            return .failure(.negativePercentages)
        }

        // Check total adds to 100% (with small tolerance for floating point)
        let total = profile.proteinPercentage + profile.carbPercentage + profile.fatPercentage
        if abs(total - 1.0) > 0.01 {
            return .failure(.percentagesDontAddUp(total: total))
        }

        // Check for extreme ratios (health safety)
        if profile.proteinPercentage < 0.15 {
            return .failure(.extremeRatios(field: "Protein", value: profile.proteinPercentage))
        }
        if profile.proteinPercentage > 0.50 {
            return .failure(.extremeRatios(field: "Protein", value: profile.proteinPercentage))
        }
        if profile.carbPercentage < 0.15 {
            return .failure(.extremeRatios(field: "Carbs", value: profile.carbPercentage))
        }
        if profile.carbPercentage > 0.60 {
            return .failure(.extremeRatios(field: "Carbs", value: profile.carbPercentage))
        }
        if profile.fatPercentage < 0.15 {
            return .failure(.extremeRatios(field: "Fat", value: profile.fatPercentage))
        }
        if profile.fatPercentage > 0.50 {
            return .failure(.extremeRatios(field: "Fat", value: profile.fatPercentage))
        }

        return .success(())
    }

    // MARK: - Common Presets

    /// Common preset configurations users can choose
    static let commonPresets: [String: (protein: Double, carbs: Double, fat: Double)] = [
        "Balanced": (protein: 0.30, carbs: 0.40, fat: 0.30),
        "High Protein": (protein: 0.40, carbs: 0.30, fat: 0.30),
        "Low Carb": (protein: 0.35, carbs: 0.25, fat: 0.40),
        "Athlete": (protein: 0.25, carbs: 0.50, fat: 0.25)
    ]
}

// MARK: - Firestore Extensions

extension MacroProfile {
    /// Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        return [
            "proteinPercentage": proteinPercentage,
            "carbPercentage": carbPercentage,
            "fatPercentage": fatPercentage,
            "goal": goal.rawValue,
            "isCustomized": isCustomized
        ]
    }

    /// Initialize from Firestore data
    static func fromFirestore(_ data: [String: Any]) -> MacroProfile? {
        guard let proteinPercentage = data["proteinPercentage"] as? Double,
              let carbPercentage = data["carbPercentage"] as? Double,
              let fatPercentage = data["fatPercentage"] as? Double,
              let goalString = data["goal"] as? String,
              let goal = UserGoals.Goal(rawValue: goalString) else {
            return nil
        }

        let isCustomized = data["isCustomized"] as? Bool ?? false

        return MacroProfile(
            proteinPercentage: proteinPercentage,
            carbPercentage: carbPercentage,
            fatPercentage: fatPercentage,
            goal: goal,
            isCustomized: isCustomized
        )
    }
}
