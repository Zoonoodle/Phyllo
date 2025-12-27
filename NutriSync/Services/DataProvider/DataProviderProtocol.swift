import Foundation
import UIKit
import FirebaseFirestore

// MARK: - Data Provider Protocol
/// Protocol defining all data operations for switching between Mock and Firebase implementations
protocol DataProvider {
    // MARK: - Meal Operations
    func saveMeal(_ meal: LoggedMeal) async throws
    func getMeals(for date: Date) async throws -> [LoggedMeal]
    func getMeal(id: String) async throws -> LoggedMeal?
    func updateMeal(_ meal: LoggedMeal) async throws
    func deleteMeal(id: String) async throws
    func getAnalyzingMeals() async throws -> [AnalyzingMeal]
    func startAnalyzingMeal(_ meal: AnalyzingMeal) async throws
    func completeAnalyzingMeal(id: String, result: MealAnalysisResult) async throws -> LoggedMeal
    func cancelAnalyzingMeal(id: String) async throws
    
    // MARK: - Window Operations
    func saveWindow(_ window: MealWindow) async throws
    func getWindows(for date: Date) async throws -> [MealWindow]
    func updateWindow(_ window: MealWindow) async throws
    func deleteWindow(id: String) async throws
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow]
    func redistributeWindows(for date: Date) async throws
    
    // MARK: - Check-In Operations
    func saveMorningCheckIn(_ checkIn: MorningCheckInData) async throws
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData?
    func saveDailySync(_ sync: DailySync) async throws
    func getDailySync(for date: Date) async throws -> DailySync?
    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) async throws
    func getPostMealCheckIns(for date: Date) async throws -> [PostMealCheckIn]
    func getPendingPostMealCheckIns() async throws -> [PostMealCheckIn]
    
    // MARK: - User Profile Operations
    func getUserProfile() async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
    func getUserGoals() async throws -> UserGoals?
    func saveUserGoals(_ goals: UserGoals) async throws
    
    // MARK: - Analytics Operations
    func getDailyAnalytics(for date: Date) async throws -> DailyAnalytics?
    func getWeeklyAnalytics(for weekStart: Date) async throws -> WeeklyAnalytics?
    func updateDailyAnalytics(_ analytics: DailyAnalytics) async throws
    func getDailyAnalyticsRange(from: Date, to: Date) async throws -> [DailyAnalytics]?
    func calculateStreak(until date: Date) async throws -> (current: Int, best: Int)
    func getMealsForDateRange(from: Date, to: Date) async throws -> [Date: [LoggedMeal]]
    func getWindowsForDateRange(from: Date, to: Date) async throws -> [Date: [MealWindow]]
    
    // MARK: - Weight Tracking Operations
    func saveWeightEntry(_ entry: WeightEntry) async throws
    func getRecentWeightEntries(userId: String, days: Int) async -> [WeightEntry]
    func getLatestWeightEntry(userId: String) async throws -> WeightEntry?
    
    // MARK: - Real-time Updates
    func observeMeals(for date: Date, onChange: @escaping ([LoggedMeal]) -> Void) -> ObservationToken
    func observeWindows(for date: Date, onChange: @escaping ([MealWindow]) -> Void) -> ObservationToken
    func observeAnalyzingMeals(onChange: @escaping ([AnalyzingMeal]) -> Void) -> ObservationToken
    
    // MARK: - Data Management
    /// Clears ALL user data - USE WITH CAUTION
    func clearAllUserData() async throws
}

// MARK: - Observation Token
/// Token for managing real-time observations
class ObservationToken {
    private let cancelHandler: () -> Void
    
    init(cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }
    
    func cancel() {
        cancelHandler()
    }
    
    deinit {
        cancel()
    }
}

// MARK: - Data Models for Firebase

/// Daily analytics summary
struct DailyAnalytics: Identifiable, Codable {
    let id: String
    let date: Date
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let mealsLogged: Int
    let targetMeals: Int
    let windowsCompleted: Int
    let totalWindows: Int
    let windowsMissed: Int
    let averageEnergyLevel: Double?
    let micronutrientProgress: [String: Double] // nutrient name -> percentage of RDA
    let timingScore: Double
    let nutrientScore: Double
    let adherenceScore: Double
    let caloriesConsumed: Int
    let targetCalories: Int
    
    var overallScore: Double {
        (timingScore + nutrientScore + adherenceScore) / 3
    }
    
    init(
        id: String = UUID().uuidString,
        date: Date,
        totalCalories: Int = 0,
        totalProtein: Double = 0,
        totalCarbs: Double = 0,
        totalFat: Double = 0,
        mealsLogged: Int = 0,
        targetMeals: Int = 5,
        windowsCompleted: Int = 0,
        totalWindows: Int = 5,
        windowsMissed: Int = 0,
        averageEnergyLevel: Double? = nil,
        micronutrientProgress: [String: Double] = [:],
        timingScore: Double = 0,
        nutrientScore: Double = 0,
        adherenceScore: Double = 0,
        caloriesConsumed: Int = 0,
        targetCalories: Int = 2400
    ) {
        self.id = id
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.mealsLogged = mealsLogged
        self.targetMeals = targetMeals
        self.windowsCompleted = windowsCompleted
        self.totalWindows = totalWindows
        self.windowsMissed = windowsMissed
        self.averageEnergyLevel = averageEnergyLevel
        self.micronutrientProgress = micronutrientProgress
        self.timingScore = timingScore
        self.nutrientScore = nutrientScore
        self.adherenceScore = adherenceScore
        self.caloriesConsumed = caloriesConsumed
        self.targetCalories = targetCalories
    }
}

/// Weekly analytics summary
struct WeeklyAnalytics: Codable {
    let weekStartDate: Date
    let averageCalories: Int
    let averageProtein: Double
    let averageCarbs: Double
    let averageFat: Double
    let totalMealsLogged: Int
    let windowCompletionRate: Double
    let topMicronutrients: [String: Double]
    let energyTrend: [Double] // Daily average energy levels
    let goalProgress: Double // 0-1
}

// MARK: - Firestore-Compatible Extensions

extension LoggedMeal {
    /// Convert to Firestore-compatible dictionary
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "timestamp": timestamp,
            "micronutrients": micronutrients,
            "appliedClarifications": appliedClarifications
        ]
        
        if let windowId = windowId {
            data["windowId"] = windowId.uuidString
        }
        
        if let imageData = imageData {
            data["imageData"] = imageData
        }
        
        // Serialize ingredients as array of dictionaries
        if !ingredients.isEmpty {
            data["ingredients"] = ingredients.map { ingredient in
                var dict: [String: Any] = [
                    "id": ingredient.id.uuidString,
                    "name": ingredient.name,
                    "quantity": ingredient.quantity,
                    "unit": ingredient.unit,
                    "foodGroup": ingredient.foodGroup.rawValue
                ]
                if let calories = ingredient.calories { dict["calories"] = calories }
                if let protein = ingredient.protein { dict["protein"] = protein }
                if let carbs = ingredient.carbs { dict["carbs"] = carbs }
                if let fat = ingredient.fat { dict["fat"] = fat }
                return dict
            }
        }
        
        return data
    }
    
    /// Initialize from Firestore document
    static func fromFirestore(_ data: [String: Any]) -> LoggedMeal? {
        guard let idString = data["id"] as? String,
              UUID(uuidString: idString) != nil,
              let name = data["name"] as? String,
              let calories = data["calories"] as? Int,
              let protein = data["protein"] as? Int,
              let carbs = data["carbs"] as? Int,
              let fat = data["fat"] as? Int else {
            return nil
        }
        
        // Handle Firestore Timestamp conversion
        guard let timestamp = (data["timestamp"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["timestamp"] as? Date) else {
            return nil
        }
        
        var meal = LoggedMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp
        )
        
        if let windowIdString = data["windowId"] as? String,
           let windowId = UUID(uuidString: windowIdString) {
            meal.windowId = windowId
        }
        
        // Parse micronutrients
        if let micronutrients = data["micronutrients"] as? [String: Double] {
            meal.micronutrients = micronutrients
        }
        
        // Parse image data
        if let imageData = data["imageData"] as? Data {
            meal.imageData = imageData
        }
        
        // Parse applied clarifications
        if let clar = data["appliedClarifications"] as? [String: String] {
            meal.appliedClarifications = clar
        }
        
        // Parse ingredients
        if let ingredientList = data["ingredients"] as? [[String: Any]] {
            meal.ingredients = ingredientList.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let quantity = dict["quantity"] as? Double,
                      let unit = dict["unit"] as? String,
                      let fgRaw = dict["foodGroup"] as? String,
                      let foodGroup = FoodGroup(rawValue: fgRaw) else {
                    return nil
                }
                var item = MealIngredient(
                    name: name,
                    quantity: quantity,
                    unit: unit,
                    foodGroup: foodGroup
                )
                item.calories = dict["calories"] as? Int
                item.protein = dict["protein"] as? Double
                item.carbs = dict["carbs"] as? Double
                item.fat = dict["fat"] as? Double
                return item
            }
        }
        
        return meal
    }
}

extension MealWindow {
    /// Convert to Firestore-compatible dictionary
    func toFirestore() -> [String: Any] {
        // IMPORTANT: Ensure dayDate is always startOfDay for consistent querying
        let calendar = Calendar.current
        let startOfDayDate = calendar.startOfDay(for: dayDate)
        
        var data: [String: Any] = [
            "id": id,
            "startTime": startTime,
            "endTime": endTime,
            "targetCalories": targetCalories,
            "targetProtein": targetMacros.protein,
            "targetCarbs": targetMacros.carbs,
            "targetFat": targetMacros.fat,
            "purpose": purpose.rawValue,
            "flexibility": flexibility.rawValue,
            "dayDate": startOfDayDate,  // Always use startOfDay for consistency
            "isMarkedAsFasted": isMarkedAsFasted
        ]
        
        // Add AI-generated fields if present
        data["name"] = name
        if let rationale = rationale { data["rationale"] = rationale }
        data["foodSuggestions"] = foodSuggestions
        data["micronutrientFocus"] = micronutrientFocus
        if let tips = tips { data["tips"] = tips }
        data["type"] = type.rawValue

        // Add smart suggestion fields
        data["smartSuggestions"] = smartSuggestions.map { $0.toFirestore() }
        if let generatedAt = suggestionsGeneratedAt {
            data["suggestionsGeneratedAt"] = generatedAt
        }
        data["suggestionStatus"] = suggestionStatus.rawValue
        if let contextNote = suggestionContextNote {
            data["suggestionContextNote"] = contextNote
        }

        if let adjustedCalories = adjustedCalories {
            data["adjustedCalories"] = adjustedCalories
        }

        if let reason = redistributionReason {
            // Convert RedistributionReason to a dictionary for Firestore
            switch reason {
            case .overconsumption(let percentOver):
                data["redistributionReason"] = ["type": "overconsumption", "percentOver": percentOver]
            case .underconsumption(let percentUnder):
                data["redistributionReason"] = ["type": "underconsumption", "percentUnder": percentUnder]
            case .missedWindow:
                data["redistributionReason"] = ["type": "missedWindow"]
            case .earlyConsumption:
                data["redistributionReason"] = ["type": "earlyConsumption"]
            case .lateConsumption:
                data["redistributionReason"] = ["type": "lateConsumption"]
            }
        }
        
        return data
    }
    
    /// Initialize from Firestore document
    static func fromFirestore(_ data: [String: Any]) -> MealWindow? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let targetCalories = data["targetCalories"] as? Int,
              let targetProtein = data["targetProtein"] as? Int,
              let targetCarbs = data["targetCarbs"] as? Int,
              let targetFat = data["targetFat"] as? Int,
              let purposeString = data["purpose"] as? String,
              let purpose = WindowPurpose(rawValue: purposeString),
              let flexibilityString = data["flexibility"] as? String,
              let flexibility = WindowFlexibility(rawValue: flexibilityString) else {
            return nil
        }
        
        // Handle Firestore Timestamp conversion
        // Firestore returns Timestamp objects, not Date objects
        let startTimeRaw = data["startTime"]
        _ = data["endTime"]
        
        // Debug logging
        if let startTimestamp = startTimeRaw as? FirebaseFirestore.Timestamp {
            let startDate = startTimestamp.dateValue()
            Task { @MainActor in
                DebugLogger.shared.info("Firestore window start timestamp: seconds=\(startTimestamp.seconds), date=\(startDate)")
            }
        }
        
        guard let startTime = (data["startTime"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["startTime"] as? Date),
              let endTime = (data["endTime"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["endTime"] as? Date),
              let dayDate = (data["dayDate"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["dayDate"] as? Date) else {
            return nil
        }
        
        // Parse AI-generated fields
        let name = data["name"] as? String
        let rationale = data["rationale"] as? String
        let foodSuggestions = data["foodSuggestions"] as? [String]
        let micronutrientFocus = data["micronutrientFocus"] as? [String]
        let tips = data["tips"] as? [String]
        let type = data["type"] as? String

        // Parse smart suggestion fields
        let smartSuggestionsData = data["smartSuggestions"] as? [[String: Any]] ?? []
        let smartSuggestions = smartSuggestionsData.compactMap { FoodSuggestion.fromFirestore($0) }

        let suggestionsGeneratedAt: Date?
        if let timestamp = data["suggestionsGeneratedAt"] as? FirebaseFirestore.Timestamp {
            suggestionsGeneratedAt = timestamp.dateValue()
        } else {
            suggestionsGeneratedAt = data["suggestionsGeneratedAt"] as? Date
        }

        let suggestionStatusString = data["suggestionStatus"] as? String ?? "pending"
        let suggestionStatus = SuggestionStatus(rawValue: suggestionStatusString) ?? .pending
        let suggestionContextNote = data["suggestionContextNote"] as? String

        // Create MealWindow with preserved ID from Firestore
        var window = MealWindow(
            id: id,  // Use the original ID from Firestore
            startTime: startTime,
            endTime: endTime,
            targetCalories: targetCalories,
            targetMacros: MacroTargets(
                protein: targetProtein,
                carbs: targetCarbs,
                fat: targetFat
            ),
            purpose: purpose,
            flexibility: flexibility,
            dayDate: dayDate,
            name: name,
            rationale: rationale,
            foodSuggestions: foodSuggestions,
            micronutrientFocus: micronutrientFocus,
            tips: tips,
            type: type,
            smartSuggestions: smartSuggestions,
            suggestionsGeneratedAt: suggestionsGeneratedAt,
            suggestionStatus: suggestionStatus,
            suggestionContextNote: suggestionContextNote
        )
        
        window.adjustedCalories = data["adjustedCalories"] as? Int
        window.isMarkedAsFasted = data["isMarkedAsFasted"] as? Bool ?? false
        
        if let reasonData = data["redistributionReason"] as? [String: Any],
           let type = reasonData["type"] as? String {
            switch type {
            case "overconsumption":
                if let percentOver = reasonData["percentOver"] as? Int {
                    window.redistributionReason = WindowRedistributionManager.RedistributionReason.overconsumption(percentOver: percentOver)
                }
            case "underconsumption":
                if let percentUnder = reasonData["percentUnder"] as? Int {
                    window.redistributionReason = WindowRedistributionManager.RedistributionReason.underconsumption(percentUnder: percentUnder)
                }
            case "missedWindow":
                window.redistributionReason = WindowRedistributionManager.RedistributionReason.missedWindow
            case "earlyConsumption":
                window.redistributionReason = WindowRedistributionManager.RedistributionReason.earlyConsumption
            case "lateConsumption":
                window.redistributionReason = WindowRedistributionManager.RedistributionReason.lateConsumption
            default:
                break
            }
        }
        
        return window
    }
}

// MARK: - Data Source Provider

/// Singleton for managing the active data provider
class DataSourceProvider {
    static let shared = DataSourceProvider()
    
    private var _provider: DataProvider?
    
    var provider: DataProvider {
        get {
            guard let provider = _provider else {
                fatalError("DataProvider not configured. Call configure() first.")
            }
            return provider
        }
        set {
            _provider = newValue
        }
    }
    
    private init() {}
    
    func configure(with provider: DataProvider) {
        self._provider = provider
        
        let providerType = type(of: provider)
        Task { @MainActor in
            DebugLogger.shared.dataProvider("DataSourceProvider configured with: \(providerType)")
        }
        
        // Clean up any stale data on startup
        Task {
            await cleanupStaleData()
        }
    }
    
    /// Clean up stale data like old analyzing meals
    private func cleanupStaleData() async {
        do {
            Task { @MainActor in
                DebugLogger.shared.dataProvider("Starting stale data cleanup")
            }
            // This will trigger cleanup of old analyzing meals in Firebase
            let analyzingMeals = try await provider.getAnalyzingMeals()
            Task { @MainActor in
                DebugLogger.shared.success("Stale data cleanup completed. Found \(analyzingMeals.count) analyzing meals")
            }
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to clean up stale data: \(error)")
            }
            print("⚠️ Failed to clean up stale data: \(error)")
        }
    }
    
    // Override for developer dashboard simulation
    func override(meals: DataProvider? = nil, windows: DataProvider? = nil, nudges: DataProvider? = nil) {
        // TODO: Implement partial override for simulation mode
    }
}