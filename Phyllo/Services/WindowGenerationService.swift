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
    
    private init() {}
    
    /// Generate meal windows for a specific date based on user profile and check-in data
    func generateWindows(
        for date: Date,
        profile: UserProfile,
        checkIn: MorningCheckInData?
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let wakeTime = checkIn?.wakeTime ?? calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date)!
        let sleepTime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: date)!
        
        // Generate windows based on primary goal
        switch profile.primaryGoal {
        case .weightLoss:
            return generateWeightLossWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile)
        case .muscleBuild:
            return generateMuscleBuildWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile)
        case .maintainWeight:
            return generateMaintenanceWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile)
        case .improveEnergy:
            return generateEnergyWindows(date: date, wakeTime: wakeTime, sleepTime: sleepTime, profile: profile)
        }
    }
    
    // MARK: - Weight Loss Windows (16:8 Intermittent Fasting)
    private func generateWeightLossWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let totalCalories = profile.dailyCalorieTarget
        let totalProtein = profile.dailyProteinTarget
        let totalCarbs = profile.dailyCarbTarget
        let totalFat = profile.dailyFatTarget
        
        // 16:8 fasting - eating window from 12pm to 8pm
        let windowStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        let windowEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
        
        return [
            // Lunch (12pm-2pm) - 40% of daily intake
            MealWindow(
                startTime: windowStart,
                endTime: calendar.date(byAdding: .hour, value: 2, to: windowStart)!,
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
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date)!,
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
    }
    
    // MARK: - Muscle Build Windows (5-6 meals)
    private func generateMuscleBuildWindows(
        date: Date,
        wakeTime: Date,
        sleepTime: Date,
        profile: UserProfile
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let totalCalories = profile.dailyCalorieTarget
        let totalProtein = profile.dailyProteinTarget
        let totalCarbs = profile.dailyCarbTarget
        let totalFat = profile.dailyFatTarget
        
        // Adjust meal times based on wake time
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
        return [
            // Breakfast - 20%
            MealWindow(
                startTime: breakfast,
                endTime: calendar.date(byAdding: .hour, value: 1, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 4, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 6, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 9, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 12, to: breakfast)!,
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
        profile: UserProfile
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let totalCalories = profile.dailyCalorieTarget
        let totalProtein = profile.dailyProteinTarget
        let totalCarbs = profile.dailyCarbTarget
        let totalFat = profile.dailyFatTarget
        
        let breakfast = calendar.date(byAdding: .hour, value: 1, to: wakeTime)!
        
        return [
            // Breakfast - 25%
            MealWindow(
                startTime: breakfast,
                endTime: calendar.date(byAdding: .hour, value: 1, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 6, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 9, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 12, to: breakfast)!,
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
        profile: UserProfile
    ) -> [MealWindow] {
        let calendar = Calendar.current
        let totalCalories = profile.dailyCalorieTarget
        let totalProtein = profile.dailyProteinTarget
        let totalCarbs = profile.dailyCarbTarget
        let totalFat = profile.dailyFatTarget
        
        let breakfast = calendar.date(byAdding: .minute, value: 30, to: wakeTime)!
        
        return [
            // Early breakfast - 20%
            MealWindow(
                startTime: breakfast,
                endTime: calendar.date(byAdding: .hour, value: 1, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 4, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 6, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 9, to: breakfast)!,
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
                endTime: calendar.date(byAdding: .hour, value: 12, to: breakfast)!,
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