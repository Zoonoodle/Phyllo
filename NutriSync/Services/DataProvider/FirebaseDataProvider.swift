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
        Task { @MainActor in
            DebugLogger.shared.dataProvider("FirebaseDataProvider.saveMeal called")
            DebugLogger.shared.logMeal(meal, action: "Attempting to save")
        }
        
        let mealRef = userRef.collection("meals").document(meal.id.uuidString)
        let docPath = "users/\(currentUserId)/meals/\(meal.id.uuidString)"
        Task { @MainActor in
            DebugLogger.shared.firebase("Writing meal to Firestore: \(docPath)")
        }
        
        try await mealRef.setData(meal.toFirestore())
        
        Task { @MainActor in
            DebugLogger.shared.success("Meal saved to Firebase: \(meal.name)")
        }
        
        // Update daily analytics
        await updateDailyAnalyticsForMeal(meal)
    }
    
    func getMeals(for date: Date) async throws -> [LoggedMeal] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        Task { @MainActor in
            DebugLogger.shared.dataProvider("FirebaseDataProvider.getMeals for date: \(dateFormatter.string(from: date))")
        }
        
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
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Retrieved \(meals.count) meals from Firebase")
        }
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
        // Fetch active analyzing meals (do not auto-delete; we want the banner to show)
        let snapshot = try await userRef.collection("analyzingMeals")
            .whereField("status", isEqualTo: "analyzing")
            .getDocuments()
        
        let meals = snapshot.documents.compactMap { AnalyzingMeal.fromFirestore($0.data()) }
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Loaded \(meals.count) analyzing meals")
        }
        return meals
    }
    
    func startAnalyzingMeal(_ meal: AnalyzingMeal) async throws {
        Task { @MainActor in
            DebugLogger.shared.dataProvider("FirebaseDataProvider.startAnalyzingMeal called")
            DebugLogger.shared.logAnalyzingMeal(meal, action: "Starting analysis")
        }
        
        let analyzingRef = userRef.collection("analyzingMeals").document(meal.id.uuidString)
        let docPath = "users/\(currentUserId)/analyzingMeals/\(meal.id.uuidString)"
        Task { @MainActor in
            DebugLogger.shared.firebase("Writing analyzing meal to Firestore: \(docPath)")
        }
        
        var data = meal.toFirestore()
        data["status"] = "analyzing" // Add status field for future compatibility
        try await analyzingRef.setData(data)
        
        Task { @MainActor in
            DebugLogger.shared.success("Analyzing meal started in Firebase")
        }
    }
    
    func completeAnalyzingMeal(id: String, result: MealAnalysisResult) async throws -> LoggedMeal {
        Task { @MainActor in
            DebugLogger.shared.dataProvider("FirebaseDataProvider.completeAnalyzingMeal called")
            DebugLogger.shared.mealAnalysis("Completing analysis for: \(result.mealName) (ID: \(id))")
        }
        
        // First, get the analyzing meal to preserve its timestamp and windowId
        let analyzingDoc = try await userRef.collection("analyzingMeals").document(id).getDocument()
        guard let analyzingData = analyzingDoc.data(),
              let analyzingMeal = AnalyzingMeal.fromFirestore(analyzingData) else {
            Task { @MainActor in
                DebugLogger.shared.error("Analyzing meal not found: \(id)")
            }
            throw NSError(domain: "FirebaseDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Analyzing meal not found"])
        }
        
        Task { @MainActor in
            DebugLogger.shared.logAnalyzingMeal(analyzingMeal, action: "Found analyzing meal")
        }
        
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
        
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Adding micronutrients to meal: \(micronutrients)")
        }
        
        // Add ingredients
        meal.ingredients = result.ingredients.map { ingredient in
            MealIngredient(
                name: ingredient.name,
                quantity: Double(ingredient.amount) ?? 1.0,
                unit: ingredient.unit,
                foodGroup: FoodGroup(rawValue: ingredient.foodGroup) ?? .other
            )
        }
        
        // Attach captured image from analyzing doc if present (we store size only; image lives client-side). If client provided one during capture,
        // it should already be on the AnalyzingMeal instance passed to the service; saving is handled by update after completion.
        
        // Save the meal (includes appliedClarifications if set via update later)
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Saving completed meal")
        }
        try await saveMeal(meal)
        
        // Delete from analyzing collection
        Task { @MainActor in
            DebugLogger.shared.firebase("Deleting analyzing meal from Firebase: \(id)")
        }
        try await userRef.collection("analyzingMeals").document(id).delete()
        
        Task { @MainActor in
            DebugLogger.shared.success("Meal analysis completed and saved")
        }
        
        return meal
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
        // Use start of day for querying by dayDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Querying windows for dayDate: \(startOfDay)")
        }
        
        // Query windows by dayDate field (single field query, no index needed)
        let snapshot = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: startOfDay)
            .getDocuments()
        
        // Avoid capturing Firestore snapshot (non-Sendable) across actor boundaries
        let docCount = snapshot.documents.count
        let firstDocDescription: String? = docCount > 0 ? String(describing: snapshot.documents[0].data()) : nil
        await MainActor.run {
            DebugLogger.shared.firebase("Found \(docCount) documents in windows collection")
            if let firstDocDescription {
                DebugLogger.shared.firebase("First document data: \(firstDocDescription)")
            }
        }
        
        // Convert and sort windows
        let windows = snapshot.documents.compactMap { doc -> MealWindow? in
            let data = doc.data()
            let window = MealWindow.fromFirestore(data)
            if window == nil {
                let bad = String(describing: data)
                Task { @MainActor in
                    DebugLogger.shared.warning("Failed to parse window document: \(bad)")
                }
            }
            return window
        }
        
        let parsedCount = windows.count
        await MainActor.run {
            DebugLogger.shared.firebase("Successfully parsed \(parsedCount) windows from Firebase for date: \(date)")
        }
        
        return windows.sorted { $0.startTime < $1.startTime }
    }
    
    func updateWindow(_ window: MealWindow) async throws {
        let windowRef = userRef.collection("windows").document(window.id.uuidString)
        try await windowRef.updateData(window.toFirestore())
    }
    
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow] {
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Generating daily windows for date: \(date)")
        }
        
        // Use proper window generation service
        let windowGenerator = WindowGenerationService.shared
        let windows = windowGenerator.generateWindows(
            for: date,
            profile: profile,
            checkIn: checkIn
        )
        
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Generated \(windows.count) windows")
        }
        // Phase 1 follow-up: clear existing windows for the day before saving new ones
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let existing = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: startOfDay)
            .getDocuments()
        if !existing.documents.isEmpty {
            let batch = db.batch()
            for doc in existing.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
            Task { @MainActor in
                DebugLogger.shared.firebase("Deleted \(existing.documents.count) existing windows for dayDate: \(startOfDay)")
            }
        }

        // Save all windows to Firestore
        for window in windows {
            Task { @MainActor in
                DebugLogger.shared.firebase("Saving window: \(window.purpose.rawValue) (\(window.startTime) - \(window.endTime))")
            }
            try await saveWindow(window)
        }
        
        Task { @MainActor in
            DebugLogger.shared.success("All \(windows.count) windows saved to Firebase")
        }
        
        return windows
    }
    
    func redistributeWindows(for date: Date) async throws {
        let windows = try await getWindows(for: date)
        let meals = try await getMeals(for: date)
        guard let profile = try await getUserProfile() else { return }
        
        // Use WindowRedistributionManager instance
        let redistributionManager = WindowRedistributionManager.shared
        let redistributed = redistributionManager.redistributeWindows(
            allWindows: windows,
            consumedMeals: meals,
            userProfile: profile,
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
        try await checkInRef.setData([
            "id": checkIn.id.uuidString,
            "date": checkIn.date,
            "wakeTime": checkIn.wakeTime,
            "sleepQuality": checkIn.sleepQuality,
            "sleepDuration": checkIn.sleepDuration,
            "energyLevel": checkIn.energyLevel,
            "plannedActivities": checkIn.plannedActivities,
            "hungerLevel": checkIn.hungerLevel
        ])
    }
    
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        let doc = try await userRef.collection("checkIns").document("morning").collection("data").document(dateString).getDocument()
        guard let data = doc.data() else { return nil }
        // Map Firestore fields back to model
        let id = (data["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
        let dateVal = (data["date"] as? Timestamp)?.dateValue() ?? date
        let wake = (data["wakeTime"] as? Timestamp)?.dateValue() ?? Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: dateVal)!
        let sleepQuality = data["sleepQuality"] as? Int ?? 7
        let sleepDuration = data["sleepDuration"] as? TimeInterval ?? 7.5 * 3600
        let energyLevel = data["energyLevel"] as? Int ?? 3
        let planned = data["plannedActivities"] as? [String] ?? []
        let hunger = data["hungerLevel"] as? Int ?? 3
        return MorningCheckInData(id: id, date: dateVal, wakeTime: wake, sleepQuality: sleepQuality, sleepDuration: sleepDuration, energyLevel: energyLevel, plannedActivities: planned, hungerLevel: hunger)
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
            let data = doc.data()
            guard let _ = data["id"] as? String,
                  let mealId = data["mealId"] as? String,
                  let mealName = data["mealName"] as? String,
                  let _ = data["timestamp"] as? Timestamp,
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
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Fetching user profile from Firebase")
        }
        
        let doc = try await userRef.collection("profile").document("current").getDocument()
        
        if let data = doc.data() {
            Task { @MainActor in
                DebugLogger.shared.success("User profile found in Firebase")
            }
            return UserProfile.fromFirestore(data)
        } else {
            Task { @MainActor in
                DebugLogger.shared.warning("No user profile in Firebase, creating default profile")
            }
            // Create and save a default profile
            let defaultProfile = UserProfile(
                id: UUID(),
                name: "User",
                age: 30,
                gender: .male,
                height: 70, // inches
                weight: 170, // lbs
                activityLevel: .moderate,
                primaryGoal: .performanceFocus,
                dietaryPreferences: [],
                dietaryRestrictions: [],
                dailyCalorieTarget: 2400,
                dailyProteinTarget: 110,
                dailyCarbTarget: 270,
                dailyFatTarget: 85,
                preferredMealTimes: [],
                micronutrientPriorities: ["Vitamin D", "Magnesium", "Omega-3"]
            )
            try await saveUserProfile(defaultProfile)
            return defaultProfile
        }
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
        // Use start of day to match how we save dayDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let listener = userRef.collection("windows")
            .whereField("dayDate", isEqualTo: startOfDay)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let windows = documents.compactMap { MealWindow.fromFirestore($0.data()) }
                    .sorted { $0.startTime < $1.startTime }  // Sort in memory instead of query
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
    
    // MARK: - Clear All Data
    
    /// Clears ALL user data from Firebase - USE WITH CAUTION
    func clearAllUserData() async throws {
        Task { @MainActor in
            DebugLogger.shared.warning("Starting complete Firebase data deletion for user: \(currentUserId)")
        }
        
        // Collections to clear
        let collections = [
            "meals",
            "windows",
            "analyzingMeals"
        ]
        
        // Clear each collection
        for collectionName in collections {
            let snapshot = try await userRef.collection(collectionName).getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared \(snapshot.documents.count) documents from \(collectionName)")
            }
        }
        
        // Clear profile
        let profileDoc = userRef.collection("profile").document("current")
        let profileExists = try await profileDoc.getDocument().exists
        if profileExists {
            try await profileDoc.delete()
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared user profile")
            }
        }
        
        // Clear check-ins (nested collections)
        // Morning check-ins
        let morningCheckIns = try await userRef.collection("checkIns").document("morning").collection("data").getDocuments()
        for doc in morningCheckIns.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(morningCheckIns.documents.count) morning check-ins")
        }
        
        // Post-meal check-ins
        let postMealCheckIns = try await userRef.collection("checkIns").document("postMeal").collection("data").getDocuments()
        for doc in postMealCheckIns.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(postMealCheckIns.documents.count) post-meal check-ins")
        }
        
        // Clear analytics
        let analyticsData = try await userRef.collection("analytics").document("daily").collection("data").getDocuments()
        for doc in analyticsData.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(analyticsData.documents.count) analytics entries")
        }
        
        Task { @MainActor in
            DebugLogger.shared.success("Successfully cleared ALL Firebase data for user: \(currentUserId)")
        }
    }
}

// Removed duplicate ISO8601DateFormatter.yyyyMMdd extension (defined in NotificationManager)

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

// UserProfile extensions moved to UserProfile.swift

// UserGoals extension removed - goals are part of UserProfile