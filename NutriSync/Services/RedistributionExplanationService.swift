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
            
        case .mealTiming:
            return "I've adjusted your upcoming windows based on when you actually ate. This helps align your schedule with your natural eating patterns."
            
        case .userRequest:
            return "Windows adjusted as requested. Your upcoming meals have been rebalanced to maintain your daily targets."
            
        case .none:
            return redistribution.adjustmentReason ?? "Your meal windows have been optimized for better balance throughout the day."
        }
    }
    
    /// Generate explanation for overconsumption
    private func generateOverconsumptionExplanation(percent: Int, redistribution: RedistributionResult) -> String {
        let calorieChange = abs(redistribution.totalCaloriesDelta)
        
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
        let calorieChange = abs(redistribution.totalCaloriesDelta)
        
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
        let affectedCount = redistribution.affectedWindowIds.count
        
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
            
        case .morningSkipping:
            return "💡 Tip: Skipping breakfast regularly? Try preparing overnight oats or a smoothie the night before for a quick morning option."
            
        case .eveningOvereating:
            return "💡 Tip: Evening overeating is common when earlier meals are too small. Try distributing calories more evenly throughout the day."
            
        case .weekendPattern:
            return "💡 Tip: Weekends have different patterns. Consider creating a separate weekend schedule that matches your lifestyle."
            
        case .workoutDayPattern:
            return "💡 Tip: On workout days, your body needs more fuel. I'll automatically adjust your windows when you log a workout."
            
        case .stressEating:
            return "💡 Tip: Stress can affect eating patterns. Try a 5-minute breathing exercise before meals to eat more mindfully."
            
        case .socialMealPattern:
            return "💡 Tip: Social meals tend to be larger. When you know you're eating out, I can pre-adjust your other windows."
            
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
    func explainConstraints(_ constraints: [RedistributionResult.AppliedConstraint]) -> [String] {
        return constraints.map { constraint in
            switch constraint {
            case .minimumCalories(let window, let adjusted):
                return "✓ \(window) kept above 200 calorie minimum (set to \(adjusted))"
                
            case .maximumCalories(let window, let adjusted):
                return "✓ \(window) kept below 1000 calorie maximum (set to \(adjusted))"
                
            case .proteinPreservation(let window, let preserved):
                return "✓ \(window) protein preserved at \(preserved)g minimum"
                
            case .bedtimeBuffer(let window):
                return "✓ \(window) protected due to 3-hour bedtime buffer"
                
            case .workoutProtection(let window):
                return "✓ \(window) maintained for workout performance"
            }
        }
    }
    
    /// Analyze user's response patterns to learn preferences
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
            
        default:
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

/// Patterns detected in user behavior
enum RedistributionPattern {
    case consistentOvereating
    case morningSkipping
    case eveningOvereating
    case weekendPattern
    case workoutDayPattern
    case stressEating
    case socialMealPattern
    case none
}