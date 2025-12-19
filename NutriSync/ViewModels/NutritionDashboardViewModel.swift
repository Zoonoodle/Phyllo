//
//  NutritionDashboardViewModel.swift
//  NutriSync
//
//  ViewModel for nutrition dashboard using real Firebase data
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NutritionDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todaysMeals: [LoggedMeal] = []
    @Published var mealWindows: [MealWindow] = []
    @Published var morningCheckIn: MorningCheckInData?
    @Published var postMealCheckIns: [PostMealCheckIn] = []
    @Published var userProfile: UserProfile = UserProfile.defaultProfile
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Adaptive Period Properties
    @Published var selectedPeriod: TimePeriod = .weekly
    @Published var periodAnalytics: [DailyAnalytics] = []
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var daysActive: Int = 0
    @Published var isLoadingPeriod = false

    // Period aggregated macros
    @Published var periodProtein: Int = 0
    @Published var periodCarbs: Int = 0
    @Published var periodFat: Int = 0
    
    // MARK: - Dependencies
    private let dataProvider = DataSourceProvider.shared.provider
    private var observations: [ObservationToken] = []
    private var loadPeriodTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        setupObservations()
        Task {
            await loadInitialData()
            await loadPeriodData()
        }
    }
    
    deinit {
        // Clean up observations
        observations.forEach { _ in } // Tokens clean up in their deinit
    }
    
    // MARK: - Data Loading
    private func setupObservations() {
        let today = Date()
        
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
            }
        }
        observations.append(windowsToken)
    }
    
    private func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let today = Date()
            
            // Load user profile
            if let profile = try await dataProvider.getUserProfile() {
                self.userProfile = profile
            }
            
            // Load meals
            todaysMeals = try await dataProvider.getMeals(for: today)
            
            // Load windows
            mealWindows = try await dataProvider.getWindows(for: today)
            
            // Load morning check-in
            morningCheckIn = try await dataProvider.getMorningCheckIn(for: today)
            
            // Load post-meal check-ins
            postMealCheckIns = try await dataProvider.getPostMealCheckIns(for: today)
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Failed to load nutrition dashboard data: \(error)")
        }
    }

    // MARK: - Adaptive Period Methods

    /// Determines the appropriate period based on user's time in app
    func determineAdaptivePeriod() {
        // Calculate days since user started
        let calendar = Calendar.current
        let startDate = userProfile.onboardingCompletedAt ?? Date()
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        daysActive = max(components.day ?? 0, 0)

        // Auto-select period based on usage
        // Weekly for first 14 days, then monthly
        if daysActive < 14 {
            selectedPeriod = .weekly
        } else if selectedPeriod == .weekly && daysActive >= 30 {
            // Suggest monthly after 30 days but don't force it
            selectedPeriod = .monthly
        }
    }

    /// Date range for current period
    var dateRangeForPeriod: (from: Date, to: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch selectedPeriod {
        case .weekly:
            let from = calendar.date(byAdding: .day, value: -7, to: today) ?? today
            return (from, today)
        case .monthly:
            let from = calendar.date(byAdding: .day, value: -30, to: today) ?? today
            return (from, today)
        }
    }

    /// Loads period-specific analytics data
    func loadPeriodData() async {
        guard !isLoadingPeriod else { return }
        isLoadingPeriod = true
        defer { isLoadingPeriod = false }

        // First determine the appropriate period
        determineAdaptivePeriod()

        do {
            let range = dateRangeForPeriod

            // Load daily analytics for the period
            if let analytics = try await dataProvider.getDailyAnalyticsRange(from: range.from, to: range.to) {
                periodAnalytics = analytics
            } else {
                periodAnalytics = []
            }

            // Load streak data
            let streakData = try await dataProvider.calculateStreak(until: Date())
            currentStreak = streakData.current
            bestStreak = streakData.best

            // Calculate aggregated macros for the period
            let mealsDict = try await dataProvider.getMealsForDateRange(from: range.from, to: range.to)
            let allMeals = mealsDict.values.flatMap { $0 }

            // Calculate daily averages
            let daysInPeriod = max(selectedPeriod.dayCount, 1)
            let totalProtein = allMeals.reduce(0) { $0 + $1.protein }
            let totalCarbs = allMeals.reduce(0) { $0 + $1.carbs }
            let totalFat = allMeals.reduce(0) { $0 + $1.fat }

            periodProtein = totalProtein / daysInPeriod
            periodCarbs = totalCarbs / daysInPeriod
            periodFat = totalFat / daysInPeriod

        } catch {
            print("❌ Failed to load period data: \(error)")
            // Keep existing values on error
        }
    }

    /// Switch to a different time period
    func switchPeriod(to period: TimePeriod) {
        guard period != selectedPeriod else { return }
        selectedPeriod = period

        // Cancel any in-flight load and start new one
        loadPeriodTask?.cancel()
        loadPeriodTask = Task {
            await loadPeriodData()
        }
    }

    // MARK: - Period-Aware Metrics

    /// Average timing score for the period
    var periodTimingScore: Double {
        guard !periodAnalytics.isEmpty else { return 0 }
        return periodAnalytics.reduce(0.0) { $0 + $1.timingScore } / Double(periodAnalytics.count)
    }

    /// Average nutrient score for the period
    var periodNutrientScore: Double {
        guard !periodAnalytics.isEmpty else { return 0 }
        return periodAnalytics.reduce(0.0) { $0 + $1.nutrientScore } / Double(periodAnalytics.count)
    }

    /// Average adherence score for the period
    var periodAdherenceScore: Double {
        guard !periodAnalytics.isEmpty else { return 0 }
        return periodAnalytics.reduce(0.0) { $0 + $1.adherenceScore } / Double(periodAnalytics.count)
    }

    // MARK: - Computed Properties
    
    var totalCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Int {
        todaysMeals.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Int {
        todaysMeals.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Int {
        todaysMeals.reduce(0) { $0 + $1.fat }
    }
    
    var dailyCalorieTarget: Int {
        userProfile.dailyCalorieTarget
    }
    
    var dailyProteinTarget: Int {
        userProfile.dailyProteinTarget
    }
    
    var dailyCarbTarget: Int {
        userProfile.dailyCarbTarget
    }
    
    var dailyFatTarget: Int {
        userProfile.dailyFatTarget
    }
    
    var windowsRemaining: Int {
        let now = Date()
        return mealWindows.filter { $0.endTime > now }.count
    }
    
    var activeWindow: MealWindow? {
        let now = Date()
        return mealWindows.first { window in
            window.startTime <= now && window.endTime > now
        }
    }
    
    var currentWindowName: String {
        if let window = activeWindow {
            return window.purpose.rawValue
        } else if windowsRemaining > 0 {
            return "Fasting"
        } else {
            return "Day Complete"
        }
    }
    
    var timeTillNextWindow: String {
        let now = Date()
        if let nextWindow = mealWindows.first(where: { $0.startTime > now }) {
            let timeInterval = nextWindow.startTime.timeIntervalSince(now)
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m until next"
            } else {
                return "\(minutes)m until next"
            }
        }
        return "No more windows today"
    }
    
    
    var lastFastingDuration: TimeInterval {
        // Calculate fasting duration since last meal
        if let lastMeal = todaysMeals.sorted(by: { $0.timestamp > $1.timestamp }).first {
            return Date().timeIntervalSince(lastMeal.timestamp)
        }
        // Default to time since midnight if no meals
        return Date().timeIntervalSince(Calendar.current.startOfDay(for: Date()))
    }
    
    // MARK: - Helper Methods
    
    func mealsInWindow(_ window: MealWindow) -> [LoggedMeal] {
        todaysMeals.filter { meal in
            if let windowId = meal.windowId {
                return windowId.uuidString == window.id
            }
            // Fallback to time-based check
            return meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
    
    func caloriesConsumedInWindow(_ window: MealWindow) -> Int {
        mealsInWindow(window).reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - Dashboard Specific Properties
    
    var insights: [NutritionInsight] {
        // Generate insights based on current data
        var insights: [NutritionInsight] = []
        
        // Example insights
        if totalProtein < dailyProteinTarget / 2 && windowsRemaining <= 1 {
            insights.append(NutritionInsight(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Low Protein Alert",
                message: "You're behind on protein today. Consider a protein-rich dinner."
            ))
        }
        
        if let lastCheckIn = postMealCheckIns.last, lastCheckIn.energyLevel.rawValue >= 4 {
            insights.append(NutritionInsight(
                icon: "bolt.fill",
                iconColor: .green,
                title: "Great Energy!",
                message: "Your last meal gave you excellent energy. Remember this combination!"
            ))
        }
        
        return insights
    }
    
    var topNutrients: [NutrientInfo] {
        // Calculate actual micronutrients from today's meals
        var nutrientTotals: [String: Double] = [:]
        
        // Aggregate all micronutrients from today's meals
        for meal in todaysMeals {
            for (nutrientName, amount) in meal.micronutrients {
                nutrientTotals[nutrientName, default: 0] += amount
            }
        }
        
        // Define nutrients to track with their RDA values and colors
        let nutrientDefinitions: [(name: String, target: Double, unit: String, color: Color)] = [
            ("Vitamin D", 20, "μg", .orange),
            ("Iron", 18, "mg", .red),
            ("Calcium", 1000, "mg", .white),
            ("Vitamin B12", 2.4, "μg", .purple)
        ]
        
        // Build nutrient info array with actual consumed values
        var nutrients: [NutrientInfo] = []
        for def in nutrientDefinitions {
            let current = nutrientTotals[def.name] ?? 0
            nutrients.append(NutrientInfo(
                name: def.name,
                current: current,
                target: def.target,
                unit: def.unit,
                color: def.color
            ))
        }
        
        // If no meals logged yet, return empty array instead of fake data
        if todaysMeals.isEmpty {
            return nutrients.map { nutrient in
                NutrientInfo(
                    name: nutrient.name,
                    current: 0,
                    target: nutrient.target,
                    unit: nutrient.unit,
                    color: nutrient.color
                )
            }
        }
        
        return nutrients.sorted { $0.percentage > $1.percentage }
    }
    
    // MARK: - Supporting Types
    
    struct NutritionInsight {
        let icon: String
        let iconColor: Color
        let title: String
        let message: String
        let type: InsightType = .suggestion
        
        enum InsightType {
            case positive, warning, suggestion, trend
        }
    }
    
    struct NutrientInfo {
        let name: String
        let current: Double
        let target: Double
        let unit: String
        let color: Color
        
        var percentage: Double {
            guard target > 0 else { return 0 }
            return min(current / target, 1.0)
        }
    }
}