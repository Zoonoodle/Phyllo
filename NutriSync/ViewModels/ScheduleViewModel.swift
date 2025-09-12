//
//  ScheduleViewModel.swift
//  NutriSync
//
//  Created on 7/31/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel that manages schedule data using the real data provider
@MainActor
class ScheduleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todaysMeals: [LoggedMeal] = []
    @Published var mealWindows: [MealWindow] = []
    @Published var analyzingMeals: [AnalyzingMeal] = []
    @Published var morningCheckIn: MorningCheckInData?
    @Published var userProfile: UserProfile = UserProfile.defaultProfile
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Redistribution nudge properties
    @Published var pendingRedistribution: RedistributionResult?
    @Published var showingRedistributionNudge = false
    
    // Computed property for compatibility with DayNavigationHeader
    var meals: [LoggedMeal] {
        todaysMeals
    }
    
    // Dynamic timeline hours based on user profile
    var timelineHours: [Int] {
        // Start with user's typical schedule if available
        let bufferBefore = 1 // hour before first window
        let bufferAfter = 2 // 2 hours after last window for scroll spacing
        // CRITICAL: Use local calendar with proper timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // First, check morning check-in wake time and planned bedtime
        var earliestHour: Int? = nil
        var latestHour: Int? = nil
        var crossesMidnight = false
        
        if let checkIn = morningCheckIn {
            let wakeHour = calendar.component(.hour, from: checkIn.wakeTime)
            let bedHour = calendar.component(.hour, from: checkIn.plannedBedtime)
            
            // Always show at least 1 hour before wake time
            earliestHour = max(0, wakeHour - bufferBefore)
            
            // Check if this is a night shift schedule (bedtime before wake time numerically)
            // e.g., wake at 8 PM (20), bed at 2 AM (2)
            if bedHour < wakeHour - 12 {
                // This crosses midnight - extend to next day
                crossesMidnight = true
                latestHour = min(23, 23) // Show until 11 PM, then we'll add early morning hours
                Task { @MainActor in
                    DebugLogger.shared.info("🌙 Night shift detected: Wake \(wakeHour):00, Bed \(bedHour):00 (next day)")
                }
            } else {
                latestHour = min(23, bedHour + bufferAfter)
            }
        }
        
        // Check meal windows to ensure all are visible
        var windowEarliestHour: Int? = nil
        var windowLatestHour: Int? = nil
        if !mealWindows.isEmpty {
            let windowStartHours = mealWindows.map { calendar.component(.hour, from: $0.startTime) }
            
            // For end hours, we need to account for minutes and round up
            let windowEndHoursWithMinutes = mealWindows.map { window -> Int in
                let hour = calendar.component(.hour, from: window.endTime)
                let minute = calendar.component(.minute, from: window.endTime)
                // If there are any minutes past the hour, we need to include the next hour
                return minute > 0 ? hour + 1 : hour
            }
            
            if let minStartHour = windowStartHours.min() {
                windowEarliestHour = max(0, minStartHour - bufferBefore)
            }
            if let maxEndHour = windowEndHoursWithMinutes.max() {
                // Use 2-hour buffer after last window for scroll spacing
                windowLatestHour = min(23, maxEndHour + bufferAfter)
            }
        }
        
        // Check for explicitly set meal hours
        if let firstMeal = userProfile.earliestMealHour,
           let lastMeal = userProfile.latestMealHour {
            var startHour = max(0, firstMeal - bufferBefore)
            var endHour = min(23, lastMeal + bufferAfter)
            
            // Ensure we include wake time if available
            if let earliestFromWake = earliestHour {
                startHour = min(startHour, earliestFromWake)
            }
            
            // Ensure we include all meal windows
            if let windowStart = windowEarliestHour {
                startHour = min(startHour, windowStart)
            }
            if let windowEnd = windowLatestHour {
                endHour = max(endHour, windowEnd)
            }
            
            // But respect planned bedtime if available
            if let latestFromBedtime = latestHour {
                endHour = min(endHour, latestFromBedtime)
            }
            
            return Array(startHour...endHour)
        }
        
        // Calculate range based on actual data, not arbitrary defaults
        var startHour: Int
        var endHour: Int
        
        // Prioritize actual window times if available
        if let windowStart = windowEarliestHour, let windowEnd = windowLatestHour {
            startHour = windowStart
            endHour = windowEnd
            
            // Include wake time if earlier than windows
            if let earliestFromWake = earliestHour {
                startHour = min(startHour, earliestFromWake)
            }
        }
        // Fall back to wake time if no windows
        else if let earliestFromWake = earliestHour {
            startHour = earliestFromWake
            // Use planned bedtime if available, otherwise default to 16 hours from wake
            if let latestFromBedtime = latestHour {
                endHour = latestFromBedtime
            } else {
                endHour = min(23, earliestFromWake + 16) // Show 16 hours from wake
            }
        }
        // Last resort: use work schedule defaults
        else {
            let (defaultEarliest, defaultLatest) = userProfile.workSchedule.defaultMealHours
            startHour = defaultEarliest
            endHour = defaultLatest
        }
        
        // Analyze meal history to find patterns
        if !todaysMeals.isEmpty {
            let mealHours = todaysMeals.map { calendar.component(.hour, from: $0.timestamp) }
            if let minHour = mealHours.min(),
               let maxHour = mealHours.max() {
                startHour = min(startHour, max(0, minHour - bufferBefore))
                endHour = max(endHour, min(23, maxHour + bufferAfter))
            }
        }
        
        // Ensure valid range
        startHour = max(0, startHour)
        endHour = min(23, endHour)
        
        // Handle schedules that cross midnight (night shift workers)
        // If we detected crossing midnight OR if windows extend past midnight
        if crossesMidnight || windowsCrossMidnight() {
            // For schedules crossing midnight, show from wake time through next morning
            if let checkIn = morningCheckIn {
                let bedHour = calendar.component(.hour, from: checkIn.plannedBedtime)
                // Return hours from wake time to 23, then 0 to bedtime
                // e.g., wake at 20 (8 PM), bed at 2 (2 AM) = [19,20,21,22,23,0,1,2,3]
                var hours: [Int] = Array(startHour...23)
                hours.append(contentsOf: Array(0...(bedHour + bufferAfter)))
                Task { @MainActor in
                    DebugLogger.shared.info("🌙 Timeline spans midnight: \(hours)")
                }
                return hours
            }
        }
        
        // Ensure we have a minimum reasonable range
        // If the range is too small or invalid, show a default day view
        if endHour <= startHour {
            DebugLogger.shared.warning("Timeline hours invalid range: \(startHour) to \(endHour), using default")
            return Array(5...22) // Default: 5 AM to 10 PM
        }
        
        // Debug final hour range calculation
        let result = Array(startHour...endHour)
        if !mealWindows.isEmpty && !hasLoggedTimelineDebug {
            hasLoggedTimelineDebug = true
            Task { @MainActor in
                DebugLogger.shared.error("🔍 FINAL TIMELINE HOURS")
                DebugLogger.shared.error("  Hours array: \(result)")
                DebugLogger.shared.error("  Range: \(startHour) to \(endHour)")
                if let first = mealWindows.first {
                    let firstHour = calendar.component(.hour, from: first.startTime)
                    DebugLogger.shared.error("  First window at hour: \(firstHour)")
                    DebugLogger.shared.error("  Should appear at position: \(firstHour - startHour) in array")
                }
            }
        }
        
        // If we have no windows and no meals, show the full day range based on wake time
        if mealWindows.isEmpty && todaysMeals.isEmpty {
            // If we have a morning check-in with wake time, use that
            if let checkIn = morningCheckIn {
                let wakeHour = calendar.component(.hour, from: checkIn.wakeTime)
                startHour = max(0, wakeHour - 1) // Show 1 hour before wake
                endHour = min(23, wakeHour + 15) // Show 15 hours after wake (typical day)
            } else {
                // No check-in, show a reasonable full day view
                startHour = 6  // 6 AM
                endHour = 22   // 10 PM
            }
        }
        
        // Debug logging removed - was causing infinite loops
        
        return Array(startHour...endHour)
    }
    
    // Helper to check if any windows cross midnight
    private func windowsCrossMidnight() -> Bool {
        for window in mealWindows {
            let calendar = Calendar.current
            let startDay = calendar.component(.day, from: window.startTime)
            let endDay = calendar.component(.day, from: window.endTime)
            if endDay != startDay {
                return true
            }
        }
        return false
    }
    
    // MARK: - Dependencies
    private let dataProvider = DataSourceProvider.shared.provider
    private let timeProvider = TimeProvider.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var observations: [ObservationToken] = []
    private var hasLoggedTimelineDebug = false
    
    // MARK: - Initialization
    init() {
        setupObservations()
        setupNotificationObservers()
        Task {
            await loadInitialData()
        }
    }
    
    deinit {
        // Clean up observations
        observations.forEach { _ in } // Tokens clean up in their deinit
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Listen for clear all data notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearAllData),
            name: .clearAllDataNotification,
            object: nil
        )
        
        // Listen for app data refresh notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDataRefresh),
            name: .appDataRefreshed,
            object: nil
        )
    }
    
    @objc private func handleClearAllData() {
        // Clear all in-memory data
        morningCheckIn = nil
        mealWindows.removeAll()
        todaysMeals.removeAll()
        analyzingMeals.removeAll()
        
        DebugLogger.shared.success("ScheduleViewModel: Cleared all in-memory data")
    }
    
    @objc private func handleAppDataRefresh() {
        // Refresh all data when app comes back from background
        Task {
            DebugLogger.shared.info("ScheduleViewModel: Refreshing data after app became active")
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    private func setupObservations() {
        // Use a computed property to always get current date
        let today = timeProvider.currentTime
        
        // Observe meals
        let mealsToken = dataProvider.observeMeals(for: today) { [weak self] meals in
            Task { @MainActor in
                self?.todaysMeals = meals
            }
        }
        observations.append(mealsToken)
        
        // Observe windows
        let windowsToken = dataProvider.observeWindows(for: today) { [weak self] windows in
            Task { @MainActor in
                guard let self = self else { return }
                
                var adjustedWindows = windows
                
                // Fix windows that are too far in the future (likely generated for wrong day)
                // If first window is more than 18 hours away, subtract 24 hours from all windows
                let now = self.timeProvider.currentTime
                if let firstWindow = adjustedWindows.sorted(by: { $0.startTime < $1.startTime }).first {
                    let timeUntilFirstWindow = firstWindow.startTime.timeIntervalSince(now)
                    
                    // If first window is more than 18 hours away, it's likely for tomorrow
                    // Adjust all windows back by 24 hours
                    if timeUntilFirstWindow > 18 * 3600 {
                        DebugLogger.shared.warning("Observed windows appear to be for tomorrow (first window in \(Int(timeUntilFirstWindow/3600))h). Adjusting by -24 hours.")
                        
                        adjustedWindows = adjustedWindows.map { window in
                            // Create new window with adjusted times since they are let constants
                            MealWindow(
                                id: window.id,
                                startTime: window.startTime.addingTimeInterval(-24 * 3600),
                                endTime: window.endTime.addingTimeInterval(-24 * 3600),
                                targetCalories: window.targetCalories,
                                targetMacros: window.targetMacros,
                                purpose: window.purpose,
                                flexibility: window.flexibility,
                                dayDate: window.dayDate.addingTimeInterval(-24 * 3600),
                                name: window.name,
                                rationale: window.rationale,
                                foodSuggestions: window.foodSuggestions,
                                micronutrientFocus: window.micronutrientFocus,
                                tips: window.tips,
                                type: window.type.rawValue,
                                adjustedCalories: window.adjustedCalories,
                                adjustedMacros: window.adjustedMacros,
                                redistributionReason: window.redistributionReason,
                                isMarkedAsFasted: window.isMarkedAsFasted
                            )
                        }
                        
                        // Save the adjusted windows back to Firebase
                        Task {
                            for window in adjustedWindows {
                                try? await self.dataProvider.updateWindow(window)
                            }
                            DebugLogger.shared.success("Adjusted all \(adjustedWindows.count) observed windows to correct day")
                        }
                    }
                }
                
                self.mealWindows = adjustedWindows
                // Schedule notifications when windows change
                await self.notificationManager.scheduleWindowNotifications(for: adjustedWindows)
            }
        }
        observations.append(windowsToken)
        
        // Observe analyzing meals
        let analyzingToken = dataProvider.observeAnalyzingMeals { [weak self] meals in
            Task { @MainActor in
                self?.analyzingMeals = meals
            }
        }
        observations.append(analyzingToken)
    }
    
    private func loadInitialData() async {
        isLoading = true
        
        do {
            // Use current time from TimeProvider for consistency
            let today = timeProvider.currentTime
            
            // Load user profile
            if let profile = try await dataProvider.getUserProfile() {
                self.userProfile = profile
            }
            
            // Load meals
            todaysMeals = try await dataProvider.getMeals(for: today)
            
            Task { @MainActor in
                DebugLogger.shared.dataProvider("Loaded \(todaysMeals.count) meals for today")
                for meal in todaysMeals {
                    DebugLogger.shared.logMeal(meal, action: "Loaded from Firebase")
                }
            }
            
            // Load windows
            var loadedWindows = try await dataProvider.getWindows(for: today)
            
            // Fix windows that are too far in the future (likely generated for wrong day)
            // If first window is more than 18 hours away, subtract 24 hours from all windows
            let now = timeProvider.currentTime
            if let firstWindow = loadedWindows.sorted(by: { $0.startTime < $1.startTime }).first {
                let timeUntilFirstWindow = firstWindow.startTime.timeIntervalSince(now)
                
                // If first window is more than 18 hours away, it's likely for tomorrow
                // Adjust all windows back by 24 hours
                if timeUntilFirstWindow > 18 * 3600 {
                    Task { @MainActor in
                        DebugLogger.shared.warning("Windows appear to be for tomorrow (first window in \(Int(timeUntilFirstWindow/3600))h). Adjusting by -24 hours.")
                    }
                    
                    loadedWindows = loadedWindows.map { window in
                        // Create new window with adjusted times since they are let constants
                        MealWindow(
                            id: window.id,
                            startTime: window.startTime.addingTimeInterval(-24 * 3600),
                            endTime: window.endTime.addingTimeInterval(-24 * 3600),
                            targetCalories: window.targetCalories,
                            targetMacros: window.targetMacros,
                            purpose: window.purpose,
                            flexibility: window.flexibility,
                            dayDate: window.dayDate.addingTimeInterval(-24 * 3600),
                            name: window.name,
                            rationale: window.rationale,
                            foodSuggestions: window.foodSuggestions,
                            micronutrientFocus: window.micronutrientFocus,
                            tips: window.tips,
                            type: window.type.rawValue,
                            adjustedCalories: window.adjustedCalories,
                            adjustedMacros: window.adjustedMacros,
                            redistributionReason: window.redistributionReason,
                            isMarkedAsFasted: window.isMarkedAsFasted
                        )
                    }
                    
                    // Save the adjusted windows back to Firebase
                    for window in loadedWindows {
                        try await dataProvider.updateWindow(window)
                    }
                    
                    Task { @MainActor in
                        DebugLogger.shared.success("Adjusted all \(loadedWindows.count) windows to correct day")
                    }
                }
            }
            
            mealWindows = loadedWindows
            
            Task { @MainActor in
                DebugLogger.shared.dataProvider("Loaded \(mealWindows.count) windows for today")
            }
            
            // Load analyzing meals
            analyzingMeals = try await dataProvider.getAnalyzingMeals()
            
            // Load morning check-in
            morningCheckIn = try await dataProvider.getMorningCheckIn(for: today)
            
            // Generate windows only if none exist AND morning check-in is completed
            if mealWindows.isEmpty {
                // Check if windows exist in Firebase but aren't loaded yet
                let existingWindows = try await dataProvider.getWindows(for: today)
                if !existingWindows.isEmpty {
                    mealWindows = existingWindows
                    Task { @MainActor in
                        DebugLogger.shared.info("Loaded \(existingWindows.count) existing windows from Firebase")
                        let hasAIContent = existingWindows.contains { !$0.name.isEmpty || !$0.foodSuggestions.isEmpty }
                        if hasAIContent {
                            DebugLogger.shared.success("Windows contain AI-generated content")
                        }
                    }
                } else if let checkIn = morningCheckIn {
                    // Only generate if check-in is from TODAY
                    let calendar = Calendar.current
                    if calendar.isDateInToday(checkIn.date) {
                        Task { @MainActor in
                            DebugLogger.shared.warning("No windows found for today, generating windows based on TODAY's check-in")
                        }
                        await generateDailyWindows()
                    } else {
                        Task { @MainActor in
                            DebugLogger.shared.info("No windows generated - check-in is from a previous day (\(checkIn.date))")
                            DebugLogger.shared.info("Waiting for TODAY's morning check-in before generating windows")
                        }
                    }
                } else {
                    Task { @MainActor in
                        DebugLogger.shared.info("No windows generated - waiting for morning check-in")
                    }
                }
            }
            
            // Set loading to false only after all operations complete
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to load schedule data: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Get meals for a specific meal window
    func mealsInWindow(_ window: MealWindow) -> [LoggedMeal] {
        todaysMeals.filter { meal in
            if let windowId = meal.windowId {
                return windowId == window.id
            }
            // Fallback to time-based check
            return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
    
    /// Get analyzing meals for a specific window
    func analyzingMealsInWindow(_ window: MealWindow) -> [AnalyzingMeal] {
        analyzingMeals.filter { meal in
            meal.windowId == window.id
        }
    }
    
    /// Complete morning check-in
    func completeMorningCheckIn(_ checkIn: MorningCheckInData) async {
        do {
            // Save check-in
            Task { @MainActor in
                DebugLogger.shared.info("Saving morning check-in data...")
            }
            try await dataProvider.saveMorningCheckIn(checkIn)
            morningCheckIn = checkIn
            Task { @MainActor in
                DebugLogger.shared.success("Morning check-in saved successfully")
            }
            
            // Only generate windows if none exist (don't overwrite AI windows)
            if mealWindows.isEmpty {
                Task { @MainActor in
                    DebugLogger.shared.info("No windows exist after check-in, generating new windows")
                }
                await generateDailyWindows()
            } else {
                Task { @MainActor in
                    DebugLogger.shared.info("Windows already exist (\(mealWindows.count)). Preserving existing schedule.")
                    let hasAIContent = mealWindows.contains { !$0.name.isEmpty || !$0.foodSuggestions.isEmpty }
                    if hasAIContent {
                        DebugLogger.shared.success("Preserving AI-generated windows with rich content")
                    }
                }
            }
            
            // Optional redistribution after generation using current meals
            await redistributeWindows()
            
        } catch {
            errorMessage = "Failed to save check-in: \(error.localizedDescription)"
            Task { @MainActor in
                DebugLogger.shared.error("Failed to save morning check-in: \(error)")
                // Log specific Firestore error for debugging
                if error.localizedDescription.contains("Missing or insufficient permissions") {
                    DebugLogger.shared.error("⚠️ Firestore permission denied! Please deploy the development rules using:")
                    DebugLogger.shared.error("firebase deploy --only firestore:rules")
                    DebugLogger.shared.error("Or update rules in Firebase Console")
                }
            }
        }
    }
    
    /// Generate daily windows
    func generateDailyWindows() async {
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Starting window generation")
        }
        
        do {
            let profile = try await dataProvider.getUserProfile() ?? UserProfile.defaultProfile
            self.userProfile = profile
            
            Task { @MainActor in
                DebugLogger.shared.dataProvider("Using profile: \(profile.primaryGoal.displayName)")
            }
            
            let windows = try await dataProvider.generateDailyWindows(
                for: timeProvider.currentTime,
                profile: profile,
                checkIn: morningCheckIn
            )
            
            Task { @MainActor in
                DebugLogger.shared.success("Generated \(windows.count) windows")
                for window in windows {
                    DebugLogger.shared.logWindow(window, action: "Generated")
                }
            }
            
            self.mealWindows = windows
            
            // Schedule notifications for the new windows
            Task {
                await notificationManager.scheduleWindowNotifications(for: windows)
                await notificationManager.scheduleMorningCheckInReminder(for: Date().addingTimeInterval(86400)) // Tomorrow
            }
        } catch {
            // Handle AI generation requirement
            if (error as NSError).code == 1001 {
                errorMessage = "AI window generation required. Please ensure windows are created through the AI service."
                Task { @MainActor in
                    DebugLogger.shared.error("⚠️ AI WINDOW GENERATION REQUIRED - No fallback available")
                    DebugLogger.shared.warning("Windows must be generated through AI service with food suggestions and micronutrient focus")
                }
            } else {
                errorMessage = "Failed to generate windows: \(error.localizedDescription)"
                if error.localizedDescription.contains("Missing or insufficient permissions") {
                    Task { @MainActor in
                        DebugLogger.shared.error("⚠️ Firestore permission error during window generation!")
                        DebugLogger.shared.error("Deploy rules: firebase deploy --only firestore:rules")
                    }
                }
            }
            DebugLogger.shared.error("Failed to generate windows: \(error)")
            Task { @MainActor in
                DebugLogger.shared.error("Window generation failed: \(error)")
            }
        }
    }
    
    /// Redistribute windows based on current time and meals
    func redistributeWindows() async {
        do {
            try await dataProvider.redistributeWindows(for: Date())
            // Windows will update via observation
        } catch {
            errorMessage = "Failed to redistribute windows: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to redistribute windows: \(error)")
        }
    }
    
    /// Delete a meal
    func deleteMeal(_ meal: LoggedMeal) async {
        do {
            try await dataProvider.deleteMeal(id: meal.id.uuidString)
            // Meals will update via observation
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to delete meal: \(error)")
        }
    }
    
    /// Get total nutrition for the day
    var totalNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        todaysMeals.reduce((0, 0, 0, 0)) { result, meal in
            (result.0 + meal.calories,
             result.1 + meal.protein,
             result.2 + meal.carbs,
             result.3 + meal.fat)
        }
    }
    
    /// Get micronutrient totals for the day
    var micronutrientTotals: [String: Double] {
        var totals: [String: Double] = [:]
        
        for meal in todaysMeals {
            for (name, amount) in meal.micronutrients {
                totals[name, default: 0] += amount
            }
        }
        
        return totals
    }
    
    // MARK: - Window Status Helpers
    
    /// Get the currently active window
    var activeWindow: MealWindow? {
        let now = TimeProvider.shared.currentTime
        return mealWindows.first { window in
            now >= window.startTime && now <= window.endTime
        }
    }
    
    /// Get upcoming windows
    var upcomingWindows: [MealWindow] {
        let now = TimeProvider.shared.currentTime
        return mealWindows.filter { $0.startTime > now }
    }
    
    /// Get past windows
    var pastWindows: [MealWindow] {
        let now = TimeProvider.shared.currentTime
        return mealWindows.filter { $0.endTime < now }
    }
}

// MARK: - Helper Extensions

extension ScheduleViewModel {
    /// Check if a meal is assigned to its window properly
    func isMealInCorrectWindow(_ meal: LoggedMeal) -> Bool {
        guard let windowId = meal.windowId,
              let window = mealWindows.first(where: { $0.id == windowId }) else {
            return false
        }
        
        return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
    }
    
    /// Find the nearest window for a meal timestamp
    func nearestWindow(for timestamp: Date) -> MealWindow? {
        var nearestWindow: MealWindow?
        var minDistance = TimeInterval.greatestFiniteMagnitude
        
        for window in mealWindows {
            let distance: TimeInterval
            
            if timestamp >= window.startTime && timestamp <= window.endTime {
                // Meal is within window
                return window
            } else if timestamp < window.startTime {
                // Meal is before window
                distance = window.startTime.timeIntervalSince(timestamp)
            } else {
                // Meal is after window
                distance = timestamp.timeIntervalSince(window.endTime)
            }
            
            if distance < minDistance {
                minDistance = distance
                nearestWindow = window
            }
        }
        
        return nearestWindow
    }
    
    /// Get calories consumed in a specific window
    func caloriesConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.calories }
    }
    
    /// Get protein consumed in a specific window
    func proteinConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.protein }
    }
    
    /// Get carbs consumed in a specific window
    func carbsConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.carbs }
    }
    
    /// Get fat consumed in a specific window
    func fatConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.fat }
    }
    
    // MARK: - Missed Meals Handling
    
    /// Get windows that have been missed (past windows with no meals)
    var missedWindows: [MealWindow] {
        pastWindows.filter { window in
            mealsInWindow(window).isEmpty && !window.isMarkedAsFasted
        }
    }
    
    /// Check if user needs missed meals recovery
    var needsMissedMealsRecovery: Bool {
        missedWindows.count >= 2
    }
    
    /// Mark windows as intentionally fasted
    func markWindowsAsFasted(_ windows: [MealWindow]) {
        Task {
            for window in windows {
                var updatedWindow = window
                updatedWindow.isMarkedAsFasted = true
                // Update in database
                do {
                    try await dataProvider.updateWindow(updatedWindow)
                } catch {
                    DebugLogger.shared.error("Failed to mark window as fasted: \(error)")
                }
            }
        }
    }
    
    /// Mark a single window as fasted
    func markWindowAsFasted(windowId: UUID) async {
        guard let windowIndex = mealWindows.firstIndex(where: { $0.id == windowId }) else {
            DebugLogger.shared.error("Window not found with id: \(windowId)")
            return
        }
        
        var updatedWindow = mealWindows[windowIndex]
        updatedWindow.isMarkedAsFasted = true
        
        // Update locally first for immediate UI feedback
        await MainActor.run {
            mealWindows[windowIndex] = updatedWindow
        }
        
        // Update in database
        do {
            try await dataProvider.updateWindow(updatedWindow)
            // Windows will update automatically via observation
        } catch {
            DebugLogger.shared.error("Failed to mark window as fasted: \(error)")
            // Revert local change on failure
            await MainActor.run {
                updatedWindow.isMarkedAsFasted = false
                mealWindows[windowIndex] = updatedWindow
            }
        }
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) async {
        do {
            try await dataProvider.saveUserProfile(profile)
            self.userProfile = profile
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to update user profile: \(error)")
        }
    }
    
    /// Process retrospective meals from user description
    func processRetrospectiveMeals(description: String, missedWindows: [MealWindow]) async {
        do {
            // Use the new RetrospectiveMealParser for better AI parsing
            let parsedMeals = try await RetrospectiveMealParser.shared.parseMealsFromDescription(
                description,
                missedWindows: missedWindows
            )
            
            // Save each parsed meal (already has windowId and timestamp assigned)
            for meal in parsedMeals {
                try await dataProvider.saveMeal(meal)
            }
            
            Task { @MainActor in
                DebugLogger.shared.success("Processed \(parsedMeals.count) retrospective meals")
            }
            
        } catch {
            errorMessage = "Failed to process meals: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to process retrospective meals: \(error)")
        }
    }
    
    // MARK: - Redistribution Handling
    
    /// Handle a redistribution proposal from the redistribution manager
    func handleRedistributionProposal(_ result: RedistributionResult) {
        pendingRedistribution = result
        showingRedistributionNudge = true
        
        DebugLogger.shared.info("Showing redistribution nudge for \(result.trigger) with \(result.adjustedWindows.count) windows affected")
    }
    
    /// Apply the pending redistribution
    func applyRedistribution() async {
        guard let redistribution = pendingRedistribution else { 
            DebugLogger.shared.warning("No pending redistribution to apply")
            return 
        }
        
        DebugLogger.shared.info("Applying redistribution: \(redistribution.explanation)")
        
        do {
            if let firebaseProvider = dataProvider as? FirebaseDataProvider {
                // Apply the redistribution through the data provider
                try await firebaseProvider.applyRedistribution(redistribution)
                
                // Update local windows
                // Note: The windows will be refreshed through the observer
                
                DebugLogger.shared.success("Redistribution applied successfully")
            } else {
                DebugLogger.shared.error("Data provider is not FirebaseDataProvider, cannot apply redistribution")
            }
        } catch {
            errorMessage = "Failed to apply redistribution: \(error.localizedDescription)"
            DebugLogger.shared.error("Failed to apply redistribution: \(error)")
        }
        
        // Clear the nudge
        showingRedistributionNudge = false
        pendingRedistribution = nil
    }
    
    /// Reject the pending redistribution
    func rejectRedistribution() {
        guard let redistribution = pendingRedistribution else { 
            DebugLogger.shared.warning("No pending redistribution to reject")
            return 
        }
        
        DebugLogger.shared.info("User rejected redistribution for \(redistribution.trigger)")
        
        // Clear the nudge
        showingRedistributionNudge = false
        pendingRedistribution = nil
        
        // Log the rejection for analytics/learning
        DebugLogger.shared.info("Redistribution rejected: \(redistribution.explanation)")
    }
}

// MARK: - Daily Aggregation
extension ScheduleViewModel {
    
    /// Status of a micronutrient compared to daily recommended values
    enum MicronutrientStatusOld {
        case deficient(percentage: Double, data: (amount: Double, unit: String, recommendation: String))
        case optimal(percentage: Double)
        case excess(percentage: Double, data: (amount: Double, unit: String, recommendation: String))
    }
    
    /// Comprehensive daily nutrition summary
    public struct DailyNutritionSummary {
        public let date: Date
        public let totalCalories: Int
        public let targetCalories: Int
        public let totalProtein: Int
        public let targetProtein: Int
        public let totalFat: Int
        public let targetFat: Int
        public let totalCarbs: Int
        public let targetCarbs: Int
        public let completedWindows: Int
        public let totalWindows: Int
        public let micronutrients: [String: Double]
        public let meals: [LoggedMeal]
        public let windows: [MealWindow]
        public let dayPurpose: DayPurpose?
        
        public init(date: Date, totalCalories: Int, targetCalories: Int, totalProtein: Int, targetProtein: Int, totalFat: Int, targetFat: Int, totalCarbs: Int, targetCarbs: Int, completedWindows: Int, totalWindows: Int, micronutrients: [String: Double], meals: [LoggedMeal], windows: [MealWindow], dayPurpose: DayPurpose?) {
            self.date = date
            self.totalCalories = totalCalories
            self.targetCalories = targetCalories
            self.totalProtein = totalProtein
            self.targetProtein = targetProtein
            self.totalFat = totalFat
            self.targetFat = targetFat
            self.totalCarbs = totalCarbs
            self.targetCarbs = targetCarbs
            self.completedWindows = completedWindows
            self.totalWindows = totalWindows
            self.micronutrients = micronutrients
            self.meals = meals
            self.windows = windows
            self.dayPurpose = dayPurpose
        }
    }
    
    /// Timeline entry for chronological food list
    public struct TimelineEntry {
        public let id: String
        public let timestamp: Date
        public let meal: LoggedMeal
        public let windowName: String
        public let windowColor: Color
        
        public init(id: String? = nil, timestamp: Date, meal: LoggedMeal, windowName: String, windowColor: Color = .phylloAccent) {
            self.id = id ?? UUID().uuidString
            self.timestamp = timestamp
            self.meal = meal
            self.windowName = windowName
            self.windowColor = windowColor
        }
    }
    
    /// Micronutrient status for daily view
    public struct MicronutrientStatus {
        public let name: String
        public let status: Status
        public let percentage: Double
        public let amount: Double
        public let unit: String
        public let recommendation: String?
        
        public init(name: String, status: Status, percentage: Double, amount: Double, unit: String, recommendation: String?) {
            self.name = name
            self.status = status
            self.percentage = percentage
            self.amount = amount
            self.unit = unit
            self.recommendation = recommendation
        }
        
        public enum Status {
            case deficient
            case optimal
            case excess
        }
    }
    
    /// Aggregate all daily nutrition data
    func aggregateDailyNutrition() -> DailyNutritionSummary {
        // Calculate totals from all meals
        let totalCalories = todaysMeals.reduce(0) { $0 + $1.calories }
        let totalProtein = todaysMeals.reduce(0) { $0 + $1.protein }
        let totalFat = todaysMeals.reduce(0) { $0 + $1.fat }
        let totalCarbs = todaysMeals.reduce(0) { $0 + $1.carbs }
        
        // Calculate daily targets from all windows
        let targetCalories = mealWindows.reduce(0) { $0 + $1.effectiveCalories }
        let targetProtein = mealWindows.reduce(0) { $0 + $1.effectiveMacros.protein }
        let targetFat = mealWindows.reduce(0) { $0 + $1.effectiveMacros.fat }
        let targetCarbs = mealWindows.reduce(0) { $0 + $1.effectiveMacros.carbs }
        
        // Count completed windows (windows with at least one meal)
        let completedWindows = mealWindows.filter { window in
            todaysMeals.contains { meal in
                if let windowId = meal.windowId {
                    return windowId == window.id
                } else {
                    return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }
            }
        }.count
        
        // Aggregate micronutrients
        var micronutrients: [String: Double] = [:]
        for meal in todaysMeals {
            for (nutrient, value) in meal.micronutrients {
                micronutrients[nutrient, default: 0] += value
            }
        }
        
        // Get cached day purpose if available
        let dayPurpose: DayPurpose?
        if let firebaseProvider = dataProvider as? FirebaseDataProvider {
            dayPurpose = firebaseProvider.currentDayPurpose
        } else {
            dayPurpose = nil
        }
        
        return DailyNutritionSummary(
            date: timeProvider.currentTime,
            totalCalories: totalCalories,
            targetCalories: targetCalories,
            totalProtein: totalProtein,
            targetProtein: targetProtein,
            totalFat: totalFat,
            targetFat: targetFat,
            totalCarbs: totalCarbs,
            targetCarbs: targetCarbs,
            completedWindows: completedWindows,
            totalWindows: mealWindows.count,
            micronutrients: micronutrients,
            meals: todaysMeals,
            windows: mealWindows,
            dayPurpose: dayPurpose
        )
    }
    
    /// Calculate micronutrient status compared to daily recommendations
    func calculateMicronutrientStatus() -> [MicronutrientStatus] {
        let summary = aggregateDailyNutrition()
        var statuses: [MicronutrientStatus] = []
        
        // Daily recommended values with units (simplified - should be personalized)
        let dailyRecommendations: [String: (value: Double, unit: String)] = [
            "Vitamin A": (900, "mcg"),
            "Vitamin C": (90, "mg"),
            "Vitamin D": (20, "mcg"),
            "Vitamin E": (15, "mg"),
            "Vitamin K": (120, "mcg"),
            "Thiamin": (1.2, "mg"),
            "Riboflavin": (1.3, "mg"),
            "Niacin": (16, "mg"),
            "Vitamin B6": (1.7, "mg"),
            "Folate": (400, "mcg"),
            "Vitamin B12": (2.4, "mcg"),
            "Calcium": (1000, "mg"),
            "Iron": (8, "mg"),
            "Magnesium": (400, "mg"),
            "Phosphorus": (700, "mg"),
            "Potassium": (2600, "mg"),
            "Sodium": (2300, "mg"),
            "Zinc": (11, "mg"),
            "Fiber": (28, "g")
        ]
        
        for (nutrient, rec) in dailyRecommendations {
            let consumed = summary.micronutrients[nutrient] ?? 0
            let percentage = (consumed / rec.value) * 100
            
            let status: MicronutrientStatus.Status
            let recommendation: String?
            
            if percentage < 80 {
                status = .deficient
                recommendation = "Increase intake of \(nutrient)-rich foods"
            } else if percentage > 150 {
                status = .excess
                recommendation = nutrient == "Sodium" ? "Reduce sodium intake" : "Monitor \(nutrient) intake"
            } else {
                status = .optimal
                recommendation = nil
            }
            
            // Only include deficient or excess nutrients
            if status != .optimal {
                statuses.append(MicronutrientStatus(
                    name: nutrient,
                    status: status,
                    percentage: percentage,
                    amount: consumed,
                    unit: rec.unit,
                    recommendation: recommendation
                ))
            }
        }
        
        // Sort by severity (furthest from 100%)
        statuses.sort { first, second in
            // Use the percentage property directly from MicronutrientStatus
            return abs(first.percentage - 100) > abs(second.percentage - 100)
        }
        
        // Return max 8 nutrients
        return Array(statuses.prefix(8))
    }
    
    /// Get chronological timeline of all foods logged today
    func getDailyFoodTimeline() -> [TimelineEntry] {
        var timeline: [TimelineEntry] = []
        
        for meal in todaysMeals.sorted(by: { $0.timestamp < $1.timestamp }) {
            // Find which window this meal belongs to
            let window = mealWindows.first { window in
                if let windowId = meal.windowId {
                    return windowId == window.id
                } else {
                    return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }
            }
            
            timeline.append(TimelineEntry(
                id: meal.id.uuidString,
                timestamp: meal.timestamp,
                meal: meal,
                windowName: window?.name ?? "Unassigned",
                windowColor: window?.purpose.color ?? .gray
            ))
        }
        
        return timeline
    }
}