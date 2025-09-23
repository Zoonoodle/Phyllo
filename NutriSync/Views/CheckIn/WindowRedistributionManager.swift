//
//  WindowRedistributionManager.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import Foundation

class WindowRedistributionManager {
    
    static let shared = WindowRedistributionManager()
    private let engine = ProximityBasedEngine()
    private let triggerManager = RedistributionTriggerManager()
    
    private init() {}
    
    struct RedistributedWindow {
        let originalWindow: MealWindow
        let adjustedCalories: Int
        let adjustedMacros: MacroTargets
        let redistributionReason: RedistributionReason?
    }
    
    enum RedistributionReason: Equatable, Codable {
        case overconsumption(percentOver: Int)
        case underconsumption(percentUnder: Int)
        case missedWindow
        case earlyConsumption
        case lateConsumption
    }
    
    // Main redistribution function - now uses proximity-based engine
    func redistributeWindows(
        allWindows: [MealWindow],
        consumedMeals: [LoggedMeal],
        userProfile: UserProfile,
        currentTime: Date
    ) -> [RedistributedWindow] {
        
        // Check if we should use the new engine based on trigger evaluation
        if let lastMeal = consumedMeals.last,
           let windowForMeal = findWindowForMeal(meal: lastMeal, windows: allWindows) {
            
            // Evaluate if this triggers redistribution
            if triggerManager.evaluateTrigger(meal: lastMeal, window: windowForMeal) {
                return redistributeWithProximityEngine(
                    meal: lastMeal,
                    window: windowForMeal,
                    allWindows: allWindows,
                    userProfile: userProfile,
                    currentTime: currentTime
                )
            }
        }
        
        // Fall back to original redistribution logic if no trigger
        return originalRedistributeWindows(
            allWindows: allWindows,
            consumedMeals: consumedMeals,
            userProfile: userProfile,
            currentTime: currentTime
        )
    }
    
    // New proximity-based redistribution method
    private func redistributeWithProximityEngine(
        meal: LoggedMeal,
        window: MealWindow,
        allWindows: [MealWindow],
        userProfile: UserProfile,
        currentTime: Date
    ) -> [RedistributedWindow] {
        
        // Calculate deviation
        let deviation = triggerManager.calculateDeviation(meal: meal, window: window)
        
        // Create trigger
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
            totalConsumed: MacroTargets(
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat
            ),
            currentTime: currentTime
        )
        
        // Calculate redistribution with proximity engine
        let constraints = RedistributionConstraints()
        let result = engine.calculateRedistribution(
            trigger: trigger,
            windows: allWindows,
            constraints: constraints,
            currentTime: currentTime
        )
        
        // Convert result to RedistributedWindow format
        var redistributedWindows: [RedistributedWindow] = []
        
        for window in allWindows {
            if let adjustment = result.adjustedWindows.first(where: { $0.windowId == window.id.uuidString }) {
                // Apply adjustment from engine
                let reason = mapTriggerToReason(trigger: result.trigger)
                redistributedWindows.append(
                    RedistributedWindow(
                        originalWindow: window,
                        adjustedCalories: adjustment.adjustedMacros.totalCalories,
                        adjustedMacros: MacroTargets(
                            protein: adjustment.adjustedMacros.protein,
                            carbs: adjustment.adjustedMacros.carbs,
                            fat: adjustment.adjustedMacros.fat
                        ),
                        redistributionReason: reason
                    )
                )
            } else {
                // Keep original values for non-adjusted windows
                redistributedWindows.append(
                    RedistributedWindow(
                        originalWindow: window,
                        adjustedCalories: window.targetCalories,
                        adjustedMacros: window.targetMacros,
                        redistributionReason: nil
                    )
                )
            }
        }
        
        return redistributedWindows
    }
    
    // Helper to find window for a meal
    private func findWindowForMeal(meal: LoggedMeal, windows: [MealWindow]) -> MealWindow? {
        return windows.first { window in
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
    
    // Helper to map trigger type to redistribution reason
    private func mapTriggerToReason(trigger: RedistributionTrigger.TriggerType) -> RedistributionReason {
        switch trigger {
        case .overconsumption(let percent):
            return .overconsumption(percentOver: percent)
        case .underconsumption(let percent):
            return .underconsumption(percentUnder: percent)
        case .missedWindow:
            return .missedWindow
        case .earlyConsumption:
            return .earlyConsumption
        case .lateConsumption:
            return .lateConsumption
        }
    }
    
    // Original redistribution function (renamed)
    private func originalRedistributeWindows(
        allWindows: [MealWindow],
        consumedMeals: [LoggedMeal],
        userProfile: UserProfile,
        currentTime: Date
    ) -> [RedistributedWindow] {
        
        // Calculate totals consumed so far
        let totalConsumedCalories = consumedMeals.reduce(0) { $0 + $1.calories }
        let totalConsumedProtein = consumedMeals.reduce(0) { $0 + $1.protein }
        let totalConsumedCarbs = consumedMeals.reduce(0) { $0 + $1.carbs }
        let totalConsumedFat = consumedMeals.reduce(0) { $0 + $1.fat }
        
        // Calculate remaining for the day
        let remainingCalories = userProfile.dailyCalorieTarget - totalConsumedCalories
        let remainingProtein = userProfile.dailyProteinTarget - totalConsumedProtein
        let remainingCarbs = userProfile.dailyCarbTarget - totalConsumedCarbs
        let remainingFat = userProfile.dailyFatTarget - totalConsumedFat
        
        // Identify windows that need adjustment
        let upcomingWindows = allWindows.filter { !$0.isPast }
        
        guard !upcomingWindows.isEmpty else {
            // No windows to redistribute to
            return allWindows.map { RedistributedWindow(originalWindow: $0, adjustedCalories: $0.targetCalories, adjustedMacros: $0.targetMacros, redistributionReason: nil) }
        }
        
        // Calculate redistribution based on goal
        return redistributeBasedOnGoal(
            allWindows: allWindows,
            upcomingWindows: upcomingWindows,
            remainingCalories: remainingCalories,
            remainingProtein: remainingProtein,
            remainingCarbs: remainingCarbs,
            remainingFat: remainingFat,
            userProfile: userProfile,
            currentTime: currentTime
        )
    }
    
    private func redistributeBasedOnGoal(
        allWindows: [MealWindow],
        upcomingWindows: [MealWindow],
        remainingCalories: Int,
        remainingProtein: Int,
        remainingCarbs: Int,
        remainingFat: Int,
        userProfile: UserProfile,
        currentTime: Date
    ) -> [RedistributedWindow] {
        
        var redistributedWindows: [RedistributedWindow] = []
        
        // Handle past windows (no changes needed)
        for window in allWindows {
            if window.isPast {
                redistributedWindows.append(
                    RedistributedWindow(
                        originalWindow: window,
                        adjustedCalories: window.targetCalories,
                        adjustedMacros: window.targetMacros,
                        redistributionReason: nil
                    )
                )
            }
        }
        
        // Calculate total original targets for upcoming windows
        let totalUpcomingCalories = upcomingWindows.reduce(0) { $0 + $1.targetCalories }
        let _ = upcomingWindows.reduce(0) { $0 + $1.targetMacros.protein }
        let _ = upcomingWindows.reduce(0) { $0 + $1.targetMacros.carbs }
        let _ = upcomingWindows.reduce(0) { $0 + $1.targetMacros.fat }
        
        // Determine redistribution reason
        let caloriePercentDiff = (remainingCalories - totalUpcomingCalories) * 100 / totalUpcomingCalories
        let redistributionReason: RedistributionReason? = {
            if caloriePercentDiff < -20 {
                return .overconsumption(percentOver: abs(caloriePercentDiff))
            } else if caloriePercentDiff > 20 {
                return .underconsumption(percentUnder: caloriePercentDiff)
            }
            return nil
        }()
        
        // Redistribute proportionally to each upcoming window
        for window in upcomingWindows {
            let proportionOfTotal = Double(window.targetCalories) / Double(totalUpcomingCalories)
            
            // Calculate adjusted values with safety bounds
            var adjustedCalories = Int(Double(remainingCalories) * proportionOfTotal)
            var adjustedProtein = Int(Double(remainingProtein) * proportionOfTotal)
            var adjustedCarbs = Int(Double(remainingCarbs) * proportionOfTotal)
            let adjustedFat = Int(Double(remainingFat) * proportionOfTotal)
            
            // Apply goal-specific adjustments
            switch userProfile.primaryGoal {
            case .weightLoss:
                // Don't go too low on calories per window
                adjustedCalories = max(adjustedCalories, 200)
                // Prioritize protein preservation
                adjustedProtein = max(adjustedProtein, window.targetMacros.protein * 80 / 100)
                
            case .muscleGain:
                // Don't go too high on calories per window
                adjustedCalories = min(adjustedCalories, window.targetCalories * 150 / 100)
                // Keep protein high
                adjustedProtein = max(adjustedProtein, window.targetMacros.protein)
                
            case .performanceFocus:
                // Balance macros based on window purpose
                if window.purpose == .preWorkout {
                    adjustedCarbs = max(adjustedCarbs, window.targetMacros.carbs)
                } else if window.purpose == .postWorkout {
                    adjustedProtein = max(adjustedProtein, window.targetMacros.protein)
                }
                
            default:
                // Balanced approach - keep within reasonable bounds
                adjustedCalories = max(200, min(adjustedCalories, window.targetCalories * 130 / 100))
            }
            
            // Ensure macros match calories (approximately)
            let adjustedMacros = balanceMacrosToCalories(
                calories: adjustedCalories,
                protein: adjustedProtein,
                carbs: adjustedCarbs,
                fat: adjustedFat,
                purpose: window.purpose
            )
            
            redistributedWindows.append(
                RedistributedWindow(
                    originalWindow: window,
                    adjustedCalories: adjustedCalories,
                    adjustedMacros: adjustedMacros,
                    redistributionReason: redistributionReason
                )
            )
        }
        
        return redistributedWindows
    }
    
    private func balanceMacrosToCalories(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        purpose: WindowPurpose
    ) -> MacroTargets {
        // Calculate current calories from macros
        let currentCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        
        if abs(currentCalories - calories) <= 50 {
            // Close enough, return as is
            return MacroTargets(protein: protein, carbs: carbs, fat: fat)
        }
        
        // Need to adjust macros to match calories
        let scaleFactor = Double(calories) / Double(currentCalories)
        
        // Scale macros proportionally
        var adjustedProtein = Int(Double(protein) * scaleFactor)
        var adjustedCarbs = Int(Double(carbs) * scaleFactor)
        var adjustedFat = Int(Double(fat) * scaleFactor)
        
        // Apply purpose-specific minimums
        switch purpose {
        case .preWorkout:
            adjustedCarbs = max(adjustedCarbs, 30)
        case .postWorkout:
            adjustedProtein = max(adjustedProtein, 30)
        case .focusBoost:
            adjustedFat = max(adjustedFat, 10)
        default:
            break
        }
        
        return MacroTargets(
            protein: adjustedProtein,
            carbs: adjustedCarbs,
            fat: adjustedFat
        )
    }
}