//
//  MealPatternAnalyzer.swift
//  Phyllo
//
//  Created on 8/12/25.
//

import Foundation

/// Service for analyzing meal patterns and updating user schedule preferences
@MainActor
class MealPatternAnalyzer {
    static let shared = MealPatternAnalyzer()
    private let dataProvider = DataSourceProvider.shared.provider
    
    private init() {}
    
    /// Analyze the last 30 days of meals to detect typical eating hours
    func analyzeMealPatterns(for userId: String) async throws -> (earliest: Int, latest: Int)? {
        DebugLogger.shared.dataProvider("Analyzing meal patterns for user")
        
        // Get meals from the last 30 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        var allMealHours: [Int] = []
        
        // Fetch meals for each day (this would be more efficient with a batch query in production)
        for dayOffset in 0..<30 {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            
            do {
                let meals = try await dataProvider.getMeals(for: date)
                let mealHours = meals.map { Calendar.current.component(.hour, from: $0.timestamp) }
                allMealHours.append(contentsOf: mealHours)
            } catch {
                // Continue if a day fails
                DebugLogger.shared.warning("Failed to fetch meals for \(date): \(error)")
            }
        }
        
        // Need at least 20 meals to establish a pattern
        guard allMealHours.count >= 20 else {
            DebugLogger.shared.info("Not enough meal data to establish pattern (found \(allMealHours.count) meals)")
            return nil
        }
        
        // Find the 10th percentile and 90th percentile to avoid outliers
        let sortedHours = allMealHours.sorted()
        let tenthPercentileIndex = Int(Double(sortedHours.count) * 0.1)
        let ninetiethPercentileIndex = Int(Double(sortedHours.count) * 0.9)
        
        let earliestTypical = sortedHours[tenthPercentileIndex]
        let latestTypical = sortedHours[ninetiethPercentileIndex]
        
        DebugLogger.shared.success("Detected meal pattern: \(earliestTypical) - \(latestTypical) from \(allMealHours.count) meals")
        
        return (earliest: earliestTypical, latest: latestTypical)
    }
    
    /// Update user profile with detected meal patterns
    func updateUserMealHours(profile: UserProfile) async throws {
        guard let patterns = try await analyzeMealPatterns(for: profile.id.uuidString) else {
            return
        }
        
        var updatedProfile = profile
        updatedProfile.earliestMealHour = patterns.earliest
        updatedProfile.latestMealHour = patterns.latest
        
        try await dataProvider.saveUserProfile(updatedProfile)
        
        DebugLogger.shared.success("Updated user meal hours: \(patterns.earliest) - \(patterns.latest)")
    }
    
    /// Detect if user appears to be following a fasting protocol
    func detectFastingPattern(for userId: String) async throws -> FastingProtocol? {
        guard let patterns = try await analyzeMealPatterns(for: userId) else {
            return nil
        }
        
        let eatingWindowHours = patterns.latest - patterns.earliest
        
        // Match to common fasting protocols
        switch eatingWindowHours {
        case 0...4:
            return .omad
        case 5...6:
            return .twenty4
        case 7...8:
            return .sixteen8
        case 9...10:
            return .eighteen6
        default:
            return FastingProtocol.none
        }
    }
    
    /// Check if user's schedule suggests shift work
    func detectShiftWork(profile: UserProfile, meals: [LoggedMeal]) -> WorkSchedule {
        // Count meals by hour of day over the period
        var mealsByHour = [Int: Int]()
        
        for meal in meals {
            let hour = Calendar.current.component(.hour, from: meal.timestamp)
            mealsByHour[hour, default: 0] += 1
        }
        
        // Check for night shift pattern (eating between 10PM - 6AM)
        let nightMeals = (22...23).reduce(0) { $0 + (mealsByHour[$1] ?? 0) } +
                        (0...6).reduce(0) { $0 + (mealsByHour[$1] ?? 0) }
        let totalMeals = meals.count
        
        if Double(nightMeals) / Double(totalMeals) > 0.3 {
            return .nightShift
        }
        
        // Check for highly variable schedule
        if let earliest = mealsByHour.keys.min(),
           let latest = mealsByHour.keys.max(),
           latest - earliest > 18 {
            return .flexible
        }
        
        return profile.workSchedule
    }
}