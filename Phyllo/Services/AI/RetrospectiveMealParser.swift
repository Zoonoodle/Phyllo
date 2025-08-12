//
//  RetrospectiveMealParser.swift
//  Phyllo
//
//  Created on 8/12/25.
//

import Foundation
import FirebaseAI

/// Service for parsing retrospective meal descriptions and distributing to windows
@MainActor
class RetrospectiveMealParser {
    static let shared = RetrospectiveMealParser()
    private let model: GenerativeModel
    
    private init() {
        // Initialize Firebase AI service
        let ai = FirebaseAI.firebaseAI()
        
        // Configure generation parameters for text-only analysis
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 1024,
            responseMIMEType: "application/json"
        )
        
        // Create GenerativeModel for text-only prompts
        self.model = ai.generativeModel(
            modelName: "gemini-2.0-flash-exp",
            generationConfig: config
        )
    }
    
    /// Parse a natural language description of meals into structured meal data
    func parseMealsFromDescription(_ description: String, missedWindows: [MealWindow]) async throws -> [LoggedMeal] {
        DebugLogger.shared.mealAnalysis("Parsing retrospective meals: \(description)")
        
        // Build context about missed windows for better meal assignment
        let windowContext = buildWindowContext(missedWindows)
        
        // Create the prompt for Gemini
        let prompt = """
        Parse the following meal description into individual meals with estimated nutrition.
        The user missed these meal windows today: \(windowContext)
        
        User's description: "\(description)"
        
        Instructions:
        1. Identify each distinct meal mentioned
        2. Estimate realistic calories and macros for each meal
        3. Assign an appropriate meal type (breakfast, lunch, dinner, snack)
        4. Consider typical portion sizes and restaurant vs home-cooked meals
        
        Return a JSON array with this structure:
        [
          {
            "name": "Meal name",
            "mealType": "breakfast|lunch|dinner|snack",
            "calories": 500,
            "protein": 30,
            "carbs": 50,
            "fat": 20,
            "confidence": 0.85,
            "reasoning": "Brief explanation of nutrition estimates"
          }
        ]
        
        Be realistic with portions and nutrition. Restaurant meals are typically larger.
        """
        
        do {
            // Generate content using text-only prompt
            let response = try await model.generateContent(prompt)
            
            // Extract text from response
            guard let responseText = response.text else {
                DebugLogger.shared.error("No text in AI response")
                return fallbackParsing(description, missedWindows: missedWindows)
            }
            
            let meals = try parseJSONResponse(responseText, missedWindows: missedWindows)
            
            DebugLogger.shared.success("Parsed \(meals.count) meals from description")
            return meals
            
        } catch {
            DebugLogger.shared.error("Failed to parse meals: \(error)")
            // Fallback to simple parsing
            return fallbackParsing(description, missedWindows: missedWindows)
        }
    }
    
    /// Build context string about missed windows
    private func buildWindowContext(_ windows: [MealWindow]) -> String {
        let windowDescriptions = windows.enumerated().map { index, window in
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeRange = "\(formatter.string(from: window.startTime))-\(formatter.string(from: window.endTime))"
            let windowType = mealTypeForWindow(window)
            return "\(index + 1). \(windowType) window (\(timeRange), \(window.targetCalories) cal)"
        }
        
        return windowDescriptions.joined(separator: ", ")
    }
    
    /// Determine meal type based on window timing
    private func mealTypeForWindow(_ window: MealWindow) -> String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...14: return "Lunch"
        case 15...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Late Snack"
        }
    }
    
    /// Parse JSON response from Gemini
    private func parseJSONResponse(_ response: String, missedWindows: [MealWindow]) throws -> [LoggedMeal] {
        // Extract JSON from response (Gemini sometimes adds explanation text)
        guard let jsonStart = response.firstIndex(of: "["),
              let jsonEnd = response.lastIndex(of: "]") else {
            throw ParseError.invalidJSON
        }
        
        let jsonString = String(response[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8) else {
            throw ParseError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        let parsedMeals = try decoder.decode([ParsedMeal].self, from: data)
        
        // Convert to LoggedMeal and assign to windows
        return parsedMeals.enumerated().compactMap { index, parsed in
            guard index < missedWindows.count else { return nil }
            
            let window = missedWindows[index]
            var meal = LoggedMeal(
                name: parsed.name,
                calories: parsed.calories,
                protein: parsed.protein,
                carbs: parsed.carbs,
                fat: parsed.fat,
                timestamp: window.startTime.addingTimeInterval(1800) // 30 min into window
            )
            meal.windowId = window.id
            
            return meal
        }
    }
    
    /// Fallback parsing using simple keyword matching
    private func fallbackParsing(_ description: String, missedWindows: [MealWindow]) -> [LoggedMeal] {
        let mealDescriptions = description
            .replacingOccurrences(of: " and ", with: ", ")
            .replacingOccurrences(of: " then ", with: ", ")
            .replacingOccurrences(of: ".", with: ", ")
            .components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return mealDescriptions.enumerated().compactMap { index, desc in
            guard index < missedWindows.count else { return nil }
            
            let window = missedWindows[index]
            let meal = createMealFromKeywords(desc)
            
            var loggedMeal = LoggedMeal(
                name: meal.name,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                timestamp: window.startTime.addingTimeInterval(1800)
            )
            loggedMeal.windowId = window.id
            
            return loggedMeal
        }
    }
    
    /// Create meal from keywords (improved version)
    private func createMealFromKeywords(_ description: String) -> (name: String, calories: Int, protein: Int, carbs: Int, fat: Int) {
        let desc = description.lowercased()
        
        // Breakfast patterns
        if desc.contains("eggs") || desc.contains("omelette") || desc.contains("scrambled") {
            return ("Eggs & Toast", 350, 20, 30, 15)
        } else if desc.contains("cereal") || desc.contains("oatmeal") || desc.contains("granola") {
            return ("Cereal Bowl", 300, 8, 55, 6)
        } else if desc.contains("pancake") || desc.contains("waffle") || desc.contains("french toast") {
            return ("Pancakes", 450, 10, 65, 15)
        }
        
        // Lunch patterns
        else if desc.contains("sandwich") || desc.contains("sub") || desc.contains("wrap") {
            return ("Sandwich", 450, 25, 45, 20)
        } else if desc.contains("salad") && desc.contains("chicken") {
            return ("Chicken Salad", 350, 30, 20, 18)
        } else if desc.contains("salad") {
            return ("Garden Salad", 250, 15, 20, 15)
        } else if desc.contains("burger") {
            return ("Burger & Fries", 750, 35, 65, 40)
        } else if desc.contains("pizza") {
            return ("Pizza", 600, 25, 70, 25)
        }
        
        // Dinner patterns
        else if desc.contains("chicken") && (desc.contains("rice") || desc.contains("pasta")) {
            return ("Chicken & Rice", 550, 35, 55, 20)
        } else if desc.contains("steak") || desc.contains("beef") {
            return ("Steak Dinner", 650, 45, 30, 35)
        } else if desc.contains("salmon") || desc.contains("fish") {
            return ("Fish Dinner", 450, 35, 30, 20)
        } else if desc.contains("pasta") || desc.contains("spaghetti") {
            return ("Pasta Dish", 500, 20, 65, 18)
        }
        
        // Snack patterns
        else if desc.contains("shake") || desc.contains("smoothie") {
            return ("Protein Shake", 200, 25, 15, 5)
        } else if desc.contains("yogurt") {
            return ("Greek Yogurt", 150, 15, 20, 3)
        } else if desc.contains("nuts") || desc.contains("almonds") {
            return ("Mixed Nuts", 170, 6, 6, 15)
        } else if desc.contains("fruit") || desc.contains("apple") || desc.contains("banana") {
            return ("Fresh Fruit", 120, 1, 30, 0)
        } else if desc.contains("snack") {
            return ("Snack", 150, 5, 20, 7)
        }
        
        // Restaurant detection
        else if desc.contains("restaurant") || desc.contains("ate out") {
            return ("Restaurant Meal", 700, 35, 60, 35)
        }
        
        // Default
        else {
            return ("Meal", 400, 20, 40, 20)
        }
    }
}

// MARK: - Supporting Types

private struct ParsedMeal: Codable {
    let name: String
    let mealType: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let confidence: Double
    let reasoning: String
}

private enum ParseError: Error {
    case invalidJSON
    case parsingFailed
}