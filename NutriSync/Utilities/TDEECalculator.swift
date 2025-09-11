//
//  TDEECalculator.swift
//  NutriSync
//
//  Calculates Total Daily Energy Expenditure using Mifflin-St Jeor equation
//

import Foundation

struct TDEECalculator {
    
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extremelyActive = "Extremely Active"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Little to no exercise"
            case .lightlyActive: return "Light exercise 1-3 days/week"
            case .moderatelyActive: return "Moderate exercise 3-5 days/week"
            case .veryActive: return "Hard exercise 6-7 days/week"
            case .extremelyActive: return "Very hard exercise, physical job"
            }
        }
    }
    
    // Mifflin-St Jeor equation for BMR
    static func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        // weight in kg, height in cm
        switch gender {
        case .male:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }
    
    // Apply activity multiplier to get TDEE
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }
    
    // Combined calculation
    static func calculate(
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> Double {
        let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender)
        return calculateTDEE(bmr: bmr, activityLevel: activityLevel)
    }
    
    // Convert between units if needed
    static func lbsToKg(_ lbs: Double) -> Double {
        return lbs * 0.453592
    }
    
    static func kgToLbs(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet * 12 + inches)
        return totalInches * 2.54
    }
    
    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
}