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
    
    // Computed property for compatibility with DayNavigationHeader
    var meals: [LoggedMeal] {
        todaysMeals
    }
    
    // Dynamic timeline hours based on user profile
    var timelineHours: [Int] {
        // Start with user's typical schedule if available
        let buffer = 1 // hour before/after
        // CRITICAL: Use local calendar with proper timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // First, check morning check-in wake time and planned bedtime
        var earliestHour: Int? = nil
        var latestHour: Int? = nil
        if let checkIn = morningCheckIn {
            let wakeHour = calendar.component(.hour, from: checkIn.wakeTime)
            // Always show at least 1 hour before wake time
            earliestHour = max(0, wakeHour - buffer)
            
            // Use planned bedtime if available
            let bedHour = calendar.component(.hour, from: checkIn.plannedBedtime)
            latestHour = min(23, bedHour)
        }
        
        // Check meal windows to ensure all are visible
        var windowEarliestHour: Int? = nil
        var windowLatestHour: Int? = nil
        if !mealWindows.isEmpty {
            let windowStartHours = mealWindows.map { calendar.component(.hour, from: $0.startTime) }
            let windowEndHours = mealWindows.map { calendar.component(.hour, from: $0.endTime) }
            
            if let minStartHour = windowStartHours.min() {
                windowEarliestHour = max(0, minStartHour - buffer)
            }
            if let maxEndHour = windowEndHours.max() {
                windowLatestHour = min(23, maxEndHour + buffer)
            }
        }
        
        // Check for explicitly set meal hours
        if let firstMeal = userProfile.earliestMealHour,
           let lastMeal = userProfile.latestMealHour {
            var startHour = max(0, firstMeal - buffer)
            var endHour = min(23, lastMeal + buffer)
            
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
                startHour = min(startHour, max(0, minHour - buffer))
                endHour = max(endHour, min(23, maxHour + buffer))
            }
        }
        
        // Ensure valid range
        startHour = max(0, startHour)
        endHour = min(23, endHour)
        
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
    }
    
    @objc private func handleClearAllData() {
        // Clear all in-memory data
        morningCheckIn = nil
        mealWindows.removeAll()
        todaysMeals.removeAll()
        analyzingMeals.removeAll()
        
        DebugLogger.shared.success("ScheduleViewModel: Cleared all in-memory data")
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
            try await dataProvider.saveMorningCheckIn(checkIn)
            morningCheckIn = checkIn
            
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
            DebugLogger.shared.error("Failed to save morning check-in: \(error)")
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
}

// MARK: - Daily Aggregation
extension ScheduleViewModel {
    
    /// Status of a micronutrient compared to daily recommended values
    enum MicronutrientStatus {
        case deficient(percentage: Double, recommendation: String)
        case optimal(percentage: Double)
        case excess(percentage: Double, recommendation: String)
        
        var name: String {
            switch self {
            case .deficient(_, _): return "deficient"
            case .optimal(_): return "optimal"
            case .excess(_, _): return "excess"
            }
        }
    }
    
    /// Comprehensive daily nutrition summary
    struct DailyNutritionSummary {
        let date: Date
        let totalCalories: Int
        let totalProtein: Int
        let totalFat: Int
        let totalCarbs: Int
        let micronutrients: [String: Double]
        let meals: [LoggedMeal]
        let windows: [MealWindow]
        let dayPurpose: DayPurpose?
    }
    
    /// Timeline entry for chronological food list
    struct TimelineEntry {
        let timestamp: Date
        let meal: LoggedMeal
        let windowName: String?
    }
    
    /// Aggregate all daily nutrition data
    func aggregateDailyNutrition() -> DailyNutritionSummary {
        // Calculate totals from all meals
        let totalCalories = todaysMeals.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = todaysMeals.reduce(0) { $0 + $1.totalProtein }
        let totalFat = todaysMeals.reduce(0) { $0 + $1.totalFat }
        let totalCarbs = todaysMeals.reduce(0) { $0 + $1.totalCarbs }
        
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
            totalProtein: totalProtein,
            totalFat: totalFat,
            totalCarbs: totalCarbs,
            micronutrients: micronutrients,
            meals: todaysMeals,
            windows: mealWindows,
            dayPurpose: dayPurpose
        )
    }
    
    /// Calculate micronutrient status compared to daily recommendations
    func calculateMicronutrientStatus() -> [(nutrient: String, status: MicronutrientStatus)] {
        let summary = aggregateDailyNutrition()
        var statuses: [(nutrient: String, status: MicronutrientStatus)] = []
        
        // Daily recommended values (simplified - should be personalized)
        let dailyRecommendations: [String: Double] = [
            "Vitamin A": 900,  // mcg
            "Vitamin C": 90,   // mg
            "Vitamin D": 20,   // mcg
            "Vitamin E": 15,   // mg
            "Vitamin K": 120,  // mcg
            "Thiamin": 1.2,    // mg
            "Riboflavin": 1.3, // mg
            "Niacin": 16,      // mg
            "Vitamin B6": 1.7, // mg
            "Folate": 400,     // mcg
            "Vitamin B12": 2.4,// mcg
            "Calcium": 1000,   // mg
            "Iron": 8,         // mg
            "Magnesium": 400,  // mg
            "Phosphorus": 700, // mg
            "Potassium": 2600, // mg
            "Sodium": 2300,    // mg (max)
            "Zinc": 11,        // mg
            "Fiber": 28        // g
        ]
        
        for (nutrient, recommended) in dailyRecommendations {
            let consumed = summary.micronutrients[nutrient] ?? 0
            let percentage = (consumed / recommended) * 100
            
            let status: MicronutrientStatus
            if percentage < 80 {
                let recommendation = "Increase intake of \(nutrient)-rich foods"
                status = .deficient(percentage: percentage, recommendation: recommendation)
            } else if percentage > 150 {
                let recommendation = nutrient == "Sodium" ? "Reduce sodium intake" : "Monitor \(nutrient) intake"
                status = .excess(percentage: percentage, recommendation: recommendation)
            } else {
                status = .optimal(percentage: percentage)
            }
            
            // Only include deficient or excess nutrients
            if case .deficient = status {
                statuses.append((nutrient: nutrient, status: status))
            } else if case .excess = status {
                statuses.append((nutrient: nutrient, status: status))
            }
        }
        
        // Sort by severity (furthest from 100%)
        statuses.sort { first, second in
            let firstPercentage: Double
            let secondPercentage: Double
            
            switch first.status {
            case .deficient(let p, _), .optimal(let p), .excess(let p, _):
                firstPercentage = p
            }
            
            switch second.status {
            case .deficient(let p, _), .optimal(let p), .excess(let p, _):
                secondPercentage = p
            }
            
            return abs(firstPercentage - 100) > abs(secondPercentage - 100)
        }
        
        // Return max 8 nutrients
        return Array(statuses.prefix(8))
    }
    
    /// Get chronological timeline of all foods logged today
    func getDailyFoodTimeline() -> [TimelineEntry] {
        var timeline: [TimelineEntry] = []
        
        for meal in todaysMeals.sorted(by: { $0.timestamp < $1.timestamp }) {
            // Find which window this meal belongs to
            let windowName = mealWindows.first { window in
                if let windowId = meal.windowId {
                    return windowId == window.id
                } else {
                    return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }
            }?.name
            
            timeline.append(TimelineEntry(
                timestamp: meal.timestamp,
                meal: meal,
                windowName: windowName
            ))
        }
        
        return timeline
    }
}