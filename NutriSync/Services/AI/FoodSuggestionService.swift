//
//  FoodSuggestionService.swift
//  NutriSync
//
//  AI-powered food suggestion generation based on remaining macros and preferences
//

import Foundation
import FirebaseAI

@MainActor
class FoodSuggestionService: ObservableObject {
    static let shared = FoodSuggestionService()

    @Published var isGenerating = false
    @Published var lastError: Error?

    private let model: GenerativeModel

    private init() {
        let ai = FirebaseAI.firebaseAI()

        let config = GenerationConfig(
            temperature: 0.7,  // Some creativity for variety
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 4096,
            responseMIMEType: "application/json"
        )

        self.model = ai.generativeModel(
            modelName: "gemini-2.0-flash",
            generationConfig: config
        )
    }

    // MARK: - Main Generation Method

    func generateSuggestions(
        for window: MealWindow,
        profile: UserProfile,
        todaysMeals: [LoggedMeal],
        previousWindows: [MealWindow]
    ) async throws -> SuggestionGenerationResult {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        // Calculate macro gaps
        let consumed = calculateConsumedMacros(from: todaysMeals)
        let remaining = MacroGap(
            calories: max(0, profile.dailyCalorieTarget - consumed.calories),
            protein: max(0, Double(profile.dailyProteinTarget) - consumed.protein),
            carbs: max(0, Double(profile.dailyCarbTarget) - consumed.carbs),
            fat: max(0, Double(profile.dailyFatTarget) - consumed.fat),
            primaryGap: determinePrimaryGap(
                proteinRemaining: Double(profile.dailyProteinTarget) - consumed.protein,
                carbsRemaining: Double(profile.dailyCarbTarget) - consumed.carbs,
                fatRemaining: Double(profile.dailyFatTarget) - consumed.fat
            )
        )

        // Build prompt
        let prompt = buildPrompt(
            window: window,
            profile: profile,
            consumed: consumed,
            remaining: remaining,
            todaysMeals: todaysMeals,
            previousWindows: previousWindows
        )

        DebugLogger.shared.info("[FoodSuggestionService] Generating suggestions for window: \(window.name)")

        do {
            // Generate
            let response = try await model.generateContent(prompt)

            guard let text = response.text else {
                throw SuggestionError.invalidResponse
            }

            // Parse
            let suggestions = try parseSuggestions(from: text, macroGap: remaining)

            // Generate context note
            let contextNote = generateContextNote(
                isFirstWindow: previousWindows.isEmpty && todaysMeals.isEmpty,
                remaining: remaining,
                todaysMeals: todaysMeals
            )

            DebugLogger.shared.success("[FoodSuggestionService] Generated \(suggestions.count) suggestions")

            return SuggestionGenerationResult(
                suggestions: suggestions,
                contextNote: contextNote,
                macroGap: remaining
            )
        } catch {
            lastError = error
            DebugLogger.shared.error("[FoodSuggestionService] Generation failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Supporting Methods

    private func calculateConsumedMacros(from meals: [LoggedMeal]) -> ConsumedMacroTotals {
        var total = ConsumedMacroTotals(calories: 0, protein: 0, carbs: 0, fat: 0)
        for meal in meals {
            total.calories += meal.calories ?? 0
            total.protein += Double(meal.protein ?? 0)
            total.carbs += Double(meal.carbs ?? 0)
            total.fat += Double(meal.fat ?? 0)
        }
        return total
    }

    private func determinePrimaryGap(proteinRemaining: Double, carbsRemaining: Double, fatRemaining: Double) -> String {
        let proteinPercent = proteinRemaining / max(1, proteinRemaining + carbsRemaining + fatRemaining)
        let carbsPercent = carbsRemaining / max(1, proteinRemaining + carbsRemaining + fatRemaining)
        let fatPercent = fatRemaining / max(1, proteinRemaining + carbsRemaining + fatRemaining)

        if abs(proteinPercent - carbsPercent) < 0.1 && abs(carbsPercent - fatPercent) < 0.1 {
            return "balanced"
        } else if proteinPercent > carbsPercent && proteinPercent > fatPercent {
            return "protein"
        } else if carbsPercent > proteinPercent && carbsPercent > fatPercent {
            return "carbs"
        } else {
            return "fat"
        }
    }

    private func determineSuggestionCount(remainingCalories: Int) -> Int {
        // Win 1: Cap at 3 suggestions max to reduce token usage
        switch remainingCalories {
        case ..<200: return 2
        default: return 3
        }
    }

    private func generateContextNote(isFirstWindow: Bool, remaining: MacroGap, todaysMeals: [LoggedMeal]) -> String {
        if isFirstWindow {
            return "Good morning! Based on your goals and preferences:"
        }

        var notes: [String] = []

        // Identify gaps
        if remaining.primaryGap == "protein" {
            notes.append("protein")
        }
        if remaining.primaryGap == "carbs" {
            notes.append("carbs")
        }
        if remaining.primaryGap == "fat" {
            notes.append("healthy fats")
        }

        if notes.isEmpty {
            return "Based on your remaining macros:"
        } else if notes.count == 1 {
            return "You need more \(notes[0]). Here are some ideas:"
        } else {
            let joined = notes.dropLast().joined(separator: ", ") + " and " + (notes.last ?? "")
            return "You need more \(joined). Here are some ideas:"
        }
    }

    // MARK: - Prompt Building

    private func buildPrompt(
        window: MealWindow,
        profile: UserProfile,
        consumed: ConsumedMacroTotals,
        remaining: MacroGap,
        todaysMeals: [LoggedMeal],
        previousWindows: [MealWindow]
    ) -> String {
        let suggestionCount = determineSuggestionCount(remainingCalories: remaining.calories)

        // Build food preferences section
        var preferencesSection = ""
        if let foodPrefs = profile.foodPreferences {
            let cuisines = foodPrefs.cuisines.map { $0.rawValue }.joined(separator: ", ")
            let favorites = foodPrefs.favoriteFoods.joined(separator: ", ")
            let dislikes = foodPrefs.dislikedFoods.joined(separator: ", ")
            let allergies = foodPrefs.allergies.joined(separator: ", ")
            let cookingPref = foodPrefs.cookingPreference?.rawValue ?? "flexible"

            preferencesSection = """
            - Favorite Cuisines: \(cuisines.isEmpty ? "Not specified" : cuisines)
            - Favorite Foods: \(favorites.isEmpty ? "Not specified" : favorites)
            - Disliked Foods: \(dislikes.isEmpty ? "None" : dislikes)
            - Allergies: \(allergies.isEmpty ? "None" : allergies) <- CRITICAL: NEVER suggest foods containing these
            - Cooking Preference: \(cookingPref)
            """
        }

        let restrictions = profile.dietaryRestrictions.joined(separator: ", ")

        // Build daily context section (from Tweak Today or Daily Sync)
        var dailyContextSection = ""
        if let dailyContext = DailySyncManager.shared.todaySync?.dailyContextDescription,
           !dailyContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dailyContextSection = """

            ## TODAY'S CONTEXT (User-provided - prioritize this!)
            \(dailyContext)
            """
            DebugLogger.shared.info("[FoodSuggestionService] Including daily context in prompt: \(dailyContext)")
        }

        // Build meals logged section
        var mealsSection = ""
        if !todaysMeals.isEmpty {
            let mealsList = todaysMeals.map { meal in
                "- \(meal.name): \(meal.calories ?? 0) cal, \(meal.protein ?? 0)g P, \(meal.carbs ?? 0)g C, \(Int(meal.fat ?? 0))g F"
            }.joined(separator: "\n")
            mealsSection = """

            ## MEALS LOGGED TODAY
            \(mealsList)
            """
        }

        // Get goal description
        let goalDescription = profile.primaryGoal.displayName

        let percentComplete = Int(Double(consumed.calories) / Double(max(1, profile.dailyCalorieTarget)) * 100)

        // Win 2 & 3: Compressed prompt with short keys + scoring
        return """
        Generate \(suggestionCount) food suggestions with predicted health scores.

        User: \(profile.name) | Goal: \(goalDescription)
        Targets: \(profile.dailyCalorieTarget)cal \(profile.dailyProteinTarget)P \(profile.dailyCarbTarget)C \(profile.dailyFatTarget)F
        Restrictions: \(restrictions.isEmpty ? "None" : restrictions)
        \(preferencesSection)

        Status: Consumed \(consumed.calories)cal \(Int(consumed.protein))P \(Int(consumed.carbs))C \(Int(consumed.fat))F
        Remaining: \(remaining.calories)cal \(Int(remaining.protein))P \(Int(remaining.carbs))C \(Int(remaining.fat))F (\(percentComplete)% done)
        Gap: \(remaining.primaryGap)
        \(dailyContextSection)\(mealsSection)

        Window: \(window.name) (\(window.purpose.rawValue)) \(formatTime(window.startTime))-\(formatTime(window.endTime))

        Rules: Close \(remaining.primaryGap) gap. Never: allergies/restrictions. Vary from eaten foods. Match window purpose. If today's context mentions energy, hunger, or food preferences, adapt suggestions accordingly.

        Score 1-10 based on: protein balance, whole foods, fiber, caloric density, micronutrients. Higher = healthier for this context.

        JSON array with short keys:
        [{"n":"Food name","c":calories,"p":protein,"cb":carbs,"f":fat,"g":"Protein|Dairy|Grain|Vegetable|Fruit|Fat/Oil|Legume|Nut/Seed|Beverage|Condiment/Sauce|Sweet|Mixed","rs":"Card text max 50ch","w":"1 sentence: why this fits your nutrition + goal","sc":8.5,"sf":[{"nm":"Factor name","ct":1.2}]}]

        Key: sc=predicted score (0-10), sf=score factors array, nm=factor name, ct=contribution (+/-)
        """
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Response Parsing

    private func parseSuggestions(from text: String, macroGap: MacroGap) throws -> [FoodSuggestion] {
        // Extract JSON from response
        let jsonText = extractFirstValidJSON(from: text)

        guard let data = jsonText.data(using: .utf8) else {
            throw SuggestionError.invalidJSON
        }

        // Parse into intermediate structure
        let decoder = JSONDecoder()
        let rawSuggestions = try decoder.decode([RawFoodSuggestion].self, from: data)

        // Convert to FoodSuggestion models (map short keys to full model)
        return rawSuggestions.map { raw in
            // Convert raw score factors to model
            let scoreFactors: [SuggestionScoreFactor]? = raw.sf?.map { factor in
                SuggestionScoreFactor(
                    name: factor.nm,
                    contribution: factor.ct
                )
            }

            var suggestion = FoodSuggestion(
                id: UUID(),
                name: raw.n,
                calories: raw.c,
                protein: raw.p,
                carbs: raw.cb,
                fat: raw.f,
                foodGroup: FoodGroup.fromString(raw.g),
                reasoningShort: raw.rs,
                reasoningDetailed: raw.w,  // Combined "why" used for detailed
                howYoullFeel: raw.w,       // Reuse combined reasoning
                supportsGoal: raw.w,       // Reuse combined reasoning
                generatedAt: Date(),
                basedOnMacroGap: macroGap
            )
            suggestion.predictedScore = raw.sc
            suggestion.scoreFactors = scoreFactors
            return suggestion
        }
    }

    private func extractFirstValidJSON(from text: String) -> String {
        var cleanedText = text

        // Remove ```json and ``` markers
        if let start = cleanedText.range(of: "```json") {
            cleanedText = String(cleanedText[start.upperBound...])
        } else if let start = cleanedText.range(of: "```") {
            cleanedText = String(cleanedText[start.upperBound...])
        }

        if let end = cleanedText.range(of: "```") {
            cleanedText = String(cleanedText[..<end.lowerBound])
        }

        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find first complete JSON array by tracking bracket depth
        guard let firstBracket = cleanedText.firstIndex(of: "[") else {
            return text
        }

        var bracketDepth = 0
        var inString = false
        var escapeNext = false

        for index in cleanedText.indices[firstBracket...] {
            let char = cleanedText[index]

            if escapeNext {
                escapeNext = false
                continue
            }

            if char == "\\" && inString {
                escapeNext = true
                continue
            }

            if char == "\"" {
                inString.toggle()
                continue
            }

            if !inString {
                if char == "[" {
                    bracketDepth += 1
                } else if char == "]" {
                    bracketDepth -= 1
                    if bracketDepth == 0 {
                        return String(cleanedText[firstBracket...index])
                    }
                }
            }
        }

        return text
    }

    // MARK: - Error Types

    enum SuggestionError: LocalizedError {
        case invalidResponse
        case invalidJSON
        case networkError(String)
        case noSuggestionsGenerated

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Received an invalid response from the AI."
            case .invalidJSON:
                return "Could not parse the suggestion data."
            case .networkError(let message):
                return "Network error: \(message)"
            case .noSuggestionsGenerated:
                return "No suggestions could be generated."
            }
        }
    }
}

// MARK: - Supporting Types

struct ConsumedMacroTotals {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
}

struct SuggestionGenerationResult {
    let suggestions: [FoodSuggestion]
    let contextNote: String
    let macroGap: MacroGap
}

// Raw response from AI for parsing (using short keys to reduce tokens)
private struct RawFoodSuggestion: Codable {
    let n: String       // name
    let c: Int          // calories
    let p: Double       // protein
    let cb: Double      // carbs
    let f: Double       // fat
    let g: String       // foodGroup
    let rs: String      // reasoningShort
    let w: String       // why (combined reasoning)
    let sc: Double?     // predicted score (0-10)
    let sf: [RawScoreFactor]?  // score factors
}

// Raw score factor from AI response
private struct RawScoreFactor: Codable {
    let nm: String      // factor name
    let ct: Double      // contribution (+/-)
}
