//
//  MockDataManager.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - Nudge State
struct NudgeState {
    var hasCompletedOnboarding = false
    var lastNudgeTimestamps: [String: Date] = [:]
    var dismissedNudges: Set<String> = []
    var nudgeFrequency: [String: Int] = [:] // Track how many times each nudge has been shown
}

class MockDataManager: ObservableObject {
    static let shared = MockDataManager()
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile = .mockProfile
    @Published var userGoals: [NutritionGoal] = []
    @Published var mealWindows: [MealWindow] = []
    // Removed old MealEntry - using LoggedMeal instead
    @Published var morningCheckIn: MorningCheckInData?
    @Published var currentSimulatedTime: Date = Date()
    @Published var showMorningCheckIn: Bool = true
    
    // Today's meals
    @Published var todaysMeals: [LoggedMeal] = []
    
    // Nudge state
    @Published var nudgeState = NudgeState()
    
    // MARK: - Initialization
    init() {
        setupDefaultData()
    }
    
    // MARK: - Setup Methods
    func setupDefaultData() {
        userGoals = [.performanceFocus, .betterSleep]
        generateMockWindows(for: userProfile.primaryGoal)
    }
    
    // MARK: - Goal Management
    func setPrimaryGoal(_ goal: NutritionGoal) {
        userProfile.primaryGoal = goal
        generateMockWindows(for: goal)
    }
    
    func addSecondaryGoal(_ goal: NutritionGoal) {
        if !userGoals.contains(where: { $0.id == goal.id }) {
            userGoals.append(goal)
        }
    }
    
    func removeSecondaryGoal(_ goal: NutritionGoal) {
        userGoals.removeAll { $0.id == goal.id }
    }
    
    // MARK: - Window Generation
    func generateMockWindows(for goal: NutritionGoal) {
        mealWindows = MealWindow.mockWindows(for: goal, checkIn: morningCheckIn, userProfile: userProfile)
    }
    
    // MARK: - Meal Management
    func addMockMeal(in window: MealWindow? = nil) {
        let mockMeals = [
            ("Grilled Chicken Salad", 450, 35, 25, 20),
            ("Protein Smoothie", 350, 30, 40, 8),
            ("Salmon & Quinoa", 550, 40, 45, 22),
            ("Greek Yogurt Parfait", 300, 20, 35, 10),
            ("Turkey Wrap", 400, 30, 35, 15),
            ("Overnight Oats", 380, 15, 55, 12)
        ]
        
        let randomMeal = mockMeals.randomElement()!
        let mealTime = window?.startTime ?? TimeProvider.shared.currentTime
        
        // Find the appropriate window for this meal time
        let targetWindow = window ?? windowForTimestamp(mealTime)
        
        let newMeal = LoggedMeal(
            name: randomMeal.0,
            calories: randomMeal.1,
            protein: randomMeal.2,
            carbs: randomMeal.3,
            fat: randomMeal.4,
            timestamp: mealTime,
            windowId: targetWindow?.id
        )
        
        todaysMeals.append(newMeal)
        todaysMeals.sort { $0.timestamp < $1.timestamp }
        
        // Trigger redistribution after adding meal
        redistributeWindows()
    }
    
    func clearAllMeals() {
        todaysMeals.removeAll()
        // Trigger redistribution after clearing meals
        redistributeWindows()
    }
    
    // MARK: - Morning Check-In
    func completeMorningCheckIn(
        wakeTime: Date = Date(),
        sleepQuality: Int = 8,
        sleepDuration: TimeInterval = 7.5 * 3600,
        energyLevel: Int = 4,
        plannedActivities: [String] = ["Morning Run"],
        hungerLevel: Int = 3
    ) {
        morningCheckIn = MorningCheckInData(
            date: Date(),
            wakeTime: wakeTime,
            sleepQuality: sleepQuality,
            sleepDuration: sleepDuration,
            energyLevel: energyLevel,
            plannedActivities: plannedActivities,
            hungerLevel: hungerLevel
        )
        
        showMorningCheckIn = false
        generateMockWindows(for: userProfile.primaryGoal)
    }
    
    func resetMorningCheckIn() {
        morningCheckIn = nil
        showMorningCheckIn = true
    }
    
    // MARK: - Time Simulation
    func simulateTime(hour: Int, minute: Int = 0) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        currentSimulatedTime = calendar.date(from: components) ?? Date()
        // Update the TimeProvider with the simulated time
        TimeProvider.shared.setSimulatedTime(currentSimulatedTime)
    }
    
    func simulateDayProgress(hour: Int) {
        simulateTime(hour: hour)
        
        // Add meals based on time
        if hour >= 8 && todaysMeals.isEmpty {
            addMockMeal() // Breakfast
        }
        if hour >= 12 && todaysMeals.count == 1 {
            addMockMeal() // Lunch
        }
        if hour >= 15 && todaysMeals.count == 2 {
            addMockMeal() // Snack
        }
        if hour >= 19 && todaysMeals.count == 3 {
            addMockMeal() // Dinner
        }
    }
    
    // MARK: - Profile Settings
    func updateActivityLevel(_ level: ActivityLevel) {
        userProfile.activityLevel = level
    }
    
    func updateWorkSchedule(_ schedule: WorkSchedule) {
        userProfile.workSchedule = schedule
    }
    
    func updateMealCount(_ count: Int) {
        userProfile.preferredMealCount = count
        generateMockWindows(for: userProfile.primaryGoal)
    }
    
    func updateFastingProtocol(_ protocol: FastingProtocol?) {
        userProfile.intermittentFastingPreference = `protocol`
        generateMockWindows(for: userProfile.primaryGoal)
    }
    
    // MARK: - Reset Functions
    func resetToDefaults() {
        setupDefaultData()
        todaysMeals.removeAll()
        morningCheckIn = nil
        showMorningCheckIn = true
        currentSimulatedTime = Date()
        TimeProvider.shared.resetToRealTime()
    }
    
    func resetDay() {
        todaysMeals.removeAll()
        morningCheckIn = nil
        showMorningCheckIn = true
        generateMockWindows(for: userProfile.primaryGoal)
        currentSimulatedTime = Date()
        TimeProvider.shared.resetToRealTime()
    }
    
    // MARK: - Meal Management
    func addMockMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, at timestamp: Date) {
        // Find the appropriate window for this meal time
        let targetWindow = windowForTimestamp(timestamp)
        
        let meal = LoggedMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            windowId: targetWindow?.id
        )
        todaysMeals.append(meal)
        todaysMeals.sort { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Computed Properties
    var activeWindow: MealWindow? {
        mealWindows.first { $0.isActive }
    }
    
    var nextWindow: MealWindow? {
        mealWindows.first { $0.isUpcoming }
    }
    
    var windowsRemaining: Int {
        mealWindows.filter { !$0.isPast }.count
    }
    
    var todaysCaloriesConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    var todaysProteinConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.protein }
    }
    
    var todaysCarbsConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.carbs }
    }
    
    var todaysFatConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.fat }
    }
    
    // MARK: - Micronutrient Tracking
    func getMicronutrientConsumption(for purpose: WindowPurpose) -> [MicronutrientConsumption] {
        // Mock consumed values based on window purpose
        // In a real app, these would be calculated from actual food data
        switch purpose {
        case .sustainedEnergy:
            return [
                MicronutrientConsumption(info: .b12, consumed: 2.0),
                MicronutrientConsumption(info: .iron, consumed: 11.7),
                MicronutrientConsumption(info: .magnesium, consumed: 364.0)
            ]
        case .focusBoost:
            return [
                MicronutrientConsumption(info: .omega3, consumed: 1.0),
                MicronutrientConsumption(info: .b6, consumed: 1.1),
                MicronutrientConsumption(info: .vitaminD, consumed: 520.0)
            ]
        case .recovery:
            return [
                MicronutrientConsumption(info: .vitaminC, consumed: 73.8),
                MicronutrientConsumption(info: .zinc, consumed: 7.2),
                MicronutrientConsumption(info: .potassium, consumed: 3185.0)
            ]
        case .preworkout:
            return [
                MicronutrientConsumption(info: .bComplex, consumed: 41.0),
                MicronutrientConsumption(info: .caffeine, consumed: 260.0),
                MicronutrientConsumption(info: .lArginine, consumed: 4.9)
            ]
        case .postworkout:
            return [
                MicronutrientConsumption(info: .protein, consumed: 41.0),
                MicronutrientConsumption(info: .leucine, consumed: 2.3),
                MicronutrientConsumption(info: .magnesium, consumed: 364.0)
            ]
        case .metabolicBoost:
            return [
                MicronutrientConsumption(info: .greenTea, consumed: 180.0),
                MicronutrientConsumption(info: .chromium, consumed: 31.5),
                MicronutrientConsumption(info: .lCarnitine, consumed: 1.8)
            ]
        case .sleepOptimization:
            return [
                MicronutrientConsumption(info: .magnesium, consumed: 328.0),
                MicronutrientConsumption(info: .tryptophan, consumed: 200.0),
                MicronutrientConsumption(info: .b6, consumed: 1.4)
            ]
        }
    }
    
    // Additional properties for Momentum tab
    var primaryGoal: NutritionGoal {
        userProfile.primaryGoal
    }
    
    var mealsLoggedToday: [LoggedMeal] {
        todaysMeals
    }
    
    var totalCalories: Double {
        Double(todaysCaloriesConsumed)
    }
    
    var totalProtein: Double {
        Double(todaysProteinConsumed)
    }
    
    var totalCarbs: Double {
        Double(todaysCarbsConsumed)
    }
    
    var totalFat: Double {
        Double(todaysFatConsumed)
    }
    
    var currentStreak: Int {
        // Mock streak data
        14
    }
    
    var bestStreak: Int {
        // Mock best streak
        21
    }
    
    var currentWeight: Double {
        // Mock weight
        68.4
    }
    
    // MARK: - Window-specific calculations
    func mealsInWindow(_ window: MealWindow) -> [LoggedMeal] {
        todaysMeals.filter { meal in
            meal.windowId == window.id
        }
    }
    
    func caloriesConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.calories }
    }
    
    func proteinConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.protein }
    }
    
    func carbsConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.carbs }
    }
    
    func fatConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.fat }
    }
    
    // Find which window a timestamp belongs to (or nearest window if outside all windows)
    func windowForTimestamp(_ timestamp: Date) -> MealWindow? {
        // First check if timestamp falls within any window
        if let exactWindow = mealWindows.first(where: { window in
            timestamp >= window.startTime && timestamp <= window.endTime
        }) {
            return exactWindow
        }
        
        // If not within any window, find the nearest window
        let nearestWindow = mealWindows.min { window1, window2 in
            let distance1 = min(
                abs(timestamp.timeIntervalSince(window1.startTime)),
                abs(timestamp.timeIntervalSince(window1.endTime))
            )
            let distance2 = min(
                abs(timestamp.timeIntervalSince(window2.startTime)),
                abs(timestamp.timeIntervalSince(window2.endTime))
            )
            return distance1 < distance2
        }
        
        return nearestWindow
    }
    
    // MARK: - Window Redistribution
    private func redistributeWindows() {
        let redistributionManager = WindowRedistributionManager.shared
        let redistributedWindows = redistributionManager.redistributeWindows(
            allWindows: mealWindows,
            consumedMeals: todaysMeals,
            userProfile: userProfile,
            currentTime: TimeProvider.shared.currentTime
        )
        
        // Update windows with redistributed values
        mealWindows = redistributedWindows.map { redistributed in
            var window = redistributed.originalWindow
            window.adjustedCalories = redistributed.adjustedCalories
            window.adjustedMacros = redistributed.adjustedMacros
            window.redistributionReason = redistributed.redistributionReason
            return window
        }
    }
}