import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Data Provider Errors
enum DataProviderError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .profileNotFound:
            return "User profile not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Firebase Data Provider
/// Production implementation using Firebase Firestore
@MainActor
class FirebaseDataProvider: @preconcurrency DataProvider, ObservableObject {
    static let shared = FirebaseDataProvider()
    
    private lazy var db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // Cache for current day purpose
    var currentDayPurpose: DayPurpose?
    
    // Redistribution trigger manager
    private let redistributionTriggerManager = RedistributionTriggerManager()
    
    // Handler for redistribution nudge presentation
    var onRedistributionProposed: ((RedistributionResult) -> Void)?
    
    // Current user ID - dynamically fetched from Firebase Auth
    var currentUserId: String {
        // Use authenticated user ID or empty string if not authenticated
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private var userRef: DocumentReference? {
        guard !currentUserId.isEmpty else { return nil }
        return db.collection("users").document(currentUserId)
    }
    
    // MARK: - Meal Operations
    
    func saveMeal(_ meal: LoggedMeal) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
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
        
        // Check for redistribution triggers after meal save
        await checkRedistributionTrigger(for: meal)
    }
    
    func getMeals(for date: Date) async throws -> [LoggedMeal] {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
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
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("meals").document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return LoggedMeal.fromFirestore(data)
    }
    
    func updateMeal(_ meal: LoggedMeal) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let mealRef = userRef.collection("meals").document(meal.id.uuidString)
        try await mealRef.updateData(meal.toFirestore())
        
        // Update analytics
        await updateDailyAnalyticsForMeal(meal)
    }
    
    func deleteMeal(id: String) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        try await userRef.collection("meals").document(id).delete()
        
        // TODO: Update analytics to reflect deletion
    }
    
    func getAnalyzingMeals() async throws -> [AnalyzingMeal] {
        // Fetch active analyzing meals (do not auto-delete; we want the banner to show)
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
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
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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
        // Clean up the meal name to remove non-food text
        let cleanedName = cleanMealName(result.mealName)
        
        var meal = LoggedMeal(
            name: cleanedName,
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
                foodGroup: FoodGroup(rawValue: ingredient.foodGroup) ?? .mixed
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
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        try await userRef.collection("analyzingMeals").document(id).delete()
    }
    
    // MARK: - Window Operations
    
    func saveWindow(_ window: MealWindow) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let windowRef = userRef.collection("windows").document(window.id)
        let firestoreData = window.toFirestore()
        
        // Debug logging to track date saving
        if let dayDate = firestoreData["dayDate"] as? Date {
            let calendar = Calendar.current
            Task { @MainActor in
                DebugLogger.shared.firebase("Saving window with dayDate: \(dayDate)")
                DebugLogger.shared.firebase("Save date components: \(calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: dayDate))")
            }
        }
        
        try await windowRef.setData(firestoreData)
    }
    
    func getWindows(for date: Date) async throws -> [MealWindow] {
        // Use start of day for querying by dayDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Querying windows for dayDate: \(startOfDay)")
            DebugLogger.shared.firebase("Query date components: \(calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: startOfDay))")
            
            // Log the exact timestamp being used for the query
            let timestamp = FirebaseFirestore.Timestamp(date: startOfDay)
            DebugLogger.shared.firebase("Query timestamp - seconds: \(timestamp.seconds), nanoseconds: \(timestamp.nanoseconds)")
        }
        
        // Query windows by dayDate field (single field query, no index needed)
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let snapshot = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: FirebaseFirestore.Timestamp(date: startOfDay))
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
            
            // Debug: log the dayDate from each document
            if let dayDateTimestamp = data["dayDate"] as? FirebaseFirestore.Timestamp {
                let docDate = dayDateTimestamp.dateValue()
                Task { @MainActor in
                    DebugLogger.shared.firebase("Document dayDate: \(docDate), expected: \(startOfDay)")
                }
            }
            
            let window = MealWindow.fromFirestore(data)
            if window == nil {
                let bad = String(describing: data)
                Task { @MainActor in
                    DebugLogger.shared.warning("Failed to parse window document: \(bad)")
                }
            }
            return window
        }
        
        // Filter windows to only include those for the requested date
        let filteredWindows = windows.filter { window in
            let windowStartOfDay = calendar.startOfDay(for: window.dayDate)
            let matches = windowStartOfDay == startOfDay
            if !matches {
                Task { @MainActor in
                    DebugLogger.shared.warning("Filtering out window with dayDate \(window.dayDate) (expected \(startOfDay))")
                }
            }
            return matches
        }
        
        let parsedCount = filteredWindows.count
        await MainActor.run {
            DebugLogger.shared.firebase("Successfully parsed \(parsedCount) windows from Firebase for date: \(date)")
        }
        
        return filteredWindows.sorted { $0.startTime < $1.startTime }
    }
    
    func updateWindow(_ window: MealWindow) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let windowRef = userRef.collection("windows").document(window.id)
        try await windowRef.updateData(window.toFirestore())
    }
    
    func generateDailyWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow] {
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Checking for existing windows before generation for date: \(date)")
        }
        
        // IMPORTANT: Check if windows already exist (especially AI-generated ones)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

        let existing = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: startOfDay)
            .getDocuments()
        
        // If windows already exist, return them instead of overwriting
        if !existing.documents.isEmpty {
            Task { @MainActor in
                DebugLogger.shared.info("Windows already exist for today (\(existing.documents.count) windows). Skipping generation.")
            }
            
            // Parse and return existing windows
            let windows = existing.documents.compactMap { doc -> MealWindow? in
                MealWindow.fromFirestore(doc.data())
            }
            
            // Check if these are AI-generated windows (have name, foodSuggestions, etc.)
            let hasAIContent = windows.contains { !$0.name.isEmpty || !$0.foodSuggestions.isEmpty }
            Task { @MainActor in
                if hasAIContent {
                    DebugLogger.shared.success("Preserving existing AI-generated windows with rich content")
                } else {
                    DebugLogger.shared.warning("Existing windows lack AI content - consider regenerating with AI service")
                }
            }
            
            return windows
        }
        
        Task { @MainActor in
            DebugLogger.shared.error("No existing windows found. Calling AI window generation service...")
            DebugLogger.shared.warning("AI service is required - no fallback available")
        }
        
        // NO FALLBACK - AI generation is ALWAYS required
        // Call the AI Window Generation Service
        do {
            let (aiWindows, dayPurpose, contextInsights) = try await AIWindowGenerationService.shared.generateWindows(
                for: profile,
                checkIn: checkIn,
                dailySync: try? await getDailySync(for: date),
                date: date
            )

            // Store day purpose if generated
            if let dayPurpose = dayPurpose {
                self.currentDayPurpose = dayPurpose

                // Save day purpose to Firestore
                let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
                let dayPurposeRef = userRef.collection("dayPurposes").document(dateString)
                try? await dayPurposeRef.setData([
                    "nutritionalStrategy": dayPurpose.nutritionalStrategy,
                    "energyManagement": dayPurpose.energyManagement,
                    "performanceOptimization": dayPurpose.performanceOptimization,
                    "recoveryFocus": dayPurpose.recoveryFocus,
                    "keyPriorities": dayPurpose.keyPriorities,
                    "generatedAt": Date()
                ])
            }

            // Store context insights if generated
            if let insights = contextInsights, !insights.isEmpty {
                // Save insights to Firestore for the current date
                let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
                let insightsRef = userRef.collection("contextInsights").document(dateString)
                try? await insightsRef.setData([
                    "insights": insights,
                    "generatedAt": Date()
                ])

                Task { @MainActor in
                    DebugLogger.shared.success("Saved \(insights.count) context insights to Firestore")
                }
            }

            Task { @MainActor in
                DebugLogger.shared.success("AI generated \(aiWindows.count) windows with rich content")
                if dayPurpose != nil {
                    DebugLogger.shared.success("Day purpose also generated successfully")
                }
                if contextInsights != nil && !contextInsights!.isEmpty {
                    DebugLogger.shared.success("Context insights also generated (\(contextInsights!.count) insights)")
                }
            }
            
            // Save AI-generated windows to Firestore
            for window in aiWindows {
                Task { @MainActor in
                    DebugLogger.shared.firebase("Saving AI window: \(window.name.isEmpty ? "\(window.purpose.rawValue) Window" : window.name)")
                }
                try await saveWindow(window)
            }
            
            Task { @MainActor in
                DebugLogger.shared.success("All \(aiWindows.count) AI windows saved to Firebase")
            }
            
            return aiWindows
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("AI window generation failed: \(error)")
            }
            throw error
        }
    }
    
    /// Clear existing windows and regenerate them with AI (useful for fixing incorrect windows)
    func clearAndRegenerateWindows(for date: Date, profile: UserProfile, checkIn: MorningCheckInData?) async throws -> [MealWindow] {
        Task { @MainActor in
            DebugLogger.shared.warning("Clearing existing windows for regeneration...")
        }
        
        // Clear existing windows for this date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

        let existing = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: startOfDay)
            .getDocuments()
        
        // Delete all existing windows
        for doc in existing.documents {
            try await doc.reference.delete()
        }
        
        Task { @MainActor in
            DebugLogger.shared.info("Cleared \(existing.documents.count) existing windows")
            DebugLogger.shared.info("Generating fresh windows with AI...")
        }
        
        // Generate new windows with AI
        do {
            let (aiWindows, dayPurpose, contextInsights) = try await AIWindowGenerationService.shared.generateWindows(
                for: profile,
                checkIn: checkIn,
                dailySync: try? await getDailySync(for: date),
                date: date
            )

            // Store day purpose if generated
            if let dayPurpose = dayPurpose {
                self.currentDayPurpose = dayPurpose

                // Save day purpose to Firestore
                let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
                let dayPurposeRef = userRef.collection("dayPurposes").document(dateString)
                try? await dayPurposeRef.setData([
                    "nutritionalStrategy": dayPurpose.nutritionalStrategy,
                    "energyManagement": dayPurpose.energyManagement,
                    "performanceOptimization": dayPurpose.performanceOptimization,
                    "recoveryFocus": dayPurpose.recoveryFocus,
                    "keyPriorities": dayPurpose.keyPriorities,
                    "generatedAt": Date()
                ])
            }

            // Store context insights if generated
            if let insights = contextInsights, !insights.isEmpty {
                // Save insights to Firestore for the current date
                let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
                let insightsRef = userRef.collection("contextInsights").document(dateString)
                try? await insightsRef.setData([
                    "insights": insights,
                    "generatedAt": Date()
                ])

                Task { @MainActor in
                    DebugLogger.shared.success("Saved \(insights.count) context insights to Firestore during regeneration")
                }
            }
            
            // Save all windows to Firebase
            for window in aiWindows {
                try await saveWindow(window)
            }
            
            Task { @MainActor in
                DebugLogger.shared.success("Generated and saved \(aiWindows.count) new AI windows")
            }
            
            return aiWindows
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to regenerate windows: \(error)")
            }
            throw error
        }
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
    
    // MARK: - Daily Sync (New System)
    
    func saveDailySync(_ sync: DailySync) async throws {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: sync.timestamp)
        
        DebugLogger.shared.log("💾 Saving DailySync - Date: \(sync.timestamp), DateString: \(dateString)", category: .dataProvider)
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let syncRef = userRef.collection("dailySync").document(dateString)
        try await syncRef.setData(sync.toFirestore())
    }
    
    func getDailySync(for date: Date) async throws -> DailySync? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)
        
        DebugLogger.shared.log("🔍 Getting DailySync - Date: \(date), DateString: \(dateString)", category: .dataProvider)
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("dailySync").document(dateString).getDocument()
        let exists = doc.exists
        DebugLogger.shared.log("📄 DailySync Document - DateString: \(dateString), Exists: \(exists)", category: .dataProvider)
        
        guard let data = doc.data() else { return nil }
        return DailySync.fromFirestore(data)
    }
    
    // MARK: - Legacy Morning Check-In (To be deprecated)
    
    func saveMorningCheckIn(_ checkIn: MorningCheckInData) async throws {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: checkIn.date)

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let checkInRef = userRef.collection("checkIns").document("morning").collection("data").document(dateString)
        try await checkInRef.setData([
            "id": checkIn.id.uuidString,
            "date": checkIn.date,
            "wakeTime": checkIn.wakeTime,
            "plannedBedtime": checkIn.plannedBedtime,
            "sleepQuality": checkIn.sleepQuality,
            "energyLevel": checkIn.energyLevel,
            "hungerLevel": checkIn.hungerLevel,
            "dayFocus": Array(checkIn.dayFocus.map { $0.rawValue }),
            "morningMood": checkIn.morningMood?.rawValue as Any,
            "plannedActivities": checkIn.plannedActivities,
            "windowPreference": checkIn.windowPreference.jsonValue,
            "hasRestrictions": checkIn.hasRestrictions,
            "restrictions": checkIn.restrictions,
            "timestamp": checkIn.timestamp
        ])
    }
    
    func getMorningCheckIn(for date: Date) async throws -> MorningCheckInData? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("checkIns").document("morning").collection("data").document(dateString).getDocument()
        guard let data = doc.data() else { return nil }
        // Map Firestore fields back to model
        let id = (data["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
        let dateVal = (data["date"] as? Timestamp)?.dateValue() ?? date
        let wake = (data["wakeTime"] as? Timestamp)?.dateValue() ?? Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: dateVal)!
        let plannedBed = (data["plannedBedtime"] as? Timestamp)?.dateValue() ?? Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: dateVal)!
        let sleepQuality = data["sleepQuality"] as? Int ?? 7
        let energyLevel = data["energyLevel"] as? Int ?? 3
        let hunger = data["hungerLevel"] as? Int ?? 3
        
        let dayFocusStrings = data["dayFocus"] as? [String] ?? []
        let dayFocus = Set(dayFocusStrings.compactMap { MorningCheckIn.DayFocus(rawValue: $0) })
        
        let moodRaw = data["morningMood"] as? Int
        let mood = moodRaw.flatMap { MoodLevel(rawValue: $0) }
        
        let planned = data["plannedActivities"] as? [String] ?? []
        
        let windowPref: MorningCheckIn.WindowPreference
        if let prefString = data["windowPreference"] as? String {
            if prefString == "auto" {
                windowPref = .auto
            } else if let count = Int(prefString) {
                windowPref = .specific(count)
            } else if prefString.contains("-") {
                let parts = prefString.split(separator: "-")
                if parts.count == 2, let min = Int(parts[0]), let max = Int(parts[1]) {
                    windowPref = .range(min, max)
                } else {
                    windowPref = .auto
                }
            } else {
                windowPref = .auto
            }
        } else {
            windowPref = .auto
        }
        
        let hasRestrictions = data["hasRestrictions"] as? Bool ?? false
        let restrictions = data["restrictions"] as? [String] ?? []
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        
        return MorningCheckInData(
            id: id,
            date: dateVal,
            wakeTime: wake,
            plannedBedtime: plannedBed,
            sleepQuality: sleepQuality,
            energyLevel: energyLevel,
            hungerLevel: hunger,
            dayFocus: dayFocus,
            morningMood: mood,
            plannedActivities: planned,
            windowPreference: windowPref,
            hasRestrictions: hasRestrictions,
            restrictions: restrictions,
            timestamp: timestamp
        )
    }
    
    func getDayPurpose(for date: Date) async throws -> DayPurpose? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("dayPurposes").document(dateString).getDocument()
        guard let data = doc.data() else { return nil }

        return DayPurpose(
            nutritionalStrategy: data["nutritionalStrategy"] as? String ?? "",
            energyManagement: data["energyManagement"] as? String ?? "",
            performanceOptimization: data["performanceOptimization"] as? String ?? "",
            recoveryFocus: data["recoveryFocus"] as? String ?? "",
            keyPriorities: data["keyPriorities"] as? [String] ?? []
        )
    }

    /// Retrieve context insights generated by AI for a specific date
    func getContextInsights(for date: Date) async throws -> [String]? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("contextInsights").document(dateString).getDocument()
        guard let data = doc.data() else { return nil }

        return data["insights"] as? [String]
    }

    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
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
                activityLevel: .moderatelyActive,
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
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        try await userRef.collection("profile").document("current").setData(profile.toFirestore())
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        // Alias for saveUserProfile for consistency
        try await saveUserProfile(profile)
    }
    
    func getUserGoals() async throws -> UserGoals? {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        let doc = try await userRef.collection("goals").document("current").getDocument()
        guard let data = doc.data() else { 
            // Return default goals if not found
            return UserGoals.defaultGoals
        }
        return UserGoals.fromFirestore(data)
    }
    
    func saveUserGoals(_ goals: UserGoals) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        try await userRef.collection("goals").document("current").setData(goals.toFirestore())
    }
    
    // MARK: - Analytics Operations
    
    func getDailyAnalytics(for date: Date) async throws -> DailyAnalytics? {
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: date)

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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

        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
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
    
    func getDailyAnalyticsRange(from: Date, to: Date) async throws -> [DailyAnalytics]? {
        var analyticsArray: [DailyAnalytics] = []
        let calendar = Calendar.current
        
        for dayOffset in 0...calendar.dateComponents([.day], from: from, to: to).day! {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: from) else { continue }
            
            let meals = try await getMeals(for: currentDate)
            let windows = try await getWindows(for: currentDate)
            let profile = try await getUserProfile()
            
            let completedWindows = windows.filter { $0.consumed.calories > 0 }.count
            let totalCalories = meals.reduce(0) { $0 + $1.calories }
            let totalProtein = Double(meals.reduce(0) { $0 + $1.protein })
            let totalCarbs = Double(meals.reduce(0) { $0 + $1.carbs })
            let totalFat = Double(meals.reduce(0) { $0 + $1.fat })
            
            let timingScore = completedWindows > 0 ? Double(completedWindows) / Double(max(windows.count, 1)) : 0
            let nutrientScore = calculateNutrientScore(
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                targetCalories: profile?.dailyCalorieTarget,
                targetProtein: profile?.dailyProteinTarget,
                targetCarbs: profile?.dailyCarbTarget,
                targetFat: profile?.dailyFatTarget
            )
            let adherenceScore = Double(meals.count) / 5.0  // Default 5 meals per day
            
            let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: currentDate)
            analyticsArray.append(DailyAnalytics(
                id: dateString,
                date: currentDate,
                totalCalories: totalCalories,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                mealsLogged: meals.count,
                targetMeals: 5,  // Default 5 meals per day
                windowsCompleted: completedWindows,
                totalWindows: windows.count,
                windowsMissed: windows.filter { $0.consumed.calories == 0 && Date() > $0.endTime }.count,
                averageEnergyLevel: nil,
                micronutrientProgress: [:],
                timingScore: timingScore,
                nutrientScore: nutrientScore,
                adherenceScore: adherenceScore,
                caloriesConsumed: totalCalories,
                targetCalories: profile?.dailyCalorieTarget ?? 2400
            ))
        }
        
        return analyticsArray.isEmpty ? nil : analyticsArray
    }
    
    func calculateStreak(until date: Date) async throws -> (current: Int, best: Int) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: date)!
        
        guard let analyticsRange = try await getDailyAnalyticsRange(from: thirtyDaysAgo, to: date) else {
            return (current: 0, best: 0)
        }
        
        let sortedAnalytics = analyticsRange.sorted { $0.date > $1.date }
        
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        
        for (index, analytics) in sortedAnalytics.enumerated() {
            let hasLoggedMeals = analytics.mealsLogged > 0
            let hasCompletedWindows = analytics.windowsCompleted > 0
            
            if hasLoggedMeals || hasCompletedWindows {
                if index == 0 {
                    currentStreak += 1
                    tempStreak = currentStreak
                } else {
                    tempStreak += 1
                }
                bestStreak = max(bestStreak, tempStreak)
            } else {
                if index == 0 {
                    currentStreak = 0
                }
                tempStreak = 0
            }
        }
        
        return (current: currentStreak, best: bestStreak)
    }
    
    func getMealsForDateRange(from: Date, to: Date) async throws -> [Date: [LoggedMeal]] {
        let startOfDay = Calendar.current.startOfDay(for: from)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to))!
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

        let docs = try await userRef.collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .getDocuments()
        
        var mealsByDate: [Date: [LoggedMeal]] = [:]
        
        for doc in docs.documents {
            if let meal = LoggedMeal.fromFirestore(doc.data()) {
                let dayDate = Calendar.current.startOfDay(for: meal.timestamp)
                if mealsByDate[dayDate] == nil {
                    mealsByDate[dayDate] = []
                }
                mealsByDate[dayDate]?.append(meal)
            }
        }
        
        return mealsByDate
    }
    
    func getWindowsForDateRange(from: Date, to: Date) async throws -> [Date: [MealWindow]] {
        let startOfDay = Calendar.current.startOfDay(for: from)
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: to)!)
        
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

        let docs = try await userRef.collection("windows")
            .whereField("dayDate", isGreaterThanOrEqualTo: startOfDay)
            .whereField("dayDate", isLessThan: endOfDay)
            .getDocuments()
        
        var windowsByDate: [Date: [MealWindow]] = [:]
        
        for doc in docs.documents {
            if let window = MealWindow.fromFirestore(doc.data()),
               let dayDate = doc.data()["dayDate"] as? Timestamp {
                let date = Calendar.current.startOfDay(for: dayDate.dateValue())
                if windowsByDate[date] == nil {
                    windowsByDate[date] = []
                }
                windowsByDate[date]?.append(window)
            }
        }
        
        for (date, windows) in windowsByDate {
            windowsByDate[date] = windows.sorted { $0.startTime < $1.startTime }
        }
        
        return windowsByDate
    }
    
    private func calculateNutrientScore(
        protein: Double,
        carbs: Double,
        fat: Double,
        targetCalories: Int?,
        targetProtein: Int?,
        targetCarbs: Int?,
        targetFat: Int?
    ) -> Double {
        guard let targetProtein = targetProtein,
              let targetCarbs = targetCarbs,
              let targetFat = targetFat,
              targetProtein > 0,
              targetCarbs > 0,
              targetFat > 0 else { return 0.5 }
        
        let proteinRatio = min(protein / Double(targetProtein), 1.0)
        let carbRatio = min(carbs / Double(targetCarbs), 1.0)
        let fatRatio = min(fat / Double(targetFat), 1.0)
        
        return (proteinRatio + carbRatio + fatRatio) / 3.0
    }
    
    // MARK: - Real-time Updates
    
    func observeMeals(for date: Date, onChange: @escaping ([LoggedMeal]) -> Void) -> ObservationToken {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        guard let userRef = userRef else {
            // Return empty token if not authenticated
            return ObservationToken {}
        }
        
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
            Task { @MainActor in
                self?.listeners[token]?.remove()
                self?.listeners[token] = nil
            }
        }
    }
    
    func observeWindows(for date: Date, onChange: @escaping ([MealWindow]) -> Void) -> ObservationToken {
        // Use start of day to match how we save dayDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let userRef = userRef else {
            // Return empty token if not authenticated
            return ObservationToken {}
        }
        
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
            Task { @MainActor in
                self?.listeners[token]?.remove()
                self?.listeners[token] = nil
            }
        }
    }
    
    func observeAnalyzingMeals(onChange: @escaping ([AnalyzingMeal]) -> Void) -> ObservationToken {
        guard let userRef = userRef else {
            // Return empty token if not authenticated
            return ObservationToken {}
        }
        
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
            Task { @MainActor in
                self?.listeners[token]?.remove()
                self?.listeners[token] = nil
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateDailyAnalyticsForMeal(_ meal: LoggedMeal) async {
        // TODO: Implement analytics update logic
        // This would aggregate meal data into daily totals
    }
    
    // MARK: - Clear All Data

    /// Clears today's data only - allows redoing DailySync → window generation
    func clearTodayData() async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

        Task { @MainActor in
            DebugLogger.shared.warning("Clearing today's data for user: \(currentUserId)")
        }

        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let dateString = ISO8601DateFormatter.yyyyMMdd.string(from: today)

        // 1. Clear today's windows
        let windowsSnapshot = try await userRef.collection("windows")
            .whereField("dayDate", isEqualTo: FirebaseFirestore.Timestamp(date: startOfToday))
            .getDocuments()

        for doc in windowsSnapshot.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(windowsSnapshot.documents.count) windows for today")
        }

        // 2. Clear today's meals
        let mealsSnapshot = try await userRef.collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startOfToday))
            .whereField("timestamp", isLessThan: FirebaseFirestore.Timestamp(date: startOfTomorrow))
            .getDocuments()

        for doc in mealsSnapshot.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(mealsSnapshot.documents.count) meals for today")
        }

        // 3. Clear today's analyzing meals
        let analyzingSnapshot = try await userRef.collection("analyzingMeals")
            .whereField("timestamp", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startOfToday))
            .whereField("timestamp", isLessThan: FirebaseFirestore.Timestamp(date: startOfTomorrow))
            .getDocuments()

        for doc in analyzingSnapshot.documents {
            try await doc.reference.delete()
        }
        Task { @MainActor in
            DebugLogger.shared.firebase("Cleared \(analyzingSnapshot.documents.count) analyzing meals for today")
        }

        // 4. Clear today's dailySync
        let dailySyncDoc = userRef.collection("dailySync").document(dateString)
        if try await dailySyncDoc.getDocument().exists {
            try await dailySyncDoc.delete()
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared today's dailySync")
            }
        }

        // 5. Clear today's dayPurpose
        let dayPurposeDoc = userRef.collection("dayPurposes").document(dateString)
        if try await dayPurposeDoc.getDocument().exists {
            try await dayPurposeDoc.delete()
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared today's dayPurpose")
            }
        }

        // 6. Clear today's contextInsights
        let contextInsightsDoc = userRef.collection("contextInsights").document(dateString)
        if try await contextInsightsDoc.getDocument().exists {
            try await contextInsightsDoc.delete()
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared today's contextInsights")
            }
        }

        // 7. Clear today's morning check-in
        let morningCheckInDoc = userRef.collection("checkIns").document("morning").collection("data").document(dateString)
        if try await morningCheckInDoc.getDocument().exists {
            try await morningCheckInDoc.delete()
            Task { @MainActor in
                DebugLogger.shared.firebase("Cleared today's morning check-in")
            }
        }

        // 8. Reset in-memory state
        await MainActor.run {
            // Reset DailySyncManager so user can do DailySync again
            DailySyncManager.shared.todaySync = nil
            DailySyncManager.shared.hasCompletedDailySync = false
            DailySyncManager.shared.pendingQuickMeals = []

            // Reset day purpose cache
            self.currentDayPurpose = nil

            DebugLogger.shared.success("Reset in-memory state for today")
        }

        Task { @MainActor in
            DebugLogger.shared.success("Successfully cleared all of today's data - ready for fresh DailySync!")
        }
    }

    /// Clears ALL user data from Firebase - USE WITH CAUTION
    func clearAllUserData() async throws {
        Task { @MainActor in
            DebugLogger.shared.warning("Starting complete Firebase data deletion for user: \(currentUserId)")
        }
        
        // Collections to clear (simple collections with direct documents)
        let collections = [
            "meals",
            "windows",
            "analyzingMeals",
            "dailySync",
            "dayPurposes",
            "contextInsights",
            "weightEntries",
            "insights"
        ]

        // Clear each collection
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }

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
    
    // MARK: - Helper Methods
    
    // REMOVED: generateBasicWindows - NO FALLBACK ALLOWED
    // All window generation MUST go through AI service
    // This ensures we always provide rich, personalized content
    
    // MARK: - Redistribution Trigger Check
    
    private func checkRedistributionTrigger(for meal: LoggedMeal) async {
        do {
            // Get current windows
            let windows = try await getWindows(for: meal.timestamp)
            
            // Find the window this meal belongs to
            guard let mealWindow = windows.first(where: { window in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }) else {
                Task { @MainActor in
                    DebugLogger.shared.info("No matching window found for meal, skipping redistribution check")
                }
                return
            }
            
            // Check if redistribution should be triggered
            if let redistributionResult = await redistributionTriggerManager.handleMealLogged(
                meal,
                window: mealWindow,
                allWindows: windows
            ) {
                Task { @MainActor in
                    DebugLogger.shared.success("Redistribution triggered: \(redistributionResult.explanation)")
                }
                
                // Notify handler if set (will be connected to ScheduleViewModel)
                await MainActor.run {
                    onRedistributionProposed?(redistributionResult)
                }
            } else {
                Task { @MainActor in
                    DebugLogger.shared.info("No redistribution needed (within threshold)")
                }
            }
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to check redistribution trigger: \(error)")
            }
        }
    }
    
    // Apply redistribution after user accepts
    func applyRedistribution(_ result: RedistributionResult) async throws {
        guard !result.adjustedWindows.isEmpty else { return }
        
        // Get current windows
        let windows = try await getWindows(for: Date())
        
        // Update windows with adjusted values
        for adjustment in result.adjustedWindows {
            if let window = windows.first(where: { $0.id == adjustment.windowId }) {
                // Create updated window with adjusted values
                var updatedWindow = window
                updatedWindow.adjustedCalories = adjustment.adjustedMacros.totalCalories
                updatedWindow.adjustedProtein = adjustment.adjustedMacros.protein
                updatedWindow.adjustedCarbs = adjustment.adjustedMacros.carbs
                updatedWindow.adjustedFat = adjustment.adjustedMacros.fat
                
                // Map trigger type to redistribution reason
                switch result.trigger {
                case .overconsumption(let percent):
                    updatedWindow.redistributionReason = WindowRedistributionManager.RedistributionReason.overconsumption(percentOver: percent)
                case .underconsumption(let percent):
                    updatedWindow.redistributionReason = WindowRedistributionManager.RedistributionReason.underconsumption(percentUnder: percent)
                case .missedWindow:
                    updatedWindow.redistributionReason = WindowRedistributionManager.RedistributionReason.missedWindow
                case .earlyConsumption:
                    updatedWindow.redistributionReason = WindowRedistributionManager.RedistributionReason.earlyConsumption
                case .lateConsumption:
                    updatedWindow.redistributionReason = WindowRedistributionManager.RedistributionReason.lateConsumption
                }
                
                // Save updated window
                try await saveWindow(updatedWindow)
            }
        }
        
        // Mark redistribution as applied
        redistributionTriggerManager.applyRedistribution(result)
        
        Task { @MainActor in
            DebugLogger.shared.success("Applied redistribution to \(result.adjustedWindows.count) windows")
        }
    }
}

// Removed duplicate ISO8601DateFormatter.yyyyMMdd extension (defined in NotificationManager)

// MARK: - Firestore Extensions

// Extension removed - using built-in Firestore conversion in saveMorningCheckIn/getMorningCheckIn

// MARK: - Onboarding Operations

extension FirebaseDataProvider {
    func hasCompletedOnboarding() async throws -> Bool {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let profileDoc = userRef.collection("profile").document("current")
        
        let snapshot = try await profileDoc.getDocument()
        
        // Log what we found for debugging
        if snapshot.exists {
            print("📱 Profile document exists for user")
            if let data = snapshot.data() {
                print("📱 Profile fields found: \(data.keys.sorted())")
            }
        } else {
            print("📱 No profile document found for user")
        }
        
        // Check if profile exists and has minimum required fields
        // These field names must match what's saved in UserProfile.toFirestore()
        if let data = snapshot.data(),
           data["name"] != nil,
           data["age"] != nil,
           data["height"] != nil,  // Changed from heightCM to height
           data["weight"] != nil {  // Changed from weightKG to weight
            print("✅ User has completed onboarding")
            return true
        }
        
        print("⚠️ User needs to complete onboarding")
        return false
    }
    
    func saveOnboardingProgress(_ progress: OnboardingProgress) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let progressRef = userRef.collection("onboarding").document("progress")
        
        try await progressRef.setData(progress.toFirestore())
    }
    
    func loadOnboardingProgress() async throws -> OnboardingProgress? {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let progressRef = userRef.collection("onboarding").document("progress")
        
        let snapshot = try await progressRef.getDocument()
        
        guard let data = snapshot.data() else { return nil }
        
        return OnboardingProgress.fromFirestore(data)
    }
    
    func createUserProfile(
        profile: UserProfile,
        goals: UserGoals,
        deleteProgress: Bool = true
    ) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let batch = db.batch()
        
        // Create profile document
        let profileRef = userRef.collection("profile").document("current")
        batch.setData(profile.toFirestore(), forDocument: profileRef)
        
        // Create goals document
        let goalsRef = userRef.collection("goals").document("current")
        batch.setData(goals.toFirestore(), forDocument: goalsRef)
        
        // Delete progress if requested
        if deleteProgress {
            let progressRef = userRef.collection("onboarding").document("progress")
            batch.deleteDocument(progressRef)
        }
        
        // Commit transaction
        try await batch.commit()
    }
    
    func generateInitialWindows() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "WindowGeneration", code: 1001, 
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        // Get current user profile
        let profile = try await getUserProfile()
        guard let profile = profile else {
            throw NSError(domain: "WindowGeneration", code: 1002, 
                         userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        let now = Date()
        
        // Check if this is a first-day user who needs partial day windows
        let firstDayService = FirstDayWindowService()
        if firstDayService.shouldGenerateFirstDayWindows(profile: profile) {
            print("Generating first-day windows for new user")
            
            // Generate partial-day windows using FirstDayWindowService
            let firstDayWindows = try await firstDayService.generateFirstDayWindows(
                for: profile,
                completionTime: now
            )
            
            if !firstDayWindows.isEmpty {
                // Save windows to Firebase
                let dateKey = ISO8601DateFormatter.yyyyMMdd.string(from: now)
                let windowsRef = db.collection("users").document(userId)
                    .collection("windows").document(dateKey)
                
                let windowsData = firstDayWindows.map { $0.toFirestore() }
                try await windowsRef.setData(["windows": windowsData])
                
                // Update profile to mark first day as completed
                var updatedProfile = profile
                updatedProfile.firstDayCompleted = true
                try await saveUserProfile(updatedProfile)
                
                // Fetch and update local windows
                let _ = try await getWindows(for: now)
                
                print("Generated \(firstDayWindows.count) first-day windows")
            } else {
                // Too late in the day, show tomorrow's plan
                print("Too late for first-day windows, user will see tomorrow's plan")
                
                // Still mark first day as completed
                var updatedProfile = profile
                updatedProfile.firstDayCompleted = true
                try await saveUserProfile(updatedProfile)
            }
        } else {
            // Regular window generation using AI service
            print("Generating regular windows using AI service")
            
            // Get morning check-in data if available
            _ = try? await getMorningCheckIn(for: now)
            
            // TODO: Implement AIWindowGenerationService
            // For now, use simple fallback window generation
            let windows = generateSimpleFallbackWindows(for: profile, date: now)
            let dayPurpose: String? = nil // Placeholder until AI service is ready
            
            if !windows.isEmpty {
                // Save windows to Firebase
                let dateKey = ISO8601DateFormatter.yyyyMMdd.string(from: now)
                let windowsRef = db.collection("users").document(userId)
                    .collection("windows").document(dateKey)
                
                let windowsData = windows.map { $0.toFirestore() }
                try await windowsRef.setData([
                    "windows": windowsData,
                    "dayPurpose": dayPurpose ?? "",
                    "generatedAt": Timestamp(date: now)
                ])
                
                // Fetch and update local windows
                let _ = try await getWindows(for: now)
                
                print("Generated \(windows.count) AI-powered windows")
            }
        }
    }
}

// MARK: - Helper Methods

private extension FirebaseDataProvider {
    /// Generate simple fallback windows when AI service is unavailable
    func generateSimpleFallbackWindows(for profile: UserProfile, date: Date) -> [MealWindow] {
        var windows: [MealWindow] = []
        let calendar = Calendar.current
        
        // Default meal times based on typical patterns
        let mealTimes: [(hour: Int, minute: Int, title: String, purpose: MealWindow.WindowPurpose)] = [
            (8, 0, "Breakfast", .metabolicBoost),
            (12, 30, "Lunch", .sustainedEnergy),
            (16, 0, "Afternoon Snack", .sustainedEnergy),
            (19, 0, "Dinner", .recovery)
        ]
        
        // Use profile's daily targets or defaults
        let totalCalories = profile.dailyCalorieTarget
        let totalProtein = profile.dailyProteinTarget
        let totalCarbs = profile.dailyCarbTarget
        let totalFat = profile.dailyFatTarget
        
        // Distribute macros across meals (40%, 30%, 10%, 20%)
        let distributions = [0.4, 0.3, 0.1, 0.2]
        
        for (index, (hour, minute, title, purpose)) in mealTimes.enumerated() {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = minute
            
            if let startTime = calendar.date(from: components),
               let endTime = calendar.date(byAdding: .hour, value: 2, to: startTime) {
                
                let distribution = distributions[index]
                let macros = MacroTargets(
                    protein: Int(Double(totalProtein) * distribution),
                    carbs: Int(Double(totalCarbs) * distribution),
                    fat: Int(Double(totalFat) * distribution)
                )
                
                let window = MealWindow(
                    id: UUID(),
                    startTime: startTime,
                    endTime: endTime,
                    targetCalories: Int(Double(totalCalories) * distribution),
                    targetMacros: macros,
                    purpose: purpose,
                    flexibility: index == 2 ? .flexible : .moderate,
                    dayDate: date,
                    name: title,
                    rationale: nil,
                    foodSuggestions: nil,
                    micronutrientFocus: nil,
                    tips: nil,
                    type: nil
                )
                windows.append(window)
            }
        }
        
        return windows
    }
    
    /// Clean up meal names by removing non-food text that may have been incorrectly included
    func cleanMealName(_ name: String) -> String {
        var cleanedName = name
        
        // Remove common non-food phrases that might appear in AI analysis
        let phrasesToRemove = [
            "on an open book",
            "on open book", 
            "on a plate",
            "on a table",
            "on a desk",
            "on a counter",
            "on a tray",
            "on a napkin",
            "in a bowl",
            "in a cup",
            "in a glass",
            "with a fork",
            "with a spoon"
        ]
        
        for phrase in phrasesToRemove {
            // Case insensitive removal
            let regex = try? NSRegularExpression(pattern: "\\s*" + NSRegularExpression.escapedPattern(for: phrase) + "\\s*", options: .caseInsensitive)
            if let regex = regex {
                cleanedName = regex.stringByReplacingMatches(in: cleanedName, options: [], range: NSRange(location: 0, length: cleanedName.count), withTemplate: "")
            }
        }
        
        // Trim whitespace
        cleanedName = cleanedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If we accidentally removed everything, return original
        if cleanedName.isEmpty {
            return name
        }
        
        return cleanedName
    }
}

// MARK: - Account Management

extension FirebaseDataProvider {
    func deleteAllUserData(userId: String) async throws {
        // Delete all user data from Firestore
        let userDocRef = db.collection("users").document(userId)
        
        // Delete ALL subcollections - including analytics and any nested collections
        let subcollections = [
            "profile", 
            "goals", 
            "meals", 
            "windows", 
            "checkIns", 
            "onboarding", 
            "insights", 
            "dayPurposes",
            "analytics"  // Added analytics collection
        ]
        
        for subcollection in subcollections {
            let documents = try await userDocRef.collection(subcollection).getDocuments()
            for document in documents.documents {
                // For analytics, also delete nested collections
                if subcollection == "analytics" {
                    // Delete the daily analytics nested collection if it exists
                    let dailyDocs = try await document.reference.collection("data").getDocuments()
                    for dailyDoc in dailyDocs.documents {
                        try await dailyDoc.reference.delete()
                    }
                }
                try await document.reference.delete()
            }
        }
        
        // Delete the main user document
        try await userDocRef.delete()
        
        print("[FirebaseDataProvider] Deleted all data for user: \(userId)")
    }
    
    // MARK: - Weight Tracking Operations
    
    func saveWeightEntry(_ entry: WeightEntry) async throws {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let data = [
            "id": entry.id.uuidString,
            "date": entry.date,
            "weight": entry.weight,
            "userId": entry.userId,
            "context": [
                "timeOfDay": entry.context.timeOfDay,
                "syncContext": entry.context.syncContext.rawValue,
                "notes": entry.context.notes ?? NSNull()
            ] as [String : Any]
        ] as [String : Any]
        
        try await userRef.collection("weightEntries")
            .document(entry.id.uuidString)
            .setData(data)
        
        Task { @MainActor in
            DebugLogger.shared.info("Saved weight entry: \(entry.weight) lbs on \(entry.date)")
        }
    }
    
    func getRecentWeightEntries(userId: String, days: Int) async -> [WeightEntry] {
        guard let userRef = userRef else {
            return []
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let snapshot = try await userRef.collection("weightEntries")
                .whereField("date", isGreaterThanOrEqualTo: startDate)
                .order(by: "date", descending: false)
                .getDocuments()
            
            let entries = snapshot.documents.compactMap { doc -> WeightEntry? in
                let data = doc.data()
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let timestamp = data["date"] as? Timestamp,
                      let weight = data["weight"] as? Double,
                      let userId = data["userId"] as? String,
                      let contextData = data["context"] as? [String: Any],
                      let timeOfDay = contextData["timeOfDay"] as? String,
                      let syncContextRaw = contextData["syncContext"] as? String,
                      let syncContext = SyncContext(rawValue: syncContextRaw) else {
                    return nil
                }
                
                let notes = contextData["notes"] as? String
                let skippedReason = contextData["skippedReason"] as? String
                let wasEstimated = contextData["wasEstimated"] as? Bool ?? false
                let context = WeightEntry.WeighInContext(
                    timeOfDay: timeOfDay,
                    syncContext: syncContext,
                    notes: notes,
                    skippedReason: skippedReason,
                    wasEstimated: wasEstimated
                )
                
                return WeightEntry(
                    id: id,
                    date: timestamp.dateValue(),
                    weight: weight,
                    context: context,
                    userId: userId
                )
            }
            
            return entries
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to fetch weight entries: \(error)")
            }
            return []
        }
    }
    
    func getLatestWeightEntry(userId: String) async throws -> WeightEntry? {
        guard let userRef = userRef else {
            throw DataProviderError.notAuthenticated
        }
        
        let snapshot = try await userRef.collection("weightEntries")
            .order(by: "date", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else {
            return nil
        }
        
        let data = doc.data()
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = data["date"] as? Timestamp,
              let weight = data["weight"] as? Double,
              let userId = data["userId"] as? String,
              let contextData = data["context"] as? [String: Any],
              let timeOfDay = contextData["timeOfDay"] as? String,
              let syncContextRaw = contextData["syncContext"] as? String,
              let syncContext = SyncContext(rawValue: syncContextRaw) else {
            return nil
        }
        
        let notes = contextData["notes"] as? String
        let skippedReason = contextData["skippedReason"] as? String
        let wasEstimated = contextData["wasEstimated"] as? Bool ?? false
        let context = WeightEntry.WeighInContext(
            timeOfDay: timeOfDay,
            syncContext: syncContext,
            notes: notes,
            skippedReason: skippedReason,
            wasEstimated: wasEstimated
        )
        
        return WeightEntry(
            id: id,
            date: timestamp.dateValue(),
            weight: weight,
            context: context,
            userId: userId
        )
    }
}

// UserProfile extensions moved to UserProfile.swift

// UserGoals extension removed - goals are part of UserProfile