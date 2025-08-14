//
//  ClarificationManager.swift
//  NutriSync
//
//  Global manager for clarification questions that can be shown from any tab
//

import Foundation
import SwiftUI

class ClarificationManager: ObservableObject {
    static let shared = ClarificationManager()
    
    @Published var showClarification = false
    @Published var pendingAnalyzingMeal: AnalyzingMeal?
    @Published var pendingAnalysisResult: MealAnalysisResult?
    @Published var clarificationAnswers: [String: String] = [:]
    
    private let dataProvider = DataSourceProvider.shared.provider
    private let captureService = MealCaptureService.shared
    
    private init() {}
    
    func presentClarification(for analyzingMeal: AnalyzingMeal, with result: MealAnalysisResult) {
        // Normalize/augment AI questions to ensure practicality and consistent impacts
        let normalized = ClarificationManager.normalizeQuestions(result.clarifications)
        var adjusted = result
        adjusted = MealAnalysisResult(
            mealName: result.mealName,
            confidence: result.confidence,
            ingredients: result.ingredients,
            nutrition: result.nutrition,
            micronutrients: result.micronutrients,
            clarifications: normalized,
            requestedTools: result.requestedTools,
            brandDetected: result.brandDetected
        )
        self.pendingAnalyzingMeal = analyzingMeal
        self.pendingAnalysisResult = adjusted
        self.clarificationAnswers = [:]
        self.showClarification = true
    }

    // Heuristic normalizer to fix AI quirks and add practical defaults
    static func normalizeQuestions(_ input: [MealAnalysisResult.ClarificationQuestion]) -> [MealAnalysisResult.ClarificationQuestion] {
        var questions = input
        // Deduplicate by question text
        var seen = Set<String>()
        questions = questions.filter { q in
            let key = q.question.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        // If no oil/sauce question present for savory meals, add one
        let lowerMealText = (input.first?.question ?? "").lowercased()
        let hasOil = questions.contains { $0.question.lowercased().contains("oil") || $0.question.lowercased().contains("butter") }
        if !hasOil {
            questions.append(
                .init(
                    question: "Was any oil or butter used when cooking?",
                    options: [
                        .init(text: "No oil/butter used", calorieImpact: 0, proteinImpact: nil, carbImpact: nil, fatImpact: nil, isRecommended: true, note: "Lowest fat"),
                        .init(text: "1 tsp olive oil", calorieImpact: 40, proteinImpact: nil, carbImpact: nil, fatImpact: 4, isRecommended: nil, note: nil),
                        .init(text: "1 tbsp butter", calorieImpact: 100, proteinImpact: nil, carbImpact: nil, fatImpact: 11, isRecommended: nil, note: nil)
                    ],
                    clarificationType: "cook_fat"
                )
            )
        }
        return questions
    }
    
    func dismissClarification() {
        self.showClarification = false
        self.pendingAnalyzingMeal = nil
        self.pendingAnalysisResult = nil
        self.clarificationAnswers = [:]
    }
    
    func completeClarification() {
        guard let analyzingMeal = pendingAnalyzingMeal,
              let analysisResult = pendingAnalysisResult else { return }
        
        Task {
            do {
                // Complete with clarification answers
                try await captureService.completeWithClarification(
                    analyzingMeal: analyzingMeal,
                    originalResult: analysisResult,
                    clarificationAnswers: clarificationAnswers
                )
                
                // Create final meal from result
                var finalMeal = LoggedMeal(
                    name: analysisResult.mealName,
                    calories: analysisResult.nutrition.calories,
                    protein: Int(analysisResult.nutrition.protein),
                    carbs: Int(analysisResult.nutrition.carbs),
                    fat: Int(analysisResult.nutrition.fat),
                    timestamp: analyzingMeal.timestamp
                )
                finalMeal.windowId = analyzingMeal.windowId
                
                // Trigger meal sliding animation
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .animateMealToWindow,
                        object: finalMeal
                    )
                }
                
            } catch {
                print("❌ Failed to complete clarification: \(error)")
            }
        }
        
        dismissClarification()
    }
    
    // Legacy support for MockDataManager
    func presentClarification(for analyzingMeal: AnalyzingMeal, with result: LoggedMeal) {
        // Convert LoggedMeal to MealAnalysisResult for compatibility
        let analysisResult = MealAnalysisResult(
            mealName: result.name,
            confidence: 0.9,
            ingredients: [],
            nutrition: .init(
                calories: result.calories,
                protein: Double(result.protein),
                carbs: Double(result.carbs),
                fat: Double(result.fat)
            ),
            micronutrients: [],
            clarifications: [],
            requestedTools: nil,
            brandDetected: nil
        )
        
        presentClarification(for: analyzingMeal, with: analysisResult)
    }
}

// Add notification name for showing meal results
extension Notification.Name {
    static let showMealResults = Notification.Name("showMealResults")
}