import Foundation
import SwiftUI

// MARK: - Redistribution Engine Protocol

protocol RedistributionEngine {
    func calculateRedistribution(
        trigger: RedistributionTrigger,
        windows: [MealWindow],
        constraints: RedistributionConstraints,
        currentTime: Date
    ) -> RedistributionResult
}

// MARK: - Data Structures

struct RedistributionTrigger {
    let triggerWindow: MealWindow
    let triggerType: TriggerType
    let deviation: Double
    let totalConsumed: MacroTargets
    let currentTime: Date
    
    enum TriggerType {
        case overconsumption(percentOver: Int)
        case underconsumption(percentUnder: Int)
        case missedWindow
        case earlyConsumption
        case lateConsumption
    }
}

struct RedistributionConstraints {
    let minCaloriesPerWindow: Int = 200
    let maxCaloriesPerWindow: Int = 1000
    let minProteinPercentage: Double = 0.7  // Preserve 70% minimum
    let bedtimeBufferHours: Double = 3.0
    let deviationThreshold: Double = 0.25   // 25% triggers redistribution
    let maxProteinPerWindow: Int = 60
    let maxCarbsPerWindow: Int = 120
    let maxFatPerWindow: Int = 50
}

struct RedistributionResult {
    let adjustedWindows: [AdjustedWindow]
    let explanation: String
    let educationalTip: String?
    let trigger: RedistributionTrigger.TriggerType
    let confidenceScore: Double
    let totalRedistributed: MacroTargets
}

struct AdjustedWindow {
    let windowId: String
    let originalMacros: MacroTargets
    let adjustedMacros: MacroTargets
    let adjustmentRatio: Double
    let reason: String
}

// Extension to add operators to the MacroTargets struct from MealWindow.swift
extension MacroTargets: Equatable {
    var calories: Int {
        totalCalories
    }
    
    static func +(lhs: MacroTargets, rhs: MacroTargets) -> MacroTargets {
        MacroTargets(
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat
        )
    }
    
    static func -(lhs: MacroTargets, rhs: MacroTargets) -> MacroTargets {
        MacroTargets(
            protein: max(0, lhs.protein - rhs.protein),
            carbs: max(0, lhs.carbs - rhs.carbs),
            fat: max(0, lhs.fat - rhs.fat)
        )
    }
    
    static func *(lhs: MacroTargets, rhs: Double) -> MacroTargets {
        MacroTargets(
            protein: Int(Double(lhs.protein) * rhs),
            carbs: Int(Double(lhs.carbs) * rhs),
            fat: Int(Double(lhs.fat) * rhs)
        )
    }
    
    static func ==(lhs: MacroTargets, rhs: MacroTargets) -> Bool {
        lhs.protein == rhs.protein && 
        lhs.carbs == rhs.carbs && 
        lhs.fat == rhs.fat
    }
}

// MARK: - Proximity-Based Redistribution Engine

class ProximityBasedEngine: RedistributionEngine {
    
    func calculateRedistribution(
        trigger: RedistributionTrigger,
        windows: [MealWindow],
        constraints: RedistributionConstraints,
        currentTime: Date
    ) -> RedistributionResult {
        
        // Filter for upcoming windows only
        let upcomingWindows = windows.filter { window in
            window.startTime > currentTime && window.consumed.calories == 0
        }
        
        guard !upcomingWindows.isEmpty else {
            return RedistributionResult(
                adjustedWindows: [],
                explanation: "No upcoming windows available for redistribution.",
                educationalTip: nil,
                trigger: trigger.triggerType,
                confidenceScore: 0.0,
                totalRedistributed: MacroTargets(protein: 0, carbs: 0, fat: 0)
            )
        }
        
        // Calculate total adjustment needed
        let adjustmentNeeded = calculateAdjustmentNeeded(
            trigger: trigger,
            triggerWindow: trigger.triggerWindow
        )
        
        // Apply bedtime buffer filter
        let eligibleWindows = filterWindowsForBedtime(
            windows: upcomingWindows,
            constraints: constraints,
            currentTime: currentTime
        )
        
        guard !eligibleWindows.isEmpty else {
            return RedistributionResult(
                adjustedWindows: [],
                explanation: "No windows available outside of bedtime buffer.",
                educationalTip: "Try to complete your meals earlier to avoid late-night eating.",
                trigger: trigger.triggerType,
                confidenceScore: 0.5,
                totalRedistributed: MacroTargets(protein: 0, carbs: 0, fat: 0)
            )
        }
        
        // Calculate proximity weights
        let weights = calculateProximityWeights(
            windows: eligibleWindows,
            triggerWindow: trigger.triggerWindow,
            currentTime: currentTime
        )
        
        // Distribute adjustment across windows
        let adjustedWindows = distributeAdjustment(
            windows: eligibleWindows,
            weights: weights,
            adjustment: adjustmentNeeded,
            constraints: constraints,
            trigger: trigger
        )
        
        // Generate explanation
        let explanation = generateExplanation(
            trigger: trigger,
            adjustedWindows: adjustedWindows
        )
        
        // Generate educational tip
        let educationalTip = generateEducationalTip(
            trigger: trigger,
            adjustedWindows: adjustedWindows
        )
        
        // Calculate total redistributed
        let totalRedistributed = calculateTotalRedistributed(
            adjustedWindows: adjustedWindows
        )
        
        return RedistributionResult(
            adjustedWindows: adjustedWindows,
            explanation: explanation,
            educationalTip: educationalTip,
            trigger: trigger.triggerType,
            confidenceScore: calculateConfidence(adjustedWindows: adjustedWindows),
            totalRedistributed: totalRedistributed
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateAdjustmentNeeded(
        trigger: RedistributionTrigger,
        triggerWindow: MealWindow
    ) -> MacroTargets {
        
        let consumed = MacroTargets(
            protein: trigger.totalConsumed.protein,
            carbs: trigger.totalConsumed.carbs,
            fat: trigger.totalConsumed.fat
        )
        
        let target = MacroTargets(
            protein: triggerWindow.effectiveProtein,
            carbs: triggerWindow.effectiveCarbs,
            fat: triggerWindow.effectiveFat
        )
        
        // Calculate the difference (positive = overconsumption, negative = underconsumption)
        switch trigger.triggerType {
        case .overconsumption:
            return consumed - target // Positive values to reduce from other windows
        case .underconsumption:
            return target - consumed // Positive values to add to other windows
        case .missedWindow:
            return target // Full window amount to redistribute
        default:
            return MacroTargets(protein: 0, carbs: 0, fat: 0)
        }
    }
    
    private func filterWindowsForBedtime(
        windows: [MealWindow],
        constraints: RedistributionConstraints,
        currentTime: Date
    ) -> [MealWindow] {
        
        // Estimate bedtime (could be from user profile)
        let calendar = Calendar.current
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
        bedtimeComponents.hour = 22 // 10 PM default
        bedtimeComponents.minute = 0
        
        guard let bedtime = calendar.date(from: bedtimeComponents) else {
            return windows
        }
        
        // Handle midnight crossover - if bedtime is before current time, it's tomorrow
        let adjustedBedtime: Date
        if bedtime < currentTime {
            // Bedtime has passed today, use tomorrow's bedtime
            adjustedBedtime = calendar.date(byAdding: .day, value: 1, to: bedtime) ?? bedtime
        } else {
            adjustedBedtime = bedtime
        }
        
        let bufferTime = adjustedBedtime.addingTimeInterval(-constraints.bedtimeBufferHours * 3600)
        
        return windows.filter { window in
            // Handle windows that might cross midnight
            let effectiveEndTime = window.endTime < window.startTime 
                ? calendar.date(byAdding: .day, value: 1, to: window.endTime) ?? window.endTime
                : window.endTime
                
            return effectiveEndTime <= bufferTime || window.startTime < currentTime.addingTimeInterval(3600)
        }
    }
    
    private func calculateProximityWeights(
        windows: [MealWindow],
        triggerWindow: MealWindow,
        currentTime: Date
    ) -> [String: Double] {
        
        var weights: [String: Double] = [:]
        
        guard let firstWindow = windows.first,
              let lastWindow = windows.last else {
            return weights
        }
        
        let maxTimeSpan = lastWindow.endTime.timeIntervalSince(firstWindow.startTime)
        
        for window in windows {
            let timeToWindow = window.startTime.timeIntervalSince(currentTime)
            
            // Closer windows get higher weight (inverse relationship)
            let proximityWeight: Double
            if maxTimeSpan > 0 {
                proximityWeight = 1.0 - (timeToWindow / maxTimeSpan)
            } else {
                proximityWeight = 1.0
            }
            
            // Apply window purpose modifier
            let purposeModifier = getPurposeModifier(for: window.purpose)
            
            weights[window.id.uuidString] = max(0.1, proximityWeight * purposeModifier)
        }
        
        // Normalize weights to sum to 1.0
        let totalWeight = weights.values.reduce(0, +)
        if totalWeight > 0 {
            for (id, weight) in weights {
                weights[id] = weight / totalWeight
            }
        }
        
        return weights
    }
    
    private func getPurposeModifier(for purpose: WindowPurpose) -> Double {
        switch purpose {
        case .preWorkout, .postWorkout:
            return 0.8 // Protect workout windows slightly
        case .sleepOptimization:
            return 0.5 // Strongly protect sleep windows
        case .metabolicBoost:
            return 1.2 // More flexible for adjustment
        default:
            return 1.0
        }
    }
    
    private func distributeAdjustment(
        windows: [MealWindow],
        weights: [String: Double],
        adjustment: MacroTargets,
        constraints: RedistributionConstraints,
        trigger: RedistributionTrigger
    ) -> [AdjustedWindow] {
        
        var adjustedWindows: [AdjustedWindow] = []
        
        for window in windows {
            guard let weight = weights[window.id.uuidString] else { continue }
            
            let originalMacros = MacroTargets(
                protein: window.effectiveProtein,
                carbs: window.effectiveCarbs,
                fat: window.effectiveFat
            )
            
            // Calculate weighted adjustment
            let windowAdjustment = adjustment * weight
            
            // Apply adjustment based on trigger type
            let proposedMacros: MacroTargets
            switch trigger.triggerType {
            case .overconsumption:
                // Reduce macros in other windows
                proposedMacros = originalMacros - windowAdjustment
            case .underconsumption, .missedWindow:
                // Increase macros in other windows
                proposedMacros = originalMacros + windowAdjustment
            default:
                proposedMacros = originalMacros
            }
            
            // Apply constraints
            let constrainedMacros = applyConstraints(
                macros: proposedMacros,
                original: originalMacros,
                constraints: constraints,
                windowPurpose: window.purpose
            )
            
            let adjustmentRatio = Double(constrainedMacros.totalCalories) / Double(originalMacros.totalCalories)
            
            adjustedWindows.append(AdjustedWindow(
                windowId: window.id.uuidString,
                originalMacros: originalMacros,
                adjustedMacros: constrainedMacros,
                adjustmentRatio: adjustmentRatio,
                reason: generateWindowReason(
                    window: window,
                    trigger: trigger,
                    adjustmentRatio: adjustmentRatio
                )
            ))
        }
        
        return adjustedWindows
    }
    
    private func applyConstraints(
        macros: MacroTargets,
        original: MacroTargets,
        constraints: RedistributionConstraints,
        windowPurpose: WindowPurpose
    ) -> MacroTargets {
        
        // Apply min/max calorie constraints
        let constrainedCalories = min(
            constraints.maxCaloriesPerWindow,
            max(constraints.minCaloriesPerWindow, macros.calories)
        )
        
        // Preserve minimum protein percentage
        let minProtein = Int(Double(original.protein) * constraints.minProteinPercentage)
        let constrainedProtein = min(
            constraints.maxProteinPerWindow,
            max(minProtein, macros.protein)
        )
        
        // Apply carb and fat constraints
        let constrainedCarbs = min(constraints.maxCarbsPerWindow, max(0, macros.carbs))
        let constrainedFat = min(constraints.maxFatPerWindow, max(0, macros.fat))
        
        return MacroTargets(
            protein: constrainedProtein,
            carbs: constrainedCarbs,
            fat: constrainedFat
        )
    }
    
    private func generateWindowReason(
        window: MealWindow,
        trigger: RedistributionTrigger,
        adjustmentRatio: Double
    ) -> String {
        let changePercent = Int((abs(adjustmentRatio - 1.0)) * 100)
        
        switch trigger.triggerType {
        case .overconsumption:
            return "Reduced by \(changePercent)% due to earlier overconsumption"
        case .underconsumption:
            return "Increased by \(changePercent)% to compensate for earlier deficit"
        case .missedWindow:
            return "Increased by \(changePercent)% to account for missed window"
        default:
            return "Adjusted by \(changePercent)%"
        }
    }
    
    private func generateExplanation(
        trigger: RedistributionTrigger,
        adjustedWindows: [AdjustedWindow]
    ) -> String {
        
        guard !adjustedWindows.isEmpty else {
            return "No adjustments were needed."
        }
        
        let totalCalorieChange = adjustedWindows.reduce(0) { sum, window in
            sum + abs(window.adjustedMacros.totalCalories - window.originalMacros.totalCalories)
        }
        
        switch trigger.triggerType {
        case .overconsumption(let percent):
            return "You ate \(percent)% more than planned. I've reduced your upcoming meals by a total of \(totalCalorieChange) calories, with larger adjustments to your next window to help balance your day."
        case .underconsumption(let percent):
            return "You ate \(percent)% less than planned. I've increased your upcoming meals by \(totalCalorieChange) calories to help you reach your daily goals."
        case .missedWindow:
            return "You missed a meal window. I've redistributed those \(totalCalorieChange) calories across your remaining meals for the day."
        default:
            return "I've adjusted your upcoming meal windows to better align with your consumption pattern."
        }
    }
    
    private func generateEducationalTip(
        trigger: RedistributionTrigger,
        adjustedWindows: [AdjustedWindow]
    ) -> String? {
        
        switch trigger.triggerType {
        case .overconsumption(let percent) where percent > 50:
            return "Try adding more protein and fiber to feel fuller with smaller portions."
        case .underconsumption(let percent) where percent > 50:
            return "Consider setting meal reminders to help you stay on track with your nutrition timing."
        case .missedWindow:
            return "Preparing meals in advance can help you avoid missing eating windows."
        default:
            return nil
        }
    }
    
    private func calculateTotalRedistributed(adjustedWindows: [AdjustedWindow]) -> MacroTargets {
        let totalChange = adjustedWindows.reduce(MacroTargets(protein: 0, carbs: 0, fat: 0)) { sum, window in
            let change = MacroTargets(
                protein: abs(window.adjustedMacros.protein - window.originalMacros.protein),
                carbs: abs(window.adjustedMacros.carbs - window.originalMacros.carbs),
                fat: abs(window.adjustedMacros.fat - window.originalMacros.fat)
            )
            return sum + change
        }
        return totalChange
    }
    
    private func calculateConfidence(adjustedWindows: [AdjustedWindow]) -> Double {
        guard !adjustedWindows.isEmpty else { return 0.0 }
        
        // Calculate confidence based on how well constraints were met
        let avgRatio = adjustedWindows.reduce(0.0) { sum, window in
            sum + abs(window.adjustmentRatio - 1.0)
        } / Double(adjustedWindows.count)
        
        // Lower ratio deviation = higher confidence
        return max(0.5, min(1.0, 1.0 - avgRatio))
    }
}

// MARK: - Redistribution Preview

extension ProximityBasedEngine {
    func previewRedistribution(
        for meal: MacroTargets,
        in window: MealWindow,
        allWindows: [MealWindow],
        constraints: RedistributionConstraints,
        currentTime: Date
    ) -> RedistributionResult {
        
        // Calculate deviation
        let targetCalories = window.effectiveCalories
        let deviation = Double(meal.calories - targetCalories) / Double(targetCalories)
        
        // Create trigger based on deviation
        let triggerType: RedistributionTrigger.TriggerType
        if deviation > 0 {
            triggerType = .overconsumption(percentOver: Int(deviation * 100))
        } else {
            triggerType = .underconsumption(percentUnder: Int(abs(deviation) * 100))
        }
        
        let trigger = RedistributionTrigger(
            triggerWindow: window,
            triggerType: triggerType,
            deviation: deviation,
            totalConsumed: meal,
            currentTime: currentTime
        )
        
        return calculateRedistribution(
            trigger: trigger,
            windows: allWindows,
            constraints: constraints,
            currentTime: currentTime
        )
    }
}