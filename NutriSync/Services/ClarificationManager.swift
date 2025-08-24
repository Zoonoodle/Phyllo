//
//  ClarificationManager.swift
//  NutriSync
//
//  Global manager for clarification questions that can be shown from any tab
//

import Foundation
import SwiftUI

@MainActor
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

    // Smart normalizer that only adds appropriate questions based on context
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
        
        // Remove max 2-3 most relevant questions to avoid overwhelming users
        if questions.count > 3 {
            // Prioritize questions with clarificationType set (these are more specific)
            questions.sort { q1, q2 in
                // Prioritize questions with clarification type
                if q1.clarificationType != nil && q2.clarificationType == nil { return true }
                if q1.clarificationType == nil && q2.clarificationType != nil { return false }
                // Then prioritize questions with more options (more nuanced)
                return q1.options.count > q2.options.count
            }
            questions = Array(questions.prefix(3))
        }
        
        // Validate each question has proper impact values
        for i in 0..<questions.count {
            var question = questions[i]
            for j in 0..<question.options.count {
                var option = question.options[j]
                // Ensure all options have at least calorieImpact
                if option.calorieImpact == nil {
                    option.calorieImpact = 0
                    question.options[j] = option
                }
            }
            questions[i] = question
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