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

// MARK: - Story Chapter Progress
struct StoryChapterProgress {
    var startDate = Date() // When user first started using the app
    var totalDaysUsed = 0
    var totalMealsLogged = 0
    
    // Chapter unlock requirements
    struct ChapterRequirements {
        let daysRequired: Int
        let mealsRequired: Int
    }
    
    let requirements: [String: ChapterRequirements] = [
        "yourPlan": ChapterRequirements(daysRequired: 0, mealsRequired: 0), // Always unlocked
        "firstWeek": ChapterRequirements(daysRequired: 7, mealsRequired: 10),
        "patterns": ChapterRequirements(daysRequired: 14, mealsRequired: 20),
        "peakState": ChapterRequirements(daysRequired: 30, mealsRequired: 40)
    ]
    
    func isChapterUnlocked(_ chapterId: String) -> Bool {
        guard let req = requirements[chapterId] else { return false }
        return totalDaysUsed >= req.daysRequired && totalMealsLogged >= req.mealsRequired
    }
    
    func progressToUnlock(_ chapterId: String) -> (days: Int, meals: Int) {
        guard let req = requirements[chapterId] else { return (0, 0) }
        let daysRemaining = max(0, req.daysRequired - totalDaysUsed)
        let mealsRemaining = max(0, req.mealsRequired - totalMealsLogged)
        return (daysRemaining, mealsRemaining)
    }
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
    
    // Computed property for compatibility
    var todayMeals: [LoggedMeal] {
        todaysMeals
    }
    
    // Analyzing meals (in progress)
    @Published var analyzingMeals: [AnalyzingMeal] = []
    
    // Nudge state
    @Published var nudgeState = NudgeState()
    
    // Story chapter tracking
    @Published var storyChapterProgress = StoryChapterProgress()
    
    // MARK: - Initialization
    init() {
        setupDefaultData()
        setupStoryProgress()
    }
    
    // MARK: - Setup Methods
    func setupDefaultData() {
        userGoals = [.performanceFocus, .betterSleep]
        generateMockWindows(for: userProfile.primaryGoal)
        
        // Add some default meals for testing
        // addDefaultMealsForTesting() // Commented out to start with empty schedule
    }
    
    private func addDefaultMealsForTesting() {
        // Add breakfast
        let breakfastTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        addMockMeal(
            name: "Veggie Omelet & Toast",
            calories: 420,
            protein: 24,
            carbs: 35,
            fat: 18,
            at: breakfastTime
        )
        
        // Add lunch
        let lunchTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
        addMockMeal(
            name: "Grilled Chicken Salad",
            calories: 480,
            protein: 38,
            carbs: 25,
            fat: 22,
            at: lunchTime
        )
        
        // Add snack
        let snackTime = Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date())!
        addMockMeal(
            name: "Greek Yogurt & Berries",
            calories: 280,
            protein: 18,
            carbs: 32,
            fat: 8,
            at: snackTime
        )
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
        
        // Generate micronutrient data based on window purpose
        var micronutrients: [String: Double] = [:]
        if let windowPurpose = targetWindow?.purpose {
            micronutrients = generateMicronutrients(for: windowPurpose, mealName: randomMeal.0)
        }
        
        // Generate ingredients based on meal name
        let ingredients = generateIngredients(for: randomMeal.0)
        
        var newMeal = LoggedMeal(
            name: randomMeal.0,
            calories: randomMeal.1,
            protein: randomMeal.2,
            carbs: randomMeal.3,
            fat: randomMeal.4,
            timestamp: mealTime,
            windowId: targetWindow?.id
        )
        newMeal.micronutrients = micronutrients
        newMeal.ingredients = ingredients
        
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
        
        // Generate micronutrient data based on window purpose
        var micronutrients: [String: Double] = [:]
        if let windowPurpose = targetWindow?.purpose {
            micronutrients = generateMicronutrients(for: windowPurpose, mealName: name)
        }
        
        // Generate ingredients
        let ingredients = generateIngredients(for: name)
        
        var meal = LoggedMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            windowId: targetWindow?.id
        )
        meal.micronutrients = micronutrients
        meal.ingredients = ingredients
        todaysMeals.append(meal)
        todaysMeals.sort { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Analyzing Meals Management
    func startAnalyzingMeal(imageData: Data? = nil, voiceDescription: String? = nil) -> AnalyzingMeal {
        let timestamp = TimeProvider.shared.currentTime
        let targetWindow = windowForTimestamp(timestamp)
        
        let analyzingMeal = AnalyzingMeal(
            timestamp: timestamp,
            windowId: targetWindow?.id,
            imageData: imageData,
            voiceDescription: voiceDescription
        )
        
        analyzingMeals.append(analyzingMeal)
        
        // Auto-cleanup stuck analyzing meals after 30 seconds
        let mealId = analyzingMeal.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            if let self = self,
               self.analyzingMeals.contains(where: { $0.id == mealId }) {
                print("Warning: Auto-cleaning up stuck analyzing meal \(mealId)")
                self.cancelAnalyzingMeal(analyzingMeal)
            }
        }
        
        return analyzingMeal
    }
    
    func completeAnalyzingMeal(_ analyzingMeal: AnalyzingMeal, with result: LoggedMeal) {
        // Remove from analyzing meals
        analyzingMeals.removeAll { $0.id == analyzingMeal.id }
        
        // Add to logged meals
        todaysMeals.append(result)
        todaysMeals.sort { $0.timestamp < $1.timestamp }
        
        // Trigger redistribution after adding meal
        redistributeWindows()
    }
    
    func cancelAnalyzingMeal(_ analyzingMeal: AnalyzingMeal) {
        analyzingMeals.removeAll { $0.id == analyzingMeal.id }
    }
    
    // Check if there's an analyzing meal for a specific window
    func analyzingMealInWindow(_ window: MealWindow) -> AnalyzingMeal? {
        analyzingMeals.first { $0.windowId == window.id }
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
    
    // Generate micronutrient data for a meal based on window purpose
    private func generateMicronutrients(for purpose: WindowPurpose, mealName: String) -> [String: Double] {
        var micronutrients: [String: Double] = [:]
        
        // Base micronutrients - all meals contribute some amount of each
        // Values are per meal, aiming for 3-4 meals to reach ~100% RDA
        micronutrients["Vitamin A"] = Double.random(in: 200...400) // mcg
        micronutrients["Vitamin C"] = Double.random(in: 15...40) // mg
        micronutrients["Vitamin D"] = Double.random(in: 100...300) // IU
        micronutrients["Vitamin E"] = Double.random(in: 3...6) // mg
        micronutrients["Vitamin K"] = Double.random(in: 20...40) // mcg
        micronutrients["B1 Thiamine"] = Double.random(in: 0.3...0.5) // mg
        micronutrients["B2 Riboflavin"] = Double.random(in: 0.3...0.5) // mg
        micronutrients["B3 Niacin"] = Double.random(in: 4...8) // mg
        micronutrients["B6"] = Double.random(in: 0.3...0.6) // mg
        micronutrients["B12"] = Double.random(in: 0.5...1.2) // mcg
        micronutrients["Folate"] = Double.random(in: 80...150) // mcg
        micronutrients["Calcium"] = Double.random(in: 200...400) // mg
        micronutrients["Iron"] = Double.random(in: 3...6) // mg
        micronutrients["Magnesium"] = Double.random(in: 60...120) // mg
        micronutrients["Zinc"] = Double.random(in: 2...4) // mg
        micronutrients["Potassium"] = Double.random(in: 500...1000) // mg
        micronutrients["Omega-3"] = Double.random(in: 0.3...0.8) // g
        micronutrients["Fiber"] = Double.random(in: 5...10) // g
        
        // Boost certain nutrients based on window purpose
        switch purpose {
        case .sustainedEnergy:
            micronutrients["B12"] = micronutrients["B12"]! * 1.5
            micronutrients["Iron"] = micronutrients["Iron"]! * 1.5
            micronutrients["Magnesium"] = micronutrients["Magnesium"]! * 1.3
            
        case .focusBoost:
            micronutrients["Omega-3"] = micronutrients["Omega-3"]! * 2.0
            micronutrients["B6"] = micronutrients["B6"]! * 1.5
            micronutrients["Vitamin D"] = micronutrients["Vitamin D"]! * 1.3
            
        case .recovery:
            micronutrients["Vitamin C"] = micronutrients["Vitamin C"]! * 2.0
            micronutrients["Zinc"] = micronutrients["Zinc"]! * 1.5
            micronutrients["Potassium"] = micronutrients["Potassium"]! * 1.5
            
        case .preworkout:
            micronutrients["B1 Thiamine"] = micronutrients["B1 Thiamine"]! * 1.5
            micronutrients["B3 Niacin"] = micronutrients["B3 Niacin"]! * 1.5
            micronutrients["Potassium"] = micronutrients["Potassium"]! * 1.3
            
        case .postworkout:
            micronutrients["Magnesium"] = micronutrients["Magnesium"]! * 1.5
            micronutrients["Zinc"] = micronutrients["Zinc"]! * 1.3
            micronutrients["Calcium"] = micronutrients["Calcium"]! * 1.3
            
        case .metabolicBoost:
            micronutrients["Green Tea"] = Double.random(in: 30...60)
            micronutrients["Chromium"] = Double.random(in: 5...10)
            micronutrients["L-Carnitine"] = Double.random(in: 0.3...0.6)
            
        case .sleepOptimization:
            micronutrients["Magnesium"] = Double.random(in: 60...100)
            micronutrients["Tryptophan"] = Double.random(in: 40...80)
            micronutrients["B6"] = Double.random(in: 0.2...0.4)
        }
        
        // Add some variation based on meal name
        if mealName.lowercased().contains("salad") {
            micronutrients["Vitamin C"] = (micronutrients["Vitamin C"] ?? 0) + Double.random(in: 10...20)
        }
        if mealName.lowercased().contains("chicken") || mealName.lowercased().contains("salmon") {
            micronutrients["Protein"] = (micronutrients["Protein"] ?? 0) + Double.random(in: 5...10)
        }
        
        return micronutrients
    }
    
    // Generate ingredients for a meal based on its name
    private func generateIngredients(for mealName: String) -> [MealIngredient] {
        var ingredients: [MealIngredient] = []
        
        switch mealName {
        case "Grilled Chicken Salad":
            ingredients = [
                MealIngredient(name: "Grilled Chicken", quantity: 4, unit: "oz", foodGroup: .protein, calories: 180, protein: 35.0, carbs: 0.0, fat: 4.0),
                MealIngredient(name: "Mixed Greens", quantity: 2, unit: "cups", foodGroup: .vegetable, calories: 20, protein: 2.0, carbs: 4.0, fat: 0.0),
                MealIngredient(name: "Cherry Tomatoes", quantity: 0.5, unit: "cup", foodGroup: .vegetable, calories: 15, protein: 1.0, carbs: 3.0, fat: 0.0),
                MealIngredient(name: "Cucumber", quantity: 0.5, unit: "cup", foodGroup: .vegetable, calories: 8, protein: 0.5, carbs: 2.0, fat: 0.0),
                MealIngredient(name: "Ranch Dressing", quantity: 2, unit: "tbsp", foodGroup: .sauce, calories: 140, protein: 0.0, carbs: 2.0, fat: 15.0),
                MealIngredient(name: "Black Olives", quantity: 0.25, unit: "cup", foodGroup: .fat, calories: 40, protein: 0.0, carbs: 2.0, fat: 4.0),
                MealIngredient(name: "Croutons", quantity: 0.25, unit: "cup", foodGroup: .grain, calories: 47, protein: 1.5, carbs: 9.0, fat: 1.0)
            ]
            
        case "Protein Smoothie":
            ingredients = [
                MealIngredient(name: "Whey Protein", quantity: 1, unit: "scoop", foodGroup: .protein, calories: 120, protein: 25.0, carbs: 3.0, fat: 1.0),
                MealIngredient(name: "Banana", quantity: 1, unit: "medium", foodGroup: .fruit, calories: 105, protein: 1.3, carbs: 27.0, fat: 0.4),
                MealIngredient(name: "Almond Milk", quantity: 1, unit: "cup", foodGroup: .dairy, calories: 40, protein: 1.0, carbs: 3.0, fat: 3.0),
                MealIngredient(name: "Peanut Butter", quantity: 1, unit: "tbsp", foodGroup: .fat, calories: 95, protein: 4.0, carbs: 3.0, fat: 8.0),
                MealIngredient(name: "Spinach", quantity: 1, unit: "cup", foodGroup: .vegetable, calories: 7, protein: 0.9, carbs: 1.1, fat: 0.1),
                MealIngredient(name: "Ice", quantity: 0.5, unit: "cup", foodGroup: .other, calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0)
            ]
            
        case "Salmon & Quinoa":
            ingredients = [
                MealIngredient(name: "Atlantic Salmon", quantity: 5, unit: "oz", foodGroup: .protein, calories: 290, protein: 37.0, carbs: 0.0, fat: 15.0),
                MealIngredient(name: "Quinoa", quantity: 0.75, unit: "cup", foodGroup: .grain, calories: 165, protein: 6.0, carbs: 30.0, fat: 2.5),
                MealIngredient(name: "Asparagus", quantity: 1, unit: "cup", foodGroup: .vegetable, calories: 27, protein: 3.0, carbs: 5.0, fat: 0.2),
                MealIngredient(name: "Lemon", quantity: 0.25, unit: "medium", foodGroup: .fruit, calories: 5, protein: 0.2, carbs: 1.5, fat: 0.1),
                MealIngredient(name: "Olive Oil", quantity: 1, unit: "tbsp", foodGroup: .fat, calories: 120, protein: 0.0, carbs: 0.0, fat: 14.0),
                MealIngredient(name: "Garlic", quantity: 2, unit: "cloves", foodGroup: .vegetable, calories: 9, protein: 0.4, carbs: 2.0, fat: 0.0)
            ]
            
        case "Greek Yogurt Parfait":
            ingredients = [
                MealIngredient(name: "Greek Yogurt", quantity: 1, unit: "cup", foodGroup: .dairy, calories: 150, protein: 20.0, carbs: 9.0, fat: 4.0),
                MealIngredient(name: "Granola", quantity: 0.25, unit: "cup", foodGroup: .grain, calories: 110, protein: 3.0, carbs: 16.0, fat: 4.5),
                MealIngredient(name: "Mixed Berries", quantity: 0.5, unit: "cup", foodGroup: .fruit, calories: 40, protein: 0.5, carbs: 10.0, fat: 0.3),
                MealIngredient(name: "Honey", quantity: 1, unit: "tbsp", foodGroup: .other, calories: 64, protein: 0.1, carbs: 17.0, fat: 0.0),
                MealIngredient(name: "Chia Seeds", quantity: 1, unit: "tsp", foodGroup: .other, calories: 20, protein: 0.8, carbs: 1.7, fat: 1.3)
            ]
            
        case "Turkey Wrap":
            ingredients = [
                MealIngredient(name: "Sliced Turkey", quantity: 4, unit: "oz", foodGroup: .protein, calories: 120, protein: 24.0, carbs: 2.0, fat: 2.0),
                MealIngredient(name: "Whole Wheat Tortilla", quantity: 1, unit: "large", foodGroup: .grain, calories: 140, protein: 5.0, carbs: 23.0, fat: 3.5),
                MealIngredient(name: "Lettuce", quantity: 0.5, unit: "cup", foodGroup: .vegetable, calories: 5, protein: 0.5, carbs: 1.0, fat: 0.1),
                MealIngredient(name: "Tomato", quantity: 2, unit: "slices", foodGroup: .vegetable, calories: 10, protein: 0.5, carbs: 2.0, fat: 0.1),
                MealIngredient(name: "Avocado", quantity: 0.25, unit: "medium", foodGroup: .fat, calories: 60, protein: 0.7, carbs: 3.0, fat: 5.5),
                MealIngredient(name: "Mustard", quantity: 1, unit: "tsp", foodGroup: .sauce, calories: 5, protein: 0.3, carbs: 0.5, fat: 0.3),
                MealIngredient(name: "Swiss Cheese", quantity: 1, unit: "slice", foodGroup: .dairy, calories: 106, protein: 8.0, carbs: 1.5, fat: 7.8)
            ]
            
        case "Overnight Oats":
            ingredients = [
                MealIngredient(name: "Rolled Oats", quantity: 0.5, unit: "cup", foodGroup: .grain, calories: 150, protein: 5.0, carbs: 27.0, fat: 3.0),
                MealIngredient(name: "Almond Milk", quantity: 0.75, unit: "cup", foodGroup: .dairy, calories: 30, protein: 0.8, carbs: 2.3, fat: 2.3),
                MealIngredient(name: "Strawberries", quantity: 0.5, unit: "cup", foodGroup: .fruit, calories: 27, protein: 0.6, carbs: 6.5, fat: 0.3),
                MealIngredient(name: "Maple Syrup", quantity: 1, unit: "tbsp", foodGroup: .other, calories: 52, protein: 0.0, carbs: 13.4, fat: 0.0),
                MealIngredient(name: "Almond Butter", quantity: 1, unit: "tbsp", foodGroup: .fat, calories: 98, protein: 3.4, carbs: 3.0, fat: 8.9),
                MealIngredient(name: "Cinnamon", quantity: 0.5, unit: "tsp", foodGroup: .other, calories: 3, protein: 0.1, carbs: 0.8, fat: 0.0)
            ]
            
        default:
            // Generic ingredients for other meals
            ingredients = [
                MealIngredient(name: "Main Protein", quantity: 4, unit: "oz", foodGroup: .protein),
                MealIngredient(name: "Vegetables", quantity: 1, unit: "cup", foodGroup: .vegetable),
                MealIngredient(name: "Grains", quantity: 0.5, unit: "cup", foodGroup: .grain)
            ]
        }
        
        return ingredients
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
        
        // Only assign to nearest window if it's within 2 hours
        if let nearestWindow = nearestWindow {
            let distance = min(
                abs(timestamp.timeIntervalSince(nearestWindow.startTime)),
                abs(timestamp.timeIntervalSince(nearestWindow.endTime))
            )
            // If more than 2 hours away from any window, don't assign to a window
            if distance > 2 * 3600 {
                return nil
            }
        }
        
        return nearestWindow
    }
    
    // MARK: - Story Chapter Management
    private func setupStoryProgress() {
        // For testing, simulate some progress
        storyChapterProgress.startDate = Date().addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
        storyChapterProgress.totalDaysUsed = 5
        storyChapterProgress.totalMealsLogged = 8
    }
    
    func updateStoryProgress() {
        // Calculate days since start
        let daysSinceStart = Calendar.current.dateComponents([.day], from: storyChapterProgress.startDate, to: Date()).day ?? 0
        storyChapterProgress.totalDaysUsed = daysSinceStart
        
        // Count total meals logged (in real app, this would query from database)
        storyChapterProgress.totalMealsLogged = todaysMeals.count + 5 // Adding some historical meals for testing
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