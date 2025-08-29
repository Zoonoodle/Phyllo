import Foundation
import UIKit
import FirebaseAI

// MARK: - Meal Analysis Agent
/// Intelligent agent that coordinates multiple analysis tools for accurate meal detection

@MainActor
class MealAnalysisAgent: ObservableObject {
    static let shared = MealAnalysisAgent()
    
    // MARK: - Published Properties
    @Published var currentTool: AnalysisTool?
    @Published var toolProgress: String = ""
    @Published var isUsingTools = false
    @Published var currentMetadata: AnalysisMetadata?
    
    // Track analysis state
    private var analysisStartTime = Date()
    private var toolsUsedInAnalysis: [AnalysisMetadata.AnalysisTool] = []
    
    // MARK: - Types
    enum AnalysisTool {
        case initial           // First pass analysis
        case brandSearch      // Search for restaurant/brand nutrition
        case deepAnalysis     // Multi-step ingredient breakdown
        case nutritionLookup  // Search nutrition databases
        
        var displayName: String {
            switch self {
            case .initial: return "Analyzing meal..."
            case .brandSearch: return "Searching restaurant info..."
            case .deepAnalysis: return "Analyzing ingredients..."
            case .nutritionLookup: return "Looking up nutrition data..."
            }
        }
        
        var iconName: String {
            switch self {
            case .initial: return "camera.viewfinder"
            case .brandSearch: return "magnifyingglass"
            case .deepAnalysis: return "eye"
            case .nutritionLookup: return "book.fill"
            }
        }
    }
    
    private let vertexAI = VertexAIService.shared
    private let analysisCache = AnalysisCache()
    
    // Common restaurant/brand keywords for detection
    private let brandKeywords = [
        "mcdonald", "mcdonalds", "burger king", "wendy", "subway", "chipotle",
        "starbucks", "dunkin", "panera", "chick-fil-a", "taco bell", "kfc",
        "pizza hut", "dominos", "papa johns", "five guys", "shake shack",
        "in-n-out", "whataburger", "arbys", "popeyes", "sonic", "dairy queen",
        "panda express", "qdoba", "jimmy johns", "jersey mikes", "firehouse",
        "sweetgreen", "cava", "tropical smoothie", "jamba juice", "smoothie king"
    ]
    
    private init() {}
    
    // MARK: - Public Methods
    
    func analyzeMealWithTools(_ request: MealAnalysisRequest) async throws -> (result: MealAnalysisResult, metadata: AnalysisMetadata) {
        DebugLogger.shared.mealAnalysis("MealAnalysisAgent starting analysis")
        analysisStartTime = Date()
        toolsUsedInAnalysis = []
        isUsingTools = true
        defer { 
            isUsingTools = false
            currentTool = nil
            toolProgress = ""
            currentMetadata = nil
        }
        
        // Step 1: Initial quick analysis
        currentTool = .initial
        toolProgress = "Performing initial analysis..."
        
        let initialResult = try await performInitialAnalysis(request)
        DebugLogger.shared.info("Initial analysis: \(initialResult.mealName) (confidence: \(initialResult.confidence))")
        
        // Step 2: Decision logic for tool usage
        var finalResult: MealAnalysisResult
        if shouldUseTools(initialResult, request: request) {
            DebugLogger.shared.mealAnalysis("Tools needed - starting deep analysis")
            do {
                finalResult = try await performDeepAnalysis(initialResult, request: request)
                DebugLogger.shared.success("Deep analysis completed successfully")
            } catch {
                DebugLogger.shared.error("Deep analysis failed: \(error)")
                // Fallback to initial result if deep analysis fails
                finalResult = initialResult
            }
        } else {
            DebugLogger.shared.success("High confidence result - no tools needed")
            finalResult = initialResult
        }
        
        // Step 3: Calculate micronutrients from ingredients if not already done
        if finalResult.micronutrients.isEmpty || finalResult.micronutrients.count < 3 {
            let calculatedNutrients = MicronutrientDatabase.shared.calculateMicronutrients(for: finalResult.ingredients)
            if !calculatedNutrients.isEmpty {
                finalResult.micronutrients = calculatedNutrients
                DebugLogger.shared.info("Final micronutrient calculation: \(calculatedNutrients.count) nutrients from \(finalResult.ingredients.count) ingredients")
            }
        }
        
        // Create metadata
        let metadata = createAnalysisMetadata(
            result: finalResult,
            request: request,
            toolsUsed: toolsUsedInAnalysis
        )
        
        currentMetadata = metadata
        
        return (result: finalResult, metadata: metadata)
    }
    
    // MARK: - Private Methods
    
    private func performInitialAnalysis(_ request: MealAnalysisRequest) async throws -> MealAnalysisResult {
        // Use existing VertexAI service for initial analysis
        return try await vertexAI.analyzeMeal(request)
    }
    
    private func shouldUseTools(_ result: MealAnalysisResult, request: MealAnalysisRequest) -> Bool {
        DebugLogger.shared.mealAnalysis("Checking if tools needed for: \(result.mealName)")
        
        // Check if the model requested tools
        if let requestedTools = result.requestedTools, !requestedTools.isEmpty {
            DebugLogger.shared.mealAnalysis("Model requested tools: \(requestedTools.joined(separator: ", "))")
            if let brand = result.brandDetected {
                DebugLogger.shared.info("Model detected brand: \(brand)")
            }
            return true
        }
        
        // Use deep analysis for anything with confidence <= 0.8
        if result.confidence <= 0.8 {
            DebugLogger.shared.mealAnalysis("Confidence (\(result.confidence)) <= 0.8 - deep analysis needed")
            return true
        }
        
        DebugLogger.shared.info("No tools requested by model, confidence: \(result.confidence)")
        return false
    }
    
    private func detectsBrandOrRestaurant(_ result: MealAnalysisResult, request: MealAnalysisRequest) -> Bool {
        let searchText = "\(result.mealName) \(request.voiceTranscript ?? "")".lowercased()
        
        // Check for brand keywords
        for brand in brandKeywords {
            if searchText.contains(brand) {
                DebugLogger.shared.info("Brand detected: \(brand)")
                return true
            }
        }
        
        // Check for restaurant indicators in meal name
        let restaurantIndicators = ["combo", "meal", "value", "deluxe", "supreme", "grande", "venti"]
        let hasIndicator = restaurantIndicators.contains { searchText.contains($0) }
        if hasIndicator {
            DebugLogger.shared.info("Restaurant indicator found in: \(searchText)")
        }
        return hasIndicator
    }
    
    private func detectBrandFromImage(_ request: MealAnalysisRequest) -> String? {
        // If there's an image, assume it might be from a restaurant/brand
        // and let the brand search tool try to identify it
        guard request.image != nil else { return nil }
        
        // Look for common visual cues in the meal name that suggest brands
        let mealName = request.voiceTranscript?.lowercased() ?? ""
        
        // Common restaurant food patterns
        let patterns = [
            "burger", "fries", "nuggets", "wrap", "sandwich", "pizza",
            "taco", "burrito", "bowl", "salad", "coffee", "latte",
            "smoothie", "shake", "combo", "meal"
        ]
        
        // If the meal contains common restaurant items, try brand search
        for pattern in patterns {
            if mealName.contains(pattern) {
                DebugLogger.shared.info("Restaurant food pattern detected: \(pattern)")
                return "restaurant" // Generic brand search trigger
            }
        }
        
        // Even without patterns, if we have an image with decent quality,
        // we should try brand detection
        DebugLogger.shared.info("Image provided - attempting brand detection")
        return "detect_from_image"
    }
    
    private func performDeepAnalysis(
        _ initialResult: MealAnalysisResult,
        request: MealAnalysisRequest
    ) async throws -> MealAnalysisResult {
        DebugLogger.shared.mealAnalysis("Starting performDeepAnalysis")
        var enhancedResult = initialResult
        let requestedTools = initialResult.requestedTools ?? []
        
        // Step 1: Always try Brand/Restaurant Search first
        // Check if brand was detected OR if we should try to detect one from the image
        let brandToSearch = initialResult.brandDetected ?? detectBrandFromImage(request)
        
        if let brand = brandToSearch {
            DebugLogger.shared.mealAnalysis("Brand detected or suspected: \(brand) - starting brand analysis")
            
            // Check cache first
            let cacheKey = "\(brand)_\(initialResult.mealName)"
            if let cached = analysisCache.getCachedBrand(cacheKey) {
                DebugLogger.shared.info("Using cached brand result for \(cacheKey)")
                toolsUsedInAnalysis.append(.brandSearch)
                return cached.result
            }
            
            currentTool = .brandSearch
            toolProgress = "Searching \(brand) nutrition info..."
            toolsUsedInAnalysis.append(.brandSearch)
            
            DebugLogger.shared.mealAnalysis("Calling performBrandSearch for \(brand)")
            let searchResult = try await performBrandSearch(
                brand: brand,
                mealName: initialResult.mealName,
                initialResult: initialResult,
                request: request
            )
            
            if let searchResult = searchResult {
                DebugLogger.shared.success("Brand search returned enhanced result")
                enhancedResult = searchResult
                // Cache the result
                analysisCache.cacheBrandResult(cacheKey, result: enhancedResult)
            } else {
                DebugLogger.shared.warning("Brand search returned nil, using initial result")
            }
        } else {
            DebugLogger.shared.info("No brand detected, skipping brand search")
        }
        
        // Step 2: Deep Ingredient Analysis (if requested by model)
        if requestedTools.contains("deepAnalysis") {
            currentTool = .deepAnalysis
            toolProgress = "Analyzing each ingredient..."
            toolsUsedInAnalysis.append(.deepAnalysis)
            
            let deepResult = try await performDeepIngredientAnalysis(
                enhancedResult,
                request: request
            )
            
            enhancedResult = deepResult
        }
        
        // Step 3: Nutrition Database Lookup (if requested by model)
        if requestedTools.contains("nutritionLookup") {
            currentTool = .nutritionLookup
            toolProgress = "Verifying nutrition data..."
            toolsUsedInAnalysis.append(.nutritionLookup)
            
            let nutritionResult = try await performNutritionLookup(
                enhancedResult,
                request: request
            )
            
            enhancedResult = nutritionResult
        }
        
        // Step 4: Calculate micronutrients from ingredients if missing or insufficient
        if enhancedResult.micronutrients.isEmpty || enhancedResult.micronutrients.count < 3 {
            let calculatedNutrients = MicronutrientDatabase.shared.calculateMicronutrients(for: enhancedResult.ingredients)
            if !calculatedNutrients.isEmpty {
                enhancedResult.micronutrients = calculatedNutrients
                DebugLogger.shared.info("Calculated \(calculatedNutrients.count) micronutrients from \(enhancedResult.ingredients.count) ingredients")
            }
        }
        
        currentTool = nil
        DebugLogger.shared.success("Deep analysis complete: \(enhancedResult.mealName) (confidence: \(enhancedResult.confidence))")
        return enhancedResult
    }
    
    private func extractBrandName(from result: MealAnalysisResult, request: MealAnalysisRequest) -> String? {
        // First check if model already detected a brand
        if let modelDetectedBrand = result.brandDetected {
            return modelDetectedBrand
        }
        
        // Fallback to keyword search
        let searchText = "\(result.mealName) \(request.voiceTranscript ?? "")".lowercased()
        
        for brand in brandKeywords {
            if searchText.contains(brand) {
                // Return properly capitalized brand name
                return brand.replacingOccurrences(of: "-", with: " ")
                    .split(separator: " ")
                    .map { $0.capitalized }
                    .joined(separator: " ")
            }
        }
        
        return nil
    }
    
    private func shouldPerformNutritionLookup(_ result: MealAnalysisResult) -> Bool {
        // Perform lookup for meals with few ingredients and moderate confidence
        return result.ingredients.count <= 3 && result.confidence < 0.9
    }
    
    private func createAnalysisMetadata(
        result: MealAnalysisResult,
        request: MealAnalysisRequest,
        toolsUsed: [AnalysisMetadata.AnalysisTool]
    ) -> AnalysisMetadata {
        // Determine complexity
        let complexity: AnalysisMetadata.ComplexityRating
        if extractBrandName(from: result, request: request) != nil {
            complexity = .restaurant
        } else if result.ingredients.count > 8 || toolsUsed.contains(.deepAnalysis) {
            complexity = .complex
        } else if result.ingredients.count > 3 {
            complexity = .moderate
        } else {
            complexity = .simple
        }
        
        // Calculate analysis time
        let analysisTime = Date().timeIntervalSince(analysisStartTime)
        
        return AnalysisMetadata(
            toolsUsed: toolsUsed,
            complexity: complexity,
            analysisTime: analysisTime,
            confidence: result.confidence,
            brandDetected: extractBrandName(from: result, request: request),
            ingredientCount: result.ingredients.count
        )
    }
}

// MARK: - Tool Implementations

extension MealAnalysisAgent {
    private func performBrandSearch(
        brand: String,
        mealName: String,
        initialResult: MealAnalysisResult,
        request: MealAnalysisRequest
    ) async throws -> MealAnalysisResult? {
        
        DebugLogger.shared.mealAnalysis("Performing brand-specific analysis for \(brand): \(mealName)")
        
        // Handle generic brand detection requests
        let actualBrand = (brand == "restaurant" || brand == "detect_from_image") 
            ? "DETECT FROM IMAGE" 
            : brand
        
        let searchPrompt = """
        BRAND/RESTAURANT DETECTION AND ANALYSIS
        
        Initial detection: \(mealName)
        \(actualBrand == "DETECT FROM IMAGE" ? "Task: IDENTIFY the brand/restaurant from the image and food characteristics" : "Brand: \(actualBrand)")
        
        DETECTION PRIORITY:
        1. Look for visual brand indicators: logos, packaging, containers, wrappers, cups
        2. Identify signature items: special sauce patterns, unique bun types, distinctive fries
        3. Match food style to known chains (e.g., waffle fries = Chick-fil-A, square patties = Wendy's)
        4. If brand detected, use EXACT official nutrition from that brand
        5. If no brand detected but looks restaurant-made, estimate as "Generic Restaurant" with higher calories
        
        IMPORTANT: 
        1. If you detect a brand, prepend it to the meal name
        2. Use official nutrition information when brand is known
        3. Set brandDetected field with the identified brand
        
        Restaurant Nutrition Database:
        
        Chick-fil-A:
        - Chicken Sandwich: 440 cal, 29g protein, 41g carbs, 19g fat
        - Deluxe Sandwich: 540 cal, 32g protein, 43g carbs, 28g fat  
        - Spicy Sandwich: 460 cal, 28g protein, 45g carbs, 22g fat
        - Grilled Sandwich: 390 cal, 37g protein, 44g carbs, 12g fat
        - Nuggets (8pc): 260 cal, 27g protein, 11g carbs, 12g fat
        - Nuggets (12pc): 390 cal, 41g protein, 16g carbs, 18g fat
        - Strips (3pc): 310 cal, 29g protein, 16g carbs, 14g fat
        - Strips (4pc): 410 cal, 39g protein, 21g carbs, 19g fat
        - Waffle Fries (small): 320 cal, 4g protein, 38g carbs, 19g fat
        - Waffle Fries (medium): 420 cal, 5g protein, 51g carbs, 24g fat
        - Waffle Fries (large): 520 cal, 7g protein, 63g carbs, 29g fat
        - Mac & Cheese (medium): 450 cal, 20g protein, 52g carbs, 19g fat
        - Side Salad: 80 cal, 5g protein, 6g carbs, 4g fat
        - Cobb Salad: 510 cal, 40g protein, 28g carbs, 27g fat
        - Market Salad: 330 cal, 28g protein, 26g carbs, 15g fat
        - Frosted Lemonade: 320 cal, 5g protein, 64g carbs, 6g fat
        - Milkshake (vanilla): 570 cal, 12g protein, 87g carbs, 20g fat
        - Sauce Packet: 140 cal, 0g protein, 6g carbs, 13g fat
        - Coca-Cola (small): 140 cal, 0g protein, 38g carbs, 0g fat
        - Coca-Cola (medium): 200 cal, 0g protein, 55g carbs, 0g fat
        - Coca-Cola (large): 310 cal, 0g protein, 86g carbs, 0g fat
        
        McDonald's:
        - Big Mac: 550 cal, 25g protein, 45g carbs, 30g fat
        - Quarter Pounder: 520 cal, 30g protein, 42g carbs, 26g fat
        - McChicken: 400 cal, 14g protein, 41g carbs, 21g fat
        - Medium Fries: 340 cal, 4g protein, 43g carbs, 16g fat
        
        Chipotle:
        - Chicken Bowl (typical): 750 cal, 45g protein, 65g carbs, 32g fat
        - Steak Bowl (typical): 800 cal, 40g protein, 65g carbs, 37g fat
        - Burrito (typical): 1000+ cal, 45g protein, 110g carbs, 40g fat
        
        Based on the image:
        1. Identify the exact menu item
        2. Use the official nutrition values above if it matches
        3. If not listed, estimate based on similar items
        4. DO NOT add extra calories for oil/preparation - it's already included in restaurant nutrition
        
        CRITICAL: Preserve the full meal name including the brand!
        - CORRECT: "Chick-fil-A Chicken Sandwich"
        - WRONG: "Chicken Sandwich" (missing brand)
        
        For ingredient breakdown:
        - List main components visible
        - Individual ingredient nutrition is optional
        - The total nutrition should match the official menu item
        
        Return a JSON response:
        {
          "mealName": "MUST include brand name - e.g. '\(brand) Chicken Sandwich' not just 'Chicken Sandwich'",
          "confidence": 0.95,
          "brandDetected": "\(brand)",
          "ingredients": [
            {
              "name": "component name",
              "amount": "1",
              "unit": "serving",
              "foodGroup": "category"
              // nutrition per ingredient is OPTIONAL
            }
          ],
          "nutrition": {
            // MUST match official nutrition for the complete menu item
            "calories": official_total_calories,
            "protein": official_total_protein,
            "carbs": official_total_carbs,
            "fat": official_total_fat
          },
          "micronutrients": [
            {"name": "Sodium", "amount": value, "unit": "mg", "percentRDA": percent}
          ],
          "clarifications": [],
          "requestedTools": null,
          "brandDetected": "\(brand)"
        }
        """
        
        do {
            DebugLogger.shared.mealAnalysis("Calling performToolAnalysis for brand search")
            let searchResult = try await vertexAI.performToolAnalysis(
                tool: .brandSearch,
                prompt: searchPrompt,
                imageData: request.image?.jpegData(compressionQuality: 0.8)
            )
            
            DebugLogger.shared.info("Brand analysis response: \(searchResult.prefix(500))...")
            
            // Try to parse as MealAnalysisResult directly
            if let data = searchResult.data(using: String.Encoding.utf8) {
                do {
                    var result = try JSONDecoder().decode(MealAnalysisResult.self, from: data)
                    DebugLogger.shared.success("Successfully parsed brand-specific result")
                    DebugLogger.shared.mealAnalysis("Brand result nutrition: \(result.nutrition.calories) cal, \(result.nutrition.protein)g P, \(result.nutrition.carbs)g C, \(result.nutrition.fat)g F")
                    
                    // Ensure brand name is preserved in meal name
                    if !result.mealName.lowercased().contains(brand.lowercased()) && initialResult.mealName.lowercased().contains(brand.lowercased()) {
                        DebugLogger.shared.warning("Brand name missing from result, using initial meal name")
                        result = MealAnalysisResult(
                            mealName: initialResult.mealName, // Keep the original name with brand
                            confidence: result.confidence,
                            ingredients: result.ingredients,
                            nutrition: result.nutrition,
                            micronutrients: result.micronutrients,
                            clarifications: result.clarifications,
                            requestedTools: result.requestedTools,
                            brandDetected: result.brandDetected
                        )
                    }
                    
                    return result
                } catch {
                    DebugLogger.shared.warning("Failed to parse as MealAnalysisResult: \(error)")
                    // Try manual parsing
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        return parseManualBrandResult(json, brand: brand, initialResult: initialResult)
                    }
                }
            }
        } catch {
            DebugLogger.shared.error("Brand search failed with error: \(error.localizedDescription)")
            // Return nil to fallback to initial result
        }
        
        return nil
    }
    
    private func performDeepIngredientAnalysis(
        _ result: MealAnalysisResult,
        request: MealAnalysisRequest
    ) async throws -> MealAnalysisResult {
        
        let deepPrompt = """
        Perform DETAILED component-by-component analysis of this meal:
        Initial detection: \(result.mealName)
        Current confidence: \(result.confidence)
        
        SYSTEMATIC ANALYSIS STEPS:
        
        1. INGREDIENT IDENTIFICATION
           - List EVERY visible component (including garnishes, sauces)
           - Don't miss: cooking oils, butter, dressings, toppings
           - Be specific: "grilled chicken breast" not just "chicken"
        
        2. PORTION ESTIMATION
           - Use visual references: compare to hand, utensils, plate size
           - Standard portions: 3oz meat = deck of cards, 1 cup = baseball
           - Account for perspective and stacking
        
        3. COOKING METHOD IMPACT
           - Fried adds ~50-100 cal from oil absorption
           - Grilled/baked minimal added fats
           - Sautéed typically 1-2 tsp oil (40-80 cal)
        
        4. HIDDEN CALORIES
           - Restaurant portions often 1.5-2x home portions
           - Butter on vegetables/bread (~100 cal/tbsp)
           - Cooking spray still adds 5-10 cal
           - Sugar in sauces/dressings
        
        5. CROSS-REFERENCE
           - Use USDA database values as baseline
           - Adjust for cooking method and added fats
           - Consider restaurant preparation (more oil/butter)
        
        For this specific meal, pay attention to:
        \(result.confidence < 0.7 ? "- Low initial confidence suggests complex/hidden ingredients" : "")
        \(result.ingredients.count > 5 ? "- Multiple components need individual analysis" : "")
        \(result.nutrition.calories > 600 ? "- High calories suggest restaurant preparation or hidden fats" : "")
        
        Return complete JSON with:
        - Updated confidence (should be 0.8+ after deep analysis)
        - Detailed ingredient list with reasoning
        - Accurate nutrition reflecting ALL components
        - Any clarifications still needed
        """
        
        let imageData = request.image != nil ? try? await compressImageForAnalysis(request.image!) : nil
        
        let analysisResult = try await vertexAI.performToolAnalysis(
            tool: .deepAnalysis,
            prompt: deepPrompt,
            imageData: imageData
        )
        
        // Parse and merge the deep analysis
        return try parseAndMergeAnalysis(result, deepAnalysis: analysisResult)
    }
    
    private func performNutritionLookup(
        _ result: MealAnalysisResult,
        request: MealAnalysisRequest
    ) async throws -> MealAnalysisResult {
        
        let lookupPrompt = """
        SEARCH NUTRITION DATABASES for accurate values:
        
        Items to verify:
        \(result.ingredients.map { "- \($0.name): \($0.amount) \($0.unit)" }.joined(separator: "\n"))
        
        USE WEB SEARCH to find:
        1. USDA FoodData Central values
        2. Nutrition labels for packaged items
        3. Standard preparation methods
        
        Search each ingredient:
        - "USDA [ingredient] nutrition per [amount]"
        - "[ingredient] calories protein carbs fat per [unit]"
        
        Account for:
        - Raw vs cooked weight changes
        - Standard cooking additions
        - Typical serving sizes
        
        Return refined nutrition totals based on database values.
        """
        
        let lookupResult = try await vertexAI.performToolAnalysis(
            tool: .nutritionLookup,
            prompt: lookupPrompt,
            imageData: nil
        )
        
        return try parseAndMergeAnalysis(result, deepAnalysis: lookupResult)
    }
}

// MARK: - Helper Methods

extension MealAnalysisAgent {
    private func parseManualBrandResult(_ json: [String: Any], brand: String, initialResult: MealAnalysisResult) -> MealAnalysisResult {
        DebugLogger.shared.mealAnalysis("Parsing manual brand result")
        
        // Parse ingredients with nutrition
        var ingredients: [MealAnalysisResult.AnalyzedIngredient] = []
        if let ingredientsArray = json["ingredients"] as? [[String: Any]] {
            for ing in ingredientsArray {
                // Parse individual ingredient nutrition if available
                var nutrition: MealAnalysisResult.NutritionInfo? = nil
                if let nutritionDict = ing["nutrition"] as? [String: Any] {
                    nutrition = MealAnalysisResult.NutritionInfo(
                        calories: nutritionDict["calories"] as? Int ?? 0,
                        protein: nutritionDict["protein"] as? Double ?? 0,
                        carbs: nutritionDict["carbs"] as? Double ?? 0,
                        fat: nutritionDict["fat"] as? Double ?? 0
                    )
                }
                
                let ingredient = MealAnalysisResult.AnalyzedIngredient(
                    name: ing["name"] as? String ?? "Unknown",
                    amount: ing["amount"] as? String ?? "1",
                    unit: ing["unit"] as? String ?? "serving",
                    foodGroup: ing["foodGroup"] as? String ?? "Unknown",
                    nutrition: nutrition
                )
                ingredients.append(ingredient)
            }
        }
        
        // Parse nutrition
        let nutritionDict = json["nutrition"] as? [String: Any] ?? [:]
        let calories = nutritionDict["calories"] as? Int ?? initialResult.nutrition.calories
        let protein = nutritionDict["protein"] as? Double ?? initialResult.nutrition.protein
        let carbs = nutritionDict["carbs"] as? Double ?? initialResult.nutrition.carbs
        let fat = nutritionDict["fat"] as? Double ?? initialResult.nutrition.fat
        
        DebugLogger.shared.mealAnalysis("Manual parse nutrition: \(calories) cal, \(protein)g P, \(carbs)g C, \(fat)g F")
        
        let nutrition = MealAnalysisResult.NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        // Parse micronutrients
        var micronutrients: [MealAnalysisResult.MicronutrientInfo] = []
        if let microArray = json["micronutrients"] as? [[String: Any]] {
            for micro in microArray {
                let nutrient = MealAnalysisResult.MicronutrientInfo(
                    name: micro["name"] as? String ?? "Unknown",
                    amount: micro["amount"] as? Double ?? 0,
                    unit: micro["unit"] as? String ?? "mg",
                    percentRDA: micro["percentRDA"] as? Double ?? 0
                )
                micronutrients.append(nutrient)
            }
        }
        
        // Ensure brand name is preserved
        var mealName = json["mealName"] as? String ?? initialResult.mealName
        if !mealName.lowercased().contains(brand.lowercased()) && initialResult.mealName.lowercased().contains(brand.lowercased()) {
            mealName = initialResult.mealName // Keep the original name with brand
            DebugLogger.shared.warning("Manual parse: Brand name missing, using initial meal name")
        }
        
        return MealAnalysisResult(
            mealName: mealName,
            confidence: json["confidence"] as? Double ?? 0.9,
            ingredients: ingredients.isEmpty ? initialResult.ingredients : ingredients,
            nutrition: nutrition,
            micronutrients: micronutrients.isEmpty ? initialResult.micronutrients : micronutrients,
            clarifications: [], // No clarifications for restaurant meals
            requestedTools: nil,
            brandDetected: brand
        )
    }
    
    private func parseAndMergeAnalysis(_ original: MealAnalysisResult, deepAnalysis: String) throws -> MealAnalysisResult {
        // Try to parse as JSON first
        if let data = deepAnalysis.data(using: .utf8),
           let parsedResult = try? JSONDecoder().decode(MealAnalysisResult.self, from: data) {
            // Successfully parsed as MealAnalysisResult
            var result = parsedResult
            
            // Calculate micronutrients if missing
            if result.micronutrients.isEmpty || result.micronutrients.count < 3 {
                let calculatedNutrients = MicronutrientDatabase.shared.calculateMicronutrients(for: result.ingredients)
                if !calculatedNutrients.isEmpty {
                    result.micronutrients = calculatedNutrients
                    DebugLogger.shared.info("Deep analysis: calculated \(calculatedNutrients.count) micronutrients")
                }
            }
            
            return result
        }
        
        // Fallback: return original with increased confidence
        var result = MealAnalysisResult(
            mealName: original.mealName,
            confidence: min(0.9, original.confidence + 0.15),
            ingredients: original.ingredients,
            nutrition: original.nutrition,
            micronutrients: original.micronutrients,
            clarifications: original.clarifications,
            requestedTools: original.requestedTools,
            brandDetected: original.brandDetected
        )
        
        // Calculate micronutrients if missing in fallback
        if result.micronutrients.isEmpty || result.micronutrients.count < 3 {
            let calculatedNutrients = MicronutrientDatabase.shared.calculateMicronutrients(for: result.ingredients)
            if !calculatedNutrients.isEmpty {
                result.micronutrients = calculatedNutrients
            }
        }
        
        return result
    }
    
    private func compressImageForAnalysis(_ image: UIImage) async throws -> Data? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        // For deep analysis, we want good quality
        let maxSize = 1024 * 1024 * 2 // 2MB
        
        if imageData.count <= maxSize {
            return imageData
        }
        
        // Compress further if needed
        var compressionQuality: CGFloat = 0.7
        while compressionQuality > 0.3 {
            if let compressed = image.jpegData(compressionQuality: compressionQuality),
               compressed.count <= maxSize {
                return compressed
            }
            compressionQuality -= 0.1
        }
        
        return image.jpegData(compressionQuality: 0.3)
    }
}

// MARK: - Analysis Cache

private class AnalysisCache {
    struct CachedBrandResult {
        let result: MealAnalysisResult
        let timestamp: Date
    }
    
    private var brandCache: [String: CachedBrandResult] = [:]
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    func getCachedBrand(_ key: String) -> CachedBrandResult? {
        guard let cached = brandCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheExpiration else {
            return nil
        }
        return cached
    }
    
    func cacheBrandResult(_ key: String, result: MealAnalysisResult) {
        brandCache[key] = CachedBrandResult(result: result, timestamp: Date())
    }
}

// MARK: - VertexAI Extension

extension VertexAIService {
    func performToolAnalysis(
        tool: MealAnalysisAgent.AnalysisTool,
        prompt: String,
        imageData: Data? = nil
    ) async throws -> String {
        DebugLogger.shared.mealAnalysis("VertexAI performToolAnalysis called for tool: \(tool.displayName)")
        
        // Configure generation for specific tool
        let config = GenerationConfig(
            temperature: 0.2, // V2: Low temperature for determinism across all tools
            topP: 0.95,
            topK: 40,
            maxOutputTokens: tool == .deepAnalysis ? 4096 : 2048,
            responseMIMEType: "application/json" // Request JSON response
        )
        
        // Create model with tool-specific config - using thinking model
        let ai = FirebaseAI.firebaseAI()
        let model = ai.generativeModel(
            modelName: "gemini-2.0-flash-thinking-exp-1219",
            generationConfig: config
        )
        
        DebugLogger.shared.mealAnalysis("Sending request to Gemini for \(tool.displayName)")
        let startTime = Date()
        
        // Generate content
        let response: String
        if let imageData = imageData {
            DebugLogger.shared.info("Including image data (\(imageData.count) bytes)")
            let imageContent = InlineDataPart(data: imageData, mimeType: "image/jpeg")
            let result = try await model.generateContent(imageContent, prompt)
            response = result.text ?? ""
        } else {
            let result = try await model.generateContent(prompt)
            response = result.text ?? ""
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        DebugLogger.shared.performance("⏱️ Tool analysis completed in \(String(format: "%.2f", elapsed))s")
        DebugLogger.shared.info("Response length: \(response.count) characters")
        
        // Extract and log thinking process for tools
        if let thinkingRange = response.range(of: "<thinking>.*?</thinking>", options: .regularExpression) {
            let thinkingContent = String(response[thinkingRange])
                .replacingOccurrences(of: "<thinking>", with: "")
                .replacingOccurrences(of: "</thinking>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🧠 \(tool.displayName.uppercased()) THINKING:")
            print(String(repeating: "-", count: 60))
            thinkingContent.split(separator: "\n").forEach { line in
                print("  \(line)")
            }
            print(String(repeating: "-", count: 60))
            
            DebugLogger.shared.mealAnalysis("🧠 Tool thinking: \(thinkingContent.prefix(300))...")
        }
        
        return response
    }
}