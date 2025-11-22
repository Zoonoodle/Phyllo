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

    // Queue for handling multiple clarifications
    private struct ClarificationRequest {
        let analyzingMeal: AnalyzingMeal
        let analysisResult: MealAnalysisResult
    }
    private var clarificationQueue: [ClarificationRequest] = []

    // Expose queue size for UI
    var queueSize: Int {
        return clarificationQueue.count
    }

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

        // Add to queue
        let request = ClarificationRequest(analyzingMeal: analyzingMeal, analysisResult: adjusted)
        clarificationQueue.append(request)

        DebugLogger.shared.mealAnalysis("Added clarification to queue: \(analyzingMeal.id.uuidString.prefix(8)) - Queue size: \(clarificationQueue.count)")

        // If not currently showing clarification, show next one
        if !showClarification {
            showNextClarification()
        }
    }

    private func showNextClarification() {
        guard !clarificationQueue.isEmpty else {
            DebugLogger.shared.mealAnalysis("Clarification queue empty")
            return
        }

        let request = clarificationQueue.removeFirst()
        DebugLogger.shared.mealAnalysis("Showing clarification for: \(request.analyzingMeal.id.uuidString.prefix(8)) - Remaining: \(clarificationQueue.count)")

        self.pendingAnalyzingMeal = request.analyzingMeal
        self.pendingAnalysisResult = request.analysisResult
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
        
        // Limit to max 4 most relevant questions to avoid overwhelming users
        if questions.count > 4 {
            // Prioritize questions with clarificationType set (these are more specific)
            questions.sort { q1, q2 in
                // Prioritize questions with non-empty clarification type
                if !q1.clarificationType.isEmpty && q2.clarificationType.isEmpty { return true }
                if q1.clarificationType.isEmpty && !q2.clarificationType.isEmpty { return false }
                // Then prioritize questions with more options (more nuanced)
                return q1.options.count > q2.options.count
            }
            questions = Array(questions.prefix(4))
        }
        
        // No need to validate calorieImpact as it's non-optional
        // All options already have calorieImpact set from the API
        
        return questions
    }
    
    func dismissClarification() {
        DebugLogger.shared.mealAnalysis("Dismissing clarification - Queue size: \(clarificationQueue.count)")
        self.showClarification = false
        self.pendingAnalyzingMeal = nil
        self.pendingAnalysisResult = nil
        self.clarificationAnswers = [:]

        // Show next clarification in queue after a short delay
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                showNextClarification()
            }
        }
    }

    func skipClarification() {
        guard let analyzingMeal = pendingAnalyzingMeal,
              let analysisResult = pendingAnalysisResult else {
            dismissClarification()
            return
        }

        DebugLogger.shared.mealAnalysis("Skipping clarification for: \(analyzingMeal.id.uuidString.prefix(8))")

        Task {
            do {
                // Complete with empty clarification answers (uses base values)
                try await captureService.completeWithClarification(
                    analyzingMeal: analyzingMeal,
                    originalResult: analysisResult,
                    clarificationAnswers: [:]
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
                DebugLogger.shared.error("Failed to skip clarification: \(error)")
            }
        }

        dismissClarification()
    }

    func completeClarification() {
        guard let analyzingMeal = pendingAnalyzingMeal,
              let analysisResult = pendingAnalysisResult else { return }

        DebugLogger.shared.mealAnalysis("Completing clarification for: \(analyzingMeal.id.uuidString.prefix(8))")

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
                DebugLogger.shared.error("Failed to complete clarification: \(error)")
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