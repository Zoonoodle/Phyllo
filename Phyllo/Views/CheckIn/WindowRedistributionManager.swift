//
//  WindowRedistributionManager.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import Foundation

class WindowRedistributionManager {
    
    static let shared = WindowRedistributionManager()
    
    private init() {}
    
    struct RedistributedWindow {
        let originalWindow: MealWindow
        let adjustedCalories: Int
        let adjustedMacros: MacroTargets
        let redistributionReason: RedistributionReason?
    }
    
    enum RedistributionReason: Equatable {
        case overconsumption(percentOver: Int)
        case underconsumption(percentUnder: Int)
        case missedWindow
        case earlyConsumption
        case lateConsumption
    }
    
    // Main redistribution function
    func redistributeWindows(
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
        let totalUpcomingProtein = upcomingWindows.reduce(0) { $0 + $1.targetMacros.protein }
        let totalUpcomingCarbs = upcomingWindows.reduce(0) { $0 + $1.targetMacros.carbs }
        let totalUpcomingFat = upcomingWindows.reduce(0) { $0 + $1.targetMacros.fat }
        
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
            var adjustedFat = Int(Double(remainingFat) * proportionOfTotal)
            
            // Apply goal-specific adjustments
            switch userProfile.primaryGoal {
            case .weightLoss:
                // Don't go too low on calories per window
                adjustedCalories = max(adjustedCalories, 200)
                // Prioritize protein preservation
                adjustedProtein = max(adjustedProtein, window.targetMacros.protein * 80 / 100)
                
            case .muscleBuild:
                // Don't go too high on calories per window
                adjustedCalories = min(adjustedCalories, window.targetCalories * 150 / 100)
                // Keep protein high
                adjustedProtein = max(adjustedProtein, window.targetMacros.protein)
                
            case .improveEnergy:
                // Balance macros based on window purpose
                if window.purpose == .preworkout {
                    adjustedCarbs = max(adjustedCarbs, window.targetMacros.carbs)
                } else if window.purpose == .postworkout {
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
        case .preworkout:
            adjustedCarbs = max(adjustedCarbs, 30)
        case .postworkout:
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