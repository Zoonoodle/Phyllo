//
//  ClarificationManager.swift
//  Phyllo
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
        self.pendingAnalyzingMeal = analyzingMeal
        self.pendingAnalysisResult = result
        self.clarificationAnswers = [:]
        self.showClarification = true
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
            clarifications: []
        )
        
        presentClarification(for: analyzingMeal, with: analysisResult)
    }
}

// Add notification name for showing meal results
extension Notification.Name {
    static let showMealResults = Notification.Name("showMealResults")
}