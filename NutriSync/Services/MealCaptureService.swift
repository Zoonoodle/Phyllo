import Foundation
import UIKit
import Combine

// MARK: - Meal Capture Service
/// Service that coordinates meal capture between data provider and AI analysis
@MainActor
class MealCaptureService: ObservableObject {
    static let shared = MealCaptureService()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentError: Error?
    
    // Store last analysis metadata for celebration nudge
    private var lastAnalysisMetadata: [UUID: AnalysisMetadata] = [:]
    
    private let dataProvider = DataSourceProvider.shared.provider
    private let vertexAI = VertexAIService.shared
    private let agent = MealAnalysisAgent.shared
    private let timeProvider = TimeProvider.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to VertexAI progress
        vertexAI.$analysisProgress
            .assign(to: &$analysisProgress)
        
        vertexAI.$isAnalyzing
            .assign(to: &$isAnalyzing)
    }
    
    /// Start analyzing a meal from captured data
    func startMealAnalysis(
        image: UIImage?,
        voiceTranscript: String? = nil,
        barcode: String? = nil,
        timestamp: Date? = nil
    ) async throws -> AnalyzingMeal {
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Starting meal analysis - Image: \(image != nil), Voice: \(voiceTranscript != nil), Barcode: \(barcode != nil)")
        }
        
        // Validate that we have at least one input
        let hasImage = image != nil
        let hasVoice = voiceTranscript != nil && !voiceTranscript!.isEmpty
        let hasBarcode = barcode != nil && !barcode!.isEmpty
        
        if !hasImage && !hasVoice && !hasBarcode {
            Task { @MainActor in
                DebugLogger.shared.error("Cannot analyze meal without any input (no image, voice, or barcode)")
            }
            throw NSError(
                domain: "MealCaptureService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Cannot analyze meal without any input. Please capture a photo, provide a voice description, or scan a barcode."]
            )
        }
        
        // Find the best window for this meal
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Fetching current windows")
        }
        let mealTimestamp = timestamp ?? timeProvider.currentTime
        let windowsDate = Calendar.current.startOfDay(for: mealTimestamp)
        let currentWindows = try await dataProvider.getWindows(for: windowsDate)
        let now = mealTimestamp
        
        // Debug logging for window assignment
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Finding window for meal at \(now) - \(currentWindows.count) windows available")
        }
        
        // 1) If any active window, use it
        var bestWindow = currentWindows.first { $0.contains(timestamp: now) }
        
        // 2) Otherwise, choose the nearest window by absolute time distance
        if bestWindow == nil {
            var nearest: MealWindow?
            var nearestDistance = TimeInterval.greatestFiniteMagnitude
            
            for window in currentWindows {
                let distance: TimeInterval
                if now < window.startTime {
                    distance = window.startTime.timeIntervalSince(now)
                } else if now > window.endTime {
                    distance = now.timeIntervalSince(window.endTime)
                } else {
                    distance = 0
                }
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearest = window
                }
            }
            
            // 3) Nudge toward upcoming window if it's within the window's flexibility buffer
            if let upcoming = currentWindows
                .filter({ now < $0.startTime })
                .sorted(by: { $0.startTime < $1.startTime })
                .first,
               now >= upcoming.startTime.addingTimeInterval(-upcoming.flexibility.timeBuffer) {
                bestWindow = upcoming
                Task { @MainActor in
                    DebugLogger.shared.success("Assigning to upcoming window within flexibility buffer: \(upcoming.purpose.rawValue) (starts in \(Int(upcoming.startTime.timeIntervalSince(now)/60))m)")
                }
            } else if let nearest {
                bestWindow = nearest
                Task { @MainActor in
                    let mins = Int(nearestDistance/60)
                    DebugLogger.shared.warning("Assigning to nearest window by distance: \(nearest.purpose.rawValue) (\(mins)m away)")
                }
            }
        }
        
        if let window = bestWindow {
            Task { @MainActor in
                DebugLogger.shared.logWindow(window, action: "Found best window for meal")
                DebugLogger.shared.success("Assigned meal to window \(window.id) (\(window.purpose.rawValue) \(window.startTime) - \(window.endTime))")
            }
        } else {
            Task { @MainActor in
                DebugLogger.shared.warning("No suitable window found for meal - will save without window assignment")
            }
        }
        
        // Create analyzing meal
        // Use autoreleasepool to ensure memory is freed immediately
        let previewData = autoreleasepool { () -> Data? in
            guard let img = image else { return nil }
            return makePreviewData(from: img)
        }
        
        Task { @MainActor in
            if let image = image {
                let imageSize = image.size
                let imageMB = (image.jpegData(compressionQuality: 1.0)?.count ?? 0) / (1024 * 1024)
                DebugLogger.shared.mealAnalysis("Image provided: \(imageSize.width)x\(imageSize.height), ~\(imageMB)MB")
                if previewData == nil {
                    DebugLogger.shared.warning("Failed to create preview data from image")
                } else {
                    DebugLogger.shared.info("Preview data created: \(previewData?.count ?? 0) bytes")
                }
            } else {
                DebugLogger.shared.mealAnalysis("No image provided for analysis")
            }
        }
        
        let analyzingMeal = AnalyzingMeal(
            timestamp: now,
            windowId: bestWindow?.id,
            imageData: previewData,
            voiceDescription: voiceTranscript
        )
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Created AnalyzingMeal with ID: \(analyzingMeal.id), Window ID: \(bestWindow?.id.uuidString ?? "nil")")
        }
        
        // Start analyzing in data provider
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Starting analyzing meal in data provider")
        }
        try await dataProvider.startAnalyzingMeal(analyzingMeal)
        
        // Perform analysis in background
        Task {
            do {
                if let image = image {
                    Task { @MainActor in
                        DebugLogger.shared.mealAnalysis("Processing image-based analysis")
                    }
                    // Use VertexAI for photo analysis
                    let (result, analysisMetadata) = try await analyzeWithAI(
                        image: image,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed (always show if confidence < 0.85 or clarifications exist)
                    if !result.clarifications.isEmpty || result.confidence < 0.85 {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("Clarification needed - \(result.clarifications.count) questions (confidence: \(result.confidence))")
                        }
                        // Present clarification questions
                        await MainActor.run {
                            ClarificationManager.shared.presentClarification(
                                for: analyzingMeal,
                                with: result
                            )
                        }
                    } else {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("No clarification needed - completing analysis")
                        }
                        // No clarification needed, complete the analysis
                        var savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        // Preserve captured image from the session when coming from photo library/camera
                        if savedMeal.imageData == nil, let img = analyzingMeal.imageData {
                            savedMeal.imageData = img
                            savedMeal = try await dataProvider.updateMeal(savedMeal)
                        }
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
                        Task { @MainActor in
                            DebugLogger.shared.success("Meal analysis completed: \(result.mealName)")
                            DebugLogger.shared.notification("Posting mealAnalysisCompleted notification")
                        }
                        
                        // Schedule post-meal check-in reminder
                        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
                        
                        // Post notification with the completed meal
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisCompleted,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
                            )
                        }
                    }
                    
                } else if let barcode = barcode {
                    // TODO: Implement barcode lookup
                    // For now, create a mock result
                    let mockResult = createMockBarcodeResult(barcode: barcode)
                    let savedMeal = try await dataProvider.completeAnalyzingMeal(
                        id: analyzingMeal.id.uuidString,
                        result: mockResult
                    )
                    
                    // Post notification with the completed meal
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .mealAnalysisCompleted,
                            object: analyzingMeal,
                            userInfo: ["result": mockResult, "savedMeal": savedMeal]
                        )
                    }
                    
                } else if let voiceTranscript = voiceTranscript {
                    // Voice-only analysis
                    Task { @MainActor in
                        DebugLogger.shared.mealAnalysis("Processing voice-only analysis")
                    }
                    
                    // Use VertexAI for voice-only analysis
                    let (result, analysisMetadata) = try await analyzeWithAI(
                        image: nil,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed (always show if confidence < 0.85 or clarifications exist)
                    if !result.clarifications.isEmpty || result.confidence < 0.85 {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("Clarification needed with \(result.clarifications.count) questions")
                        }
                        // Complete the meal in data provider
                        let savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
                        // Post notification with clarification
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisClarificationNeeded,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
                            )
                        }
                    } else {
                        // Complete analysis without clarification
                        let savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
                        Task { @MainActor in
                            DebugLogger.shared.success("Voice-only meal analysis completed: \(result.mealName)")
                            DebugLogger.shared.notification("Posting mealAnalysisCompleted notification")
                        }
                        
                        // Schedule post-meal check-in reminder
                        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
                        
                        // Post notification with the completed meal
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisCompleted,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
                            )
                        }
                    }
                }
                
            } catch {
                Task { @MainActor in
                    DebugLogger.shared.error("Meal analysis failed: \(error)")
                }
                await MainActor.run {
                    self.currentError = error
                }
                
                // Remove the analyzing meal on error so it doesn't get stuck
                do {
                    Task { @MainActor in
                        DebugLogger.shared.dataProvider("Cancelling analyzing meal due to error")
                    }
                    try await dataProvider.cancelAnalyzingMeal(id: analyzingMeal.id.uuidString)
                } catch {
                    Task { @MainActor in
                        DebugLogger.shared.error("Failed to remove analyzing meal after error: \(error)")
                    }
                }
            }
        }
        
        return analyzingMeal
    }
    
    /// Analyze meal with AI
    private func analyzeWithAI(
        image: UIImage?,
        voiceTranscript: String?,
        analyzingMeal: AnalyzingMeal
    ) async throws -> (MealAnalysisResult, AnalysisMetadata?) {
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("analyzeWithAI called - Image: \(image != nil), Voice: \(voiceTranscript != nil ? "\"\(voiceTranscript!)\"" : "nil")")
            if let image = image {
                DebugLogger.shared.info("Image size for AI: \(image.size.width)x\(image.size.height)")
            }
        }
        
        // Get current user context
        let userProfile = try await dataProvider.getUserProfile() ?? UserProfile.defaultProfile
        
        // Find assigned window
        let windows = try await dataProvider.getWindows(for: analyzingMeal.timestamp)
        let assignedWindow = windows.first { window in
            window.contains(timestamp: analyzingMeal.timestamp)
        }
        
        // Create context for AI
        let context = UserNutritionContext(
            primaryGoal: userProfile.primaryGoal,
            dailyCalorieTarget: userProfile.dailyCalorieTarget,
            dailyProteinTarget: userProfile.dailyProteinTarget,
            dailyCarbTarget: userProfile.dailyCarbTarget,
            dailyFatTarget: userProfile.dailyFatTarget
        )
        
        // Create analysis request
        let request = MealAnalysisRequest(
            image: image,
            voiceTranscript: voiceTranscript,
            userContext: context,
            mealWindow: assignedWindow
        )
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Created MealAnalysisRequest - Has Image: \(request.image != nil), Has Voice: \(request.voiceTranscript != nil)")
        }
        
        // Perform AI analysis with intelligent agent tools
        let (result, metadata) = try await agent.analyzeMealWithTools(request)
        
        // Note: metadata is available but we can't modify the analyzingMeal parameter
        // The metadata will be available in the notification userInfo instead
        
        return (result, metadata)
    }
    
    // MARK: - Helper Functions for Clarification Matching
    
    private func findMatchingOption(in question: MealAnalysisResult.ClarificationQuestion, for selectedId: String) -> MealAnalysisResult.ClarificationOption? {
        return question.options.first { option in
            // Strategy 1: Direct text match
            if option.text == selectedId { return true }
            
            // Strategy 2: Direct ID match (if option has an id field)
            // Note: Currently ClarificationOption doesn't have an id field, so skipping this
            
            // Strategy 3: Normalized ID match
            let normalizedFromText = normalizeForId(option.text)
            if normalizedFromText == selectedId.lowercased() { return true }
            
            // Strategy 4: Bidirectional partial match for robustness
            let selectedNormalized = selectedId.lowercased()
            if normalizedFromText.contains(selectedNormalized) || 
               selectedNormalized.contains(normalizedFromText) { 
                return true 
            }
            
            return false
        }
    }
    
    private func normalizeForId(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    // MARK: - Meal Transformation System
    
    private func transformMealBasedOnClarification(
        original: MealAnalysisResult,
        clarificationType: String,
        selectedOption: String,
        nutritionDeltas: (cal: Int, protein: Double, carbs: Double, fat: Double)
    ) -> MealAnalysisResult {
        
        var transformedName = original.mealName
        var transformedIngredients = original.ingredients
        
        switch clarificationType {
        case "beverage_type_volume":
            // Complete replacement for beverages
            if selectedOption.lowercased().contains("black coffee") {
                transformedName = "Black Coffee"
                transformedIngredients = [
                    .init(
                        name: "Black Coffee",
                        amount: extractAmount(from: selectedOption) ?? "12",
                        unit: "oz",
                        foodGroup: "Beverage"
                    )
                ]
            } else if selectedOption.lowercased().contains("water") {
                transformedName = "Water"
                transformedIngredients = [
                    .init(
                        name: "Water",
                        amount: extractAmount(from: selectedOption) ?? "16",
                        unit: "oz",
                        foodGroup: "Beverage"
                    )
                ]
            }
            
        case "menu_item_variation":
            // Update name and ingredients for variations
            if selectedOption.lowercased().contains("spicy deluxe") {
                transformedName = transformMenuItemName(original: transformedName, variation: "Spicy Deluxe")
                transformedIngredients = addDeluxeIngredients(to: transformedIngredients)
            } else if selectedOption.lowercased().contains("grilled") {
                transformedName = transformMenuItemName(original: transformedName, variation: "Grilled")
                // Adjust fat content for grilled vs fried
            }
            
        case "portion_size":
            // Scale ingredients based on portion
            let scale = extractPortionScale(from: selectedOption)
            transformedIngredients = transformedIngredients.map { ingredient in
                if let amount = Double(ingredient.amount) {
                    // Create new ingredient with scaled amount since amount is immutable
                    return MealAnalysisResult.AnalyzedIngredient(
                        name: ingredient.name,
                        amount: String(amount * scale),
                        unit: ingredient.unit,
                        foodGroup: ingredient.foodGroup
                    )
                }
                return ingredient
            }
            
        case "cooking_method":
            // Adjust based on cooking method
            if selectedOption.lowercased().contains("fried") {
                // Add oil to ingredients
                transformedIngredients.append(
                    .init(
                        name: "Cooking Oil",
                        amount: "1",
                        unit: "tbsp",
                        foodGroup: "Fats"
                    )
                )
            }
            
        default:
            break
        }
        
        // Apply nutrition deltas and create result
        return MealAnalysisResult(
            mealName: transformedName,
            confidence: original.confidence,
            ingredients: transformedIngredients,
            nutrition: .init(
                calories: max(0, original.nutrition.calories + nutritionDeltas.cal),
                protein: max(0, original.nutrition.protein + nutritionDeltas.protein),
                carbs: max(0, original.nutrition.carbs + nutritionDeltas.carbs),
                fat: max(0, original.nutrition.fat + nutritionDeltas.fat)
            ),
            micronutrients: original.micronutrients,
            clarifications: [],  // Already answered
            requestedTools: original.requestedTools,
            brandDetected: original.brandDetected
        )
    }
    
    // Helper functions for transformation
    private func extractAmount(from text: String) -> String? {
        // Extract "12" from "Black coffee (approx. 12 oz / 350 ml)"
        let pattern = #"(\d+)\s*oz"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }
    
    private func transformMenuItemName(original: String, variation: String) -> String {
        // Smart name transformation
        if original.lowercased().contains("sandwich") {
            return original.replacingOccurrences(of: "Sandwich", with: "\(variation) Sandwich")
        } else if original.lowercased().contains("burger") {
            return original.replacingOccurrences(of: "Burger", with: "\(variation) Burger")
        }
        return "\(variation) \(original)"
    }
    
    private func addDeluxeIngredients(to ingredients: [MealAnalysisResult.AnalyzedIngredient]) -> [MealAnalysisResult.AnalyzedIngredient] {
        var updated = ingredients
        
        // Add typical deluxe ingredients if not present
        let hasLettuce = ingredients.contains { $0.name.lowercased().contains("lettuce") }
        let hasTomato = ingredients.contains { $0.name.lowercased().contains("tomato") }
        let hasCheese = ingredients.contains { $0.name.lowercased().contains("cheese") }
        
        if !hasLettuce {
            updated.append(MealAnalysisResult.AnalyzedIngredient(
                name: "Lettuce",
                amount: "1",
                unit: "leaf",
                foodGroup: "Vegetables"
            ))
        }
        
        if !hasTomato {
            updated.append(MealAnalysisResult.AnalyzedIngredient(
                name: "Tomato",
                amount: "2",
                unit: "slices",
                foodGroup: "Vegetables"
            ))
        }
        
        if !hasCheese {
            updated.append(MealAnalysisResult.AnalyzedIngredient(
                name: "American Cheese",
                amount: "1",
                unit: "slice",
                foodGroup: "Dairy"
            ))
        }
        
        return updated
    }
    
    private func extractPortionScale(from text: String) -> Double {
        if text.lowercased().contains("small") { return 0.75 }
        if text.lowercased().contains("large") { return 1.25 }
        if text.lowercased().contains("extra large") { return 1.5 }
        if text.lowercased().contains("half") { return 0.5 }
        return 1.0
    }
    
    /// Handle clarification answers
    func completeWithClarification(
        analyzingMeal: AnalyzingMeal,
        originalResult: MealAnalysisResult,
        clarificationAnswers: [String: String]
    ) async throws {
        
        guard !clarificationAnswers.isEmpty else { 
            // No clarifications to apply, save original
            _ = try await dataProvider.completeAnalyzingMeal(
                id: analyzingMeal.id.uuidString,
                result: originalResult
            )
            return
        }
        
        var adjustedResult = originalResult
        var appliedClarifications: [String: String] = [:] // clarificationType -> option text
        
        for (key, selectedOptionId) in clarificationAnswers {
            guard let questionIndex = Int(key),
                  originalResult.clarifications.indices.contains(questionIndex) else { continue }
            let question = originalResult.clarifications[questionIndex]
            
            // Use new robust matching
            guard let matchedOption = findMatchingOption(in: question, for: selectedOptionId) else {
                print("⚠️ No matching option found for '\(selectedOptionId)' in question '\(question.question)'")
                continue
            }
            
            // Calculate nutrition deltas
            let deltas = (
                cal: matchedOption.calorieImpact,
                protein: matchedOption.proteinImpact ?? 0,
                carbs: matchedOption.carbImpact ?? 0,
                fat: matchedOption.fatImpact ?? 0
            )
            
            // Apply transformation based on clarification type
            adjustedResult = transformMealBasedOnClarification(
                original: adjustedResult,
                clarificationType: question.clarificationType,
                selectedOption: matchedOption.text,
                nutritionDeltas: deltas
            )
            
            appliedClarifications[question.clarificationType] = matchedOption.text
            
            // Debug logging
            print("📊 Clarification Debug:")
            print("   Question: \(question.question)")
            print("   Selected ID: \(selectedOptionId)")
            print("   Matched: \(matchedOption.text)")
            print("   Type: \(question.clarificationType)")
            print("   Before: \(originalResult.mealName) - \(originalResult.nutrition.calories) cal")
            print("   After: \(adjustedResult.mealName) - \(adjustedResult.nutrition.calories) cal")
            print("   Deltas: cal: \(deltas.cal), protein: \(deltas.protein), carbs: \(deltas.carbs), fat: \(deltas.fat)")
            print("   Ingredients: \(adjustedResult.ingredients.count) items")
        }
        
        // Log final result
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("✅ Applied \(appliedClarifications.count) clarifications")
            DebugLogger.shared.mealAnalysis("   Final meal: \(adjustedResult.mealName)")
            DebugLogger.shared.mealAnalysis("   Final nutrition: \(adjustedResult.nutrition.calories) cal, \(String(format: "%.1f", adjustedResult.nutrition.protein))P, \(String(format: "%.1f", adjustedResult.nutrition.carbs))C, \(String(format: "%.1f", adjustedResult.nutrition.fat))F")
            DebugLogger.shared.mealAnalysis("   Ingredients: \(adjustedResult.ingredients.map { $0.name }.joined(separator: ", "))")
        }

        // Save with adjusted result
        var savedMeal = try await dataProvider.completeAnalyzingMeal(
            id: analyzingMeal.id.uuidString,
            result: adjustedResult
        )

        // Persist applied clarifications on the saved meal and update record
        savedMeal.appliedClarifications = appliedClarifications
        // Attach image data if available from capture time
        if savedMeal.imageData == nil {
            savedMeal.imageData = analyzingMeal.imageData
        }
        savedMeal = try await dataProvider.updateMeal(savedMeal)
        
        // Schedule post-meal check-in reminder
        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
        
        // Post notification with the completed meal
        await MainActor.run {
            NotificationCenter.default.post(
                name: .mealAnalysisCompleted,
                object: analyzingMeal,
                userInfo: ["result": adjustedResult, "savedMeal": savedMeal, "metadata": Optional<AnalysisMetadata>.none as Any]
            )
        }
    }
    
    // MARK: - Mock Results (Temporary)
    
    private func createMockBarcodeResult(barcode: String) -> MealAnalysisResult {
        MealAnalysisResult(
            mealName: "Protein Bar",
            confidence: 1.0,
            ingredients: [
                .init(name: "Protein Bar", amount: "1", unit: "bar", foodGroup: "Snack")
            ],
            nutrition: .init(
                calories: 250,
                protein: 20,
                carbs: 25,
                fat: 8
            ),
            micronutrients: [
                .init(name: "Calcium", amount: 100, unit: "mg", percentRDA: 10),
                .init(name: "Iron", amount: 2, unit: "mg", percentRDA: 11)
            ],
            clarifications: [],
            requestedTools: nil,
            brandDetected: nil
        )
    }
    
    private func createMockVoiceResult(transcript: String) -> MealAnalysisResult {
        MealAnalysisResult(
            mealName: "Voice Logged Meal",
            confidence: 0.7,
            ingredients: [
                .init(name: "Unknown", amount: "1", unit: "serving", foodGroup: "Unknown")
            ],
            nutrition: .init(
                calories: 400,
                protein: 25,
                carbs: 45,
                fat: 15
            ),
            micronutrients: [],
            clarifications: [],
            requestedTools: nil,
            brandDetected: nil
        )
    }
}

// MARK: - Helper Extensions

private func makePreviewData(from image: UIImage) -> Data? {
    // Create a small preview image suitable for Firestore (<1 MB)
    // Reduce dimensions for lower memory usage
    let maxDimension: CGFloat = 480  // Reduced from 640
    let widthScale = maxDimension / image.size.width
    let heightScale = maxDimension / image.size.height
    let scale = min(1.0, min(widthScale, heightScale))
    
    // Skip if already small enough
    guard scale < 1.0 else {
        return image.jpegData(compressionQuality: 0.5)  // Lower quality for small images
    }
    
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    
    // Use autoreleasepool to free memory immediately
    return autoreleasepool {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return resized.jpegData(compressionQuality: 0.5)  // Reduced from 0.65
    }
}

// MARK: - Metadata Management

extension MealCaptureService {
    func getAnalysisMetadata(for mealId: UUID) -> AnalysisMetadata? {
        return lastAnalysisMetadata[mealId]
    }
    
    private func storeAnalysisMetadata(_ metadata: AnalysisMetadata?, for mealId: UUID) {
        guard let metadata = metadata else { return }
        lastAnalysisMetadata[mealId] = metadata
        
        // Clean up old metadata (keep only last 10)
        if lastAnalysisMetadata.count > 10 {
            let sortedKeys = lastAnalysisMetadata.keys.sorted { a, b in
                // Keep most recent based on insertion order (no timestamp available)
                return true
            }
            if let oldestKey = sortedKeys.first {
                lastAnalysisMetadata.removeValue(forKey: oldestKey)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let mealAnalysisStarted = Notification.Name("mealAnalysisStarted")
    static let mealAnalysisCompleted = Notification.Name("mealAnalysisCompleted")
    static let mealAnalysisFailed = Notification.Name("mealAnalysisFailed")
    static let mealAnalysisClarificationNeeded = Notification.Name("mealAnalysisClarificationNeeded")
}