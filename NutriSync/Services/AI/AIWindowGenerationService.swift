//
//  AIWindowGenerationService.swift
//  NutriSync
//
//  AI-powered window generation service using Google Gemini
//

import Foundation
import FirebaseAI
import FirebaseFirestore

/// Schedule types for different user patterns
enum ScheduleType {
    case earlyBird      // Wake: 4-7am
    case standard       // Wake: 7-10am  
    case nightOwl       // Wake: 10am-2pm
    case nightShift     // Wake: 2pm+ or sleep during day
    
    static func detect(wakeTime: Date, bedTime: Date) -> ScheduleType {
        let hour = Calendar.current.component(.hour, from: wakeTime)
        let sleepHour = Calendar.current.component(.hour, from: bedTime)
        
        if sleepHour >= 4 && sleepHour <= 10 { // Sleep during day
            return .nightShift
        } else if hour >= 14 { // Wake after 2pm
            return .nightShift
        } else if hour >= 10 {
            return .nightOwl
        } else if hour < 7 {
            return .earlyBird
        }
        return .standard
    }
}

/// Context-aware window name generator
struct WindowNameGenerator {
    struct Context {
        let windowIndex: Int
        let totalWindows: Int
        let scheduleType: ScheduleType
        let isPreWorkout: Bool
        let isPostWorkout: Bool
        let timeOfDay: TimeOfDay
        let userGoal: UserGoals.Goal
        let isFirstMeal: Bool
        let isLastMeal: Bool
    }
    
    enum TimeOfDay {
        case earlyMorning  // 5-8am
        case morning       // 8-11am
        case midday        // 11am-2pm
        case afternoon     // 2-5pm
        case evening       // 5-8pm
        case lateNight     // 8pm+
        
        static func from(hour: Int) -> TimeOfDay {
            switch hour {
            case 5..<8: return .earlyMorning
            case 8..<11: return .morning
            case 11..<14: return .midday
            case 14..<17: return .afternoon
            case 17..<20: return .evening
            default: return .lateNight
            }
        }
    }
    
    static func generate(context: Context) -> String {
        // Priority order for naming
        if context.isPreWorkout {
            return preWorkoutName(context)
        } else if context.isPostWorkout {
            return postWorkoutName(context)
        } else if context.isFirstMeal {
            return firstMealName(context)
        } else if context.isLastMeal {
            return lastMealName(context)
        } else {
            return functionalName(context)
        }
    }
    
    private static func preWorkoutName(_ context: Context) -> String {
        switch context.userGoal {
        case .buildMuscle:
            return "Anabolic Primer"
        case .improvePerformance:
            return "Performance Fuel"
        case .loseWeight:
            return "Pre-Training Energy"
        case .betterSleep:
            return "Active Energy"
        case .maintainWeight, .overallHealth:
            return "Pre-Activity Boost"
        }
    }
    
    private static func postWorkoutName(_ context: Context) -> String {
        let baseNames = [
            "Recovery Window",
            "Post-Training Recovery", 
            "Anabolic Window",
            "Muscle Recovery"
        ]
        // Add time context for late workouts
        if context.timeOfDay == .lateNight {
            return "Night Recovery"
        }
        return baseNames.randomElement() ?? "Recovery Window"
    }
    
    private static func firstMealName(_ context: Context) -> String {
        switch context.scheduleType {
        case .nightShift:
            return "First Meal" // Not "breakfast" at 8pm
        case .nightOwl:
            return "Late Morning Fuel"
        case .earlyBird:
            return "Dawn Foundation"
        default:
            return "Morning Foundation"
        }
    }
    
    private static func lastMealName(_ context: Context) -> String {
        switch context.scheduleType {
        case .nightShift:
            return "Pre-Sleep Wind Down"
        case .nightOwl:
            return "Late Night Sustainer"
        case .earlyBird:
            return "Early Evening Closure"
        default:
            return "Evening Wind-Down"
        }
    }
    
    private static func functionalName(_ context: Context) -> String {
        // Generate based on time and goal
        let timePrefix: String
        switch context.timeOfDay {
        case .earlyMorning: timePrefix = "Early"
        case .morning: timePrefix = "Morning"
        case .midday: timePrefix = "Midday"
        case .afternoon: timePrefix = "Afternoon"
        case .evening: timePrefix = "Evening"
        case .lateNight: timePrefix = "Late"
        }
        
        let goalSuffix: String
        switch context.userGoal {
        case .loseWeight: goalSuffix = "Metabolic Boost"
        case .buildMuscle: goalSuffix = "Growth Window"
        case .improvePerformance: goalSuffix = "Energy Sustainer"
        case .betterSleep: goalSuffix = "Balance Window"
        case .maintainWeight, .overallHealth: goalSuffix = "Nourishment"
        }
        
        return "\(timePrefix) \(goalSuffix)"
    }
}

/// Window name validator for quality control
struct WindowNameValidator {
    static let genericPatterns = [
        "Window \\d+",
        "Meal \\d+",
        "Eating Window \\d+",
        "Period \\d+"
    ]
    
    static func isGeneric(_ name: String) -> Bool {
        for pattern in genericPatterns {
            if name.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
    
    static func logForReview(_ window: MealWindow, reason: String) {
        Task { @MainActor in
            DebugLogger.shared.warning("Window name review needed: '\(window.name)' - Reason: \(reason)")
        }
        
        // Log to Firebase for manual review (if connected)
        Task {
            do {
                let db = Firestore.firestore()
                let log: [String: Any] = [
                    "windowName": window.name,
                    "reason": reason,
                    "timestamp": Date(),
                    "windowId": window.id.uuidString,
                    "startTime": window.startTime,
                    "windowType": window.purpose.rawValue
                ]
                
                try await db.collection("windowNameReviews").addDocument(data: log)
            } catch {
                // Silently fail if Firebase is not configured
                print("Could not log window name for review: \(error)")
            }
        }
    }
}

/// Enhanced workout parser for activity detection
struct WorkoutParser {
    struct WorkoutInfo {
        let time: Date
        let isLateNight: Bool  // After 8pm
        let isFasted: Bool      // Before 8am with no prior window
        let intensity: WorkoutIntensity
    }
    
    enum WorkoutIntensity {
        case light
        case moderate
        case high
    }
    
    static func parseWorkouts(from activities: [String], baseDate: Date) -> [WorkoutInfo] {
        var workouts: [WorkoutInfo] = []
        let calendar = Calendar.current
        
        for activity in activities {
            let lowercased = activity.lowercased()
            
            // Enhanced regex patterns for various formats
            let patterns = [
                (pattern: "workout.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.moderate),
                (pattern: "gym.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.high),
                (pattern: "training.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.high),
                (pattern: "exercise.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.moderate),
                (pattern: "run.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.moderate),
                (pattern: "lift.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.high),
                (pattern: "yoga.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.light),
                (pattern: "walk.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", intensity: WorkoutIntensity.light)
            ]
            
            // Also check for simple presence of workout keywords
            let simpleKeywords = ["workout", "gym", "training", "exercise", "run", "lift", "yoga", "walk", "fitness"]
            var foundWorkout = false
            
            for (pattern, intensity) in patterns {
                if let _ = lowercased.range(of: pattern, options: .regularExpression) {
                    // Try to extract time, or use default afternoon time
                    let workoutTime = parseWorkoutTime(from: lowercased, baseDate: baseDate) ?? 
                                     calendar.date(bySettingHour: 16, minute: 0, second: 0, of: baseDate) ?? baseDate
                    
                    let hour = calendar.component(.hour, from: workoutTime)
                    let workout = WorkoutInfo(
                        time: workoutTime,
                        isLateNight: hour >= 20,
                        isFasted: hour < 8,
                        intensity: intensity
                    )
                    workouts.append(workout)
                    foundWorkout = true
                    break
                }
            }
            
            // If no pattern matched but keyword exists, add default workout
            if !foundWorkout {
                for keyword in simpleKeywords {
                    if lowercased.contains(keyword) {
                        let defaultTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: baseDate) ?? baseDate
                        let workout = WorkoutInfo(
                            time: defaultTime,
                            isLateNight: false,
                            isFasted: false,
                            intensity: .moderate
                        )
                        workouts.append(workout)
                        break
                    }
                }
            }
        }
        
        return workouts
    }
    
    private static func parseWorkoutTime(from text: String, baseDate: Date) -> Date? {
        let calendar = Calendar.current
        
        // Try to extract time from text
        let timePattern = "(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?"
        guard let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive) else {
            return nil
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard let match = matches.first else { return nil }
        
        // Extract hour
        guard let hourRange = Range(match.range(at: 1), in: text),
              let hour = Int(text[hourRange]) else { return nil }
        
        // Extract minute if present
        var minute = 0
        if let minuteRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minuteRange]) ?? 0
        }
        
        // Check for AM/PM
        var adjustedHour = hour
        if let ampmRange = Range(match.range(at: 3), in: text) {
            let ampm = text[ampmRange].lowercased()
            if ampm == "pm" && hour < 12 {
                adjustedHour = hour + 12
            } else if ampm == "am" && hour == 12 {
                adjustedHour = 0
            }
        }
        
        return calendar.date(bySettingHour: adjustedHour, minute: minute, second: 0, of: baseDate)
    }
    
    /// Determine dynamic window count based on workouts and schedule
    static func determineWindowCount(workouts: [WorkoutInfo], scheduleType: ScheduleType) -> Int {
        let baseWindows = 3
        var additionalWindows = 0
        
        for workout in workouts {
            if workout.isLateNight {
                // Late workout needs recovery window that might cross midnight
                additionalWindows += 2 // Pre + extended post
            } else if workout.isFasted {
                // Fasted workout needs careful fueling
                additionalWindows += 2 // Light pre + substantial post
            } else {
                // Standard workout
                additionalWindows += 1 // Combined pre/post window
            }
        }
        
        // Cap at 6 windows max
        return min(baseWindows + additionalWindows, 6)
    }
}

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
        
        // Determine actual date for windows based on check-in time
        let actualDate = determineWindowDate(checkIn: checkIn, requestedDate: date)
        
        let prompt = buildPrompt(profile: profile, checkIn: checkIn, date: actualDate)
        
        Task { @MainActor in
            DebugLogger.shared.info("Calling Gemini AI for window generation")
            DebugLogger.shared.info("User goal: \(profile.primaryGoal.displayName)")
            DebugLogger.shared.info("Requested date: \(date), Actual date for windows: \(actualDate)")
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
        
        // Parse the JSON response with the actual date
        return try parseAIResponse(text, for: actualDate)
    }
    
    /// Determine the correct date for window generation based on check-in time
    private func determineWindowDate(checkIn: MorningCheckInData?, requestedDate: Date) -> Date {
        // IMPORTANT: Always use the requested date (today) for window generation
        // Don't try to be smart about incrementing to tomorrow based on time of day
        // If the user does a morning check-in at ANY time, they want windows for TODAY
        // The only exception would be if it's actually past midnight, but that's handled
        // by the requestedDate already being tomorrow
        return requestedDate
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
            
            // Use the date parameter which has already been adjusted in generateWindows
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
        
        // Calculate example window times based on TODAY'S wake time (not the original wakeTime)
        let todayWakeTime = calendar.date(bySettingHour: calendar.dateComponents([.hour, .minute], from: wakeTime).hour ?? 7,
                                          minute: calendar.dateComponents([.hour, .minute], from: wakeTime).minute ?? 0,
                                          second: 0,
                                          of: date) ?? date
        let firstWindowStart = todayWakeTime.addingTimeInterval(60 * 60) // 1 hour after waking
        let firstWindowEnd = firstWindowStart.addingTimeInterval(120 * 60) // 2 hour window
        
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
        
        // Detect schedule type
        let bedTime = checkIn?.plannedBedtime ?? calendar.date(bySettingHour: 22, minute: 30, second: 0, of: date) ?? date
        let scheduleType = ScheduleType.detect(wakeTime: wakeTime, bedTime: bedTime)
        
        if let checkIn = checkIn {
            prompt += """
            
            ## Morning Check-In
            - Wake Time: \(wakeTimeString) (ISO8601 format)
            - Wake Time (human readable): \(wakeTimeSimple) local time
            - Sleep Quality: \(checkIn.sleepQuality)/10
            - Energy Level: \(checkIn.energyLevel)/10
            - Hunger Level: \(checkIn.hungerLevel)/10
            - Planned Activities: \(checkIn.plannedActivities.joined(separator: ", "))
            - Schedule Type: \(String(describing: scheduleType))
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
            - Schedule Type: \(String(describing: scheduleType))
            """
        }
        
        // Format today's date for the prompt
        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        let todayString = dateOnlyFormatter.string(from: date)
        
        prompt += """
        
        ## Requirements
        Generate 4-6 meal windows for THE SAME DAY AS THE WAKE TIME (\(todayString)) optimized for the user's goal with:
        1. Window timing based on the WAKE TIME provided above (not fixed hours)
        2. First meal window should start 30-90 minutes after wake time  
        3. CRITICAL: Each window MUST be between 1.5 to 3 hours in duration (90-180 minutes)
        4. Space windows appropriately throughout the day (2-4 hours apart)
        5. Last meal should be 2-3 hours before typical bedtime (assume 10-11 PM if not specified)
        6. Creative, contextual window names based on:
           - Window purpose and timing (e.g., "Morning Metabolic Primer", "Pre-Workout Fuel", "Recovery Feast")  
           - User's goal (e.g., for weight loss: "Fat Burning Window", "Metabolic Boost")
           - Planned activities (e.g., "Post-Gym Protein Load", "Pre-Meeting Energy")
           - Never use generic names like "Window 1", "Window 2", "Breakfast", "Lunch", "Dinner"
        7. Food suggestions (2-3 specific foods per window)
        8. Micronutrient focus (2-3 vitamins/minerals to prioritize)
        9. Optimization tips (2-3 actionable tips)
        10. Rationale explaining why this window supports their goal
        11. Appropriate macro distribution based on window purpose
        
        CRITICAL DATE AND TIMEZONE INSTRUCTIONS:
        - The wake time is \(wakeTimeSimple) in the user's LOCAL timezone
        - ALL windows MUST be for THE SAME DATE as the wake time (\(todayString))
        - If wake time is on \(todayString), ALL windows must be on \(todayString)
        - Do NOT generate windows for the next day
        - NO WINDOW should cross midnight - all windows must end before 11:59 PM on \(todayString)
        - If a window would naturally extend past midnight, end it at 11:30 PM instead
        - ALL window times MUST use the EXACT SAME timezone offset as the wake time ISO8601 string above
        - For example, if wake time is "2025-08-26T05:00:00-05:00", ALL your windows must be on 2025-08-26 and end with "-05:00"
        - The first window should start around \(simpleTimeFormatter.string(from: firstWindowStart)) local time ON THE SAME DAY
        - Do NOT convert to UTC (+00:00). Keep the LOCAL timezone offset.
        - IMPORTANT: Each window's endTime must be LATER than its startTime on the SAME date
        
        ## Window Naming Examples by Goal:
        - Weight Loss: "Fat Burning Primer", "Metabolic Acceleration", "Satiety Sustainer", "Evening Wind-Down"
        - Muscle Building: "Anabolic Kickstart", "Pre-Training Fuel", "Post-Workout Recovery", "Growth Window"
        - Performance: "Energy Foundation", "Performance Fuel", "Recovery & Adaptation", "Sleep Prep Nutrition"
        - Better Sleep: "Gentle Awakening", "Sustained Energy", "Light & Early", "Sleep Optimization"
        - General Health: "Morning Vitality", "Midday Balance", "Afternoon Energy", "Evening Nourishment"
        
        ## Window Naming Based on Activities:
        - If user has "gym" or "workout": Include "Pre-Workout Fuel" or "Post-Training Recovery"
        - If user has "meetings" or "work": Include "Focus Fuel" or "Brain Power Window"
        - If user has no activities: Focus on metabolic and energy-based names
        
        ## Schedule-Specific Instructions:
        """
        
        // Add schedule-specific instructions
        switch scheduleType {
        case .nightShift:
            prompt += """
        CRITICAL: User works night shift or has nocturnal schedule.
        - First window should be their "breakfast" even if at evening time (8pm, etc.)
        - Respect their biological clock (their morning is evening time)
        - Include a "Pre-Work Energy" window if they work nights
        - Avoid traditional meal names like "dinner" for their first meal
        - Use functional names: "First Meal", "Pre-Shift Energy", "Mid-Shift Fuel", "Recovery Window"
        - Their last window might be morning time (6-8am) which is their "evening"
        """
        case .nightOwl:
            prompt += """
        User is a night owl (late riser).
        - Compress or skip traditional morning windows if waking after 11am
        - Focus on afternoon/evening optimization
        - Later workout windows are normal for this user
        - Use names like "Late Morning Fuel", "Afternoon Foundation", "Evening Performance"
        - Their peak energy is likely in evening/night hours
        """
        case .earlyBird:
            prompt += """
        User is an early bird (early riser).
        - First window can start within 30 minutes of waking
        - Morning is their peak performance time
        - Earlier workout windows are optimal
        - Last window should be well before 8pm for optimal sleep
        - Use energizing morning names: "Dawn Fuel", "Early Bird Energy", "Morning Power"
        """
        case .standard:
            prompt += """
        User has standard schedule.
        - Follow typical meal timing patterns
        - Balance windows throughout the day
        - Standard naming conventions apply
        """
        }
        
        prompt += """
        
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
            
            // Debug log the raw date string from AI
            Task { @MainActor in
                DebugLogger.shared.info("AI returned date string: \(dateString)")
            }
            
            // Try parsing with full ISO8601 formatter first
            if let date = formatter.date(from: dateString) {
                Task { @MainActor in
                    DebugLogger.shared.info("Parsed as: \(date) (using full ISO8601)")
                }
                return date
            }
            
            // Fallback to basic ISO8601 if needed
            let basicFormatter = ISO8601DateFormatter()
            if let date = basicFormatter.date(from: dateString) {
                Task { @MainActor in
                    DebugLogger.shared.warning("Parsed as: \(date) (using basic ISO8601 - NO TIMEZONE)")
                }
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
            
            return aiResponse.windows.enumerated().map { index, window in
                // Validate and fix window times
                var correctedEndTime = window.endTime
                
                // If end time is before start time, it means it crosses midnight
                if window.endTime <= window.startTime {
                    // Add 24 hours to the end time
                    correctedEndTime = window.endTime.addingTimeInterval(24 * 60 * 60)
                    
                    Task { @MainActor in
                        DebugLogger.shared.warning("Window '\(window.name)' crosses midnight - adjusting end time")
                        DebugLogger.shared.warning("  Original: \(window.startTime) to \(window.endTime)")
                        DebugLogger.shared.warning("  Corrected: \(window.startTime) to \(correctedEndTime)")
                    }
                }
                
                // Fix generic window names
                let windowName = fixGenericWindowName(
                    window.name,
                    index: index,
                    purpose: window.purpose,
                    startTime: window.startTime,
                    totalWindows: aiResponse.windows.count
                )
                
                return MealWindow(
                    id: UUID(),
                    startTime: window.startTime,
                    endTime: correctedEndTime,
                    targetCalories: window.targetCalories,
                    targetMacros: MacroTargets(
                        protein: window.targetProtein,
                        carbs: window.targetCarbs,
                        fat: window.targetFat
                    ),
                    purpose: mapPurpose(window.purpose),
                    flexibility: mapFlexibility(window.flexibility),
                    dayDate: dayDate,
                    name: windowName,
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
    /// Fix generic window names with contextual alternatives
    private func fixGenericWindowName(
        _ originalName: String,
        index: Int,
        purpose: String,
        startTime: Date,
        totalWindows: Int
    ) -> String {
        // Check if the name is generic
        let genericPatterns = ["Window \\d+", "Breakfast", "Lunch", "Dinner", "Snack"]
        let isGeneric = genericPatterns.contains { pattern in
            originalName.range(of: pattern, options: .regularExpression) != nil
        }
        
        // If not generic, return as-is
        guard isGeneric else { return originalName }
        
        // Generate contextual name based on time and purpose
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        
        // Determine time-based prefix
        let timePrefix: String
        switch hour {
        case 5..<9:
            timePrefix = "Morning"
        case 9..<11:
            timePrefix = "Mid-Morning"
        case 11..<14:
            timePrefix = "Midday"
        case 14..<17:
            timePrefix = "Afternoon"
        case 17..<20:
            timePrefix = "Evening"
        case 20..<23:
            timePrefix = "Late Evening"
        default:
            timePrefix = "Night"
        }
        
        // Map purpose to meaningful suffix
        let purposeSuffix: String
        switch purpose.lowercased() {
        case "preworkout", "pre-workout":
            purposeSuffix = "Pre-Training Fuel"
        case "postworkout", "post-workout":
            purposeSuffix = "Recovery Window"
        case "metabolicboost", "metabolic-boost":
            purposeSuffix = "Metabolic Boost"
        case "recovery":
            purposeSuffix = "Recovery & Repair"
        case "sustainedenergy", "sustained-energy":
            purposeSuffix = "Energy Sustainer"
        case "sleepoptimization", "sleep-optimization":
            purposeSuffix = "Sleep Prep"
        case "focusboost", "focus-boost":
            purposeSuffix = "Brain Power"
        default:
            // Position-based fallbacks
            if index == 0 {
                purposeSuffix = "Metabolic Primer"
            } else if index == totalWindows - 1 {
                purposeSuffix = "Wind-Down"
            } else {
                purposeSuffix = "Fuel Window"
            }
        }
        
        let newName = "\(timePrefix) \(purposeSuffix)"
        
        Task { @MainActor in
            DebugLogger.shared.warning("Replaced generic name '\(originalName)' with '\(newName)'")
        }
        
        return newName
    }
    
    /// Map AI-generated purpose strings to WindowPurpose enum
    private func mapPurpose(_ purposeString: String) -> WindowPurpose {
        switch purposeString.lowercased() {
        case "preworkout", "pre-workout":
            return .preWorkout
        case "postworkout", "post-workout":
            return .postWorkout
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
