import Foundation
import UIKit

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
    func completeAnalyzingMeal(id: String, result: MealAnalysisResult) async throws
    func cancelAnalyzingMeal(id: String) async throws
    
    // MARK: - Window Operations
    func saveWindow(_ window: MealWindow) async throws
    func getWindows(for date: Date) async throws -> [MealWindow]
    func updateWindow(_ window: MealWindow) async throws
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow]
    func redistributeWindows(for date: Date) async throws
    
    // MARK: - Check-In Operations
    func saveMorningCheckIn(_ checkIn: MorningCheckInData) async throws
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData?
    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) async throws
    func getPostMealCheckIns(for date: Date) async throws -> [PostMealCheckIn]
    func getPendingPostMealCheckIns() async throws -> [PostMealCheckIn]
    
    // MARK: - User Profile Operations
    func getUserProfile() async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
    
    // MARK: - Analytics Operations
    func getDailyAnalytics(for date: Date) async throws -> DailyAnalytics?
    func getWeeklyAnalytics(for weekStart: Date) async throws -> WeeklyAnalytics?
    func updateDailyAnalytics(_ analytics: DailyAnalytics) async throws
    
    // MARK: - Real-time Updates
    func observeMeals(for date: Date, onChange: @escaping ([LoggedMeal]) -> Void) -> ObservationToken
    func observeWindows(for date: Date, onChange: @escaping ([MealWindow]) -> Void) -> ObservationToken
    func observeAnalyzingMeals(onChange: @escaping ([AnalyzingMeal]) -> Void) -> ObservationToken
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
struct DailyAnalytics: Codable {
    let date: Date
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let mealsLogged: Int
    let windowsCompleted: Int
    let windowsMissed: Int
    let averageEnergyLevel: Double?
    let micronutrientProgress: [String: Double] // nutrient name -> percentage of RDA
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
            "micronutrients": micronutrients
        ]
        
        if let windowId = windowId {
            data["windowId"] = windowId.uuidString
        }
        
        return data
    }
    
    /// Initialize from Firestore document
    static func fromFirestore(_ data: [String: Any]) -> LoggedMeal? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let calories = data["calories"] as? Int,
              let protein = data["protein"] as? Int,
              let carbs = data["carbs"] as? Int,
              let fat = data["fat"] as? Int,
              let timestamp = data["timestamp"] as? Date else {
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
        
        // TODO: Parse micronutrients from data["micronutrients"]
        
        return meal
    }
}

extension MealWindow {
    /// Convert to Firestore-compatible dictionary
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "startTime": startTime,
            "endTime": endTime,
            "targetCalories": targetCalories,
            "targetProtein": targetMacros.protein,
            "targetCarbs": targetMacros.carbs,
            "targetFat": targetMacros.fat,
            "purpose": purpose.rawValue,
            "flexibility": flexibility.rawValue,
            "dayDate": dayDate
        ]
        
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
              let startTime = data["startTime"] as? Date,
              let endTime = data["endTime"] as? Date,
              let targetCalories = data["targetCalories"] as? Int,
              let targetProtein = data["targetProtein"] as? Int,
              let targetCarbs = data["targetCarbs"] as? Int,
              let targetFat = data["targetFat"] as? Int,
              let purposeString = data["purpose"] as? String,
              let purpose = WindowPurpose(rawValue: purposeString),
              let flexibilityString = data["flexibility"] as? String,
              let flexibility = WindowFlexibility(rawValue: flexibilityString),
              let dayDate = data["dayDate"] as? Date else {
            return nil
        }
        
        // MealWindow generates its own ID, so we can't restore the original ID from Firestore
        // This is a limitation of the current design
        var window = MealWindow(
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
            dayDate: dayDate
        )
        
        window.adjustedCalories = data["adjustedCalories"] as? Int
        
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
        
        // Clean up any stale data on startup
        Task {
            await cleanupStaleData()
        }
    }
    
    /// Clean up stale data like old analyzing meals
    private func cleanupStaleData() async {
        do {
            // This will trigger cleanup of old analyzing meals in Firebase
            _ = try await provider.getAnalyzingMeals()
        } catch {
            print("⚠️ Failed to clean up stale data: \(error)")
        }
    }
    
    // Override for developer dashboard simulation
    func override(meals: DataProvider? = nil, windows: DataProvider? = nil, nudges: DataProvider? = nil) {
        // TODO: Implement partial override for simulation mode
    }
}