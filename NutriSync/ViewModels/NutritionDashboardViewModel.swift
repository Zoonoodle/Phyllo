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
    
    // MARK: - Dependencies
    private let dataProvider = DataSourceProvider.shared.provider
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
    
    var currentStreak: Int {
        // TODO: Calculate actual streak from historical data
        return 14 // Mock value for now
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
                return windowId == window.id
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