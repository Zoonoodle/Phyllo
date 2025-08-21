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
        let calendar = Calendar.current
        
        // First, check morning check-in wake time
        var earliestHour: Int? = nil
        if let checkIn = morningCheckIn {
            let wakeHour = calendar.component(.hour, from: checkIn.wakeTime)
            // Always show at least 1 hour before wake time
            earliestHour = max(0, wakeHour - buffer)
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
            
            return Array(startHour...endHour)
        }
        
        // Use work schedule defaults
        let (defaultEarliest, defaultLatest) = userProfile.workSchedule.defaultMealHours
        
        // Calculate range based on all available data
        var startHour = defaultEarliest
        var endHour = defaultLatest
        
        // Include wake time
        if let earliestFromWake = earliestHour {
            startHour = min(startHour, earliestFromWake)
        }
        
        // Include meal windows
        if let windowStart = windowEarliestHour {
            startHour = min(startHour, windowStart)
        }
        if let windowEnd = windowLatestHour {
            endHour = max(endHour, windowEnd)
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
        
        return Array(startHour...endHour)
    }
    
    // MARK: - Dependencies
    private let dataProvider = DataSourceProvider.shared.provider
    private let timeProvider = TimeProvider.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var observations: [ObservationToken] = []
    
    // MARK: - Initialization
    init() {
        setupObservations()
        Task {
            await loadInitialData()
        }
    }
    
    deinit {
        // Clean up observations
        observations.forEach { _ in } // Tokens clean up in their deinit
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
                self?.mealWindows = windows
                // Schedule notifications when windows change
                await self?.notificationManager.scheduleWindowNotifications(for: windows)
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
        defer { isLoading = false }
        
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
            mealWindows = try await dataProvider.getWindows(for: today)
            
            Task { @MainActor in
                DebugLogger.shared.dataProvider("Loaded \(mealWindows.count) windows for today")
            }
            
            // Load analyzing meals
            analyzingMeals = try await dataProvider.getAnalyzingMeals()
            
            // Load morning check-in
            morningCheckIn = try await dataProvider.getMorningCheckIn(for: today)
            
            // Generate windows only if morning check-in is completed
            if mealWindows.isEmpty {
                if morningCheckIn != nil {
                    Task { @MainActor in
                        DebugLogger.shared.warning("No windows found for today, generating windows based on check-in")
                    }
                    await generateDailyWindows()
                } else {
                    Task { @MainActor in
                        DebugLogger.shared.info("No windows generated - waiting for morning check-in")
                    }
                }
            }
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Failed to load schedule data: \(error)")
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
            
            // Generate windows based on check-in
            await generateDailyWindows()
            
            // Optional redistribution after generation using current meals
            await redistributeWindows()
            
        } catch {
            errorMessage = "Failed to save check-in: \(error.localizedDescription)"
            print("❌ Failed to save morning check-in: \(error)")
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
            errorMessage = "Failed to generate windows: \(error.localizedDescription)"
            print("❌ Failed to generate windows: \(error)")
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
            print("❌ Failed to redistribute windows: \(error)")
        }
    }
    
    /// Delete a meal
    func deleteMeal(_ meal: LoggedMeal) async {
        do {
            try await dataProvider.deleteMeal(id: meal.id.uuidString)
            // Meals will update via observation
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
            print("❌ Failed to delete meal: \(error)")
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
                    print("❌ Failed to mark window as fasted: \(error)")
                }
            }
        }
    }
    
    /// Mark a single window as fasted
    func markWindowAsFasted(windowId: UUID) async {
        guard let windowIndex = mealWindows.firstIndex(where: { $0.id == windowId }) else {
            print("❌ Window not found with id: \(windowId)")
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
            print("❌ Failed to mark window as fasted: \(error)")
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
            print("❌ Failed to update user profile: \(error)")
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
            print("❌ Failed to process retrospective meals: \(error)")
        }
    }
}