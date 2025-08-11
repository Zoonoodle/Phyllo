//
//  WindowGenerationService.swift
//  Phyllo
//
//  Created on 8/6/25.
//

import Foundation

/// Service responsible for generating meal windows based on user goals and preferences
class WindowGenerationService {
    static let shared = WindowGenerationService()
    private let goalCalculator = GoalCalculationService.shared
    
    private init() {}
    
    // Phase 1: central purpose→duration mapping
    private func purposeDuration(_ purpose: WindowPurpose) -> TimeInterval {
        switch purpose {
        case .sustainedEnergy, .recovery:
            return 120 * 60 // 120 min
        case .metabolicBoost, .sleepOptimization:
            return 105 * 60 // 105 min
        case .focusBoost, .preworkout, .postworkout:
            return 60 * 60 // 60 min
        }
    }
    
    /// Generate meal windows for a specific date based on user profile and check-in data
    func generateWindows(
        for date: Date,
        profile: UserProfile,
        checkIn: MorningCheckInData?
    ) -> [MealWindow] {
        // Calculate nutrition targets based on goals
        let targets = calculateNutritionTargets(for: profile)
        
        let calendar = Calendar.current
        let currentTime = TimeProvider.shared.currentTime
        
        // Derive wake and sleep ranges from morning check-in when available.
        let wakeTime = checkIn?.wakeTime ?? calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date)!
        // Heuristic: earlier dinner if short sleep or low energy; later dinner allowed with high energy
        let defaultSleep = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: date)!
        let sleepTime = defaultSleep
        
        // Phase 1 foundation: centralize purpose→duration mapping and guardrail end times
        func purposeDuration(_ purpose: WindowPurpose) -> TimeInterval {
            switch purpose {
            case .sustainedEnergy, .recovery:
                return 120 * 60 // 120 min
            case .metabolicBoost, .sleepOptimization:
                return 105 * 60 // 105 min
            case .focusBoost, .preworkout, .postworkout:
                return 60 * 60 // 60 min
            }
        }
        
        // Phase 2 adjustments hooks would live here (post-meal/morning signals) — for now generation returns base windows; redistribution happens later
        switch profile.primaryGoal {
        case .weightLoss:
            return generateWeightLossWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
        case .muscleGain:
            return generateMuscleBuildWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
        case .maintainWeight:
            return generateMaintenanceWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
        case .performanceFocus:
            return generateEnergyWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
            
        case .betterSleep:
            // Use performance approach for better sleep
            return generateEnergyWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
            
        case .overallWellbeing:
            // Use balanced maintenance approach
            return generateMaintenanceWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
            
        case .athleticPerformance:
            // Use muscle building approach for athletic performance
            return generateMuscleBuildWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile, targets: targets)
        }
    }
    
    // MARK: - Nutrition Target Calculation
    
    private func calculateNutritionTargets(for profile: UserProfile) -> GoalCalculationService.NutritionTargets {
        // Determine goal type based on profile
        let goalType: GoalCalculationService.GoalType
        
        switch profile.primaryGoal {
        case .weightLoss(let targetPounds, let timeline):
            goalType = .specificWeightTarget(
                currentWeight: profile.weight,
                targetWeight: profile.weight - targetPounds,
                weeks: timeline
            )
            
        case .muscleGain(let targetPounds, let timeline):
            goalType = .specificWeightTarget(
                currentWeight: profile.weight,
                targetWeight: profile.weight + targetPounds,
                weeks: timeline
            )
            
        case .maintainWeight, .overallWellbeing:
            goalType = .performanceOptimization(
                currentWeight: profile.weight,
                activityLevel: profile.activityLevel
            )
            
        case .performanceFocus, .betterSleep:
            goalType = .performanceOptimization(
                currentWeight: profile.weight,
                activityLevel: profile.activityLevel
            )
            
        case .athleticPerformance:
            goalType = .bodyComposition(
                currentWeight: profile.weight,
                currentBF: nil, // Would be provided if we track it
                targetBF: nil,
                focus: .leanMuscleGain
            )
        }
        
        // Calculate targets using the service
        return goalCalculator.calculateTargets(
            for: goalType,
            height: profile.height,
            age: profile.age,
            gender: profile.gender,
            activityLevel: profile.activityLevel
        )
    }
    
    // MARK: - Weight Loss Windows (16:8 Intermittent Fasting)
    private func generateWeightLossWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile,
        targets: GoalCalculationService.NutritionTargets
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let currentTime = TimeProvider.shared.currentTime
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        // 16:8 fasting - eating window from 12pm to 8pm
        let windowStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        let windowEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
        
        // Calculate available time for eating window
        let availableTime = windowEnd.timeIntervalSince(windowStart)
        let minimumWindowDuration: TimeInterval = 60 * 60 // 1 hour minimum
        
        // Generate windows based on available time
        if availableTime >= 6 * 60 * 60 { // At least 6 hours available
            // Standard 3-window approach
            let lunchEnd = min(windowStart.addingTimeInterval(purposeDuration(.sustainedEnergy)), windowStart.addingTimeInterval(availableTime * 0.33))
            let snackStart = lunchEnd.addingTimeInterval(30 * 60) // 30 min gap
            let snackEnd = min(snackStart.addingTimeInterval(purposeDuration(.focusBoost)), snackStart.addingTimeInterval(minimumWindowDuration))
            let dinnerStart = snackEnd.addingTimeInterval(30 * 60) // 30 min gap
            
            return [
                // Lunch - 40% of daily intake
                MealWindow(
                    startTime: windowStart,
                    endTime: lunchEnd,
                    targetCalories: Int(Double(totalCalories) * 0.4),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.4),
                        carbs: Int(Double(totalCarbs) * 0.4),
                        fat: Int(Double(totalFat) * 0.4)
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                
                // Snack - 20% of daily intake
                MealWindow(
                    startTime: snackStart,
                    endTime: snackEnd,
                    targetCalories: Int(Double(totalCalories) * 0.2),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.2),
                        carbs: Int(Double(totalCarbs) * 0.2),
                        fat: Int(Double(totalFat) * 0.2)
                    ),
                    purpose: .focusBoost,
                    flexibility: .flexible,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                
                // Dinner - 40% of daily intake
                MealWindow(
                    startTime: dinnerStart,
                    endTime: min(dinnerStart.addingTimeInterval(purposeDuration(.recovery)), windowEnd),
                    targetCalories: Int(Double(totalCalories) * 0.4),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.4),
                        carbs: Int(Double(totalCarbs) * 0.4),
                        fat: Int(Double(totalFat) * 0.4)
                    ),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        } else if availableTime >= 3 * 60 * 60 { // 3-6 hours available
            // Compressed 2-window approach
            let firstWindowEnd = windowStart.addingTimeInterval(availableTime * 0.45)
            let secondWindowStart = firstWindowEnd.addingTimeInterval(30 * 60) // 30 min gap
            
            return [
                // Combined Lunch/Snack - 60% of daily intake
                MealWindow(
                    startTime: windowStart,
                    endTime: firstWindowEnd,
                    targetCalories: Int(Double(totalCalories) * 0.6),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.6),
                        carbs: Int(Double(totalCarbs) * 0.6),
                        fat: Int(Double(totalFat) * 0.6)
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .flexible,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                
                // Dinner - 40% of daily intake
                MealWindow(
                    startTime: secondWindowStart,
                    endTime: windowEnd,
                    targetCalories: Int(Double(totalCalories) * 0.4),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.4),
                        carbs: Int(Double(totalCarbs) * 0.4),
                        fat: Int(Double(totalFat) * 0.4)
                    ),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        } else {
            // Less than 3 hours - single window with all nutrition
            return [
                MealWindow(
                    startTime: windowStart,
                    endTime: windowEnd,
                    targetCalories: totalCalories,
                    targetMacros: MacroTargets(
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fat: totalFat
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .flexible,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        }
    }
    
    // MARK: - Muscle Build Windows (5-6 meals)
    private func generateMuscleBuildWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile,
        targets: GoalCalculationService.NutritionTargets
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let currentTime = TimeProvider.shared.currentTime
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        // Adjust meal times based on wake time
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
        // Calculate remaining time until sleep
        let remainingTime = sleepTime.timeIntervalSince(breakfast) - (90 * 60) // Minus 90 min before sleep
        
        // Adjust number of windows based on available time
        if remainingTime < 4 * 60 * 60 { // Less than 4 hours
            // Compressed schedule with 2 windows
            let firstWindowEnd = breakfast.addingTimeInterval(remainingTime * 0.45)
            let secondWindowStart = firstWindowEnd.addingTimeInterval(30 * 60)
            
            return [
                MealWindow(
                    startTime: breakfast,
                    endTime: firstWindowEnd,
                    targetCalories: Int(Double(totalCalories) * 0.6),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.6),
                        carbs: Int(Double(totalCarbs) * 0.65),
                        fat: Int(Double(totalFat) * 0.5)
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .flexible,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                
                MealWindow(
                    startTime: secondWindowStart,
                    endTime: min(secondWindowStart.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                    targetCalories: Int(Double(totalCalories) * 0.4),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.4),
                        carbs: Int(Double(totalCarbs) * 0.35),
                        fat: Int(Double(totalFat) * 0.5)
                    ),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        }
        
        return [
            // Breakfast - 20%
            MealWindow(
                startTime: breakfast,
                endTime: min(breakfast.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.2),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.2),
                    carbs: Int(Double(totalCarbs) * 0.25),
                    fat: Int(Double(totalFat) * 0.15)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Mid-morning snack - 15%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 3, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 3, to: breakfast)!.addingTimeInterval(purposeDuration(.preworkout)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.15),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.15),
                    carbs: Int(Double(totalCarbs) * 0.15),
                    fat: Int(Double(totalFat) * 0.1)
                ),
                purpose: .preworkout,
                flexibility: .flexible,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Lunch - 25%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 5, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 5, to: breakfast)!.addingTimeInterval(purposeDuration(.postworkout)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.25),
                    carbs: Int(Double(totalCarbs) * 0.3),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .postworkout,
                flexibility: .strict,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Afternoon snack - 15%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 8, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 8, to: breakfast)!.addingTimeInterval(purposeDuration(.focusBoost)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.15),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.15),
                    carbs: Int(Double(totalCarbs) * 0.1),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .focusBoost,
                flexibility: .flexible,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Dinner - 25%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 11, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 11, to: breakfast)!.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.25),
                    carbs: Int(Double(totalCarbs) * 0.2),
                    fat: Int(Double(totalFat) * 0.35)
                ),
                purpose: .recovery,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            )
        ]
    }
    
    // MARK: - Maintenance Windows (3-4 meals)
    private func generateMaintenanceWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile,
        targets: GoalCalculationService.NutritionTargets
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let currentTime = TimeProvider.shared.currentTime
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
        // Calculate available time
        let remainingTime = sleepTime.timeIntervalSince(breakfast) - (90 * 60)
        
        // If less than 5 hours remaining, compress to 2 windows
        if remainingTime < 5 * 60 * 60 {
            let firstWindowEnd = breakfast.addingTimeInterval(remainingTime * 0.45)
            let secondWindowStart = firstWindowEnd.addingTimeInterval(30 * 60)
            
            return [
                MealWindow(
                    startTime: breakfast,
                    endTime: firstWindowEnd,
                    targetCalories: Int(Double(totalCalories) * 0.6),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.6),
                        carbs: Int(Double(totalCarbs) * 0.65),
                        fat: Int(Double(totalFat) * 0.55)
                    ),
                    purpose: .sustainedEnergy,
                    flexibility: .flexible,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                
                MealWindow(
                    startTime: secondWindowStart,
                    endTime: min(secondWindowStart.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                    targetCalories: Int(Double(totalCalories) * 0.4),
                    targetMacros: MacroTargets(
                        protein: Int(Double(totalProtein) * 0.4),
                        carbs: Int(Double(totalCarbs) * 0.35),
                        fat: Int(Double(totalFat) * 0.45)
                    ),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: calendar.startOfDay(for: date),
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        }
        
        return [
            // Breakfast - 25%
            MealWindow(
                startTime: breakfast,
                endTime: min(breakfast.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.25),
                    carbs: Int(Double(totalCarbs) * 0.3),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Lunch - 35%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 5, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 5, to: breakfast)!.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.35),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.35),
                    carbs: Int(Double(totalCarbs) * 0.35),
                    fat: Int(Double(totalFat) * 0.35)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Snack - 15%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 8, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 8, to: breakfast)!.addingTimeInterval(purposeDuration(.focusBoost)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.15),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.15),
                    carbs: Int(Double(totalCarbs) * 0.1),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .focusBoost,
                flexibility: .flexible,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Dinner - 25%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 11, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 11, to: breakfast)!.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.25),
                    carbs: Int(Double(totalCarbs) * 0.25),
                    fat: Int(Double(totalFat) * 0.25)
                ),
                purpose: .recovery,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            )
        ]
    }
    
    // MARK: - Energy Windows (Timed for stable blood sugar)
    private func generateEnergyWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile,
        targets: GoalCalculationService.NutritionTargets
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let currentTime = TimeProvider.shared.currentTime
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        let breakfast = calendar.date(byAdding: .minute, value: 30, to: wakeTime)!
        
        // Calculate available time
        let remainingTime = sleepTime.timeIntervalSince(breakfast) - (90 * 60)
        
        // If less than 5 hours remaining, compress schedule
        if remainingTime < 5 * 60 * 60 {
            // Create 2-3 windows based on available time
            if remainingTime < 3 * 60 * 60 {
                // Very compressed - 2 windows
                let firstWindowEnd = breakfast.addingTimeInterval(remainingTime * 0.45)
                let secondWindowStart = firstWindowEnd.addingTimeInterval(30 * 60)
                
                return [
                    MealWindow(
                        startTime: breakfast,
                        endTime: firstWindowEnd,
                        targetCalories: Int(Double(totalCalories) * 0.6),
                        targetMacros: MacroTargets(
                            protein: Int(Double(totalProtein) * 0.6),
                            carbs: Int(Double(totalCarbs) * 0.5),
                            fat: Int(Double(totalFat) * 0.65)
                        ),
                        purpose: .sustainedEnergy,
                        flexibility: .flexible,
                        dayDate: calendar.startOfDay(for: date),
                        adjustedCalories: nil,
                        adjustedMacros: nil,
                        redistributionReason: nil
                    ),
                    
                    MealWindow(
                        startTime: secondWindowStart,
                        endTime: min(secondWindowStart.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                        targetCalories: Int(Double(totalCalories) * 0.4),
                        targetMacros: MacroTargets(
                            protein: Int(Double(totalProtein) * 0.4),
                            carbs: Int(Double(totalCarbs) * 0.5),
                            fat: Int(Double(totalFat) * 0.35)
                        ),
                        purpose: .recovery,
                        flexibility: .moderate,
                        dayDate: calendar.startOfDay(for: date),
                        adjustedCalories: nil,
                        adjustedMacros: nil,
                        redistributionReason: nil
                    )
                ]
            } else {
                // 3 compressed windows
                let windowSpacing = remainingTime / 3.5
                
                return [
                    MealWindow(
                        startTime: breakfast,
                        endTime: breakfast.addingTimeInterval(windowSpacing * 0.8),
                        targetCalories: Int(Double(totalCalories) * 0.35),
                        targetMacros: MacroTargets(
                            protein: Int(Double(totalProtein) * 0.35),
                            carbs: Int(Double(totalCarbs) * 0.3),
                            fat: Int(Double(totalFat) * 0.4)
                        ),
                        purpose: .sustainedEnergy,
                        flexibility: .moderate,
                        dayDate: calendar.startOfDay(for: date),
                        adjustedCalories: nil,
                        adjustedMacros: nil,
                        redistributionReason: nil
                    ),
                    
                    MealWindow(
                        startTime: breakfast.addingTimeInterval(windowSpacing),
                        endTime: breakfast.addingTimeInterval(windowSpacing * 1.8),
                        targetCalories: Int(Double(totalCalories) * 0.35),
                        targetMacros: MacroTargets(
                            protein: Int(Double(totalProtein) * 0.35),
                            carbs: Int(Double(totalCarbs) * 0.4),
                            fat: Int(Double(totalFat) * 0.3)
                        ),
                        purpose: .focusBoost,
                        flexibility: .flexible,
                        dayDate: calendar.startOfDay(for: date),
                        adjustedCalories: nil,
                        adjustedMacros: nil,
                        redistributionReason: nil
                    ),
                    
                    MealWindow(
                        startTime: breakfast.addingTimeInterval(windowSpacing * 2),
                        endTime: min(breakfast.addingTimeInterval(windowSpacing * 2.8), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                        targetCalories: Int(Double(totalCalories) * 0.3),
                        targetMacros: MacroTargets(
                            protein: Int(Double(totalProtein) * 0.3),
                            carbs: Int(Double(totalCarbs) * 0.3),
                            fat: Int(Double(totalFat) * 0.3)
                        ),
                        purpose: .recovery,
                        flexibility: .moderate,
                        dayDate: calendar.startOfDay(for: date),
                        adjustedCalories: nil,
                        adjustedMacros: nil,
                        redistributionReason: nil
                    )
                ]
            }
        }
        
        return [
            // Early breakfast - 20%
            MealWindow(
                startTime: breakfast,
                endTime: min(breakfast.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.2),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.2),
                    carbs: Int(Double(totalCarbs) * 0.15),
                    fat: Int(Double(totalFat) * 0.25)
                ),
                purpose: .sustainedEnergy,
                flexibility: .strict,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Mid-morning - 20%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 3, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 3, to: breakfast)!.addingTimeInterval(purposeDuration(.focusBoost)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.2),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.2),
                    carbs: Int(Double(totalCarbs) * 0.2),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .focusBoost,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Lunch - 25%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 5, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 5, to: breakfast)!.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.25),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.25),
                    carbs: Int(Double(totalCarbs) * 0.3),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Afternoon - 15%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 8, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 8, to: breakfast)!.addingTimeInterval(purposeDuration(.focusBoost)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.15),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.15),
                    carbs: Int(Double(totalCarbs) * 0.15),
                    fat: Int(Double(totalFat) * 0.15)
                ),
                purpose: .focusBoost,
                flexibility: .flexible,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            ),
            
            // Dinner - 20%
            MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 11, to: breakfast)!,
                endTime: min(calendar.date(byAdding: .hour, value: 11, to: breakfast)!.addingTimeInterval(purposeDuration(.recovery)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
                targetCalories: Int(Double(totalCalories) * 0.2),
                targetMacros: MacroTargets(
                    protein: Int(Double(totalProtein) * 0.2),
                    carbs: Int(Double(totalCarbs) * 0.2),
                    fat: Int(Double(totalFat) * 0.2)
                ),
                purpose: .recovery,
                flexibility: .moderate,
                dayDate: calendar.startOfDay(for: date),
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
            )
        ]
    }
}