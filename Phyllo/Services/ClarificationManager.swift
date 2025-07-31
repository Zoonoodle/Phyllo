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
    @Published var pendingMealResult: LoggedMeal?
    
    private init() {}
    
    func presentClarification(for analyzingMeal: AnalyzingMeal, with result: LoggedMeal) {
        self.pendingAnalyzingMeal = analyzingMeal
        self.pendingMealResult = result
        self.showClarification = true
    }
    
    func dismissClarification() {
        self.showClarification = false
        self.pendingAnalyzingMeal = nil
        self.pendingMealResult = nil
    }
    
    func completeClarification(with finalMeal: LoggedMeal) {
        if let analyzingMeal = pendingAnalyzingMeal {
            // Complete the analyzing meal
            MockDataManager.shared.completeAnalyzingMeal(analyzingMeal, with: finalMeal)
            
            // Trigger meal sliding animation
            NotificationCenter.default.post(
                name: .animateMealToWindow,
                object: finalMeal
            )
            
            // Note: Meal results are shown via the meal celebration nudge
            // No need to trigger showMealResults here
        }
        
        dismissClarification()
    }
}

// Add notification name for showing meal results
extension Notification.Name {
    static let showMealResults = Notification.Name("showMealResults")
}