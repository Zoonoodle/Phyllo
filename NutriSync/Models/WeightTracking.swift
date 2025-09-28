//
//  WeightTracking.swift
//  NutriSync
//
//  Weight tracking models and logic for Daily Sync
//

import Foundation
import FirebaseFirestore

// MARK: - Weight Entry Model
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double
    let context: WeighInContext
    let userId: String
    
    struct WeighInContext: Codable {
        let timeOfDay: String
        let syncContext: SyncContext
        let notes: String?
        let skippedReason: String?
        let wasEstimated: Bool
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Double,
        context: WeighInContext,
        userId: String
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.context = context
        self.userId = userId
    }
    
    // Firestore conversion
    func toFirestore() -> [String: Any] {
        return [
            "id": id.uuidString,
            "date": date,
            "weight": weight,
            "timeOfDay": context.timeOfDay,
            "syncContext": context.syncContext.rawValue,
            "notes": context.notes as Any,
            "skippedReason": context.skippedReason as Any,
            "wasEstimated": context.wasEstimated,
            "userId": userId
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> WeightEntry? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let weight = data["weight"] as? Double,
              let userId = data["userId"] as? String,
              let syncContextRaw = data["syncContext"] as? String,
              let syncContext = SyncContext(rawValue: syncContextRaw) else {
            return nil
        }
        
        // Handle date conversion from Firestore Timestamp
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        
        let context = WeighInContext(
            timeOfDay: data["timeOfDay"] as? String ?? "morning",
            syncContext: syncContext,
            notes: data["notes"] as? String,
            skippedReason: data["skippedReason"] as? String,
            wasEstimated: data["wasEstimated"] as? Bool ?? false
        )
        
        return WeightEntry(
            id: id,
            date: date,
            weight: weight,
            context: context,
            userId: userId
        )
    }
}

// MARK: - Skip Reasons
enum WeightSkipReason: String, CaseIterable {
    case traveling = "I'm traveling"
    case noScale = "No scale available"
    case notReady = "Not ready today"
    case forgotMorning = "Forgot this morning"
    case other = "Skip for now"
    
    var icon: String {
        switch self {
        case .traveling: return "airplane"
        case .noScale: return "scalemass"
        case .notReady: return "clock.arrow.circlepath"
        case .forgotMorning: return "sunrise"
        case .other: return "arrow.right.circle"
        }
    }
}

// MARK: - Weight Trend Analysis
struct WeightTrend {
    let currentWeight: Double?
    let previousWeight: Double?
    let weeklyAverage: Double?
    let monthlyTrend: TrendDirection
    let progressToGoal: Double? // Percentage
    let daysTracked: Int
    
    enum TrendDirection: String {
        case up = "up"
        case down = "down"
        case stable = "stable"
        case insufficient = "insufficient" // Not enough data
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .stable: return "arrow.left.arrow.right.circle.fill"
            case .insufficient: return "questionmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .up: return "green"
            case .down: return "red"
            case .stable: return "blue"
            case .insufficient: return "gray"
            }
        }
    }
    
    func getFeedback(for goal: NutritionGoal) -> String {
        guard let current = currentWeight,
              let previous = previousWeight else {
            return "Start tracking to see your progress!"
        }
        
        let change = current - previous
        let changeStr = String(format: "%.1f", abs(change))
        
        switch goal {
        case .weightLoss(_, _):
            if monthlyTrend == .down {
                return "Great progress! Down \(changeStr) lbs 🎉"
            } else if monthlyTrend == .stable {
                return "Maintaining well. Let's boost that deficit!"
            } else {
                return "Let's adjust your windows for better results"
            }
            
        case .muscleGain(_, _):
            if monthlyTrend == .up {
                return "Building nicely! Up \(changeStr) lbs 💪"
            } else if monthlyTrend == .stable {
                return "Time to increase calories slightly"
            } else {
                return "Let's boost those portions!"
            }
            
        case .maintainWeight:
            if monthlyTrend == .stable {
                return "Perfect maintenance! ✅"
            } else {
                return "Small adjustment needed"
            }
            
        default:
            return "Keep up the consistency!"
        }
    }
}

// MARK: - Weight Check Schedule
struct WeightCheckSchedule {
    /// Determines if we should prompt for weight based on goal and last check
    static func shouldPromptForWeighIn(
        lastWeighIn: Date?,
        goal: NutritionGoal,
        syncContext: SyncContext
    ) -> Bool {
        // Only prompt during morning syncs for most accurate weight
        guard syncContext == .earlyMorning || syncContext == .morning else { 
            return false 
        }
        
        // Always prompt if never weighed in
        guard let lastWeighIn = lastWeighIn else { 
            return true
        }
        
        let calendar = Calendar.current
        let daysSinceLastWeighIn = calendar.dateComponents(
            [.day], 
            from: lastWeighIn, 
            to: Date()
        ).day ?? 0
        
        // Determine frequency based on goal
        let requiredDays: Int
        switch goal {
        case .weightLoss(_, _):
            requiredDays = 3 // Every 3 days for weight loss
        case .muscleGain(_, _):
            requiredDays = 7 // Weekly for muscle gain
        case .maintainWeight:
            requiredDays = 7 // Weekly for maintenance
        case .performanceFocus, .athleticPerformance:
            requiredDays = 7 // Weekly for performance
        case .betterSleep, .overallWellbeing:
            requiredDays = 14 // Bi-weekly for wellness goals
        default:
            requiredDays = 7 // Default to weekly
        }
        
        return daysSinceLastWeighIn >= requiredDays
    }
    
    /// Get the next scheduled weigh-in date
    static func nextWeighInDate(
        lastWeighIn: Date?,
        goal: NutritionGoal
    ) -> Date? {
        guard let lastWeighIn = lastWeighIn else { 
            return Date() // Prompt today if never weighed
        }
        
        let daysToAdd: Int
        switch goal {
        case .weightLoss(_, _):
            daysToAdd = 3
        case .muscleGain(_, _), .maintainWeight:
            daysToAdd = 7
        default:
            daysToAdd = 7
        }
        
        return Calendar.current.date(
            byAdding: .day, 
            value: daysToAdd, 
            to: lastWeighIn
        )
    }
}

// MARK: - Weight Manager (Singleton)
@MainActor
class WeightTrackingManager: ObservableObject {
    static let shared = WeightTrackingManager()
    
    @Published var lastWeightEntry: WeightEntry?
    @Published var weightHistory: [WeightEntry] = []
    @Published var currentTrend: WeightTrend?
    
    private init() {}
    
    /// Save a new weight entry
    func saveWeightEntry(_ entry: WeightEntry) async throws {
        // Save to Firebase
        guard let userId = FirebaseDataProvider.shared.currentUserId else {
            throw DataProviderError.notAuthenticated
        }
        
        let db = Firestore.firestore()
        let weightRef = db.collection("users").document(userId)
            .collection("weightEntries").document(entry.id.uuidString)
        
        try await weightRef.setData(entry.toFirestore())
        
        // Update local state
        lastWeightEntry = entry
        weightHistory.append(entry)
        
        // Update user profile weight if this is a real weight (not skipped)
        if entry.context.skippedReason == nil {
            try await updateProfileWeight(entry.weight)
        }
        
        // Recalculate trend
        await calculateTrend()
    }
    
    /// Load weight history
    func loadWeightHistory() async throws {
        guard let userId = FirebaseDataProvider.shared.currentUserId else {
            throw DataProviderError.notAuthenticated
        }
        
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(userId)
            .collection("weightEntries")
            .order(by: "date", descending: true)
            .limit(to: 30) // Last 30 entries
            .getDocuments()
        
        weightHistory = snapshot.documents.compactMap { doc in
            WeightEntry.fromFirestore(doc.data())
        }
        
        lastWeightEntry = weightHistory.first
        await calculateTrend()
    }
    
    /// Update profile weight in Firebase
    private func updateProfileWeight(_ weight: Double) async throws {
        var profile = try await FirebaseDataProvider.shared.getUserProfile()
        profile?.weight = weight
        
        if let profile = profile {
            try await FirebaseDataProvider.shared.updateUserProfile(profile)
        }
    }
    
    /// Calculate weight trend
    private func calculateTrend() async {
        guard weightHistory.count >= 2 else {
            currentTrend = WeightTrend(
                currentWeight: lastWeightEntry?.weight,
                previousWeight: nil,
                weeklyAverage: nil,
                monthlyTrend: .insufficient,
                progressToGoal: nil,
                daysTracked: weightHistory.count
            )
            return
        }
        
        let current = weightHistory[0].weight
        let previous = weightHistory[1].weight
        
        // Calculate weekly average
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = weightHistory.filter { $0.date >= oneWeekAgo }
        let weeklyAvg = weekEntries.isEmpty ? nil : 
            weekEntries.map(\.weight).reduce(0, +) / Double(weekEntries.count)
        
        // Determine monthly trend
        let monthlyTrend: WeightTrend.TrendDirection
        if weightHistory.count < 4 {
            monthlyTrend = .insufficient
        } else {
            let oldWeight = weightHistory[min(10, weightHistory.count - 1)].weight
            let difference = current - oldWeight
            
            if abs(difference) < 0.5 {
                monthlyTrend = .stable
            } else if difference > 0 {
                monthlyTrend = .up
            } else {
                monthlyTrend = .down
            }
        }
        
        currentTrend = WeightTrend(
            currentWeight: current,
            previousWeight: previous,
            weeklyAverage: weeklyAvg,
            monthlyTrend: monthlyTrend,
            progressToGoal: nil, // Calculate based on goal
            daysTracked: weightHistory.count
        )
    }
}