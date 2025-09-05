import Foundation
import SwiftUI
import Combine

// MARK: - Redistribution Trigger Manager

@Observable
class RedistributionTriggerManager {
    
    // MARK: - Properties
    
    private let engine = ProximityBasedEngine()
    private let constraints = RedistributionConstraints()
    private var cancellables = Set<AnyCancellable>()
    
    var pendingRedistribution: RedistributionResult?
    var isProcessingRedistribution = false
    
    // MARK: - Threshold Evaluation
    
    func evaluateTrigger(meal: LoggedMeal, window: MealWindow) -> Bool {
        let deviation = calculateDeviation(meal: meal, window: window)
        return abs(deviation) > constraints.deviationThreshold
    }
    
    func calculateDeviation(meal: LoggedMeal, window: MealWindow) -> Double {
        let targetCalories = window.effectiveCalories
        guard targetCalories > 0 else { return 0.0 }
        
        let consumedCalories = meal.calories
        let deviation = Double(consumedCalories - targetCalories) / Double(targetCalories)
        
        return deviation
    }
    
    // MARK: - Meal Logging Handler
    
    @MainActor
    func handleMealLogged(
        _ meal: LoggedMeal,
        window: MealWindow,
        allWindows: [MealWindow]
    ) async -> RedistributionResult? {
        
        guard evaluateTrigger(meal: meal, window: window) else {
            return nil
        }
        
        isProcessingRedistribution = true
        defer { isProcessingRedistribution = false }
        
        // Calculate the deviation percentage
        let deviation = calculateDeviation(meal: meal, window: window)
        
        // Determine trigger type
        let triggerType: RedistributionTrigger.TriggerType
        if deviation > 0 {
            let percentOver = Int(deviation * 100)
            triggerType = .overconsumption(percentOver: percentOver)
        } else {
            let percentUnder = Int(abs(deviation) * 100)
            triggerType = .underconsumption(percentUnder: percentUnder)
        }
        
        // Create trigger
        let trigger = RedistributionTrigger(
            triggerWindow: window,
            triggerType: triggerType,
            deviation: deviation,
            totalConsumed: MacroTargets(
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat
            ),
            currentTime: Date()
        )
        
        // Calculate redistribution
        let result = engine.calculateRedistribution(
            trigger: trigger,
            windows: allWindows,
            constraints: constraints,
            currentTime: Date()
        )
        
        // Store pending redistribution
        pendingRedistribution = result
        
        return result
    }
    
    // MARK: - Window Miss Handler
    
    @MainActor
    func handleWindowMissed(
        _ window: MealWindow,
        allWindows: [MealWindow]
    ) async -> RedistributionResult? {
        
        isProcessingRedistribution = true
        defer { isProcessingRedistribution = false }
        
        // Create trigger for missed window
        let trigger = RedistributionTrigger(
            triggerWindow: window,
            triggerType: .missedWindow,
            deviation: -1.0, // Full miss
            totalConsumed: MacroTargets(
                protein: 0,
                carbs: 0,
                fat: 0
            ),
            currentTime: Date()
        )
        
        // Calculate redistribution
        let result = engine.calculateRedistribution(
            trigger: trigger,
            windows: allWindows,
            constraints: constraints,
            currentTime: Date()
        )
        
        // Store pending redistribution
        pendingRedistribution = result
        
        return result
    }
    
    // MARK: - Check-In Update Handler
    
    @MainActor
    func handleCheckInUpdate(
        _ checkIn: MorningCheckInData,
        windows: [MealWindow]
    ) async -> RedistributionResult? {
        
        // Evaluate if check-in data suggests redistribution
        // For example, if user reports poor sleep, might want lighter evening meals
        
        guard shouldRedistributeForCheckIn(checkIn) else {
            return nil
        }
        
        isProcessingRedistribution = true
        defer { isProcessingRedistribution = false }
        
        // This would be more sophisticated in production
        // For now, just return nil as placeholder
        return nil
    }
    
    // MARK: - Preview Generation
    
    func previewRedistribution(
        for meal: AnalyzingMeal,
        in window: MealWindow,
        allWindows: [MealWindow]
    ) -> RedistributionResult? {
        
        // Convert analyzing meal to macro targets
        let macros = MacroTargets(
            protein: meal.estimatedProtein ?? 0,
            carbs: meal.estimatedCarbs ?? 0,
            fat: meal.estimatedFat ?? 0
        )
        
        // Check if this would trigger redistribution
        let targetCalories = window.effectiveCalories
        guard targetCalories > 0 else { return nil }
        
        let deviation = Double(macros.totalCalories - targetCalories) / Double(targetCalories)
        
        // Only preview if it would actually trigger
        guard abs(deviation) > constraints.deviationThreshold else {
            return nil
        }
        
        // Generate preview
        return engine.previewRedistribution(
            for: macros,
            in: window,
            allWindows: allWindows,
            constraints: constraints,
            currentTime: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func shouldRedistributeForCheckIn(_ checkIn: MorningCheckInData) -> Bool {
        // Implement logic to determine if check-in warrants redistribution
        // For example:
        // - Poor sleep quality → lighter evening meals
        // - High stress → more balanced distribution
        // - Low energy → front-load calories
        
        if checkIn.sleepQuality < 3 {
            return true
        }
        
        // Check energy level instead of stress level
        if checkIn.energyLevel < 3 {
            return true
        }
        
        return false
    }
    
    // MARK: - Redistribution Application
    
    func applyRedistribution(_ result: RedistributionResult) {
        // Clear pending redistribution
        pendingRedistribution = nil
        
        // The actual application will be handled by FirebaseDataProvider
        // This just manages the state
    }
    
    func rejectRedistribution() {
        // Clear pending redistribution without applying
        pendingRedistribution = nil
    }
    
    // MARK: - Pattern Recognition
    
    func analyzeRedistributionPatterns(history: [RedistributionHistory]) -> RedistributionPattern? {
        // Analyze patterns in redistribution history
        guard history.count >= 5 else { return nil }
        
        // Count trigger types
        var overconsumptionCount = 0
        var underconsumptionCount = 0
        var missedWindowCount = 0
        
        for item in history {
            switch item.reason {
            case .overconsumption:
                overconsumptionCount += 1
            case .underconsumption:
                underconsumptionCount += 1
            case .missedWindow:
                missedWindowCount += 1
            default:
                break
            }
        }
        
        // Identify dominant pattern
        if overconsumptionCount > history.count / 2 {
            return .consistentOvereating
        } else if underconsumptionCount > history.count / 2 {
            return .consistentUndereating
        } else if missedWindowCount > history.count / 3 {
            return .frequentMissedWindows
        }
        
        return nil
    }
}

// MARK: - Supporting Types

enum RedistributionPattern {
    case consistentOvereating
    case consistentUndereating
    case frequentMissedWindows
    case morningOvereating
    case eveningOvereating
    case weekendPattern
    
    var educationalMessage: String {
        switch self {
        case .consistentOvereating:
            return "You tend to eat more than planned. Consider adding more protein and fiber to feel fuller."
        case .consistentUndereating:
            return "You often eat less than planned. Try setting meal reminders to stay on track."
        case .frequentMissedWindows:
            return "You miss meals frequently. Meal prep on weekends could help you stay consistent."
        case .morningOvereating:
            return "You tend to overeat at breakfast. A protein-rich morning meal can help control portions."
        case .eveningOvereating:
            return "Evening meals tend to be larger. Try having a balanced afternoon snack to reduce dinner cravings."
        case .weekendPattern:
            return "Your weekend eating differs from weekdays. Planning weekend meals can help maintain consistency."
        }
    }
}

struct RedistributionHistory: Identifiable {
    let id = UUID()
    let timestamp: Date
    let sourceWindowId: String
    let affectedWindowIds: [String]
    let adjustments: [MacroTargets]
    let reason: WindowRedistributionManager.RedistributionReason
    let userAccepted: Bool
    let userFeedback: String?
}

// MARK: - Extensions for Analyzing Meal

extension AnalyzingMeal {
    // These are placeholder values since AnalyzingMeal doesn't have analyzed nutrition yet
    // In production, these would come from the AI analysis result
    var estimatedCalories: Int {
        // Default estimate until AI analysis completes
        return 400
    }
    
    var estimatedProtein: Int? {
        // Default estimate until AI analysis completes
        return 25
    }
    
    var estimatedCarbs: Int? {
        // Default estimate until AI analysis completes
        return 45
    }
    
    var estimatedFat: Int? {
        // Default estimate until AI analysis completes
        return 15
    }
}