//
//  SampleDataGenerator.swift
//  NutriSync
//
//  Generates sample meal windows and logged meals for the full day preview
//

import Foundation

/// Generates realistic sample data for preview purposes
@MainActor
class SampleDataGenerator {

    static let shared = SampleDataGenerator()

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Sample Window Generation

    /// Generate sample windows for a full day based on user profile
    func generateSampleWindows(for profile: UserProfile, on date: Date = Date()) -> [MealWindow] {
        let wakeTime = normalizedTimeToday(from: profile.typicalWakeTime, defaultHour: 7, on: date)
        let sleepTime = normalizedTimeToday(from: profile.typicalSleepTime, defaultHour: 22, on: date)

        let mealsPerDay = profile.mealsPerDay ?? 3
        let dailyCalories = profile.dailyCalorieTarget
        let dailyProtein = profile.dailyProteinTarget
        let dailyCarbs = profile.dailyCarbTarget
        let dailyFat = profile.dailyFatTarget

        var windows: [MealWindow] = []

        switch mealsPerDay {
        case 2:
            windows = generateTwoMealWindows(
                wakeTime: wakeTime,
                sleepTime: sleepTime,
                calories: dailyCalories,
                protein: dailyProtein,
                carbs: dailyCarbs,
                fat: dailyFat,
                date: date
            )
        case 3:
            windows = generateThreeMealWindows(
                wakeTime: wakeTime,
                sleepTime: sleepTime,
                calories: dailyCalories,
                protein: dailyProtein,
                carbs: dailyCarbs,
                fat: dailyFat,
                date: date
            )
        case 4, 5:
            windows = generateFourPlusMealWindows(
                wakeTime: wakeTime,
                sleepTime: sleepTime,
                calories: dailyCalories,
                protein: dailyProtein,
                carbs: dailyCarbs,
                fat: dailyFat,
                mealsPerDay: mealsPerDay,
                date: date
            )
        default:
            windows = generateThreeMealWindows(
                wakeTime: wakeTime,
                sleepTime: sleepTime,
                calories: dailyCalories,
                protein: dailyProtein,
                carbs: dailyCarbs,
                fat: dailyFat,
                date: date
            )
        }

        return windows
    }

    // MARK: - Sample Meal Generation

    /// Generate sample logged meals that would fit within the windows
    func generateSampleMeals(for windows: [MealWindow], profile: UserProfile) -> [LoggedMeal] {
        var meals: [LoggedMeal] = []

        for (index, window) in windows.enumerated() {
            // Generate 1-2 meals per window for demo
            let mealCount = index == 0 ? 1 : (index == windows.count - 1 ? 1 : Int.random(in: 1...2))

            for mealIndex in 0..<mealCount {
                let meal = generateSampleMeal(
                    for: window,
                    index: mealIndex,
                    totalInWindow: mealCount,
                    profile: profile
                )
                meals.append(meal)
            }
        }

        return meals
    }

    // MARK: - Private Helpers

    private func normalizedTimeToday(from date: Date?, defaultHour: Int, on referenceDate: Date) -> Date {
        let sourceDate = date ?? calendar.date(bySettingHour: defaultHour, minute: 0, second: 0, of: referenceDate)!

        var components = calendar.dateComponents([.hour, .minute], from: sourceDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)

        components.year = todayComponents.year
        components.month = todayComponents.month
        components.day = todayComponents.day

        return calendar.date(from: components) ?? referenceDate
    }

    private func generateTwoMealWindows(
        wakeTime: Date,
        sleepTime: Date,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        date: Date
    ) -> [MealWindow] {
        // Brunch and Dinner
        let brunchStart = calendar.date(byAdding: .hour, value: 3, to: wakeTime)!
        let brunchEnd = calendar.date(byAdding: .hour, value: 2, to: brunchStart)!

        let dinnerStart = calendar.date(byAdding: .hour, value: -4, to: sleepTime)!
        let dinnerEnd = calendar.date(byAdding: .hour, value: 2, to: dinnerStart)!

        return [
            MealWindow(
                id: UUID(),
                name: "Brunch",
                startTime: brunchStart,
                endTime: brunchEnd,
                targetCalories: Int(Double(calories) * 0.45),
                targetProtein: Int(Double(protein) * 0.45),
                targetCarbs: Int(Double(carbs) * 0.45),
                targetFat: Int(Double(fat) * 0.45),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                type: .regular
            ),
            MealWindow(
                id: UUID(),
                name: "Dinner",
                startTime: dinnerStart,
                endTime: dinnerEnd,
                targetCalories: Int(Double(calories) * 0.55),
                targetProtein: Int(Double(protein) * 0.55),
                targetCarbs: Int(Double(carbs) * 0.55),
                targetFat: Int(Double(fat) * 0.55),
                purpose: .recovery,
                flexibility: .moderate,
                type: .regular
            )
        ]
    }

    private func generateThreeMealWindows(
        wakeTime: Date,
        sleepTime: Date,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        date: Date
    ) -> [MealWindow] {
        // Breakfast, Lunch, Dinner
        let breakfastStart = calendar.date(byAdding: .minute, value: 30, to: wakeTime)!
        let breakfastEnd = calendar.date(byAdding: .hour, value: 1, to: breakfastStart)!

        let lunchStart = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date)!
        let lunchEnd = calendar.date(byAdding: .hour, value: 1, to: lunchStart)!

        let dinnerStart = calendar.date(byAdding: .hour, value: -4, to: sleepTime)!
        let dinnerEnd = calendar.date(byAdding: .hour, value: 1, to: dinnerStart)!

        return [
            MealWindow(
                id: UUID(),
                name: "Breakfast",
                startTime: breakfastStart,
                endTime: breakfastEnd,
                targetCalories: Int(Double(calories) * 0.25),
                targetProtein: Int(Double(protein) * 0.25),
                targetCarbs: Int(Double(carbs) * 0.30),
                targetFat: Int(Double(fat) * 0.25),
                purpose: .metabolicBoost,
                flexibility: .moderate,
                type: .regular
            ),
            MealWindow(
                id: UUID(),
                name: "Lunch",
                startTime: lunchStart,
                endTime: lunchEnd,
                targetCalories: Int(Double(calories) * 0.35),
                targetProtein: Int(Double(protein) * 0.35),
                targetCarbs: Int(Double(carbs) * 0.35),
                targetFat: Int(Double(fat) * 0.35),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                type: .regular
            ),
            MealWindow(
                id: UUID(),
                name: "Dinner",
                startTime: dinnerStart,
                endTime: dinnerEnd,
                targetCalories: Int(Double(calories) * 0.40),
                targetProtein: Int(Double(protein) * 0.40),
                targetCarbs: Int(Double(carbs) * 0.35),
                targetFat: Int(Double(fat) * 0.40),
                purpose: .recovery,
                flexibility: .moderate,
                type: .regular
            )
        ]
    }

    private func generateFourPlusMealWindows(
        wakeTime: Date,
        sleepTime: Date,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        mealsPerDay: Int,
        date: Date
    ) -> [MealWindow] {
        // Breakfast, Morning Snack, Lunch, Afternoon Snack (optional), Dinner
        var windows: [MealWindow] = []

        let breakfastStart = calendar.date(byAdding: .minute, value: 30, to: wakeTime)!
        let breakfastEnd = calendar.date(byAdding: .hour, value: 1, to: breakfastStart)!

        windows.append(MealWindow(
            id: UUID(),
            name: "Breakfast",
            startTime: breakfastStart,
            endTime: breakfastEnd,
            targetCalories: Int(Double(calories) * 0.20),
            targetProtein: Int(Double(protein) * 0.20),
            targetCarbs: Int(Double(carbs) * 0.25),
            targetFat: Int(Double(fat) * 0.20),
            purpose: .metabolicBoost,
            flexibility: .moderate,
            type: .regular
        ))

        let snack1Start = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: date)!
        let snack1End = calendar.date(byAdding: .minute, value: 30, to: snack1Start)!

        windows.append(MealWindow(
            id: UUID(),
            name: "Morning Snack",
            startTime: snack1Start,
            endTime: snack1End,
            targetCalories: Int(Double(calories) * 0.10),
            targetProtein: Int(Double(protein) * 0.10),
            targetCarbs: Int(Double(carbs) * 0.10),
            targetFat: Int(Double(fat) * 0.10),
            purpose: .sustainedEnergy,
            flexibility: .flexible,
            type: .regular
        ))

        let lunchStart = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date)!
        let lunchEnd = calendar.date(byAdding: .hour, value: 1, to: lunchStart)!

        windows.append(MealWindow(
            id: UUID(),
            name: "Lunch",
            startTime: lunchStart,
            endTime: lunchEnd,
            targetCalories: Int(Double(calories) * 0.30),
            targetProtein: Int(Double(protein) * 0.30),
            targetCarbs: Int(Double(carbs) * 0.30),
            targetFat: Int(Double(fat) * 0.30),
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            type: .regular
        ))

        if mealsPerDay >= 5 {
            let snack2Start = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: date)!
            let snack2End = calendar.date(byAdding: .minute, value: 30, to: snack2Start)!

            windows.append(MealWindow(
                id: UUID(),
                name: "Afternoon Snack",
                startTime: snack2Start,
                endTime: snack2End,
                targetCalories: Int(Double(calories) * 0.10),
                targetProtein: Int(Double(protein) * 0.10),
                targetCarbs: Int(Double(carbs) * 0.10),
                targetFat: Int(Double(fat) * 0.10),
                purpose: .sustainedEnergy,
                flexibility: .flexible,
                type: .regular
            ))
        }

        let dinnerStart = calendar.date(byAdding: .hour, value: -4, to: sleepTime)!
        let dinnerEnd = calendar.date(byAdding: .hour, value: 1, to: dinnerStart)!

        let remainingCaloriePercent = mealsPerDay >= 5 ? 0.30 : 0.40

        windows.append(MealWindow(
            id: UUID(),
            name: "Dinner",
            startTime: dinnerStart,
            endTime: dinnerEnd,
            targetCalories: Int(Double(calories) * remainingCaloriePercent),
            targetProtein: Int(Double(protein) * remainingCaloriePercent),
            targetCarbs: Int(Double(carbs) * remainingCaloriePercent - 0.05),
            targetFat: Int(Double(fat) * remainingCaloriePercent),
            purpose: .recovery,
            flexibility: .moderate,
            type: .regular
        ))

        return windows
    }

    private func generateSampleMeal(
        for window: MealWindow,
        index: Int,
        totalInWindow: Int,
        profile: UserProfile
    ) -> LoggedMeal {
        // Sample meal names based on window name and user preferences
        let mealName = getSampleMealName(for: window, index: index, profile: profile)

        // Calculate portion of window's targets
        let portionMultiplier = 1.0 / Double(totalInWindow)
        let calories = Int(Double(window.targetCalories) * portionMultiplier * Double.random(in: 0.85...1.15))
        let protein = Int(Double(window.targetProtein) * portionMultiplier * Double.random(in: 0.85...1.15))
        let carbs = Int(Double(window.targetCarbs) * portionMultiplier * Double.random(in: 0.85...1.15))
        let fat = Int(Double(window.targetFat) * portionMultiplier * Double.random(in: 0.85...1.15))

        // Random timestamp within window
        let timeRange = window.endTime.timeIntervalSince(window.startTime)
        let randomOffset = TimeInterval.random(in: 0...(timeRange * 0.8))
        let timestamp = window.startTime.addingTimeInterval(randomOffset)

        return LoggedMeal(
            id: UUID(),
            name: mealName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            windowId: UUID(uuidString: window.id)
        )
    }

    private func getSampleMealName(for window: MealWindow, index: Int, profile: UserProfile) -> String {
        // Check for dietary preferences
        let isVegetarian = profile.dietaryRestrictions.contains { $0.lowercased().contains("vegetarian") }
        let isVegan = profile.dietaryRestrictions.contains { $0.lowercased().contains("vegan") }

        switch window.name.lowercased() {
        case let name where name.contains("breakfast"):
            if isVegan {
                return ["Oatmeal with Berries", "Avocado Toast", "Smoothie Bowl"][index % 3]
            } else if isVegetarian {
                return ["Greek Yogurt Parfait", "Eggs & Toast", "Protein Pancakes"][index % 3]
            } else {
                return ["Eggs & Bacon", "Protein Oatmeal", "Breakfast Burrito"][index % 3]
            }

        case let name where name.contains("lunch"):
            if isVegan {
                return ["Buddha Bowl", "Veggie Wrap", "Quinoa Salad"][index % 3]
            } else if isVegetarian {
                return ["Caprese Sandwich", "Greek Salad", "Veggie Stir-fry"][index % 3]
            } else {
                return ["Grilled Chicken Salad", "Turkey Sandwich", "Salmon Bowl"][index % 3]
            }

        case let name where name.contains("dinner"):
            if isVegan {
                return ["Tofu Stir-fry", "Lentil Curry", "Veggie Pasta"][index % 3]
            } else if isVegetarian {
                return ["Pasta Primavera", "Vegetable Curry", "Cheese Quesadilla"][index % 3]
            } else {
                return ["Grilled Salmon", "Chicken & Rice", "Steak & Vegetables"][index % 3]
            }

        case let name where name.contains("snack"):
            if isVegan {
                return ["Trail Mix", "Apple & Almond Butter", "Hummus & Veggies"][index % 3]
            } else {
                return ["Greek Yogurt", "Protein Bar", "Cheese & Crackers"][index % 3]
            }

        case let name where name.contains("brunch"):
            if isVegan {
                return ["Avocado Toast & Smoothie", "Tofu Scramble"][index % 2]
            } else {
                return ["Eggs Benedict", "Pancakes & Bacon", "Omelette"][index % 3]
            }

        default:
            return "Balanced Meal"
        }
    }
}
