import Foundation
import SwiftUI

/// Service that generates user-friendly explanations for redistribution events
class RedistributionExplanationService {
    static let shared = RedistributionExplanationService()
    
    private init() {}
    
    /// Generate the main explanation for a redistribution result
    func generateExplanation(for redistribution: RedistributionResult) -> String {
        switch redistribution.trigger {
        case .overconsumption(let percent):
            return generateOverconsumptionExplanation(percent: percent, redistribution: redistribution)
            
        case .underconsumption(let percent):
            return generateUnderconsumptionExplanation(percent: percent, redistribution: redistribution)
            
        case .missedWindow:
            return generateMissedWindowExplanation(redistribution: redistribution)
            
        case .earlyConsumption:
            return "I've adjusted your upcoming windows based on when you actually ate. This helps align your schedule with your natural eating patterns."
            
        case .lateConsumption:
            return "Windows adjusted for late consumption. Your upcoming meals have been rebalanced to maintain your daily targets."
        }
    }
    
    /// Generate explanation for overconsumption
    private func generateOverconsumptionExplanation(percent: Int, redistribution: RedistributionResult) -> String {
        let calorieChange = redistribution.totalRedistributed.calories
        
        if percent > 50 {
            return "You ate \(percent)% more than planned (\(calorieChange) extra calories). I've significantly reduced your upcoming meals, with the biggest adjustment to your next window to help you stay on track."
        } else if percent > 25 {
            return "You ate \(percent)% more than planned. I've reduced your upcoming meals proportionally, focusing on windows closer to now for gradual adjustment."
        } else {
            return "You went slightly over target by \(percent)%. I've made minor adjustments to your next few meals to keep you balanced."
        }
    }
    
    /// Generate explanation for underconsumption
    private func generateUnderconsumptionExplanation(percent: Int, redistribution: RedistributionResult) -> String {
        let calorieChange = redistribution.totalRedistributed.calories
        
        if percent > 50 {
            return "You ate \(percent)% less than planned (\(calorieChange) calories remaining). I've increased your upcoming meals to help you reach your daily goals, with more added to your next window."
        } else if percent > 25 {
            return "You ate \(percent)% less than planned. I've increased your upcoming meals to help meet your targets, distributed based on proximity."
        } else {
            return "You're slightly under target by \(percent)%. I've added a bit more to your upcoming meals to keep you on track."
        }
    }
    
    /// Generate explanation for missed windows
    private func generateMissedWindowExplanation(redistribution: RedistributionResult) -> String {
        let affectedCount = redistribution.adjustedWindows.count
        
        if affectedCount > 1 {
            return "You missed a meal window. I've redistributed those calories and nutrients across your \(affectedCount) remaining windows to help you meet your daily goals."
        } else {
            return "You missed a meal window. I've added those calories and nutrients to your next window to help you catch up."
        }
    }
    
    /// Generate educational tip based on redistribution pattern
    func generateEducationalTip(for pattern: RedistributionPattern) -> String {
        switch pattern {
        case .consistentOvereating:
            return "💡 Tip: You often eat more than planned at lunch. Consider having a protein-rich snack 30 minutes before to reduce hunger."
            
        case .frequentMissedWindows:
            return "💡 Tip: Missing meals regularly? Try preparing meals in advance or setting reminders for your meal windows."
            
        case .eveningOvereating:
            return "💡 Tip: Evening overeating is common when earlier meals are too small. Try distributing calories more evenly throughout the day."
            
        case .weekendPattern:
            return "💡 Tip: Weekends have different patterns. Consider creating a separate weekend schedule that matches your lifestyle."
            
        case .morningOvereating:
            return "💡 Tip: Morning overeating may indicate you're too hungry after fasting. Consider a balanced evening snack."
            
        case .consistentUndereating:
            return "💡 Tip: You're consistently eating less than planned. Let's adjust your targets to better match your natural appetite."
            
        default:
            return generateGeneralTip()
        }
    }
    
    /// Generate a general educational tip
    private func generateGeneralTip() -> String {
        let tips = [
            "💡 Tip: Eating at consistent times helps regulate hunger hormones and improve energy levels.",
            "💡 Tip: Protein at each meal helps maintain satiety and makes it easier to stick to your plan.",
            "💡 Tip: Drinking water 30 minutes before meals can help with portion control.",
            "💡 Tip: Your body adapts to regular eating times. Consistency is key for metabolic health.",
            "💡 Tip: If a window feels too large, split it into a meal and a snack for better control."
        ]
        
        return tips.randomElement() ?? tips[0]
    }
    
    /// Generate constraint explanation for UI
    func explainConstraints(_ windows: [AdjustedWindow]) -> [String] {
        return windows.map { window in
            let calorieChange = window.adjustedMacros.calories - window.originalMacros.calories
            if calorieChange > 0 {
                return "✓ \(window.windowId): +\(calorieChange) calories added - \(window.reason)"
            } else if calorieChange < 0 {
                return "✓ \(window.windowId): \(calorieChange) calories removed - \(window.reason)"
            } else {
                return "✓ \(window.windowId): unchanged - \(window.reason)"
            }
        }
    }
    
    /// Analyze user's response patterns to learn preferences
    @MainActor
    func analyzeUserResponse(accepted: Bool, redistribution: RedistributionResult) {
        if accepted {
            DebugLogger.shared.info("User accepted redistribution for \(redistribution.trigger)")
        } else {
            DebugLogger.shared.info("User rejected redistribution for \(redistribution.trigger)")
        }
    }
    
    /// Get the severity level for UI styling
    func getSeverityLevel(for redistribution: RedistributionResult) -> SeverityLevel {
        switch redistribution.trigger {
        case .overconsumption(let percent):
            if percent > 50 { return .high }
            else if percent > 25 { return .medium }
            else { return .low }
            
        case .underconsumption(let percent):
            if percent > 50 { return .high }
            else if percent > 25 { return .medium }
            else { return .low }
            
        case .missedWindow:
            return .medium
            
        case .earlyConsumption, .lateConsumption:
            return .low
        }
    }
    
    enum SeverityLevel {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.octagon"
            }
        }
    }
}