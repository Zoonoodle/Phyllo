//
//  GoalCalculationService.swift
//  NutriSync
//
//  Created on 8/10/25.
//

import Foundation

/// Service for calculating personalized nutrition goals based on user stats and objectives
class GoalCalculationService {
    static let shared = GoalCalculationService()
    
    private init() {}
    
    // MARK: - Goal Types
    
    enum GoalType {
        case specificWeightTarget(currentWeight: Double, targetWeight: Double, weeks: Int)
        case bodyComposition(currentWeight: Double, currentBF: Double?, targetBF: Double?, focus: CompositionFocus)
        case performanceOptimization(currentWeight: Double, activityLevel: ActivityLevel)
    }
    
    enum CompositionFocus {
        case leanMuscleGain
        case fatLoss
        case recomposition // Simultaneous muscle gain and fat loss
    }
    
    struct NutritionTargets {
        let dailyCalories: Int
        let macroProfile: MacroProfile  // User's macro distribution profile
        let deficit: Int? // Calorie deficit if applicable
        let surplus: Int? // Calorie surplus if applicable
        let weeklyWeightChange: Double // Expected pounds per week

        // Computed properties for backward compatibility
        var protein: Int {
            macroProfile.calculateGrams(calories: dailyCalories).protein
        }
        var carbs: Int {
            macroProfile.calculateGrams(calories: dailyCalories).carbs
        }
        var fat: Int {
            macroProfile.calculateGrams(calories: dailyCalories).fat
        }
    }
    
    // MARK: - TDEE Calculation
    
    /// Calculate Total Daily Energy Expenditure using Mifflin-St Jeor equation
    func calculateTDEE(
        weight: Double, // pounds
        height: Double, // inches
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> Double {
        // Convert to metric
        let weightKg = weight * 0.453592
        let heightCm = height * 2.54
        
        // Mifflin-St Jeor BMR calculation
        let bmr: Double
        switch gender {
        case .male:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        case .female:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        case .other, .preferNotToSay:
            // Use average of male and female calculations
            let maleBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
            let femaleBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
            bmr = (maleBMR + femaleBMR) / 2
        }
        
        // Apply activity multiplier
        let activityMultiplier: Double
        switch activityLevel {
        case .sedentary:
            activityMultiplier = 1.2
        case .lightlyActive:
            activityMultiplier = 1.375
        case .moderatelyActive:
            activityMultiplier = 1.55
        case .veryActive:
            activityMultiplier = 1.725
        case .extremelyActive:
            activityMultiplier = 1.9
        }
        
        return bmr * activityMultiplier
    }
    
    // MARK: - Goal Calculation
    
    /// Calculate nutrition targets based on goal type
    func calculateTargets(
        for goal: GoalType,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> NutritionTargets {
        switch goal {
        case .specificWeightTarget(let current, let target, let weeks):
            return calculateWeightGoalTargets(
                currentWeight: current,
                targetWeight: target,
                weeks: weeks,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activityLevel
            )
            
        case .bodyComposition(let weight, let currentBF, let targetBF, let focus):
            return calculateCompositionTargets(
                weight: weight,
                currentBF: currentBF,
                targetBF: targetBF,
                focus: focus,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activityLevel
            )
            
        case .performanceOptimization(let weight, let activity):
            return calculatePerformanceTargets(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activity
            )
        }
    }
    
    // MARK: - Specific Weight Target Calculation
    
    private func calculateWeightGoalTargets(
        currentWeight: Double,
        targetWeight: Double,
        weeks: Int,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> NutritionTargets {
        let tdee = calculateTDEE(weight: currentWeight, height: height, age: age, gender: gender, activityLevel: activityLevel)
        let totalWeightChange = targetWeight - currentWeight
        let weeklyWeightChange = totalWeightChange / Double(weeks)
        
        // Safe weight change: 0.5-2 lbs per week for loss, 0.5-1 lb for gain
        let safeWeeklyChange: Double
        if totalWeightChange < 0 { // Weight loss
            safeWeeklyChange = max(weeklyWeightChange, -2.0)
        } else { // Weight gain
            safeWeeklyChange = min(weeklyWeightChange, 1.0)
        }
        
        // Calculate daily calorie adjustment (3500 calories = 1 pound)
        let dailyCalorieAdjustment = Int(safeWeeklyChange * 3500 / 7)
        let dailyCalories = Int(tdee) + dailyCalorieAdjustment

        // Get macro profile based on goal direction
        let goal: UserGoals.Goal = totalWeightChange < 0 ? .loseWeight : .buildMuscle
        let macroProfile = MacroCalculationService.getProfile(for: goal)

        return NutritionTargets(
            dailyCalories: dailyCalories,
            macroProfile: macroProfile,
            deficit: dailyCalorieAdjustment < 0 ? abs(dailyCalorieAdjustment) : nil,
            surplus: dailyCalorieAdjustment > 0 ? dailyCalorieAdjustment : nil,
            weeklyWeightChange: safeWeeklyChange
        )
    }
    
    // MARK: - Body Composition Target Calculation
    
    private func calculateCompositionTargets(
        weight: Double,
        currentBF: Double?,
        targetBF: Double?,
        focus: CompositionFocus,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> NutritionTargets {
        let tdee = calculateTDEE(weight: weight, height: height, age: age, gender: gender, activityLevel: activityLevel)
        
        // Calculate targets based on composition focus
        let (calorieAdjustment, weeklyChange) = calculateCompositionAdjustment(
            focus: focus,
            weight: weight,
            currentBF: currentBF,
            targetBF: targetBF,
            gender: gender
        )
        
        let dailyCalories = Int(tdee) + calorieAdjustment

        // Get macro profile based on composition focus
        let goal: UserGoals.Goal = switch focus {
            case .leanMuscleGain: .buildMuscle
            case .fatLoss: .loseWeight
            case .recomposition: .loseWeight  // Use weight loss profile for recomp
        }
        let macroProfile = MacroCalculationService.getProfile(for: goal)

        return NutritionTargets(
            dailyCalories: dailyCalories,
            macroProfile: macroProfile,
            deficit: calorieAdjustment < 0 ? abs(calorieAdjustment) : nil,
            surplus: calorieAdjustment > 0 ? calorieAdjustment : nil,
            weeklyWeightChange: weeklyChange
        )
    }
    
    // MARK: - Performance Target Calculation
    
    private func calculatePerformanceTargets(
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> NutritionTargets {
        let tdee = calculateTDEE(weight: weight, height: height, age: age, gender: gender, activityLevel: activityLevel)
        
        // Performance goals typically maintain or slightly surplus
        let dailyCalories = Int(tdee * 1.05) // 5% surplus for recovery

        // Get macro profile for performance goals
        let macroProfile = MacroCalculationService.getProfile(for: .improvePerformance)

        return NutritionTargets(
            dailyCalories: dailyCalories,
            macroProfile: macroProfile,
            deficit: nil,
            surplus: Int(tdee * 0.05),
            weeklyWeightChange: 0.0
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateCompositionAdjustment(
        focus: CompositionFocus,
        weight: Double,
        currentBF: Double?,
        targetBF: Double?,
        gender: Gender
    ) -> (adjustment: Int, weeklyChange: Double) {
        switch focus {
        case .leanMuscleGain:
            // Conservative surplus for lean gains
            return (300, 0.5) // 300 cal surplus, 0.5 lb/week gain
            
        case .fatLoss:
            // Moderate deficit to preserve muscle
            return (-500, -1.0) // 500 cal deficit, 1 lb/week loss
            
        case .recomposition:
            // Slight deficit or maintenance with high protein
            return (-200, -0.25) // 200 cal deficit, 0.25 lb/week loss
        }
    }

    // MARK: - DEPRECATED: Old macro calculation method
    // This method has been replaced by MacroCalculationService
    // Kept for reference only - remove after verification
    /*
    private func calculateMacros(
        calories: Int,
        weight: Double,
        isWeightLoss: Bool,
        activityLevel: ActivityLevel,
        highProtein: Bool = false,
        performance: Bool = false
    ) -> (protein: Int, carbs: Int, fat: Int) {
        // DEPRECATED - See MacroCalculationService.swift
    }
    */

    // MARK: - Default Body Fat Estimation
    
    /// Estimate body fat percentage based on gender and BMI if not provided
    func estimateBodyFat(weight: Double, height: Double, gender: Gender, age: Int) -> Double {
        let bmi = (weight * 703) / (height * height)
        
        // Very rough estimation based on BMI and demographics
        switch gender {
        case .male:
            return (1.20 * bmi) + (0.23 * Double(age)) - 16.2
        case .female:
            return (1.20 * bmi) + (0.23 * Double(age)) - 5.4
        case .other, .preferNotToSay:
            // Average of male and female calculations
            let male = (1.20 * bmi) + (0.23 * Double(age)) - 16.2
            let female = (1.20 * bmi) + (0.23 * Double(age)) - 5.4
            return (male + female) / 2
        }
    }
}