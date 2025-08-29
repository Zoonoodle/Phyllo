import Foundation
import UIKit

// MARK: - Meal Analysis Models
// Shared models for AI meal analysis

struct MealAnalysisRequest {
    let image: UIImage?
    let voiceTranscript: String?
    let userContext: UserNutritionContext
    let mealWindow: MealWindow?
}

struct UserNutritionContext {
    let primaryGoal: NutritionGoal
    let dailyCalorieTarget: Int
    let dailyProteinTarget: Int
    let dailyCarbTarget: Int
    let dailyFatTarget: Int
    
    var dailyMacros: String {
        "\(dailyCalorieTarget) cal, \(dailyProteinTarget)g protein, \(dailyCarbTarget)g carbs, \(dailyFatTarget)g fat"
    }
}

struct MealAnalysisResult: Codable {
    let mealName: String
    let confidence: Double
    let ingredients: [AnalyzedIngredient]
    var nutrition: NutritionInfo  // Made mutable for V2 calorie-macro consistency
    var micronutrients: [MicronutrientInfo]  // Made mutable for V2 goal-based prioritization
    let clarifications: [ClarificationQuestion]
    // Model can request additional analysis tools
    let requestedTools: [String]?
    let brandDetected: String?
    
    struct AnalyzedIngredient: Codable {
        let name: String
        let amount: String
        let unit: String
        let foodGroup: String
        // Optional nutrition for individual ingredients
        let nutrition: NutritionInfo?
        
        // Backward compatibility initializer
        init(name: String, amount: String, unit: String, foodGroup: String, nutrition: NutritionInfo? = nil) {
            self.name = name
            self.amount = amount
            self.unit = unit
            self.foodGroup = foodGroup
            self.nutrition = nutrition
        }
    }
    
    struct NutritionInfo: Codable {
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
    }
    
    struct MicronutrientInfo: Codable {
        let name: String
        let amount: Double
        let unit: String
        let percentRDA: Double
    }
    
    struct ClarificationQuestion: Codable {
        let question: String
        let options: [ClarificationOption]
        let clarificationType: String
    }
    
    struct ClarificationOption: Codable {
        let text: String
        let calorieImpact: Int
        let proteinImpact: Double?
        let carbImpact: Double?
        let fatImpact: Double?
        let isRecommended: Bool?
        let note: String?
    }
}