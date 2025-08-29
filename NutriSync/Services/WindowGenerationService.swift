//
//  WindowGenerationService.swift
//  NutriSync
//
//  Created on 12/28/24.
//

import Foundation
import FirebaseAI

class WindowGenerationService: ObservableObject {
    @Published var isGenerating = false
    @Published var currentWindows: [MealWindow] = []
    @Published var generationError: String?
    
    private let model: GenerativeModel
    
    // Singleton
    static let shared = WindowGenerationService()
    
    private init() {
        // Initialize Firebase AI service
        let ai = FirebaseAI.firebaseAI()
        
        // Use Gemini Pro for complex window generation
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 2000
        )
        
        model = ai.generativeModel(
            modelName: "gemini-1.5-pro",
            generationConfig: config
        )
    }
    
    func generateWindows(
        profile: UserProfile,
        checkIn: MorningCheckIn,
        goals: UserGoals
    ) async throws -> [MealWindow] {
        isGenerating = true
        generationError = nil
        
        do {
            // Build the input JSON for the model
            let input = buildInputJSON(profile: profile, checkIn: checkIn, goals: goals)
            
            // Load the system prompt from file
            let systemPrompt = loadSystemPrompt()
            
            // Combine system prompt with input
            let fullPrompt = """
            \(systemPrompt)
            
            ## INPUT:
            \(input)
            """
            
            // Generate the response
            let response = try await model.generateContent(fullPrompt)
            
            guard let text = response.text else {
                throw WindowGenerationError.noResponse
            }
            
            // Log raw response for debugging
            print("🤖 AI Response (first 500 chars):")
            print(String(text.prefix(500)))
            
            // Parse the JSON response
            let windows = try parseWindowsResponse(text)
            
            print("✅ Successfully parsed \(windows.count) windows")
            
            // Validate windows
            try validateWindows(windows, checkIn: checkIn, goals: goals)
            
            // Update published windows
            await MainActor.run {
                self.currentWindows = windows
                self.isGenerating = false
            }
            
            return windows
            
        } catch {
            await MainActor.run {
                self.generationError = error.localizedDescription
                self.isGenerating = false
            }
            throw error
        }
    }
    
    // MARK: - Redistribution Logic
    
    func redistributeMissedWindow(
        missedWindow: MealWindow,
        upcomingWindows: [MealWindow],
        dailyTargets: DailyMacros
    ) -> [MealWindow] {
        let remainingWindows = upcomingWindows.filter { $0.startTime > Date() }
        
        guard !remainingWindows.isEmpty else { return upcomingWindows }
        
        // Calculate early-bias weights
        let weights = calculateEarlyBiasWeights(count: remainingWindows.count)
        
        var updatedWindows = remainingWindows
        
        for (index, window) in updatedWindows.enumerated() {
            let weight = weights[index]
            
            // Calculate redistribution amounts
            let additionalCalories = Int(Double(missedWindow.targetCalories) * weight)
            let additionalProtein = Int(Double(missedWindow.targetProtein) * weight)
            let additionalCarbs = Int(Double(missedWindow.targetCarbs) * weight)
            let additionalFat = Int(Double(missedWindow.targetFat) * weight)
            
            // Check if window is in late guard
            if isInLateGuard(window: window, bedtime: getPlannedBedtime()) {
                // Apply late guard caps (15% of daily calories max)
                let maxCalories = Int(Double(dailyTargets.calories) * 0.15)
                let currentPlusAdditional = window.targetCalories + additionalCalories
                
                if currentPlusAdditional <= maxCalories {
                    updatedWindows[index].targetCalories += additionalCalories
                    updatedWindows[index].targetProtein += additionalProtein
                    // Keep carbs modest in late guard
                    updatedWindows[index].targetCarbs += min(additionalCarbs / 2, 20)
                    updatedWindows[index].targetFat += additionalFat
                }
            } else {
                // Full redistribution for non-late-guard windows
                updatedWindows[index].targetCalories += additionalCalories
                updatedWindows[index].targetProtein += additionalProtein
                updatedWindows[index].targetCarbs += additionalCarbs
                updatedWindows[index].targetFat += additionalFat
            }
            
            // Maintain protein floor (25g minimum)
            updatedWindows[index].targetProtein = max(updatedWindows[index].targetProtein, 25)
        }
        
        return updatedWindows
    }
    
    // MARK: - Private Helpers
    
    private func loadSystemPrompt() -> String {
        // In production, this would load from the window-generation-prompt.md file
        // For now, returning the core prompt inline
        return """
        You are an advanced meal window scheduling engine. Generate a same-day eating plan optimized for the user's circadian rhythm, activities, and goals. 
        
        CRITICAL: Return ONLY valid JSON without markdown code blocks or backticks. Start with { and end with }.
        
        ## CORE CONSTRAINTS
        • All timestamps use Wake Time's date and timezone offset exactly
        • CRITICAL: NO window can start at or after bedtime. ALL windows MUST end BEFORE bedtime
        • CRITICAL: Final window MUST end 1.5-5 hours before bedtime (ideal: 2-3 hours, but allow flexibility for late sleepers)
        • Generate 2-6 windows based on user preference or auto-decide
        • Each window: 90-180 min duration; 120-240 min spacing between starts
        • No overlaps; sum of all windows' macros = daily targets (fix rounding in LAST window)
        • Use ISO8601 format for ALL timestamps (e.g., "2025-08-28T18:30:00-05:00")
        
        ## FIRST WINDOW TIMING
        • Hunger ≥7 OR Energy ≤3: start +30-45min after wake
        • Typical conditions: start +60min after wake
        • Hunger ≤3 AND Sleep ≥7: start +75-90min after wake
        
        ## EVIDENCE-BASED NUTRITION RULES
        
        ### Circadian Optimization
        • Front-load ≥55-65% daily calories before 15:30 local time
        • Largest carb portions in late morning/early afternoon
        • Late guard zone (Bedtime-180min to Bedtime): no window >15% daily calories, minimize carbs
        
        ### Activity Anchoring
        For planned activities: Insert PRE-workout ending 30-60min before, POST-workout starting 0-45min after
        Fixed meal events (eating out) have HIGHEST PRIORITY - override other rules
        
        ### Micronutrient Focus by Purpose
        • pre-workout: sodium, potassium, caffeine, B-complex
        • post-workout: leucine, magnesium, zinc, vitamin D
        • sustained-energy: fiber, iron, B-vitamins, chromium
        • recovery: protein, vitamin C, glutamine, vitamin E
        • metabolic-boost: chromium, catechins, capsaicin
        • sleep-optimization: magnesium, tryptophan, calcium
        • focus-boost: omega-3, choline, L-theanine, antioxidants
        
        ### Food Suggestions
        • Provide 3-5 INDIVIDUAL FOODS (not full meals) per window
        • Single ingredients only: "eggs", "berries", "spinach", "almonds", "salmon"
        • Filter by restrictions if hasRestrictions=true
        
        ## REQUIRED JSON FORMAT
        Return JSON with this exact structure:
        {
          "meta": {
            "date": "YYYY-MM-DD",
            "timezoneOffset": "+/-HH:MM",
            "wakeTime": "ISO8601 timestamp",
            "bedtime": "ISO8601 timestamp",
            "lateGuardStart": "ISO8601 timestamp",
            "goal": "string",
            "dailyTargets": {"calories": N, "protein": N, "carbs": N, "fat": N},
            "totalWindows": N,
            "conflictsResolved": ["string array"],
            "redistributionWeights": [optional number array]
          },
          "windows": [
            {
              "name": "Window 1",
              "startTime": "ISO8601 timestamp",
              "endTime": "ISO8601 timestamp",
              "targetCalories": N,
              "targetProtein": N,
              "targetCarbs": N,
              "targetFat": N,
              "purpose": "pre-workout|post-workout|sustained-energy|recovery|metabolic-boost|sleep-optimization|focus-boost",
              "flexibility": "fixed|moderate|flexible",
              "type": "regular|pre-workout|post-workout",
              "rationale": "string",
              "foodSuggestions": ["food1", "food2", "food3"],
              "micronutrientFocus": ["nutrient1", "nutrient2"],
              "activityLinked": "optional string"
            }
          ]
        }
        """
    }
    
    private func buildInputJSON(
        profile: UserProfile,
        checkIn: MorningCheckIn,
        goals: UserGoals
    ) -> String {
        let profileDict: [String: Any] = [
            "age": profile.age,
            "gender": profile.gender.rawValue,
            "weight": profile.weight,
            "goal": goals.primaryGoal.rawValue,
            "activityLevel": goals.activityLevel.rawValue,
            "hasRestrictions": checkIn.hasRestrictions,
            "restrictions": checkIn.restrictions
        ]
        
        let checkInDict: [String: Any] = [
            "wakeTime": ISO8601DateFormatter().string(from: checkIn.wakeTime),
            "bedtime": ISO8601DateFormatter().string(from: checkIn.plannedBedtime),
            "sleepQuality": checkIn.sleepQuality,
            "energyLevel": checkIn.energyLevel,
            "hungerLevel": checkIn.hungerLevel,
            "plannedActivities": checkIn.plannedActivities,
            "windowPreference": checkIn.windowPreference.jsonValue
        ]
        
        let dailyTargetsDict: [String: Any] = [
            "calories": goals.dailyCalories ?? 2000,
            "protein": goals.dailyProtein ?? 150,
            "carbs": goals.dailyCarbs ?? 250,
            "fat": goals.dailyFat ?? 67
        ]
        
        let input: [String: Any] = [
            "profile": profileDict,
            "checkIn": checkInDict,
            "dailyTargets": dailyTargetsDict
        ]
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: input, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func parseWindowsResponse(_ json: String) throws -> [MealWindow] {
        // Clean the JSON string - remove markdown code blocks if present
        var cleanedJSON = json
        
        // Remove ```json or ``` markers
        if cleanedJSON.contains("```") {
            // Find the content between the backticks
            let lines = cleanedJSON.components(separatedBy: .newlines)
            var inCodeBlock = false
            var jsonLines: [String] = []
            
            for line in lines {
                if line.hasPrefix("```") {
                    inCodeBlock.toggle()
                    continue
                }
                if inCodeBlock {
                    jsonLines.append(line)
                }
            }
            
            // If we found content in code blocks, use it
            if !jsonLines.isEmpty {
                cleanedJSON = jsonLines.joined(separator: "\n")
            }
        }
        
        // Trim whitespace
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw WindowGenerationError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(WindowGenerationResponse.self, from: jsonData)
        
        return response.windows.map { windowData in
            MealWindow(
                id: UUID(),
                name: windowData.name,
                startTime: ISO8601DateFormatter().date(from: windowData.startTime) ?? Date(),
                endTime: ISO8601DateFormatter().date(from: windowData.endTime) ?? Date(),
                targetCalories: windowData.targetCalories,
                targetProtein: windowData.targetProtein,
                targetCarbs: windowData.targetCarbs,
                targetFat: windowData.targetFat,
                purpose: MealWindow.WindowPurpose(rawValue: windowData.purpose) ?? .sustainedEnergy,
                flexibility: MealWindow.Flexibility(rawValue: windowData.flexibility) ?? .moderate,
                type: MealWindow.WindowType(rawValue: windowData.type) ?? .regular,
                foodSuggestions: windowData.foodSuggestions,
                micronutrientFocus: windowData.micronutrientFocus,
                rationale: windowData.rationale,
                activityLinked: windowData.activityLinked,
                consumed: MealWindow.ConsumedMacros()
            )
        }
    }
    
    private func validateWindows(_ windows: [MealWindow], checkIn: MorningCheckIn, goals: UserGoals) throws {
        // Validate same date
        let wakeDate = Calendar.current.dateComponents([.year, .month, .day], from: checkIn.wakeTime)
        for window in windows {
            let windowDate = Calendar.current.dateComponents([.year, .month, .day], from: window.startTime)
            guard wakeDate == windowDate else {
                throw WindowGenerationError.invalidDate
            }
            
            // CRITICAL: No window can start at or after bedtime
            guard window.startTime < checkIn.plannedBedtime else {
                print("❌ Window '\(window.name ?? "")' starts at or after bedtime!")
                print("  - Window starts: \(window.startTime)")
                print("  - Bedtime: \(checkIn.plannedBedtime)")
                throw WindowGenerationError.windowAfterBedtime
            }
            
            // CRITICAL: No window can end after bedtime
            guard window.endTime <= checkIn.plannedBedtime else {
                print("❌ Window '\(window.name ?? "")' ends after bedtime!")
                print("  - Window ends: \(window.endTime)")
                print("  - Bedtime: \(checkIn.plannedBedtime)")
                throw WindowGenerationError.windowAfterBedtime
            }
        }
        
        // Validate final window timing (2-3h before bed)
        guard let lastWindow = windows.last else {
            throw WindowGenerationError.noWindows
        }
        
        let timeToBed = checkIn.plannedBedtime.timeIntervalSince(lastWindow.endTime)
        
        // Add debug logging
        print("🔍 Window Validation Debug:")
        print("  - Last window ends: \(lastWindow.endTime)")
        print("  - Planned bedtime: \(checkIn.plannedBedtime)")
        print("  - Time to bed: \(timeToBed / 3600) hours")
        print("  - Expected: 1.5-5 hours")
        
        // Allow more flexibility for late bedtimes (1.5-5 hours)
        guard timeToBed >= 5400 && timeToBed <= 18000 else { // 1.5-5 hours in seconds
            print("❌ Validation failed: Time to bed is \(timeToBed / 3600) hours")
            throw WindowGenerationError.invalidFinalWindowTiming
        }
        
        // Validate macro totals (within 5% tolerance)
        let totalCalories = windows.reduce(0) { $0 + $1.targetCalories }
        let targetCalories = goals.dailyCalories ?? 2000
        let caloriesDiff = abs(Double(totalCalories - targetCalories)) / Double(targetCalories)
        
        guard caloriesDiff <= 0.05 else {
            throw WindowGenerationError.macroMismatch
        }
    }
    
    private func calculateEarlyBiasWeights(count: Int) -> [Double] {
        switch count {
        case 1: return [1.0]
        case 2: return [0.6, 0.4]
        case 3: return [0.5, 0.3, 0.2]
        case 4: return [0.4, 0.3, 0.2, 0.1]
        default: 
            var weights = [0.4, 0.3, 0.2]
            let remaining = 0.1 / Double(count - 3)
            for _ in 3..<count {
                weights.append(remaining)
            }
            return weights
        }
    }
    
    private func isInLateGuard(window: MealWindow, bedtime: Date) -> Bool {
        let lateGuardStart = bedtime.addingTimeInterval(-180 * 60) // 180 minutes before bed
        return window.startTime >= lateGuardStart
    }
    
    private func getPlannedBedtime() -> Date {
        // In production, this would fetch from the current day's check-in
        // For now, returning a default 10pm
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Supporting Types

enum WindowGenerationError: LocalizedError {
    case noResponse
    case invalidJSON
    case invalidDate
    case noWindows
    case invalidFinalWindowTiming
    case macroMismatch
    case windowAfterBedtime
    
    var errorDescription: String? {
        switch self {
        case .noResponse: return "No response from AI model"
        case .invalidJSON: return "Invalid JSON response"
        case .invalidDate: return "Windows not on same date as wake time"
        case .noWindows: return "No windows generated"
        case .invalidFinalWindowTiming: return "Final window timing issue - should end 1.5-5h before bed"
        case .macroMismatch: return "Window macros don't match daily targets"
        case .windowAfterBedtime: return "Window extends past planned bedtime"
        }
    }
}

// Response structure from AI
struct WindowGenerationResponse: Codable {
    let meta: WindowMeta
    let windows: [WindowData]
    
    struct WindowMeta: Codable {
        let date: String
        let timezoneOffset: String
        let wakeTime: String
        let bedtime: String
        let lateGuardStart: String
        let goal: String
        let dailyTargets: DailyTargetsResponse
        let totalWindows: Int
        let conflictsResolved: [String]
        let redistributionWeights: [Double]?
        
        struct DailyTargetsResponse: Codable {
            let calories: Int
            let protein: Int
            let carbs: Int
            let fat: Int
        }
    }
    
    struct WindowData: Codable {
        let name: String
        let startTime: String
        let endTime: String
        let targetCalories: Int
        let targetProtein: Int
        let targetCarbs: Int
        let targetFat: Int
        let purpose: String
        let flexibility: String
        let type: String
        let rationale: String
        let foodSuggestions: [String]
        let micronutrientFocus: [String]
        let activityLinked: String?
    }
}

// Daily macro targets
struct DailyMacros {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}