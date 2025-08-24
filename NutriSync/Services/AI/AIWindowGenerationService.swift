//
//  AIWindowGenerationService.swift
//  NutriSync
//
//  AI-powered window generation service using Google Gemini
//

import Foundation
import FirebaseVertexAI

/// Service responsible for generating personalized meal windows using AI
class AIWindowGenerationService {
    static let shared = AIWindowGenerationService()
    
    private init() {}
    
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
        
        // Placeholder for Gemini API integration
        throw NSError(
            domain: "AIWindowGeneration",
            code: 2001,
            userInfo: [
                NSLocalizedDescriptionKey: "AI window generation not yet implemented",
                NSLocalizedFailureReasonErrorKey: "Gemini API integration pending",
                NSLocalizedRecoverySuggestionErrorKey: "Complete Gemini API integration for window generation"
            ]
        )
    }
    
    /// Build the prompt for AI window generation
    private func buildPrompt(
        profile: UserProfile,
        checkIn: MorningCheckInData?,
        date: Date
    ) -> String {
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
            - Wake Time: \(formatTime(checkIn.wakeTime))
            - Sleep Quality: \(checkIn.sleepQuality)/10
            - Energy Level: \(checkIn.energyLevel)/10
            - Hunger Level: \(checkIn.hungerLevel)/10
            - Planned Activities: \(checkIn.plannedActivities.joined(separator: ", "))
            """
        }
        
        prompt += """
        
        ## Requirements
        Generate 4-6 meal windows optimized for the user's goal with:
        1. Window timing based on circadian rhythm and user's schedule
        2. Personalized window names (not generic breakfast/lunch/dinner)
        3. Food suggestions (2-3 specific foods per window)
        4. Micronutrient focus (2-3 vitamins/minerals to prioritize)
        5. Optimization tips (2-3 actionable tips)
        6. Rationale explaining why this window supports their goal
        7. Appropriate macro distribution based on window purpose
        
        Return as JSON array with this structure:
        {
            "windows": [
                {
                    "name": "Morning Metabolic Primer",
                    "startTime": "2025-08-24T07:00:00Z",
                    "endTime": "2025-08-24T09:00:00Z",
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
        // TODO: Implement JSON parsing of Gemini response
        // Convert AI-generated JSON into MealWindow objects
        return []
    }
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