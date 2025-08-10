//
//  ScheduleViewModel.swift
//  Phyllo
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
}