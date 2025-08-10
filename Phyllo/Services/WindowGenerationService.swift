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
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        // 16:8 fasting - eating window from 12pm to 8pm
        let windowStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        let windowEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
        
        return [
            // Lunch (12pm-2pm) - 40% of daily intake
            MealWindow(
                startTime: windowStart,
                endTime: min(windowStart.addingTimeInterval(purposeDuration(.sustainedEnergy)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
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
            
            // Snack (3pm-4pm) - 20% of daily intake
            MealWindow(
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!,
                endTime: min(calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!.addingTimeInterval(purposeDuration(.focusBoost)), calendar.date(byAdding: .minute, value: -90, to: sleepTime)!),
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
            
            // Dinner (6pm-8pm) - 40% of daily intake
            MealWindow(
                startTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date)!,
                endTime: min(calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date)!.addingTimeInterval(purposeDuration(.recovery)), windowEnd),
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
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        // Adjust meal times based on wake time
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
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
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
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
        let totalCalories = targets.dailyCalories
        let totalProtein = targets.protein
        let totalCarbs = targets.carbs
        let totalFat = targets.fat
        
        let breakfast = calendar.date(byAdding: .minute, value: 30, to: wakeTime)!
        
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