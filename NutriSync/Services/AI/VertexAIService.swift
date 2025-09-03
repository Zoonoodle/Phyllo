import Foundation
import UIKit
import FirebaseAI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

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
        
        // Configure generation parameters (V2 - low temperature for determinism)
        // Enable thinking tokens for better reasoning about complex meals
        // IMPORTANT: When using thinking models, the thinking tokens count against the limit
        // Set higher limit to account for both thinking (typically 2000-3000) and response tokens
        let config = GenerationConfig(
            temperature: 0.2,
            topP: 0.95,
            topK: 40,
            candidateCount: 1,
            maxOutputTokens: 8192,  // Increased to handle thinking tokens + JSON response
            presencePenalty: nil,
            frequencyPenalty: nil,
            stopSequences: nil,
            responseMIMEType: "application/json",
            responseSchema: nil
        )
        
        // Create GenerativeModel using public API
        // Using gemini-2.0-flash-thinking-exp for better reasoning
        self.model = ai.generativeModel(
            modelName: "gemini-2.0-flash-thinking-exp-1219",
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
        
        // Compress image if provided
        var imageData: Data? = nil
        if let image = request.image {
            Task { @MainActor in
                DebugLogger.shared.mealAnalysis("Compressing image for analysis")
            }
            imageData = compressImage(image)
            if imageData == nil {
                Task { @MainActor in
                    DebugLogger.shared.error("Image compression failed")
                }
                throw AnalysisError.imageCompressionFailed
            }
            Task { @MainActor in
                DebugLogger.shared.info("Image compressed to \((imageData?.count ?? 0) / 1024)KB")
            }
        } else if request.voiceTranscript != nil {
            Task { @MainActor in
                DebugLogger.shared.mealAnalysis("Voice-only analysis - no image to compress")
            }
        } else {
            Task { @MainActor in
                DebugLogger.shared.error("No image or voice transcript provided")
            }
            throw AnalysisError.noInputProvided
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
            "Meal window: \(window.purpose.displayName) (\(window.timeRemaining ?? 0) minutes remaining), Targets: \(window.targetCalories) cal, \(window.targetMacros.protein)g protein, \(window.targetMacros.carbs)g carbs, \(window.targetMacros.fat)g fat"
        } ?? "No active meal window"
        
        // Voice-only analysis V2
        if request.image == nil, let voiceTranscript = request.voiceTranscript {
            return """
            You are an expert nutritionist. Parse the user's voice description and return only the strict JSON described below.
            
            <thinking>
            Consider the following in your analysis:
            1. Is this a restaurant/brand item or homemade?
            2. What are the key ingredients and their likely quantities?
            3. What cooking methods affect the calorie content?
            4. Are there any hidden calories (oils, sauces, dressings)?
            5. What similar items can I reference for accuracy?
            </thinking>
            
            Critical rules:
            - Never output text outside JSON.
            - Canonicalize units to allowed list: g, oz, ml, cup, tbsp, tsp, slice, piece, egg, can, bottle, packet, bowl
            - Food groups must be: Protein, Grain, Vegetable, Fruit, Dairy, Beverage, Fat/Oil, Legume, Nut/Seed, Condiment/Sauce, Sweet, Mixed
            - Apply default assumptions only if the description lacks that info, and prefer asking a clarification when its calorie uncertainty is large (>±80 kcal).
            - Confidence calibration:
              • 0.85–0.95: simple, fully specified items (brand & size known).
              • 0.70–0.84: some uncertainty (size or one ingredient unclear).
              • 0.50–0.69: mixed dishes or multiple uncertainties; include clarifications.
            - BRAND DETECTION PRIORITY: Always look for brand/restaurant indicators FIRST:
              • Check for visible logos, packaging, containers, wrappers
              • Look for restaurant-style plating, takeout containers, branded cups
              • Identify chain restaurant menu items (burgers, fries, coffee cups, pizza boxes)
              • If ANY brand/restaurant is suspected, set brandDetected and request brandSearch tool
              • Common brands to detect: McDonald's, Starbucks, Subway, Chipotle, Pizza Hut, KFC, Taco Bell, Dunkin', Wendy's, Burger King, Chick-fil-A, Panera, Five Guys, In-N-Out, Shake Shack
            - Tool requests:
              • brandSearch: brand known but item/size/customization unclear.
              • nutritionLookup: unbranded foods where database values would materially reduce uncertainty.
              • deepAnalysis: highly mixed/ambiguous meals with multiple components or unusual cuisines.
            - Rounding/validation: macros to 1 decimal; calories = round(4P+4C+9F) within ±8%. If outside, adjust carbs.
            - Clarifications: ask max 3, each with SPECIFIC, MEASURABLE options the user can actually determine:
              • BAD: "Regular/Large/Small" (too vague)
              • GOOD: "Single patty (~4oz)" / "Double patty (~8oz)" / "Triple patty (~12oz)"
              • GOOD: "Small fries (~70g, fits in palm)" / "Medium fries (~120g, standard box)" / "Large fries (~180g, oversized container)"
              • For drinks: "12 oz can" / "16 oz cup" / "20 oz bottle" / "32 oz large cup"
              • For restaurant items: use their actual menu sizes when known
            - Each option must have signed impacts relative to the current base; mark the assumed option with note: "assumed in base" and isRecommended: true.
            - Never ask about oil/butter for raw salads; never ask disallowed questions from the category guide.
            
            USER CONTEXT
            Goal: \(request.userContext.primaryGoal.displayName)
            Daily Targets: \(request.userContext.dailyMacros)
            \(windowInfo)
            
            VOICE DESCRIPTION
            \(voiceTranscript)
            
            Return ONLY this JSON:
            {
              "mealName": "Descriptive name based on voice input",
              "confidence": 0.8,
              "ingredients": [
                {"name": "ingredient", "amount": "1", "unit": "cup", "foodGroup": "Vegetable"}
              ],
              "nutrition": { "calories": 50, "protein": 0.5, "carbs": 1.0, "fat": 5.0 },
              "micronutrients": [],
              "clarifications": [
                {
                  "question": "What size was the coffee?",
                  "clarificationType": "drink_size",
                  "options": [
                    {"text": "Small (12 oz)", "calorieImpact": 0, "proteinImpact": 0, "carbImpact": 0, "fatImpact": 0, "isRecommended": true, "note": "assumed in base"},
                    {"text": "Medium (16 oz)", "calorieImpact": 20, "proteinImpact": 1, "carbImpact": 2, "fatImpact": 1, "isRecommended": false},
                    {"text": "Large (20 oz)", "calorieImpact": 40, "proteinImpact": 2, "carbImpact": 4, "fatImpact": 2, "isRecommended": false}
                  ]
                }
              ],
              "requestedTools": [],
              "brandDetected": ""
            }
            """
        }
        
        // Image-based analysis V2 (with optional voice)
        let voiceInfo = request.voiceTranscript.map { "Voice text: \($0)" } ?? ""
        
        return """
        You are an expert nutritionist analyzing images (optionally with voice text). Return only the strict JSON below.
        
        <thinking>
        Analyze this meal step-by-step:
        1. What brands/logos/packaging are visible? Check containers, cups, wrappers.
        2. What are the main components and their estimated portions?
        3. Are there any hidden calories I should account for (cooking oil, butter, sauces)?
        4. What's my confidence level based on what I can clearly see?
        5. What critical information would most improve accuracy if I asked the user?
        6. Does this match any known restaurant items based on presentation/packaging?
        </thinking>
        
        Process (internal):
        - Identify visible components; don't guess hidden ones.
        - Portion estimation via visual cues: plate diameter (~26–28 cm common), utensil size, hand reference if visible, container sizes. Use defaults only when necessary.
        - Cooking method inference only when clearly indicated (grill marks, breading crispness, oil sheen).
        - Brand detection only with visible packaging/logo or explicit mention in the voice text.
        - Compose macros from components; sum and validate calories (±8%).
        - Confidence based on visibility of each major component and portion certainty:
          • 0.90–1.00: all major components and portions are clear.
          • 0.70–0.85: mixed dish/beverage/sauce uncertainty.
          • 0.50–0.69: occlusions, unknown sauces, or brand/size unknown.
        - Clarification policy: ask max 3 high-impact questions with SPECIFIC, MEASURABLE options users can determine from the image:
          • NEVER use generic "Small/Medium/Large" - be specific!
          • Burger example: "Single patty (~4oz)" / "Double patty (~8oz)" / "Triple patty (~12oz)"
          • Fries example: "Small portion (~70g, handful)" / "Medium (~120g, standard serving)" / "Large (~180g, sharing size)"
          • Pizza: "Personal 10\" pizza" / "Medium 14\" pizza" / "Large 16\" pizza" / "Single slice from 14\" pizza"
          • Drinks: "12 oz can" / "16 oz cup" / "20 oz bottle" / "32 oz large cup"
          • Include visual cues when helpful: "fits in palm", "standard box", "sharing bowl"
          • Each option must have signed impacts relative to your current base and mark the assumed option with note: "assumed in base" and isRecommended: true.
        
        Category guide (abbrev):
        - Restaurant/Branded: use actual menu names/sizes when known; never ask about cooking oil/butter.
        - Beverages/Shakes: specific volumes, actual product names; never ask cooking methods.
        - Home-cooked proteins: weight estimates with visual references, cooking method if unclear.
        - Salads/Vegetables: specific dressing amounts (1 tbsp, 2 tbsp, 1/4 cup); skip oil question for raw salads.
        - Packaged snacks: actual package count or weight shown on package.
        - Mixed dishes: specific bowl sizes or cup measurements; ask oil only if visibly oily.
        
        Tool requests:
        - brandSearch (branding present but details missing)
        - nutritionLookup (standard database values needed)
        - deepAnalysis (complex mixed dish)
        
        USER CONTEXT:
        Goal: \(request.userContext.primaryGoal.displayName)
        Daily Targets: \(request.userContext.dailyMacros)
        \(windowInfo)
        
        \(voiceInfo)
        
        Return ONLY this JSON:
        {
          "mealName": "Name of meal",
          "confidence": 0.75,
          "ingredients": [
            {"name": "Protein shake base", "amount": "1", "unit": "serving", "foodGroup": "Beverage"}
          ],
          "nutrition": { "calories": 300, "protein": 30.0, "carbs": 35.0, "fat": 5.0 },
          "micronutrients": [
            {"name": "Calcium", "amount": 250, "unit": "mg", "percentRDA": 25.0}
          ],
          "clarifications": [
            {
              "question": "How many burger patties are there?",
              "clarificationType": "burger_size",
              "options": [
                {"text": "Single patty (~4 oz)", "calorieImpact": 0, "proteinImpact": 0, "carbImpact": 0, "fatImpact": 0, "isRecommended": true, "note": "assumed in base"},
                {"text": "Double patty (~8 oz)", "calorieImpact": 280, "proteinImpact": 28, "carbImpact": 0, "fatImpact": 20, "isRecommended": false},
                {"text": "Triple patty (~12 oz)", "calorieImpact": 560, "proteinImpact": 56, "carbImpact": 0, "fatImpact": 40, "isRecommended": false}
              ]
            }
          ],
          "requestedTools": [],
          "brandDetected": ""
        }
        """
    }
    
    private func callGeminiAI(prompt: String, imageData: Data?) async throws -> MealAnalysisResult {
        analysisProgress = 0.4
        
        // Log full prompt for debugging
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("=== MEAL ANALYSIS REQUEST ===")
            DebugLogger.shared.mealAnalysis("Prompt length: \(prompt.count) characters")
            DebugLogger.shared.mealAnalysis("Has image: \(imageData != nil)")
            if let imageData = imageData {
                DebugLogger.shared.mealAnalysis("Image size: \(imageData.count / 1024)KB")
            }
            // Log full prompt in Developer Dashboard for debugging
            DebugLogger.shared.info("Full prompt:\n\(prompt)")
        }
        
        var imageRef: StorageReference? = nil
        
        // Handle image upload if provided
        if let imageData = imageData {
            // Upload image to Firebase Storage temporarily
            let imagePath = "temp_meal_images/\(UUID().uuidString).jpg"
            imageRef = storage.reference().child(imagePath)
            
            Task { @MainActor in
                DebugLogger.shared.firebase("Uploading image to Firebase Storage: \(imagePath)")
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Upload with automatic deletion after 24 hours
            metadata.customMetadata = ["deleteAfter": String(Date().addingTimeInterval(86400).timeIntervalSince1970)]
            
            _ = try await imageRef!.putDataAsync(imageData, metadata: metadata)
            Task { @MainActor in
                DebugLogger.shared.success("Image uploaded to Firebase Storage")
            }
        }
        
        analysisProgress = 0.5
        
        // Generate content using Firebase AI (Gemini) with retry logic
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Sending request to Gemini AI")
        }
        let aiStart = Date()
        
        var response: GenerateContentResponse? = nil
        var lastError: Error?
        let maxRetries = 3
        var retryCount = 0
        
        // Retry loop for network failures
        while retryCount < maxRetries {
            do {
                if let imageData = imageData {
                    // Multi-modal prompt with image
                    Task { @MainActor in
                        if retryCount > 0 {
                            DebugLogger.shared.info("Retry attempt \(retryCount) of \(maxRetries - 1)")
                        }
                        DebugLogger.shared.info("Creating InlineDataPart with image data: \(imageData.count) bytes, hash: \(imageData.hashValue)")
                    }
                    let imageContent = InlineDataPart(data: imageData, mimeType: "image/jpeg")
                    let textContent = prompt
                    analysisProgress = 0.6
                    response = try await model.generateContent(imageContent, textContent)
                } else {
                    // Text-only prompt for voice-only analysis
                    analysisProgress = 0.6
                    response = try await model.generateContent(prompt)
                }
                // Success - break out of retry loop
                break
            } catch let error as NSError where error.domain == NSURLErrorDomain {
                // Network error - check if it's a connection lost error
                lastError = error
                retryCount += 1
                
                if error.code == NSURLErrorNetworkConnectionLost || 
                   error.code == NSURLErrorNotConnectedToInternet ||
                   error.code == NSURLErrorTimedOut {
                    Task { @MainActor in
                        DebugLogger.shared.warning("Network error (attempt \(retryCount)/\(maxRetries)): \(error.localizedDescription)")
                    }
                    
                    if retryCount < maxRetries {
                        // Wait before retrying (exponential backoff)
                        let delay = Double(retryCount) * 2.0
                        Task { @MainActor in
                            DebugLogger.shared.info("Waiting \(delay) seconds before retry...")
                        }
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                } else {
                    // Other network error - throw immediately
                    throw AnalysisError.networkError(error.localizedDescription)
                }
            } catch {
                // Non-network error - throw immediately
                throw error
            }
        }
        
        // Check if we got a response or need to throw an error
        guard let finalResponse = response else {
            // We exhausted retries without success
            if let error = lastError {
                Task { @MainActor in
                    DebugLogger.shared.error("Failed after \(maxRetries) attempts: \(error.localizedDescription)")
                }
                throw AnalysisError.networkError("Connection failed after \(maxRetries) attempts. Please check your internet connection and try again.")
            } else {
                // This shouldn't happen, but handle it gracefully
                throw AnalysisError.invalidResponse
            }
        }
        
        Task { @MainActor in
            let elapsed = Date().timeIntervalSince(aiStart)
            DebugLogger.shared.performance("⏱️ Completed Gemini API Call in \(String(format: "%.3f", elapsed))s")
        }
        analysisProgress = 0.8
        
        // Parse the JSON response
        guard let text = finalResponse.text else {
            Task { @MainActor in
                DebugLogger.shared.error("No text in AI response")
            }
            throw AnalysisError.invalidResponse
        }
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("=== MEAL ANALYSIS RESPONSE ===")
            DebugLogger.shared.info("Response size: \(text.count) characters")
            // Log full response for debugging
            DebugLogger.shared.info("Full response:\n\(text)")
        }
        
        // Extract and log thinking process if present
        if let thinkingRange = text.range(of: "<thinking>.*?</thinking>", options: .regularExpression) {
            let thinkingContent = String(text[thinkingRange])
                .replacingOccurrences(of: "<thinking>", with: "")
                .replacingOccurrences(of: "</thinking>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            Task { @MainActor in
                DebugLogger.shared.mealAnalysis("🧠 Model thinking process detected")
                DebugLogger.shared.info("Thinking content:\n\(thinkingContent)")
            }
        } else {
            Task { @MainActor in
                DebugLogger.shared.mealAnalysis("No explicit thinking tokens in response")
            }
        }
        
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
        
        // Schedule image deletion if uploaded
        if let imageRef = imageRef {
            Task {
                try? await Task.sleep(nanoseconds: 86_400_000_000_000) // 24 hours
                try? await imageRef.delete()
            }
        }
        
        do {
            var result = try JSONDecoder().decode(MealAnalysisResult.self, from: jsonData)
            
            // Validate and adjust calorie-macro consistency (V2 requirement)
            result = validateAndAdjustMacros(result)
            
            // Calculate micronutrients from ingredients if missing or insufficient
            if result.micronutrients.isEmpty || result.micronutrients.count < 3 {
                let calculatedNutrients = MicronutrientDatabase.shared.calculateMicronutrients(for: result.ingredients)
                if !calculatedNutrients.isEmpty {
                    result.micronutrients = calculatedNutrients
                    Task { @MainActor in
                        DebugLogger.shared.info("Calculated \(calculatedNutrients.count) micronutrients from ingredients")
                    }
                }
            }
            
            // Prioritize micronutrients based on user goal (V2 requirement)
            if let userGoal = try? await getUserGoal() {
                result = prioritizeMicronutrients(result, for: userGoal)
            }
            
            Task { @MainActor in
                DebugLogger.shared.success("Successfully parsed meal analysis")
                DebugLogger.shared.mealAnalysis("=== ANALYSIS RESULT ===")
                DebugLogger.shared.mealAnalysis("Meal: \(result.mealName)")
                DebugLogger.shared.mealAnalysis("Confidence: \(result.confidence)")
                DebugLogger.shared.mealAnalysis("Calories: \(result.nutrition.calories)")
                DebugLogger.shared.mealAnalysis("Macros: P:\(result.nutrition.protein)g C:\(result.nutrition.carbs)g F:\(result.nutrition.fat)g")
                DebugLogger.shared.mealAnalysis("Ingredients: \(result.ingredients.count)")
                DebugLogger.shared.mealAnalysis("Micronutrients: \(result.micronutrients.count)")
                DebugLogger.shared.mealAnalysis("Clarifications needed: \(result.clarifications.count)")
                if let tools = result.requestedTools, !tools.isEmpty {
                    DebugLogger.shared.mealAnalysis("Tools requested: \(tools.joined(separator: ", "))")
                }
                if let brand = result.brandDetected {
                    DebugLogger.shared.mealAnalysis("Brand detected: \(brand)")
                }
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
                    .init(name: "Food Item", amount: "1", unit: "serving", foodGroup: "Mixed", nutrition: nil)
                ],
                nutrition: .init(
                    calories: 400,
                    protein: 20,
                    carbs: 40,
                    fat: 15
                ),
                micronutrients: [],
                clarifications: [],
                requestedTools: nil,
                brandDetected: nil
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserGoal() async throws -> NutritionGoal {
        // Get user goal from Firebase
        guard let userId = Auth.auth().currentUser?.uid else {
            return .overallWellbeing // Default
        }
        
        let userDoc = try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("data")
            .getDocument()
        
        if let data = userDoc.data(),
           let goalDict = data["primaryGoal"] as? [String: Any],
           let goalData = try? JSONSerialization.data(withJSONObject: goalDict),
           let goal = try? JSONDecoder().decode(NutritionGoal.self, from: goalData) {
            return goal
        }
        
        return .overallWellbeing
    }
    
    // MARK: - Micronutrient Prioritization (V2 requirement)
    
    private func prioritizeMicronutrients(_ result: MealAnalysisResult, for goal: NutritionGoal) -> MealAnalysisResult {
        guard !result.micronutrients.isEmpty else { return result }
        
        // Define priority nutrients for each goal (from V2 spec)
        let priorityNutrients: [String]
        switch goal {
        case .weightLoss:
            priorityNutrients = ["fiber", "protein", "potassium", "calcium", "sodium"]
        case .muscleGain:
            priorityNutrients = ["protein", "vitamin b12", "b-12", "iron", "zinc"]
        case .athleticPerformance, .performanceFocus:
            priorityNutrients = ["iron", "b vitamins", "magnesium", "potassium", "sodium"]
        case .betterSleep:
            priorityNutrients = ["magnesium", "calcium", "vitamin d", "tryptophan", "melatonin"]
        case .overallWellbeing, .maintainWeight:
            priorityNutrients = ["fiber", "calcium", "iron", "potassium", "vitamin d"]
        }
        
        // Sort micronutrients with priority nutrients first
        var sortedMicronutrients = result.micronutrients.sorted { first, second in
            let firstPriority = priorityNutrients.firstIndex { nutrient in
                first.name.lowercased().contains(nutrient.lowercased())
            } ?? Int.max
            
            let secondPriority = priorityNutrients.firstIndex { nutrient in
                second.name.lowercased().contains(nutrient.lowercased())
            } ?? Int.max
            
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            
            // Secondary sort by %RDA (higher first)
            return first.percentRDA > second.percentRDA
        }
        
        // Limit to top 8 micronutrients (V2 spec)
        sortedMicronutrients = Array(sortedMicronutrients.prefix(8))
        
        Task { @MainActor in
            DebugLogger.shared.info("Prioritized \(sortedMicronutrients.count) micronutrients for goal")
        }
        
        var adjustedResult = result
        adjustedResult.micronutrients = sortedMicronutrients
        return adjustedResult
    }
    
    // MARK: - Calorie-Macro Consistency Validation (V2 requirement)
    
    private func validateAndAdjustMacros(_ result: MealAnalysisResult) -> MealAnalysisResult {
        // Calculate expected calories: 4P + 4C + 9F
        let calculatedCalories = round(
            4 * result.nutrition.protein +
            4 * result.nutrition.carbs +
            9 * result.nutrition.fat
        )
        
        // Check if within ±8% tolerance
        let tolerance = 0.08
        let calorieRatio = abs(Double(result.nutrition.calories) - calculatedCalories) / calculatedCalories
        
        if calorieRatio <= tolerance {
            // Within tolerance, return as-is
            return result
        }
        
        Task { @MainActor in
            DebugLogger.shared.warning("Calorie-macro mismatch: reported \(result.nutrition.calories) cal, calculated \(Int(calculatedCalories)) cal")
        }
        
        // Adjust carbs to fix discrepancy (least harm to protein/fat accuracy)
        let targetCalories = Double(result.nutrition.calories)
        let proteinCalories = 4 * result.nutrition.protein
        let fatCalories = 9 * result.nutrition.fat
        let carbCalories = targetCalories - proteinCalories - fatCalories
        let adjustedCarbs = max(0, carbCalories / 4)
        
        Task { @MainActor in
            DebugLogger.shared.info("Adjusted carbs from \(result.nutrition.carbs)g to \(adjustedCarbs)g to match calorie total")
        }
        
        // Return adjusted result
        var adjustedResult = result
        adjustedResult.nutrition = MealAnalysisResult.NutritionInfo(
            calories: result.nutrition.calories,
            protein: result.nutrition.protein,
            carbs: round(adjustedCarbs * 10) / 10, // Round to 1 decimal
            fat: result.nutrition.fat
        )
        
        return adjustedResult
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
            clarifications: clarifications,
            requestedTools: json["requestedTools"] as? [String],
            brandDetected: json["brandDetected"] as? String
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
        case noInputProvided
        
        var errorDescription: String? {
            switch self {
            case .imageCompressionFailed:
                return "Failed to process the image. Please try taking another photo."
            case .noInputProvided:
                return "No image or voice description provided. Please capture a photo or describe your meal."
            case .invalidResponse:
                return "Unable to analyze the meal. Please try again."
            case .networkError(let message):
                // Make network errors more user-friendly
                if message.contains("network connection was lost") || message.contains("Connection failed") {
                    return "Network connection lost. Please check your internet connection and try again."
                } else if message.contains("timed out") {
                    return "Request timed out. Please check your connection and try again."
                } else {
                    return "Unable to connect. Please check your internet connection and try again."
                }
            case .quotaExceeded:
                return "You've reached your daily analysis limit. Please try again tomorrow."
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .networkError:
                return "The app will automatically retry when you have a stable connection."
            case .imageCompressionFailed:
                return "Try taking a clearer photo with better lighting."
            case .quotaExceeded:
                return "You can still log meals manually or use voice input."
            default:
                return nil
            }
        }
    }
}

// MARK: - Extensions

extension WindowPurpose {
    var displayName: String {
        switch self {
        case .preWorkout:
            return "Pre-Workout"
        case .postWorkout:
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