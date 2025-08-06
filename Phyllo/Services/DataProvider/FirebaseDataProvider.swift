import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase Data Provider
/// Production implementation using Firebase Firestore
class FirebaseDataProvider: DataProvider {
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // Current user ID (will be replaced with Auth in Phase 8)
    private var currentUserId: String {
        // For now, use a development user ID
        // This will be replaced with: Auth.auth().currentUser?.uid ?? ""
        return "dev_user_001"
    }
    
    private var userRef: DocumentReference {
        db.collection("users").document(currentUserId)
    }
    
    // MARK: - Meal Operations
    
    func saveMeal(_ meal: LoggedMeal) async throws {
        DebugLogger.shared.dataProvider("FirebaseDataProvider.saveMeal called")
        DebugLogger.shared.logMeal(meal, action: "Attempting to save")
        
        let mealRef = userRef.collection("meals").document(meal.id.uuidString)
        let docPath = "users/\(currentUserId)/meals/\(meal.id.uuidString)"
        DebugLogger.shared.firebase("Writing meal to Firestore: \(docPath)")
        
        try await mealRef.setData(meal.toFirestore())
        
        DebugLogger.shared.success("Meal saved to Firebase: \(meal.name)")
        
        // Update daily analytics
        await updateDailyAnalyticsForMeal(meal)
    }
    
    func getMeals(for date: Date) async throws -> [LoggedMeal] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        DebugLogger.shared.dataProvider("FirebaseDataProvider.getMeals for date: \(dateFormatter.string(from: date))")
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await userRef.collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .order(by: "timestamp")
            .getDocuments()
        
        let meals = snapshot.documents.compactMap { doc in
            LoggedMeal.fromFirestore(doc.data())
        }
        
        DebugLogger.shared.firebase("Retrieved \(meals.count) meals from Firebase")
        return meals
    }
    
    func getMeal(id: String) async throws -> LoggedMeal? {
        let doc = try await userRef.collection("meals").document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return LoggedMeal.fromFirestore(data)
    }
    
    func updateMeal(_ meal: LoggedMeal) async throws {
        let mealRef = userRef.collection("meals").document(meal.id.uuidString)
        try await mealRef.updateData(meal.toFirestore())
        
        // Update analytics
        await updateDailyAnalyticsForMeal(meal)
    }
    
    func deleteMeal(id: String) async throws {
        try await userRef.collection("meals").document(id).delete()
        
        // TODO: Update analytics to reflect deletion
    }
    
    func getAnalyzingMeals() async throws -> [AnalyzingMeal] {
        // Get all analyzing meals
        let snapshot = try await userRef.collection("analyzingMeals")
            .getDocuments()
        
        // DELETE ALL analyzing meals - we don't want any old test data
        let allMeals = snapshot.documents.compactMap { doc in
            AnalyzingMeal.fromFirestore(doc.data())
        }
        
        // Delete ALL analyzing meals in the background
        if !allMeals.isEmpty {
            print("🧹 Cleaning up \(allMeals.count) old analyzing meals")
            Task {
                for meal in allMeals {
                    try? await userRef.collection("analyzingMeals").document(meal.id.uuidString).delete()
                }
                print("✅ Cleaned up all analyzing meals")
            }
        }
        
        // Return empty array - no analyzing meals should be shown on startup
        return []
    }
    
    func startAnalyzingMeal(_ meal: AnalyzingMeal) async throws {
        DebugLogger.shared.dataProvider("FirebaseDataProvider.startAnalyzingMeal called")
        DebugLogger.shared.logAnalyzingMeal(meal, action: "Starting analysis")
        
        let analyzingRef = userRef.collection("analyzingMeals").document(meal.id.uuidString)
        let docPath = "users/\(currentUserId)/analyzingMeals/\(meal.id.uuidString)"
        DebugLogger.shared.firebase("Writing analyzing meal to Firestore: \(docPath)")
        
        var data = meal.toFirestore()
        data["status"] = "analyzing" // Add status field for future compatibility
        try await analyzingRef.setData(data)
        
        DebugLogger.shared.success("Analyzing meal started in Firebase")
    }
    
    func completeAnalyzingMeal(id: String, result: MealAnalysisResult) async throws {
        DebugLogger.shared.dataProvider("FirebaseDataProvider.completeAnalyzingMeal called")
        DebugLogger.shared.mealAnalysis("Completing analysis for: \(result.mealName) (ID: \(id))")
        
        // First, get the analyzing meal to preserve its timestamp and windowId
        let analyzingDoc = try await userRef.collection("analyzingMeals").document(id).getDocument()
        guard let analyzingData = analyzingDoc.data(),
              let analyzingMeal = AnalyzingMeal.fromFirestore(analyzingData) else {
            DebugLogger.shared.error("Analyzing meal not found: \(id)")
            throw NSError(domain: "FirebaseDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Analyzing meal not found"])
        }
        
        DebugLogger.shared.logAnalyzingMeal(analyzingMeal, action: "Found analyzing meal")
        
        // Create the final meal with original timestamp and window
        var meal = LoggedMeal(
            name: result.mealName,
            calories: result.nutrition.calories,
            protein: Int(result.nutrition.protein),
            carbs: Int(result.nutrition.carbs),
            fat: Int(result.nutrition.fat),
            timestamp: analyzingMeal.timestamp,
            windowId: analyzingMeal.windowId
        )
        
        // Add micronutrients
        var micronutrients: [String: Double] = [:]
        for micro in result.micronutrients {
            micronutrients[micro.name] = micro.amount
        }
        meal.micronutrients = micronutrients
        
        // Add ingredients
        meal.ingredients = result.ingredients.map { ingredient in
            MealIngredient(
                name: ingredient.name,
                quantity: Double(ingredient.amount) ?? 1.0,
                unit: ingredient.unit,
                foodGroup: FoodGroup(rawValue: ingredient.foodGroup) ?? .other
            )
        }
        
        // Save the meal
        DebugLogger.shared.dataProvider("Saving completed meal")
        try await saveMeal(meal)
        
        // Delete from analyzing collection
        DebugLogger.shared.firebase("Deleting analyzing meal from Firebase: \(id)")
        try await userRef.collection("analyzingMeals").document(id).delete()
        
        DebugLogger.shared.success("Meal analysis completed and saved")
    }
    
    func cancelAnalyzingMeal(id: String) async throws {
        // Delete the analyzing meal
        try await userRef.collection("analyzingMeals").document(id).delete()
    }
    
    // MARK: - Window Operations
    
    func saveWindow(_ window: MealWindow) async throws {
        let windowRef = userRef.collection("windows").document(window.id.uuidString)
        try await windowRef.setData(window.toFirestore())
    }
    
    func getWindows(for date: Date) async throws -> [MealWindow] {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        
        // Simplified query without ordering to avoid index requirement
        let snapshot = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: dateString)
            .getDocuments()
        
        // Sort in memory instead
        let windows = snapshot.documents.compactMap { doc in
            MealWindow.fromFirestore(doc.data())
        }
        
        return windows.sorted { $0.startTime < $1.startTime }
    }
    
    func updateWindow(_ window: MealWindow) async throws {
        let windowRef = userRef.collection("windows").document(window.id.uuidString)
        try await windowRef.updateData(window.toFirestore())
    }
    
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow] {
        // Use MealWindow's mock generation for now
        // TODO: Implement proper window generation service
        let windows = MealWindow.mockWindows(
            for: profile.primaryGoal,
            checkIn: checkIn,
            userProfile: profile
        )
        
        // Save all windows to Firestore
        for window in windows {
            try await saveWindow(window)
        }
        
        return windows
    }
    
    func redistributeWindows(for date: Date) async throws {
        let windows = try await getWindows(for: date)
        let meals = try await getMeals(for: date)
        
        // Use WindowRedistributionManager instance
        let redistributionManager = WindowRedistributionManager.shared
        let redistributed = redistributionManager.redistributeWindows(
            allWindows: windows,
            consumedMeals: meals,
            userProfile: UserProfile.mockProfile, // TODO: Get actual profile
            currentTime: Date()
        ).map { $0.originalWindow }
        
        // Update all redistributed windows
        for window in redistributed {
            try await updateWindow(window)
        }
    }
    
    // MARK: - Check-In Operations
    
    func saveMorningCheckIn(_ checkIn: MorningCheckInData) async throws {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: checkIn.date)
        let checkInRef = userRef.collection("checkIns").document("morning").collection("data").document(dateString)
        try await checkInRef.setData(checkIn.toFirestore())
    }
    
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        let doc = try await userRef.collection("checkIns").document("morning").collection("data").document(dateString).getDocument()
        guard let data = doc.data() else { return nil }
        return MorningCheckInData.fromFirestore(data)
    }
    
    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) async throws {
        let checkInRef = userRef.collection("checkIns").document("postMeal").collection("data").document(checkIn.id.uuidString)
        try await checkInRef.setData([
            "id": checkIn.id.uuidString,
            "mealId": checkIn.mealId,
            "mealName": checkIn.mealName,
            "timestamp": checkIn.timestamp,
            "energyLevel": checkIn.energyLevel.rawValue,
            "fullnessLevel": checkIn.fullnessLevel.rawValue,
            "moodFocus": checkIn.moodFocus.rawValue
        ])
    }
    
    func getPostMealCheckIns(for date: Date) async throws -> [PostMealCheckIn] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await userRef.collection("checkIns").document("postMeal").collection("data")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> PostMealCheckIn? in
            guard let data = doc.data() as? [String: Any],
                  let id = data["id"] as? String,
                  let mealId = data["mealId"] as? String,
                  let mealName = data["mealName"] as? String,
                  let timestamp = data["timestamp"] as? Timestamp,
                  let energyLevel = data["energyLevel"] as? Int,
                  let fullnessLevel = data["fullnessLevel"] as? Int,
                  let moodFocus = data["moodFocus"] as? Int else { return nil }
            
            // Map integer values to enums
            let energy = PostMealCheckIn.EnergyLevel(rawValue: energyLevel) ?? .moderate
            let fullness = PostMealCheckIn.FullnessLevel(rawValue: fullnessLevel) ?? .satisfied
            let mood = MoodLevel(rawValue: moodFocus) ?? .neutral
            
            return PostMealCheckIn(
                mealId: mealId,
                mealName: mealName,
                energyLevel: energy,
                fullnessLevel: fullness,
                moodFocus: mood
            )
        }
    }
    
    func getPendingPostMealCheckIns() async throws -> [PostMealCheckIn] {
        // TODO: Implement logic to find meals without check-ins
        return []
    }
    
    // MARK: - User Profile Operations
    
    func getUserProfile() async throws -> UserProfile? {
        let doc = try await userRef.collection("profile").document("current").getDocument()
        guard let data = doc.data() else { return nil }
        return UserProfile.fromFirestore(data)
    }
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        try await userRef.collection("profile").document("current").setData(profile.toFirestore())
    }
    
    // UserGoals methods removed - goals are part of UserProfile
    
    // MARK: - Analytics Operations
    
    func getDailyAnalytics(for date: Date) async throws -> DailyAnalytics? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        let doc = try await userRef.collection("analytics").document("daily").collection("data").document(dateString).getDocument()
        
        guard let data = doc.data() else { return nil }
        
        return DailyAnalytics(
            date: date,
            totalCalories: data["totalCalories"] as? Int ?? 0,
            totalProtein: data["totalProtein"] as? Double ?? 0,
            totalCarbs: data["totalCarbs"] as? Double ?? 0,
            totalFat: data["totalFat"] as? Double ?? 0,
            mealsLogged: data["mealsLogged"] as? Int ?? 0,
            windowsCompleted: data["windowsCompleted"] as? Int ?? 0,
            windowsMissed: data["windowsMissed"] as? Int ?? 0,
            averageEnergyLevel: data["averageEnergyLevel"] as? Double,
            micronutrientProgress: data["micronutrientProgress"] as? [String: Double] ?? [:]
        )
    }
    
    func getWeeklyAnalytics(for weekStart: Date) async throws -> WeeklyAnalytics? {
        // TODO: Implement weekly analytics aggregation
        return nil
    }
    
    func updateDailyAnalytics(_ analytics: DailyAnalytics) async throws {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: analytics.date)
        let analyticsRef = userRef.collection("analytics").document("daily").collection("data").document(dateString)
        
        try await analyticsRef.setData([
            "date": analytics.date,
            "totalCalories": analytics.totalCalories,
            "totalProtein": analytics.totalProtein,
            "totalCarbs": analytics.totalCarbs,
            "totalFat": analytics.totalFat,
            "mealsLogged": analytics.mealsLogged,
            "windowsCompleted": analytics.windowsCompleted,
            "windowsMissed": analytics.windowsMissed,
            "averageEnergyLevel": analytics.averageEnergyLevel as Any,
            "micronutrientProgress": analytics.micronutrientProgress
        ])
    }
    
    // MARK: - Real-time Updates
    
    func observeMeals(for date: Date, onChange: @escaping ([LoggedMeal]) -> Void) -> ObservationToken {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let listener = userRef.collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let meals = documents.compactMap { LoggedMeal.fromFirestore($0.data()) }
                onChange(meals)
            }
        
        let token = UUID().uuidString
        listeners[token] = listener
        
        return ObservationToken { [weak self] in
            self?.listeners[token]?.remove()
            self?.listeners[token] = nil
        }
    }
    
    func observeWindows(for date: Date, onChange: @escaping ([MealWindow]) -> Void) -> ObservationToken {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        
        let listener = userRef.collection("windows")
            .whereField("dayDate", isEqualTo: dateString)
            .order(by: "startTime")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let windows = documents.compactMap { MealWindow.fromFirestore($0.data()) }
                onChange(windows)
            }
        
        let token = UUID().uuidString
        listeners[token] = listener
        
        return ObservationToken { [weak self] in
            self?.listeners[token]?.remove()
            self?.listeners[token] = nil
        }
    }
    
    func observeAnalyzingMeals(onChange: @escaping ([AnalyzingMeal]) -> Void) -> ObservationToken {
        let listener = userRef.collection("analyzingMeals")
            .whereField("status", isEqualTo: "analyzing")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let meals = documents.compactMap { AnalyzingMeal.fromFirestore($0.data()) }
                onChange(meals)
            }
        
        let token = UUID().uuidString
        listeners[token] = listener
        
        return ObservationToken { [weak self] in
            self?.listeners[token]?.remove()
            self?.listeners[token] = nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateDailyAnalyticsForMeal(_ meal: LoggedMeal) async {
        // TODO: Implement analytics update logic
        // This would aggregate meal data into daily totals
    }
}

// MARK: - Date Formatter Extension

extension ISO8601DateFormatter {
    static let yyyyMMdd: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()
}

// MARK: - Firestore Extensions

extension MorningCheckInData {
    func toFirestore() -> [String: Any] {
        return [
            "date": date,
            "wakeTime": wakeTime,
            "sleepQuality": sleepQuality,
            "sleepDuration": sleepDuration,
            "energyLevel": energyLevel,
            "plannedActivities": plannedActivities,
            "hungerLevel": hungerLevel,
            "completed": true
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> MorningCheckInData? {
        guard let date = data["date"] as? Timestamp,
              let wakeTime = data["wakeTime"] as? Date,
              let sleepQuality = data["sleepQuality"] as? Int,
              let sleepDuration = data["sleepDuration"] as? TimeInterval,
              let energyLevel = data["energyLevel"] as? Int,
              let plannedActivities = data["plannedActivities"] as? [String],
              let hungerLevel = data["hungerLevel"] as? Int else {
            return nil
        }
        
        return MorningCheckInData(
            date: date.dateValue(),
            wakeTime: wakeTime,
            sleepQuality: sleepQuality,
            sleepDuration: sleepDuration,
            energyLevel: energyLevel,
            plannedActivities: plannedActivities,
            hungerLevel: hungerLevel
        )
    }
}

extension UserProfile {
    func toFirestore() -> [String: Any] {
        // TODO: Implement based on actual UserProfile structure
        return [:]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserProfile? {
        // TODO: Implement based on actual UserProfile structure
        return UserProfile.mockProfile
    }
}

// UserGoals extension removed - goals are part of UserProfile