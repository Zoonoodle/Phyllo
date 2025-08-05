import Foundation
import Combine

// MARK: - Mock Data Provider
/// Mock implementation wrapping the existing MockDataManager
class MockDataProvider: DataProvider {
    private let mockManager = MockDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Meal Operations
    
    func saveMeal(_ meal: LoggedMeal) async throws {
        await MainActor.run {
            // Add the meal to todaysMeals
            mockManager.todaysMeals.append(meal)
        }
    }
    
    func getMeals(for date: Date) async throws -> [LoggedMeal] {
        await MainActor.run {
            mockManager.todaysMeals
        }
    }
    
    func getMeal(id: String) async throws -> LoggedMeal? {
        await MainActor.run {
            mockManager.todaysMeals.first { $0.id.uuidString == id }
        }
    }
    
    func updateMeal(_ meal: LoggedMeal) async throws {
        await MainActor.run {
            if let index = mockManager.todaysMeals.firstIndex(where: { $0.id == meal.id }) {
                mockManager.todaysMeals[index] = meal
            }
        }
    }
    
    func deleteMeal(id: String) async throws {
        await MainActor.run {
            mockManager.todaysMeals.removeAll { $0.id.uuidString == id }
        }
    }
    
    func getAnalyzingMeals() async throws -> [AnalyzingMeal] {
        await MainActor.run {
            mockManager.analyzingMeals
        }
    }
    
    func startAnalyzingMeal(_ meal: AnalyzingMeal) async throws {
        await MainActor.run {
            mockManager.startAnalyzingMeal(imageData: meal.imageData)
        }
    }
    
    func completeAnalyzingMeal(id: String, result: MealAnalysisResult) async throws {
        await MainActor.run {
            // Create meal from result
            let meal = LoggedMeal(
                name: result.mealName,
                calories: result.nutrition.calories,
                protein: Int(result.nutrition.protein),
                carbs: Int(result.nutrition.carbs),
                fat: Int(result.nutrition.fat),
                timestamp: Date()
            )
            
            // Complete the analyzing meal
            if let analyzingMeal = mockManager.analyzingMeals.first(where: { $0.id.uuidString == id }) {
                mockManager.completeAnalyzingMeal(analyzingMeal, with: meal)
            }
        }
    }
    
    // MARK: - Window Operations
    
    func saveWindow(_ window: MealWindow) async throws {
        await MainActor.run {
            if let index = mockManager.mealWindows.firstIndex(where: { $0.id == window.id }) {
                mockManager.mealWindows[index] = window
            } else {
                mockManager.mealWindows.append(window)
            }
        }
    }
    
    func getWindows(for date: Date) async throws -> [MealWindow] {
        await MainActor.run {
            mockManager.mealWindows
        }
    }
    
    func updateWindow(_ window: MealWindow) async throws {
        await MainActor.run {
            if let index = mockManager.mealWindows.firstIndex(where: { $0.id == window.id }) {
                mockManager.mealWindows[index] = window
            }
        }
    }
    
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow] {
        await MainActor.run {
            // Generate windows based on profile and check-in
            let windows = MealWindow.mockWindows(
                for: profile.primaryGoal,
                checkIn: checkIn ?? MorningCheckInData.mockData,
                userProfile: profile
            )
            mockManager.mealWindows = windows
            return windows
        }
    }
    
    func redistributeWindows(for date: Date) async throws {
        await MainActor.run {
            // Redistribute windows - this is a private method in MockDataManager
            // For now, we'll just regenerate them
            let profile = UserProfile.mockProfile
            let windows = MealWindow.mockWindows(
                for: profile.primaryGoal,
                checkIn: mockManager.morningCheckIn,
                userProfile: profile
            )
            mockManager.mealWindows = windows
        }
    }
    
    // MARK: - Check-In Operations
    
    func saveMorningCheckIn(_ checkIn: MorningCheckInData) async throws {
        await MainActor.run {
            mockManager.morningCheckIn = checkIn
        }
    }
    
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData? {
        await MainActor.run {
            mockManager.morningCheckIn
        }
    }
    
    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) async throws {
        await MainActor.run {
            // MockDataManager doesn't have post-meal check-ins yet
            // This would be stored in a new array
        }
    }
    
    func getPostMealCheckIns(for date: Date) async throws -> [PostMealCheckIn] {
        // MockDataManager doesn't track these yet
        return []
    }
    
    func getPendingPostMealCheckIns() async throws -> [PostMealCheckIn] {
        await MainActor.run {
            // Create pending check-ins for meals logged >30 minutes ago
            let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
            return mockManager.todaysMeals
                .filter { $0.timestamp < thirtyMinutesAgo }
                .map { meal in
                    PostMealCheckIn(
                        mealId: meal.id.uuidString,
                        mealName: meal.name,
                        energyLevel: .moderate,
                        fullnessLevel: .full,
                        moodFocus: .neutral
                    )
                }
        }
    }
    
    // MARK: - User Profile Operations
    
    func getUserProfile() async throws -> UserProfile? {
        await MainActor.run {
            UserProfile.mockProfile
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        // MockDataManager uses a static profile
        // In a real mock, this would update the stored profile
    }
    
    // UserGoals methods removed - goals are part of UserProfile
    
    // MARK: - Analytics Operations
    
    func getDailyAnalytics(for date: Date) async throws -> DailyAnalytics? {
        await MainActor.run {
            let meals = mockManager.todaysMeals
            let windows = mockManager.mealWindows
            
            let totalCalories = meals.reduce(0) { $0 + $1.calories }
            let totalProtein = meals.reduce(0.0) { $0 + Double($1.protein) }
            let totalCarbs = meals.reduce(0.0) { $0 + Double($1.carbs) }
            let totalFat = meals.reduce(0.0) { $0 + Double($1.fat) }
            
            let completedWindows = windows.filter { window in
                meals.contains { $0.windowId == window.id }
            }.count
            
            let missedWindows = windows.filter { window in
                window.isPast && !meals.contains { $0.windowId == window.id }
            }.count
            
            return DailyAnalytics(
                date: date,
                totalCalories: totalCalories,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                mealsLogged: meals.count,
                windowsCompleted: completedWindows,
                windowsMissed: missedWindows,
                averageEnergyLevel: nil,
                micronutrientProgress: [:]
            )
        }
    }
    
    func getWeeklyAnalytics(for weekStart: Date) async throws -> WeeklyAnalytics? {
        // Simple mock weekly analytics
        let dailyAnalytics = try await getDailyAnalytics(for: Date())
        
        return WeeklyAnalytics(
            weekStartDate: weekStart,
            averageCalories: dailyAnalytics?.totalCalories ?? 0,
            averageProtein: dailyAnalytics?.totalProtein ?? 0,
            averageCarbs: dailyAnalytics?.totalCarbs ?? 0,
            averageFat: dailyAnalytics?.totalFat ?? 0,
            totalMealsLogged: (dailyAnalytics?.mealsLogged ?? 0) * 7,
            windowCompletionRate: 0.75,
            topMicronutrients: [:],
            energyTrend: [3.5, 3.8, 3.2, 4.0, 3.9, 3.6, 3.7],
            goalProgress: 0.68
        )
    }
    
    func updateDailyAnalytics(_ analytics: DailyAnalytics) async throws {
        // MockDataManager doesn't persist analytics
        // This would update stored analytics in a real implementation
    }
    
    // MARK: - Real-time Updates
    
    func observeMeals(for date: Date, onChange: @escaping ([LoggedMeal]) -> Void) -> ObservationToken {
        // Subscribe to MockDataManager's published properties
        let cancellable = mockManager.$todaysMeals
            .sink { meals in
                onChange(meals)
            }
        
        let token = UUID().uuidString
        var tokenCancellable: AnyCancellable? = cancellable
        
        return ObservationToken { [weak self] in
            tokenCancellable?.cancel()
            tokenCancellable = nil
        }
    }
    
    func observeWindows(for date: Date, onChange: @escaping ([MealWindow]) -> Void) -> ObservationToken {
        let cancellable = mockManager.$mealWindows
            .sink { windows in
                onChange(windows)
            }
        
        let token = UUID().uuidString
        var tokenCancellable: AnyCancellable? = cancellable
        
        return ObservationToken { [weak self] in
            tokenCancellable?.cancel()
            tokenCancellable = nil
        }
    }
    
    func observeAnalyzingMeals(onChange: @escaping ([AnalyzingMeal]) -> Void) -> ObservationToken {
        let cancellable = mockManager.$analyzingMeals
            .sink { meals in
                onChange(meals)
            }
        
        let token = UUID().uuidString
        var tokenCancellable: AnyCancellable? = cancellable
        
        return ObservationToken { [weak self] in
            tokenCancellable?.cancel()
            tokenCancellable = nil
        }
    }
}