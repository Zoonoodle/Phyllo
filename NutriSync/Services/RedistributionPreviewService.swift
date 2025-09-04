import Foundation
import SwiftUI
import Combine

// MARK: - Redistribution Preview Service

@Observable
class RedistributionPreviewService {
    
    // MARK: - Properties
    
    var pendingRedistribution: RedistributionResult?
    var showingPreview: Bool = false
    var isGeneratingPreview: Bool = false
    
    private let engine = ProximityBasedEngine()
    private let constraints = RedistributionConstraints()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Preview Generation
    
    @MainActor
    func generatePreview(for meal: AnalyzingMeal, in window: MealWindow?, allWindows: [MealWindow]) async -> RedistributionPreview? {
        
        guard let window = window else {
            DebugLogger.shared.warning("No window provided for redistribution preview")
            return nil
        }
        
        isGeneratingPreview = true
        defer { isGeneratingPreview = false }
        
        // Convert analyzing meal to macro targets
        let macros = MacroTargets(
            calories: meal.estimatedCalories,
            protein: meal.estimatedProtein ?? 0,
            carbs: meal.estimatedCarbs ?? 0,
            fat: meal.estimatedFat ?? 0
        )
        
        // Check if this would trigger redistribution
        let targetCalories = window.effectiveCalories
        guard targetCalories > 0 else { return nil }
        
        let deviation = Double(macros.calories - targetCalories) / Double(targetCalories)
        
        // Only preview if it would actually trigger (25% threshold)
        guard abs(deviation) > constraints.deviationThreshold else {
            DebugLogger.shared.info("Deviation (\(Int(deviation * 100))%) below threshold, no preview needed")
            return nil
        }
        
        // Generate preview using the engine
        let result = engine.previewRedistribution(
            for: macros,
            in: window,
            allWindows: allWindows,
            constraints: constraints,
            currentTime: Date()
        )
        
        // Convert to preview format
        return RedistributionPreview(
            result: result,
            originalMeal: meal,
            triggerWindow: window,
            impactSummary: generateImpactSummary(result: result)
        )
    }
    
    // MARK: - Real-Time Preview Updates
    
    @MainActor
    func updatePreviewForMealChanges(
        meal: AnalyzingMeal,
        window: MealWindow?,
        allWindows: [MealWindow]
    ) async {
        
        // Debounce rapid updates
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // Generate preview after a short delay
        perform(#selector(generatePreviewDelayed), with: [meal, window, allWindows], afterDelay: 0.5)
    }
    
    @objc private func generatePreviewDelayed(_ args: [Any]) {
        guard args.count == 3,
              let meal = args[0] as? AnalyzingMeal,
              let window = args[1] as? MealWindow,
              let allWindows = args[2] as? [MealWindow] else {
            return
        }
        
        Task { @MainActor in
            if let preview = await generatePreview(for: meal, in: window, allWindows: allWindows) {
                self.pendingRedistribution = preview.result
                self.showingPreview = true
            }
        }
    }
    
    // MARK: - Impact Summary Generation
    
    private func generateImpactSummary(result: RedistributionResult) -> RedistributionImpactSummary {
        
        let totalCaloriesAffected = result.adjustedWindows.reduce(0) { sum, window in
            sum + abs(window.adjustedMacros.calories - window.originalMacros.calories)
        }
        
        let affectedWindowCount = result.adjustedWindows.count
        
        let largestChange = result.adjustedWindows.max { a, b in
            abs(a.adjustedMacros.calories - a.originalMacros.calories) <
            abs(b.adjustedMacros.calories - b.originalMacros.calories)
        }
        
        let severity: RedistributionImpactSummary.ImpactSeverity
        if totalCaloriesAffected > 500 {
            severity = .high
        } else if totalCaloriesAffected > 250 {
            severity = .medium
        } else {
            severity = .low
        }
        
        return RedistributionImpactSummary(
            totalCaloriesAffected: totalCaloriesAffected,
            windowsAffected: affectedWindowCount,
            largestWindowChange: largestChange,
            severity: severity,
            recommendation: generateRecommendation(result: result, severity: severity)
        )
    }
    
    private func generateRecommendation(
        result: RedistributionResult,
        severity: RedistributionImpactSummary.ImpactSeverity
    ) -> String {
        
        switch result.trigger {
        case .overconsumption(let percent):
            if severity == .high {
                return "Consider lighter options for your next meal to stay on track."
            } else if percent > 50 {
                return "You've had a hearty meal! The adjustments will help balance your day."
            } else {
                return "Minor adjustments to keep you aligned with your goals."
            }
            
        case .underconsumption(let percent):
            if percent > 50 {
                return "You have more room in upcoming windows. Consider adding nutritious snacks."
            } else {
                return "Slight increases to help you meet your daily targets."
            }
            
        case .missedWindow:
            return "We've spread the missed calories across your remaining meals."
            
        default:
            return "Adjustments made to optimize your nutrition timing."
        }
    }
    
    // MARK: - User Actions
    
    @MainActor
    func acceptPreview() {
        guard let pending = pendingRedistribution else { return }
        
        // This will be connected to FirebaseDataProvider.applyRedistribution
        NotificationCenter.default.post(
            name: .redistributionAccepted,
            object: pending
        )
        
        clearPreview()
    }
    
    @MainActor
    func rejectPreview() {
        DebugLogger.shared.info("User rejected redistribution preview")
        clearPreview()
    }
    
    @MainActor
    private func clearPreview() {
        pendingRedistribution = nil
        showingPreview = false
    }
}

// MARK: - Supporting Types

struct RedistributionPreview {
    let result: RedistributionResult
    let originalMeal: AnalyzingMeal
    let triggerWindow: MealWindow
    let impactSummary: RedistributionImpactSummary
}

struct RedistributionImpactSummary {
    let totalCaloriesAffected: Int
    let windowsAffected: Int
    let largestWindowChange: AdjustedWindow?
    let severity: ImpactSeverity
    let recommendation: String
    
    enum ImpactSeverity {
        case low    // < 250 calories total change
        case medium // 250-500 calories
        case high   // > 500 calories
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "checkmark.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.octagon"
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let redistributionAccepted = Notification.Name("redistributionAccepted")
    static let redistributionRejected = Notification.Name("redistributionRejected")
}