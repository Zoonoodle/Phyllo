//
//  InsightsEngine.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Calculates real-time nutrition insights based on actual user data

import Foundation
import SwiftUI

class InsightsEngine: ObservableObject {
    static let shared = InsightsEngine()
    
    @Published var currentPhylloScore: Int = 0
    @Published var scoreBreakdown: ScoreBreakdown?
    @Published var micronutrientStatus: MicronutrientStatus?
    @Published var topInsights: [Insight] = []
    
    private init() {}
    
    // MARK: - PhylloScore Calculation
    
    struct ScoreBreakdown {
        let totalScore: Int
        let mealTimingScore: Int     // Max 25 points
        let macroBalanceScore: Int   // Max 25 points
        let micronutrientScore: Int  // Max 25 points
        let consistencyScore: Int    // Max 25 points
        let trend: ScoreTrend
        
        enum ScoreTrend {
            case improving
            case stable
            case declining
            
            var icon: String {
                switch self {
                case .improving: return "arrow.up.circle.fill"
                case .stable: return "equal.circle.fill"
                case .declining: return "arrow.down.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .improving: return .green
                case .stable: return .orange
                case .declining: return .red
                }
            }
        }
    }
    
    func calculatePhylloScore(
        todayMeals: [LoggedMeal],
        mealWindows: [MealWindow],
        checkIns: [PostMealCheckIn],
        primaryGoal: NutritionGoal
    ) -> ScoreBreakdown {
        // 1. Meal Timing Score (25 points)
        let timingScore = calculateMealTimingScore(meals: todayMeals, windows: mealWindows)
        
        // 2. Macro Balance Score (25 points)
        let macroScore = calculateMacroBalanceScore(meals: todayMeals, primaryGoal: primaryGoal)
        
        // 3. Micronutrient Score (25 points)
        let microScore = calculateMicronutrientScore(meals: todayMeals)
        
        // 4. Consistency Score (25 points)
        let consistencyScore = calculateConsistencyScore(
            todayMeals: todayMeals,
            checkIns: checkIns,
            windows: mealWindows
        )
        
        let totalScore = timingScore + macroScore + microScore + consistencyScore
        
        // Determine trend (would need historical data in real app)
        let trend: ScoreBreakdown.ScoreTrend = {
            if totalScore > 75 { return .improving }
            else if totalScore > 50 { return .stable }
            else { return .declining }
        }()
        
        return ScoreBreakdown(
            totalScore: totalScore,
            mealTimingScore: timingScore,
            macroBalanceScore: macroScore,
            micronutrientScore: microScore,
            consistencyScore: consistencyScore,
            trend: trend
        )
    }
    
    private func calculateMealTimingScore(meals: [LoggedMeal], windows: [MealWindow]) -> Int {
        guard !meals.isEmpty && !windows.isEmpty else { return 0 }
        
        var score = 0
        let maxScore = 25
        
        // Check how many meals were eaten within their designated windows
        let mealsInWindows = meals.filter { meal in
            windows.contains { window in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }
        
        let windowAdherence = Double(mealsInWindows.count) / Double(meals.count)
        score = Int(windowAdherence * Double(maxScore))
        
        return score
    }
    
    private func calculateMacroBalanceScore(meals: [LoggedMeal], primaryGoal: NutritionGoal) -> Int {
        guard !meals.isEmpty else { return 0 }
        
        let totalProtein = meals.reduce(0) { $0 + $1.protein }
        let totalCarbs = meals.reduce(0) { $0 + $1.carbs }
        let totalFat = meals.reduce(0) { $0 + $1.fat }
        let totalCalories = meals.reduce(0) { $0 + $1.calories }
        
        // Target macro ratios based on goal
        let (targetProteinRatio, targetCarbRatio, targetFatRatio) = getTargetMacroRatios(for: primaryGoal)
        
        // Calculate actual ratios
        let proteinCalories = totalProtein * 4
        let carbCalories = totalCarbs * 4
        let fatCalories = totalFat * 9
        
        guard totalCalories > 0 else { return 0 }
        
        let actualProteinRatio = Double(proteinCalories) / Double(totalCalories)
        let actualCarbRatio = Double(carbCalories) / Double(totalCalories)
        let actualFatRatio = Double(fatCalories) / Double(totalCalories)
        
        // Calculate deviation from targets
        let proteinDeviation = abs(actualProteinRatio - targetProteinRatio)
        let carbDeviation = abs(actualCarbRatio - targetCarbRatio)
        let fatDeviation = abs(actualFatRatio - targetFatRatio)
        
        let totalDeviation = proteinDeviation + carbDeviation + fatDeviation
        let score = max(0, 25 - Int(totalDeviation * 50)) // Scale deviation to points
        
        return score
    }
    
    private func getTargetMacroRatios(for goal: NutritionGoal) -> (protein: Double, carbs: Double, fat: Double) {
        switch goal {
        case .weightLoss:
            return (0.35, 0.35, 0.30) // Higher protein for satiety
        case .muscleGain:
            return (0.30, 0.45, 0.25) // Higher carbs for energy
        case .maintainWeight:
            return (0.25, 0.45, 0.30) // Balanced maintenance
        case .performanceFocus:
            return (0.30, 0.40, 0.30) // Balanced for mental clarity
        case .betterSleep:
            return (0.25, 0.40, 0.35) // Higher fat for satiety
        case .overallWellbeing:
            return (0.25, 0.50, 0.25) // Standard balanced diet
        case .athleticPerformance:
            return (0.30, 0.45, 0.25) // Higher carbs for performance
        }
    }
    
    private func calculateMicronutrientScore(meals: [LoggedMeal]) -> Int {
        guard !meals.isEmpty else { return 0 }
        
        // Aggregate micronutrients from all meals
        var totalMicronutrients: [String: Double] = [:]
        for meal in meals {
            for (nutrient, amount) in meal.micronutrients {
                totalMicronutrients[nutrient, default: 0] += amount
            }
        }
        
        // Get RDA values
        let rdaValues = MicronutrientData.getAllNutrients()
        
        // Calculate percentage of RDA met for each nutrient
        var metRDACount = 0
        var totalNutrients = 0
        
        for rda in rdaValues {
            if let consumed = totalMicronutrients[rda.name] {
                let percentageOfRDA = (consumed / rda.rda) * 100
                if percentageOfRDA >= 80 { // Consider 80% as "met"
                    metRDACount += 1
                }
            }
            totalNutrients += 1
        }
        
        // Score based on percentage of nutrients meeting RDA
        let percentageMet = Double(metRDACount) / Double(totalNutrients)
        return Int(percentageMet * 25)
    }
    
    private func calculateConsistencyScore(
        todayMeals: [LoggedMeal],
        checkIns: [PostMealCheckIn],
        windows: [MealWindow]
    ) -> Int {
        var score = 0
        
        // Points for logging meals (max 10)
        if todayMeals.count >= 3 {
            score += 10
        } else {
            score += (todayMeals.count * 3)
        }
        
        // Points for check-ins (max 10)
        let checkInRate = Double(checkIns.count) / Double(max(1, todayMeals.count))
        score += Int(checkInRate * 10)
        
        // Points for hitting meal windows (max 5)
        let activeWindows = windows.filter { window in
            todayMeals.contains { meal in
                meal.windowId == window.id
            }
        }
        let windowHitRate = Double(activeWindows.count) / Double(max(1, windows.count))
        score += Int(windowHitRate * 5)
        
        return min(25, score)
    }
    
    // MARK: - Micronutrient Analysis
    
    struct MicronutrientStatus {
        let nutrients: [NutrientStatus]
        let topDeficiencies: [NutrientStatus]
        let wellSupplied: [NutrientStatus]
        
        struct NutrientStatus {
            let nutrient: MicronutrientData // From MicronutrientData.swift model
            let consumed: Double
            let percentageOfRDA: Double
            let status: Status
            
            enum Status {
                case deficient    // <50% RDA
                case low          // 50-79% RDA
                case adequate     // 80-120% RDA
                case high         // >120% RDA
                
                var color: Color {
                    switch self {
                    case .deficient: return .red
                    case .low: return .orange
                    case .adequate: return .green
                    case .high: return .blue
                    }
                }
                
                var icon: String {
                    switch self {
                    case .deficient: return "exclamationmark.triangle.fill"
                    case .low: return "exclamationmark.circle.fill"
                    case .adequate: return "checkmark.circle.fill"
                    case .high: return "arrow.up.circle.fill"
                    }
                }
            }
        }
    }
    
    func analyzeMicronutrients(meals: [LoggedMeal]) -> MicronutrientStatus {
        // Aggregate micronutrients
        var totalMicronutrients: [String: Double] = [:]
        for meal in meals {
            for (nutrient, amount) in meal.micronutrients {
                totalMicronutrients[nutrient, default: 0] += amount
            }
        }
        
        // Calculate status for each nutrient
        var nutrientStatuses: [MicronutrientStatus.NutrientStatus] = []
        let rdaValues = MicronutrientData.getAllNutrients()
        
        for rda in rdaValues {
            let consumed = totalMicronutrients[rda.name] ?? 0
            let percentage = (consumed / rda.rda) * 100
            
            let status: MicronutrientStatus.NutrientStatus.Status = {
                if percentage < 50 { return .deficient }
                else if percentage < 80 { return .low }
                else if percentage <= 120 { return .adequate }
                else { return .high }
            }()
            
            nutrientStatuses.append(MicronutrientStatus.NutrientStatus(
                nutrient: rda,
                consumed: consumed,
                percentageOfRDA: percentage,
                status: status
            ))
        }
        
        // Sort and categorize
        let deficiencies = nutrientStatuses
            .filter { $0.status == .deficient || $0.status == .low }
            .sorted { $0.percentageOfRDA < $1.percentageOfRDA }
            .prefix(5)
            .map { $0 }
        
        let wellSupplied = nutrientStatuses
            .filter { $0.status == .adequate || $0.status == .high }
            .sorted { $0.percentageOfRDA > $1.percentageOfRDA }
            .prefix(3)
            .map { $0 }
        
        return MicronutrientStatus(
            nutrients: nutrientStatuses,
            topDeficiencies: deficiencies,
            wellSupplied: wellSupplied
        )
    }
    
    // MARK: - Insights Generation
    
    struct Insight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let message: String
        let evidence: String?
        let action: String?
        
        enum InsightType {
            case positive
            case warning
            case discovery
            case tip
            
            var icon: String {
                switch self {
                case .positive: return "star.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .discovery: return "lightbulb.fill"
                case .tip: return "info.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .positive: return .green
                case .warning: return .orange
                case .discovery: return .blue
                case .tip: return .purple
                }
            }
        }
    }
    
    func generateInsights(
        meals: [LoggedMeal],
        checkIns: [PostMealCheckIn],
        microStatus: MicronutrientStatus,
        score: ScoreBreakdown
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // Score-based insight
        if score.totalScore >= 80 {
            insights.append(Insight(
                type: .positive,
                title: "Excellent Day!",
                message: "Your PhylloScore of \(score.totalScore) shows great nutrition choices",
                evidence: "All meal windows hit, balanced macros",
                action: nil
            ))
        } else if score.totalScore < 50 {
            insights.append(Insight(
                type: .warning,
                title: "Room for Improvement",
                message: "Your PhylloScore is \(score.totalScore)/100",
                evidence: "Missed \(3 - meals.count) meals today",
                action: "Try to hit your next meal window"
            ))
        }
        
        // Micronutrient insights
        if let topDeficiency = microStatus.topDeficiencies.first {
            let foods = getFoodsRichInNutrient(topDeficiency.nutrient.name)
            insights.append(Insight(
                type: .warning,
                title: "Low \(topDeficiency.nutrient.name)",
                message: "You're at \(Int(topDeficiency.percentageOfRDA))% of daily needs",
                evidence: "Only \(String(format: "%.1f", topDeficiency.consumed))\(topDeficiency.nutrient.unit) consumed",
                action: "Add \(foods.joined(separator: " or ")) to your next meal"
            ))
        }
        
        // Energy pattern insights
        if let bestEnergyMeal = findBestEnergyMeal(meals: meals, checkIns: checkIns) {
            insights.append(Insight(
                type: .discovery,
                title: "Energy Booster Found",
                message: "\(bestEnergyMeal.meal.name) gave you great energy",
                evidence: "Energy level: \(bestEnergyMeal.checkIn.energyLevel.label)",
                action: "Include similar high-protein meals"
            ))
        }
        
        return insights
    }
    
    private func getFoodsRichInNutrient(_ nutrient: String) -> [String] {
        let foodSources: [String: [String]] = [
            "Vitamin A": ["sweet potato", "carrots", "spinach"],
            "Vitamin C": ["oranges", "strawberries", "bell peppers"],
            "Vitamin D": ["salmon", "egg yolks", "fortified milk"],
            "Vitamin E": ["almonds", "sunflower seeds", "avocado"],
            "Vitamin K": ["kale", "broccoli", "brussels sprouts"],
            "B1 Thiamine": ["whole grains", "pork", "legumes"],
            "B2 Riboflavin": ["milk", "eggs", "almonds"],
            "B3 Niacin": ["chicken", "tuna", "peanuts"],
            "B6": ["chickpeas", "salmon", "potatoes"],
            "B12": ["beef", "eggs", "dairy"],
            "Folate": ["leafy greens", "beans", "citrus"],
            "Calcium": ["dairy", "tofu", "almonds"],
            "Iron": ["red meat", "spinach", "lentils"],
            "Magnesium": ["dark chocolate", "avocado", "nuts"],
            "Zinc": ["oysters", "beef", "pumpkin seeds"],
            "Potassium": ["bananas", "sweet potatoes", "beans"],
            "Omega-3": ["salmon", "walnuts", "chia seeds"],
            "Fiber": ["beans", "whole grains", "vegetables"]
        ]
        
        return foodSources[nutrient] ?? ["varied whole foods"]
    }
    
    private func findBestEnergyMeal(meals: [LoggedMeal], checkIns: [PostMealCheckIn]) -> (meal: LoggedMeal, checkIn: PostMealCheckIn)? {
        for checkIn in checkIns.sorted(by: { $0.energyLevel.rawValue > $1.energyLevel.rawValue }) {
            if let meal = meals.first(where: { $0.id.uuidString == checkIn.mealId }) {
                if checkIn.energyLevel.rawValue >= 4 {
                    return (meal, checkIn)
                }
            }
        }
        return nil
    }
}