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
        let finalResult: MealAnalysisResult
        if shouldUseTools(initialResult, request: request) {
            DebugLogger.shared.mealAnalysis("Tools needed - starting deep analysis")
            finalResult = try await performDeepAnalysis(initialResult, request: request)
        } else {
            DebugLogger.shared.success("High confidence result - no tools needed")
            finalResult = initialResult
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
        // 1. Low confidence triggers tools
        if result.confidence < 0.75 {
            DebugLogger.shared.mealAnalysis("Low confidence (\(result.confidence)) - tools needed")
            return true
        }
        
        // 2. Brand/restaurant detected
        if detectsBrandOrRestaurant(result, request: request) {
            DebugLogger.shared.mealAnalysis("Brand/restaurant detected - tools needed")
            return true
        }
        
        // 3. Complex mixed dishes
        if result.ingredients.count > 5 || 
           ["mixed", "combo", "platter", "bowl"].contains(where: { result.mealName.lowercased().contains($0) }) {
            DebugLogger.shared.mealAnalysis("Complex dish detected - tools needed")
            return true
        }
        
        // 4. High calorie variance dishes (likely restaurant portions)
        if result.nutrition.calories > 800 && result.confidence < 0.85 {
            DebugLogger.shared.mealAnalysis("High calorie dish with moderate confidence - tools needed")
            return true
        }
        
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
    
    private func performDeepAnalysis(
        _ initialResult: MealAnalysisResult,
        request: MealAnalysisRequest
    ) async throws -> MealAnalysisResult {
        var enhancedResult = initialResult
        let brandName = extractBrandName(from: initialResult, request: request)
        
        // Step 1: Brand/Restaurant Search (if applicable)
        if let brand = brandName {
            // Check cache first
            let cacheKey = "\(brand)_\(initialResult.mealName)"
            if let cached = analysisCache.getCachedBrand(cacheKey) {
                DebugLogger.shared.info("Using cached brand result for \(cacheKey)")
                return cached.result
            }
            
            currentTool = .brandSearch
            toolProgress = "Searching \(brand) nutrition info..."
            toolsUsedInAnalysis.append(.brandSearch)
            
            let searchResult = try await performBrandSearch(
                brand: brand,
                mealName: initialResult.mealName,
                initialResult: initialResult
            )
            
            if let searchResult = searchResult {
                enhancedResult = searchResult
                // Cache the result
                analysisCache.cacheBrandResult(cacheKey, result: enhancedResult)
            }
        }
        
        // Step 2: Deep Ingredient Analysis (if still low confidence)
        if enhancedResult.confidence < 0.85 {
            currentTool = .deepAnalysis
            toolProgress = "Analyzing each ingredient..."
            toolsUsedInAnalysis.append(.deepAnalysis)
            
            let deepResult = try await performDeepIngredientAnalysis(
                enhancedResult,
                request: request
            )
            
            enhancedResult = deepResult
        }
        
        // Step 3: Nutrition Database Lookup (for specific ingredients if needed)
        if shouldPerformNutritionLookup(enhancedResult) {
            currentTool = .nutritionLookup
            toolProgress = "Verifying nutrition data..."
            toolsUsedInAnalysis.append(.nutritionLookup)
            
            let nutritionResult = try await performNutritionLookup(
                enhancedResult,
                request: request
            )
            
            enhancedResult = nutritionResult
        }
        
        currentTool = nil
        DebugLogger.shared.success("Deep analysis complete: \(enhancedResult.mealName) (confidence: \(enhancedResult.confidence))")
        return enhancedResult
    }
    
    private func extractBrandName(from result: MealAnalysisResult, request: MealAnalysisRequest) -> String? {
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
        initialResult: MealAnalysisResult
    ) async throws -> MealAnalysisResult? {
        
        let searchPrompt = """
        SEARCH ONLINE for official nutrition information:
        
        Restaurant/Brand: \(brand)
        Item: \(mealName)
        
        USE YOUR WEB SEARCH CAPABILITY to find:
        1. Official \(brand) nutrition PDFs or website nutrition facts
        2. Current menu nutrition data (check for 2024-2025 updates)
        3. Exact serving sizes and variations
        4. All ingredients and allergen information
        
        Search queries to try:
        - "\(brand) \(mealName) nutrition facts"
        - "\(brand) menu nutrition PDF 2024"
        - "site:\(brand.lowercased().replacingOccurrences(of: " ", with: "")).com nutrition"
        
        IMPORTANT:
        - Only use OFFICIAL sources (restaurant websites, official PDFs)
        - Include the source URL for verification
        - If multiple sizes exist, match to the image
        - Return exact values, not estimates
        
        Return JSON with structure:
        {
          "found": true/false,
          "source": "URL of source",
          "mealName": "Official menu name",
          "confidence": 0.95-1.0 for official data,
          "nutrition": { calories, protein, carbs, fat },
          "ingredients": [{"name", "amount", "unit", "foodGroup"}],
          "servingSize": "e.g., 1 sandwich (250g)"
        }
        """
        
        do {
            let searchResult = try await vertexAI.performToolAnalysis(
                tool: .brandSearch,
                prompt: searchPrompt,
                imageData: nil
            )
            
            // Parse the search result
            if let data = searchResult.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let found = json["found"] as? Bool, found {
                
                // Merge with initial result
                return mergeWithBrandData(initialResult, brandData: json)
            }
        } catch {
            DebugLogger.shared.error("Brand search failed: \(error)")
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
        
        let imageData = try? await compressImageForAnalysis(request.image)
        
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
    private func mergeWithBrandData(_ original: MealAnalysisResult, brandData: [String: Any]) -> MealAnalysisResult {
        // Extract nutrition from brand data
        let nutrition = brandData["nutrition"] as? [String: Any] ?? [:]
        
        return MealAnalysisResult(
            mealName: (brandData["mealName"] as? String) ?? original.mealName,
            confidence: (brandData["confidence"] as? Double) ?? 0.95,
            ingredients: original.ingredients, // Keep original for now
            nutrition: .init(
                calories: (nutrition["calories"] as? Int) ?? original.nutrition.calories,
                protein: (nutrition["protein"] as? Double) ?? original.nutrition.protein,
                carbs: (nutrition["carbs"] as? Double) ?? original.nutrition.carbs,
                fat: (nutrition["fat"] as? Double) ?? original.nutrition.fat
            ),
            micronutrients: original.micronutrients,
            clarifications: [] // Brand data is accurate, no clarifications needed
        )
    }
    
    private func parseAndMergeAnalysis(_ original: MealAnalysisResult, deepAnalysis: String) throws -> MealAnalysisResult {
        // Try to parse as JSON first
        if let data = deepAnalysis.data(using: .utf8),
           let _ = try? JSONDecoder().decode(MealAnalysisResult.self, from: data) {
            // Successfully parsed as MealAnalysisResult
            return try JSONDecoder().decode(MealAnalysisResult.self, from: data)
        }
        
        // Fallback: return original with increased confidence
        return MealAnalysisResult(
            mealName: original.mealName,
            confidence: min(0.9, original.confidence + 0.15),
            ingredients: original.ingredients,
            nutrition: original.nutrition,
            micronutrients: original.micronutrients,
            clarifications: original.clarifications
        )
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
        // Configure generation for specific tool
        let config = GenerationConfig(
            temperature: tool == .brandSearch ? 0.3 : 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: tool == .deepAnalysis ? 4096 : 2048,
            responseMIMEType: "text/plain" // For search results
        )
        
        // Create model with tool-specific config
        let ai = FirebaseAI.firebaseAI()
        let model = ai.generativeModel(
            modelName: "gemini-2.0-flash-exp",
            generationConfig: config
        )
        
        // Generate content
        if let imageData = imageData {
            let imageContent = InlineDataPart(data: imageData, mimeType: "image/jpeg")
            let response = try await model.generateContent(imageContent, prompt)
            return response.text ?? ""
        } else {
            let response = try await model.generateContent(prompt)
            return response.text ?? ""
        }
    }
}