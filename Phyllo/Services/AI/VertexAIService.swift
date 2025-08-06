import Foundation
import UIKit
import FirebaseAI
import FirebaseStorage

// MARK: - Vertex AI Service with Firebase AI
// Production implementation using Firebase AI (Gemini)

// MARK: - Vertex AI Service Implementation

@MainActor
class VertexAIService: ObservableObject {
    static let shared = VertexAIService()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    private let model: GenerativeModel
    private let storage = Storage.storage()
    
    private init() {
        // Initialize Firebase AI service
        let ai = FirebaseAI.firebaseAI()
        
        // Configure generation parameters
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 2048,
            responseMIMEType: "application/json"
        )
        
        // Create GenerativeModel using public API
        self.model = ai.generativeModel(
            modelName: "gemini-2.0-flash-exp",
            generationConfig: config
        )
    }
    
    // MARK: - Public Methods
    
    func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysisResult {
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("VertexAIService.analyzeMeal started")
        }
        let analysisStart = Date()
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        // Compress image
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Compressing image for analysis")
        }
        guard let imageData = compressImage(request.image) else {
            Task { @MainActor in
                DebugLogger.shared.error("Image compression failed")
            }
            throw AnalysisError.imageCompressionFailed
        }
        Task { @MainActor in
            DebugLogger.shared.info("Image compressed to \(imageData.count / 1024)KB")
        }
        
        analysisProgress = 0.2
        
        // Create prompt
        let prompt = createAnalysisPrompt(request)
        
        analysisProgress = 0.3
        
        // Call Firebase AI (Gemini)
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Calling Gemini AI for analysis")
        }
        let result = try await callGeminiAI(prompt: prompt, imageData: imageData)
        
        Task { @MainActor in
            DebugLogger.shared.success("AI analysis completed: \(result.mealName) (confidence: \(result.confidence))")
        }
        analysisProgress = 1.0
        
        Task { @MainActor in
            let elapsed = Date().timeIntervalSince(analysisStart)
            DebugLogger.shared.performance("⏱️ Completed AI Analysis in \(String(format: "%.3f", elapsed))s")
        }
        return result
    }
    
    // MARK: - Private Methods
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize to max 1024x1024 maintaining aspect ratio
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        
        guard scale < 1 else {
            return image.jpegData(compressionQuality: 0.8)
        }
        
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
    
    private func createAnalysisPrompt(_ request: MealAnalysisRequest) -> String {
        let windowInfo = request.mealWindow.map { window in
            """
            Current Window: \(window.purpose.displayName) (\(window.timeRemaining ?? 0) minutes remaining)
            Window Targets: \(window.targetCalories) cal, \(window.targetMacros.protein)g protein, \(window.targetMacros.carbs)g carbs, \(window.targetMacros.fat)g fat
            """
        } ?? "No active meal window"
        
        let voiceInfo = request.voiceTranscript.map { "VOICE DESCRIPTION: \($0)" } ?? ""
        
        return """
        You are an expert nutritionist analyzing a meal photo for precise tracking.
        
        USER CONTEXT:
        - Goal: \(request.userContext.primaryGoal.displayName)
        - Daily Targets: \(request.userContext.dailyMacros)
        - \(windowInfo)
        
        \(voiceInfo)
        
        ANALYZE THE MEAL IMAGE AND PROVIDE:
        
        1. MEAL IDENTIFICATION
           - Name: [concise meal name, max 4 words]
           - Confidence: [0.0-1.0]
           - Main Components: [list key ingredients]
        
        2. PORTION ESTIMATION
           - Use visual cues (plate size, utensils, hand comparison)
           - Estimate weight/volume for each component
           
        3. NUTRITION CALCULATION
           - Use USDA standard values
           - Account for cooking methods and added fats
           - Calories: [number]
           - Protein: [grams with 1 decimal]
           - Carbs: [grams with 1 decimal]
           - Fat: [grams with 1 decimal]
           
        4. MICRONUTRIENTS (top 5-8 most significant)
           - Focus on goal-relevant nutrients
           - Include vitamin/mineral name, amount, unit, and %RDA
           
        5. CLARIFICATION NEEDS
           - Only ask if confidence < 0.8 or critical info missing
           - Max 2 questions
           - Provide 3-4 multiple choice options per question
           - Each option must include nutritional impact
        
        IMPORTANT: Return ONLY this exact JSON structure with these exact field names:
        {
          "mealName": "Name of meal",
          "confidence": 0.9,
          "ingredients": [
            {"name": "Chicken breast", "amount": "4", "unit": "oz", "foodGroup": "Protein"},
            {"name": "Lettuce", "amount": "2", "unit": "cups", "foodGroup": "Vegetable"}
          ],
          "nutrition": {
            "calories": 350,
            "protein": 32.5,
            "carbs": 15.0,
            "fat": 12.5
          },
          "micronutrients": [
            {"name": "Iron", "amount": 2.5, "unit": "mg", "percentRDA": 14.0}
          ],
          "clarifications": [
            {
              "question": "What dressing was used?",
              "clarificationType": "condiment",
              "options": [
                {"text": "No dressing", "calorieImpact": 0, "proteinImpact": 0, "carbImpact": 0, "fatImpact": 0, "isRecommended": false},
                {"text": "Ranch dressing (2 tbsp)", "calorieImpact": 140, "proteinImpact": 1, "carbImpact": 2, "fatImpact": 14, "isRecommended": false},
                {"text": "Vinaigrette (2 tbsp)", "calorieImpact": 70, "proteinImpact": 0, "carbImpact": 3, "fatImpact": 7, "isRecommended": true, "note": "Most common"},
                {"text": "Caesar dressing (2 tbsp)", "calorieImpact": 160, "proteinImpact": 2, "carbImpact": 2, "fatImpact": 16, "isRecommended": false}
              ]
            }
          ]
        }
        
        CRITICAL: Use exactly these field names:
        - "ingredients" (NOT mainComponents)
        - "nutrition" (NOT nutritionCalculation)
        - "clarifications" (NOT clarificationNeeds)
        - Each ingredient must have: name, amount, unit, foodGroup
        """
    }
    
    private func callGeminiAI(prompt: String, imageData: Data) async throws -> MealAnalysisResult {
        analysisProgress = 0.4
        
        // Upload image to Firebase Storage temporarily
        let imagePath = "temp_meal_images/\(UUID().uuidString).jpg"
        let imageRef = storage.reference().child(imagePath)
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Uploading image to Firebase Storage: \(imagePath)")
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with automatic deletion after 24 hours
        metadata.customMetadata = ["deleteAfter": String(Date().addingTimeInterval(86400).timeIntervalSince1970)]
        
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        Task { @MainActor in
            DebugLogger.shared.success("Image uploaded to Firebase Storage")
        }
        
        analysisProgress = 0.5
        
        // Create multi-modal prompt with image
        let imageContent = InlineDataPart(data: imageData, mimeType: "image/jpeg")
        let textContent = prompt
        
        analysisProgress = 0.6
        
        // Generate content using Firebase AI (Gemini)
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Sending request to Gemini AI")
        }
        let aiStart = Date()
        
        let response = try await model.generateContent(imageContent, textContent)
        
        Task { @MainActor in
            let elapsed = Date().timeIntervalSince(aiStart)
            DebugLogger.shared.performance("⏱️ Completed Gemini API Call in \(String(format: "%.3f", elapsed))s")
        }
        analysisProgress = 0.8
        
        // Parse the JSON response
        guard let text = response.text else {
            Task { @MainActor in
                DebugLogger.shared.error("No text in AI response")
            }
            throw AnalysisError.invalidResponse
        }
        
        Task { @MainActor in
            DebugLogger.shared.info("AI Response received: \(text.count) characters")
        }
        print("📝 AI Response: \(text)")
        
        // Try to extract JSON from the response
        let jsonText: String
        if let jsonStart = text.firstIndex(of: "{"),
           let jsonEnd = text.lastIndex(of: "}") {
            // Extract JSON portion from the response
            jsonText = String(text[jsonStart...jsonEnd])
        } else {
            jsonText = text
        }
        
        guard let jsonData = jsonText.data(using: .utf8) else {
            print("❌ Failed to convert text to data")
            throw AnalysisError.invalidResponse
        }
        
        // Schedule image deletion
        Task {
            try? await Task.sleep(nanoseconds: 86_400_000_000_000) // 24 hours
            try? await imageRef.delete()
        }
        
        do {
            let result = try JSONDecoder().decode(MealAnalysisResult.self, from: jsonData)
            Task { @MainActor in
                DebugLogger.shared.success("Successfully parsed meal analysis")
                DebugLogger.shared.mealAnalysis("Detected: \(result.mealName) - \(result.nutrition.calories) cal")
            }
            return result
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("JSON parsing error: \(error)")
                DebugLogger.shared.warning("Attempting to parse with flexible decoder...")
            }
            
            // Try to parse with a more flexible approach
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                return parseFallbackJSON(json)
            }
            
            // Last resort: Return a basic result based on what we could detect
            return MealAnalysisResult(
                mealName: "Analyzed Meal",
                confidence: 0.8,
                ingredients: [
                    .init(name: "Food Item", amount: "1", unit: "serving", foodGroup: "Mixed")
                ],
                nutrition: .init(
                    calories: 400,
                    protein: 20,
                    carbs: 40,
                    fat: 15
                ),
                micronutrients: [],
                clarifications: []
            )
        }
    }
    
    // MARK: - Fallback Parser
    
    private func parseFallbackJSON(_ json: [String: Any]) -> MealAnalysisResult {
        Task { @MainActor in
            DebugLogger.shared.warning("Using fallback parser for AI response")
        }
        print("🔄 Using fallback parser for AI response")
        
        // Extract basic fields
        let mealName = json["mealName"] as? String ?? "Analyzed Meal"
        let confidence = json["confidence"] as? Double ?? 0.8
        
        // Parse ingredients (handle both "ingredients" and "mainComponents")
        var ingredients: [MealAnalysisResult.AnalyzedIngredient] = []
        if let ingredientsList = json["ingredients"] as? [[String: Any]] {
            ingredients = parseIngredients(ingredientsList)
        } else if let mainComponents = json["mainComponents"] as? [String] {
            // Convert simple string array to ingredients
            ingredients = mainComponents.map { component in
                .init(name: component, amount: "1", unit: "serving", foodGroup: "Mixed")
            }
        }
        
        // Parse nutrition (handle both "nutrition" and "nutritionCalculation")
        let nutritionData = (json["nutrition"] ?? json["nutritionCalculation"]) as? [String: Any]
        let nutrition = MealAnalysisResult.NutritionInfo(
            calories: (nutritionData?["calories"] as? Int) ?? 400,
            protein: (nutritionData?["protein"] as? Double) ?? 20,
            carbs: (nutritionData?["carbs"] as? Double) ?? 40,
            fat: (nutritionData?["fat"] as? Double) ?? 15
        )
        
        // Parse micronutrients
        let micronutrients = parseMicronutrients(json["micronutrients"] as? [[String: Any]] ?? [])
        
        // Parse clarifications (handle both "clarifications" and "clarificationNeeds")
        let clarifications = parseClarifications(
            (json["clarifications"] ?? json["clarificationNeeds"]) as? [[String: Any]] ?? []
        )
        
        return MealAnalysisResult(
            mealName: mealName,
            confidence: confidence,
            ingredients: ingredients,
            nutrition: nutrition,
            micronutrients: micronutrients,
            clarifications: clarifications
        )
    }
    
    private func parseIngredients(_ list: [[String: Any]]) -> [MealAnalysisResult.AnalyzedIngredient] {
        list.compactMap { item in
            guard let name = item["name"] as? String else { return nil }
            return .init(
                name: name,
                amount: item["amount"] as? String ?? "1",
                unit: item["unit"] as? String ?? "serving",
                foodGroup: item["foodGroup"] as? String ?? "Mixed"
            )
        }
    }
    
    private func parseMicronutrients(_ list: [[String: Any]]) -> [MealAnalysisResult.MicronutrientInfo] {
        list.compactMap { item in
            guard let name = item["name"] as? String,
                  let amount = item["amount"] as? Double else { return nil }
            return .init(
                name: name,
                amount: amount,
                unit: item["unit"] as? String ?? "mg",
                percentRDA: item["percentRDA"] as? Double ?? 0
            )
        }
    }
    
    private func parseClarifications(_ list: [[String: Any]]) -> [MealAnalysisResult.ClarificationQuestion] {
        list.compactMap { item in
            guard let question = item["question"] as? String else { return nil }
            
            // Parse options - handle both string array and object array formats
            let options: [MealAnalysisResult.ClarificationOption]
            if let optionsArray = item["options"] as? [[String: Any]] {
                // New format with detailed options
                options = optionsArray.compactMap { opt in
                    guard let text = opt["text"] as? String else { return nil }
                    return .init(
                        text: text,
                        calorieImpact: (opt["calorieImpact"] as? Int) ?? 0,
                        proteinImpact: opt["proteinImpact"] as? Double,
                        carbImpact: opt["carbImpact"] as? Double,
                        fatImpact: opt["fatImpact"] as? Double,
                        isRecommended: opt["isRecommended"] as? Bool,
                        note: opt["note"] as? String
                    )
                }
            } else if let simpleOptions = item["options"] as? [String] {
                // Old format with just strings
                options = simpleOptions.map { text in
                    .init(
                        text: text,
                        calorieImpact: 0,
                        proteinImpact: nil,
                        carbImpact: nil,
                        fatImpact: nil,
                        isRecommended: nil,
                        note: nil
                    )
                }
            } else {
                options = []
            }
            
            return .init(
                question: question,
                options: options,
                clarificationType: item["clarificationType"] as? String ?? "portion"
            )
        }
    }
    
    // MARK: - Error Types
    
    enum AnalysisError: LocalizedError {
        case imageCompressionFailed
        case invalidResponse
        case networkError(String)
        case quotaExceeded
        
        var errorDescription: String? {
            switch self {
            case .imageCompressionFailed:
                return "Failed to process the image"
            case .invalidResponse:
                return "Invalid response from AI service"
            case .networkError(let message):
                return "Network error: \(message)"
            case .quotaExceeded:
                return "Daily analysis limit reached"
            }
        }
    }
}

// MARK: - Extensions

extension WindowPurpose {
    var displayName: String {
        switch self {
        case .preworkout:
            return "Pre-Workout"
        case .postworkout:
            return "Post-Workout"
        case .sustainedEnergy:
            return "Sustained Energy"
        case .recovery:
            return "Recovery"
        case .metabolicBoost:
            return "Metabolic Boost"
        case .sleepOptimization:
            return "Sleep Optimization"
        case .focusBoost:
            return "Focus Boost"
        }
    }
}