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
    @Published var morningCheckIn: MorningCheckIn?
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
    
    func loadData() async {
        await loadInitialData()
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
    
    var dailyCarbsTarget: Int {  // Alias for compatibility
        dailyCarbTarget
    }
    
    var dailyFatTarget: Int {
        userProfile.dailyFatTarget
    }
    
    var windowsRemaining: Int {
        let now = Date()
        return mealWindows.filter { $0.endTime > now }.count
    }
    
    var currentWindow: MealWindow? {
        let now = Date()
        return mealWindows.first { window in
            window.startTime <= now && window.endTime > now
        }
    }
    
    var nextWindow: MealWindow? {
        let now = Date()
        return mealWindows.first { window in
            window.startTime > now
        }
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
        // Return top micronutrients for the day
        let nutrients = [
            NutrientInfo(name: "Vitamin D", current: 12, target: 20, unit: "μg", color: .orange),
            NutrientInfo(name: "Iron", current: 8, target: 18, unit: "mg", color: .red),
            NutrientInfo(name: "Calcium", current: 600, target: 1000, unit: "mg", color: .white),
            NutrientInfo(name: "Vitamin B12", current: 1.8, target: 2.4, unit: "μg", color: .purple)
        ]
        return nutrients.sorted { $0.percentage > $1.percentage }
    }
    
    // MARK: - Additional Dashboard Properties
    
    var checkInsCompleted: Int {
        return (morningCheckIn != nil ? 1 : 0) + postMealCheckIns.count
    }
    
    var nutrientsHit: Int {
        // Count nutrients that are at least 80% of target
        return topNutrients.filter { $0.percentage >= 0.8 }.count
    }
    
    var timingPercentage: Double {
        // Calculate based on meals eaten within windows
        guard !mealWindows.isEmpty else { return 0 }
        let mealsInWindows = todaysMeals.filter { meal in
            mealWindows.contains { window in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }
        return Double(mealsInWindows.count) / Double(max(todaysMeals.count, 1)) * 100
    }
    
    var nutrientPercentage: Double {
        // Average percentage of all nutrient targets
        let avgPercentage = topNutrients.map { $0.percentage }.reduce(0, +) / Double(max(topNutrients.count, 1))
        return avgPercentage * 100
    }
    
    var adherencePercentage: Double {
        // Windows used vs total windows
        let windowsUsed = mealWindows.filter { window in
            mealsInWindow(window).count > 0
        }.count
        return Double(windowsUsed) / Double(max(mealWindows.count, 1)) * 100
    }
    
    // MARK: - Week View Properties
    
    var weekAverageScore: Int { 75 } // Mock for now
    var weekScoreValues: [Double] { [65, 78, 82, 75, 80, 72, 85] } // Mock for now
    var daysLogged: Int { 6 } // Mock for now
    var weekAverageCalories: Int { 1850 } // Mock for now
    var weekWindowAdherence: Double { 82.5 } // Mock for now
    var weekNutrientsAverage: Int { 24 } // Mock for now
    var weekTimingValues: [Double] { [75, 80, 85, 78, 82, 79, 88] } // Mock for now
    var weekNutrientValues: [Double] { [70, 75, 80, 72, 78, 74, 82] } // Mock for now
    var weekAdherenceValues: [Double] { [80, 85, 78, 82, 88, 75, 90] } // Mock for now
    
    var totalWindows: Int { mealWindows.count }
    
    var windowsHit: Int {
        // Count windows that have at least one meal
        mealWindows.filter { window in
            mealsInWindow(window).count > 0
        }.count
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    var todayScore: Int {
        // Calculate a simple score based on progress
        let calorieScore = min(Double(totalCalories) / Double(dailyCalorieTarget), 1.0) * 25
        let proteinScore = min(Double(totalProtein) / Double(dailyProteinTarget), 1.0) * 25
        let windowScore = Double(windowsHit) / Double(max(totalWindows, 1)) * 25
        let checkInScore = Double(checkInsCompleted) / 4.0 * 25
        return Int(calorieScore + proteinScore + windowScore + checkInScore)
    }
    
    var todayWindows: [MealWindow] { mealWindows }
    
    var totalPercentage: Int {
        // Overall percentage of daily goals
        let caloriePercent = Double(totalCalories) / Double(dailyCalorieTarget) * 100
        let proteinPercent = Double(totalProtein) / Double(dailyProteinTarget) * 100
        let carbPercent = Double(totalCarbs) / Double(dailyCarbTarget) * 100
        let fatPercent = Double(totalFat) / Double(dailyFatTarget) * 100
        return Int((caloriePercent + proteinPercent + carbPercent + fatPercent) / 4)
    }
    
    var nutrientsStatus: String {
        let hitCount = nutrientsHit
        if hitCount >= 25 { return "Excellent" }
        else if hitCount >= 20 { return "Great" }
        else if hitCount >= 15 { return "Good" }
        else if hitCount >= 10 { return "Fair" }
        else { return "Needs Focus" }
    }
    
    var currentWindowStatus: (mainText: String, subText: String, progress: Double) {
        guard let currentWindow = currentWindow else {
            if let nextWindow = nextWindow {
                let timeUntil = nextWindow.startTime.timeIntervalSince(Date())
                let hoursUntil = Int(timeUntil / 3600)
                let minutesUntil = Int((timeUntil.truncatingRemainder(dividingBy: 3600)) / 60)
                return ("Next window", "in \(hoursUntil)h \(minutesUntil)m", 0)
            }
            return ("No active window", "All windows complete", 1.0)
        }
        
        let elapsed = Date().timeIntervalSince(currentWindow.startTime)
        let total = currentWindow.endTime.timeIntervalSince(currentWindow.startTime)
        let progress = elapsed / total
        let remaining = currentWindow.endTime.timeIntervalSince(Date())
        let minutesRemaining = Int(remaining / 60)
        
        return (currentWindow.title, "\(minutesRemaining) min remaining", progress)
    }
    
    var dailyCalorieProgress: Double {
        Double(totalCalories) / Double(dailyCalorieTarget)
    }
    
    var fastingTime: String {
        guard let lastMeal = todaysMeals.last else { return "0h 0m" }
        let timeSince = Date().timeIntervalSince(lastMeal.timestamp)
        let hours = Int(timeSince / 3600)
        let minutes = Int((timeSince.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var fastingStatus: String {
        guard let lastMeal = todaysMeals.last else { return "No meals logged" }
        let timeSince = Date().timeIntervalSince(lastMeal.timestamp)
        let hours = timeSince / 3600
        
        if hours < 2 { return "Digesting" }
        else if hours < 8 { return "Early Fast" }
        else if hours < 12 { return "Moderate Fast" }
        else if hours < 16 { return "Deep Fast" }
        else { return "Extended Fast" }
    }
    
    var fastingProgress: Double {
        // Progress towards a 16-hour fast
        guard let lastMeal = todaysMeals.last else { return 0 }
        let timeSince = Date().timeIntervalSince(lastMeal.timestamp)
        let hours = timeSince / 3600
        return min(hours / 16.0, 1.0)
    }
    
    var nextWindowName: String {
        nextWindow?.title ?? "No upcoming windows"
    }
    
    // MARK: - Supporting Types
    
    struct NutritionInsight: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let message: String
        let type: InsightType = .suggestion
        
        enum InsightType {
            case positive, warning, suggestion, trend
        }
    }
    
    struct NutrientInfo: Identifiable {
        let id = UUID()
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