//
//  AIWindowGenerationService.swift
//  NutriSync
//
//  AI-powered window generation service using Google Gemini
//

import Foundation
import FirebaseAI
import FirebaseFirestore

/// Service responsible for generating personalized meal windows using AI
class AIWindowGenerationService {
    static let shared = AIWindowGenerationService()
    private let model: GenerativeModel
    
    private init() {
        // Initialize Firebase AI service
        let ai = FirebaseAI.firebaseAI()
        
        // Configure generation parameters for structured JSON output
        let config = GenerationConfig(
            temperature: 0.8,  // Slightly creative for variety
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 4096,  // Larger for detailed windows
            responseMIMEType: "application/json"
        )
        
        // Use Gemini 2.0 Flash for fast, detailed responses
        self.model = ai.generativeModel(
            modelName: "gemini-2.0-flash-exp",
            generationConfig: config
        )
    }
    
    /// Generate AI-powered meal windows with rich content
    /// - Parameters:
    ///   - profile: User's profile with goals and preferences
    ///   - checkIn: Morning check-in data with wake time and energy levels
    ///   - date: Date to generate windows for
    /// - Returns: Array of meal windows with AI-generated content
    func generateWindows(
        for profile: UserProfile,
        checkIn: MorningCheckInData?,
        date: Date
    ) async throws -> [MealWindow] {
        
        // TODO: Implement Gemini API call here
        // This should generate windows with:
        // - Personalized names (e.g., "Afternoon Energy Boost")
        // - Food suggestions based on goals
        // - Micronutrient focus for each window
        // - Tips for optimization
        // - Rationale for timing and content
        
        let prompt = buildPrompt(profile: profile, checkIn: checkIn, date: date)
        
        Task { @MainActor in
            DebugLogger.shared.info("Calling Gemini AI for window generation")
            DebugLogger.shared.info("User goal: \(profile.primaryGoal.displayName)")
        }
        
        // Call Gemini AI
        let response = try await model.generateContent(prompt)
        
        guard let text = response.text else {
            Task { @MainActor in
                DebugLogger.shared.error("No response text from Gemini")
            }
            throw NSError(
                domain: "AIWindowGeneration",
                code: 3001,
                userInfo: [NSLocalizedDescriptionKey: "No response from AI"]
            )
        }
        
        Task { @MainActor in
            DebugLogger.shared.info("Received response from Gemini, parsing JSON...")
            DebugLogger.shared.info("Raw AI response (first 500 chars): \(String(text.prefix(500)))")
        }
        
        // Parse the JSON response
        return try parseAIResponse(text, for: date)
    }
    
    /// Build the prompt for AI window generation
    private func buildPrompt(
        profile: UserProfile,
        checkIn: MorningCheckInData?,
        date: Date
    ) -> String {
        // Get timezone information
        let timeZone = TimeZone.current
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        
        // Create a simple time formatter for human-readable times
        let simpleTimeFormatter = DateFormatter()
        simpleTimeFormatter.timeStyle = .short
        simpleTimeFormatter.timeZone = timeZone
        
        // Get wake time for today
        let calendar = Calendar.current
        let wakeTime: Date
        let wakeTimeString: String
        let wakeTimeSimple: String
        
        if let checkIn = checkIn {
            wakeTime = checkIn.wakeTime
            // Format wake time as ISO8601 for today
            let wakeComponents = calendar.dateComponents([.hour, .minute], from: checkIn.wakeTime)
            let todayWakeTime = calendar.date(bySettingHour: wakeComponents.hour ?? 7, 
                                               minute: wakeComponents.minute ?? 0, 
                                               second: 0, 
                                               of: date) ?? date
            wakeTimeString = formatter.string(from: todayWakeTime)
            wakeTimeSimple = simpleTimeFormatter.string(from: todayWakeTime)
            
            // Debug logging
            Task { @MainActor in
                DebugLogger.shared.info("Wake time being sent to AI:")
                DebugLogger.shared.info("  Original checkIn.wakeTime: \(checkIn.wakeTime)")
                DebugLogger.shared.info("  Today wake time: \(todayWakeTime)")
                DebugLogger.shared.info("  ISO8601 string: \(wakeTimeString)")
                DebugLogger.shared.info("  Simple format: \(wakeTimeSimple)")
                DebugLogger.shared.info("  Timezone: \(timeZone.identifier) (offset: \(timeZone.secondsFromGMT() / 3600) hours)")
            }
        } else {
            // Default wake time: 7 AM today
            let defaultWakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date
            wakeTime = defaultWakeTime
            wakeTimeString = formatter.string(from: defaultWakeTime)
            wakeTimeSimple = simpleTimeFormatter.string(from: defaultWakeTime)
        }
        
        // Calculate example window times based on actual wake time
        let firstWindowStart = wakeTime.addingTimeInterval(60 * 60) // 1 hour after waking
        let firstWindowEnd = firstWindowStart.addingTimeInterval(90 * 60) // 1.5 hour window
        
        var prompt = """
        Generate a personalized meal window schedule for the following user:
        
        ## User Profile
        - Goal: \(profile.primaryGoal.displayName)
        - Age: \(profile.age)
        - Gender: \(profile.gender)
        - Weight: \(profile.weight) lbs
        - Height: \(profile.height) inches
        - Activity Level: \(profile.activityLevel.rawValue)
        - Daily Calorie Target: \(profile.dailyCalorieTarget)
        - Daily Protein Target: \(profile.dailyProteinTarget)g
        - Daily Carb Target: \(profile.dailyCarbTarget)g
        - Daily Fat Target: \(profile.dailyFatTarget)g
        """
        
        if let checkIn = checkIn {
            prompt += """
            
            ## Morning Check-In
            - Wake Time: \(wakeTimeString) (ISO8601 format)
            - Wake Time (human readable): \(wakeTimeSimple) local time
            - Sleep Quality: \(checkIn.sleepQuality)/10
            - Energy Level: \(checkIn.energyLevel)/10
            - Hunger Level: \(checkIn.hungerLevel)/10
            - Planned Activities: \(checkIn.plannedActivities.joined(separator: ", "))
            """
        } else {
            // No check-in, use reasonable defaults
            prompt += """
            
            ## Morning Check-In (Default - No check-in completed)
            - Wake Time: \(wakeTimeString) (ISO8601 format)
            - Wake Time (human readable): \(wakeTimeSimple) local time
            - Sleep Quality: 7/10
            - Energy Level: 3/5
            - Hunger Level: 3/5
            - Planned Activities: Regular work day
            """
        }
        
        // Format today's date for the prompt
        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        let todayString = dateOnlyFormatter.string(from: date)
        
        prompt += """
        
        ## Requirements
        Generate 4-6 meal windows for TODAY (\(todayString)) optimized for the user's goal with:
        1. Window timing based on the WAKE TIME provided above (not fixed hours)
        2. First meal window should start 30-90 minutes after wake time  
        3. Space windows appropriately throughout the day (2-4 hours apart)
        4. Last meal should be 2-3 hours before typical bedtime (assume 10-11 PM if not specified)
        5. Personalized window names (not generic breakfast/lunch/dinner)
        6. Food suggestions (2-3 specific foods per window)
        7. Micronutrient focus (2-3 vitamins/minerals to prioritize)
        8. Optimization tips (2-3 actionable tips)
        9. Rationale explaining why this window supports their goal
        10. Appropriate macro distribution based on window purpose
        
        CRITICAL TIMEZONE INSTRUCTIONS:
        - The wake time is \(wakeTimeSimple) in the user's LOCAL timezone
        - ALL window times MUST use the EXACT SAME timezone offset as the wake time ISO8601 string above
        - For example, if wake time is "2025-08-25T06:20:00-05:00", ALL your times must end with "-05:00"
        - The first window should start around \(simpleTimeFormatter.string(from: firstWindowStart)) local time
        - Do NOT convert to UTC (+00:00). Keep the LOCAL timezone offset.
        
        Return as JSON array with this structure:
        {
            "windows": [
                {
                    "name": "Morning Metabolic Primer",
                    "startTime": "\(formatter.string(from: firstWindowStart))",
                    "endTime": "\(formatter.string(from: firstWindowEnd))",
                    "targetCalories": 450,
                    "targetProtein": 30,
                    "targetCarbs": 50,
                    "targetFat": 15,
                    "purpose": "metabolicBoost",
                    "flexibility": "moderate",
                    "type": "regular",
                    "rationale": "Kickstart metabolism after overnight fast with balanced macros",
                    "foodSuggestions": ["Oatmeal with berries and nuts", "Greek yogurt parfait", "Eggs with whole grain toast"],
                    "micronutrientFocus": ["vitamin D", "calcium", "fiber"],
                    "tips": ["Eat within 30 minutes of waking", "Include protein to stabilize blood sugar", "Stay hydrated"]
                }
            ]
        }
        """
        
        return prompt
    }
    
    /// Format time for prompt
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Parse AI response into MealWindow objects
    private func parseAIResponse(_ response: String, for date: Date) throws -> [MealWindow] {
        guard let data = response.data(using: .utf8) else {
            throw NSError(domain: "AIWindowGeneration", code: 3002, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        
        // Use a custom date decoding strategy that handles timezone properly
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try parsing with full ISO8601 formatter first
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to basic ISO8601 if needed
            let basicFormatter = ISO8601DateFormatter()
            if let date = basicFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, 
                debugDescription: "Cannot decode date string \(dateString)")
        }
        
        do {
            let aiResponse = try decoder.decode(AIWindowResponse.self, from: data)
            
            Task { @MainActor in
                DebugLogger.shared.success("Parsed \(aiResponse.windows.count) windows from AI response")
                for window in aiResponse.windows {
                    DebugLogger.shared.info("AI Window: \(window.name)")
                    DebugLogger.shared.info("  Start: \(window.startTime)")
                    DebugLogger.shared.info("  End: \(window.endTime)")
                }
            }
            
            // Convert to MealWindow objects
            let calendar = Calendar.current
            let dayDate = calendar.startOfDay(for: date)
            
            return aiResponse.windows.map { window in
                MealWindow(
                    startTime: window.startTime,
                    endTime: window.endTime,
                    targetCalories: window.targetCalories,
                    targetMacros: MacroTargets(
                        protein: window.targetProtein,
                        carbs: window.targetCarbs,
                        fat: window.targetFat
                    ),
                    purpose: mapPurpose(window.purpose),
                    flexibility: mapFlexibility(window.flexibility),
                    dayDate: dayDate,
                    name: window.name,
                    rationale: window.rationale,
                    foodSuggestions: window.foodSuggestions,
                    micronutrientFocus: window.micronutrientFocus,
                    tips: window.tips,
                    type: window.type
                )
            }
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to parse AI response: \(error)")
                DebugLogger.shared.error("Response was: \(String(response.prefix(500)))")
            }
            throw error
        }
    }
}

// MARK: - AI Response Models
private struct AIWindowResponse: Codable {
    let windows: [AIWindow]
}

private struct AIWindow: Codable {
    let name: String
    let startTime: Date
    let endTime: Date
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
    let tips: [String]
}

// MARK: - Purpose Mapping
extension AIWindowGenerationService {
    /// Map AI-generated purpose strings to WindowPurpose enum
    private func mapPurpose(_ purposeString: String) -> WindowPurpose {
        switch purposeString.lowercased() {
        case "preworkout", "pre-workout":
            return .preworkout
        case "postworkout", "post-workout":
            return .postworkout
        case "sustainedenergy", "sustained-energy", "sustained energy":
            return .sustainedEnergy
        case "recovery":
            return .recovery
        case "metabolicboost", "metabolic-boost", "metabolic boost":
            return .metabolicBoost
        case "sleepoptimization", "sleep-optimization", "sleep optimization":
            return .sleepOptimization
        case "focusboost", "focus-boost", "focus boost":
            return .focusBoost
        default:
            return .sustainedEnergy
        }
    }
    
    /// Map flexibility strings to WindowFlexibility enum
    private func mapFlexibility(_ flexibilityString: String) -> WindowFlexibility {
        switch flexibilityString.lowercased() {
        case "strict":
            return .strict
        case "moderate":
            return .moderate
        case "flexible":
            return .flexible
        default:
            return .moderate
        }
    }
}
