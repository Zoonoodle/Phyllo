import Foundation

// MARK: - Micronutrient Database Service
/// Provides micronutrient lookup and aggregation for food ingredients
/// Based on USDA FoodData Central values

@MainActor
class MicronutrientDatabase {
    static let shared = MicronutrientDatabase()
    
    private init() {}
    
    // MARK: - Types
    
    struct FoodMicronutrients {
        let per100g: [MicronutrientInfo]
        
        struct MicronutrientInfo {
            let name: String
            let amount: Double  // Amount per 100g
            let unit: String
            let dailyValue: Double  // Daily recommended value for %RDA calculation
        }
    }
    
    // MARK: - Database
    
    /// Comprehensive micronutrient database per 100g of food
    /// Data sourced from USDA FoodData Central
    private let database: [String: FoodMicronutrients] = [
        // EGGS
        "egg": FoodMicronutrients(per100g: [
            .init(name: "Vitamin D", amount: 2.0, unit: "mcg", dailyValue: 20.0),
            .init(name: "Vitamin B12", amount: 0.89, unit: "mcg", dailyValue: 2.4),
            .init(name: "Selenium", amount: 30.7, unit: "mcg", dailyValue: 55.0),
            .init(name: "Choline", amount: 293.8, unit: "mg", dailyValue: 550.0),
            .init(name: "Iron", amount: 1.75, unit: "mg", dailyValue: 18.0),
            .init(name: "Phosphorus", amount: 198.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin A", amount: 160.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Folate", amount: 47.0, unit: "mcg", dailyValue: 400.0)
        ]),
        "fried egg": FoodMicronutrients(per100g: [
            .init(name: "Vitamin D", amount: 2.1, unit: "mcg", dailyValue: 20.0),
            .init(name: "Vitamin B12", amount: 0.91, unit: "mcg", dailyValue: 2.4),
            .init(name: "Selenium", amount: 31.0, unit: "mcg", dailyValue: 55.0),
            .init(name: "Choline", amount: 295.0, unit: "mg", dailyValue: 550.0),
            .init(name: "Iron", amount: 1.8, unit: "mg", dailyValue: 18.0),
            .init(name: "Phosphorus", amount: 200.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin A", amount: 165.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Sodium", amount: 207.0, unit: "mg", dailyValue: 2300.0)
        ]),
        
        // CORN
        "corn": FoodMicronutrients(per100g: [
            .init(name: "Vitamin C", amount: 6.8, unit: "mg", dailyValue: 90.0),
            .init(name: "Thiamin", amount: 0.155, unit: "mg", dailyValue: 1.2),
            .init(name: "Folate", amount: 42.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Magnesium", amount: 37.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Phosphorus", amount: 89.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Potassium", amount: 270.0, unit: "mg", dailyValue: 3500.0),
            .init(name: "Vitamin A", amount: 9.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Lutein+Zeaxanthin", amount: 644.0, unit: "mcg", dailyValue: 10000.0)
        ]),
        "sweet corn": FoodMicronutrients(per100g: [
            .init(name: "Vitamin C", amount: 6.8, unit: "mg", dailyValue: 90.0),
            .init(name: "Thiamin", amount: 0.155, unit: "mg", dailyValue: 1.2),
            .init(name: "Folate", amount: 42.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Magnesium", amount: 37.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Phosphorus", amount: 89.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Potassium", amount: 270.0, unit: "mg", dailyValue: 3500.0)
        ]),
        
        // BROCCOLI
        "broccoli": FoodMicronutrients(per100g: [
            .init(name: "Vitamin C", amount: 89.2, unit: "mg", dailyValue: 90.0),
            .init(name: "Vitamin K", amount: 101.6, unit: "mcg", dailyValue: 120.0),
            .init(name: "Folate", amount: 63.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Vitamin A", amount: 31.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Potassium", amount: 316.0, unit: "mg", dailyValue: 3500.0),
            .init(name: "Fiber", amount: 2.6, unit: "g", dailyValue: 28.0),
            .init(name: "Calcium", amount: 47.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Iron", amount: 0.73, unit: "mg", dailyValue: 18.0)
        ]),
        
        // TOMATOES
        "tomato": FoodMicronutrients(per100g: [
            .init(name: "Vitamin C", amount: 13.7, unit: "mg", dailyValue: 90.0),
            .init(name: "Vitamin K", amount: 7.9, unit: "mcg", dailyValue: 120.0),
            .init(name: "Potassium", amount: 237.0, unit: "mg", dailyValue: 3500.0),
            .init(name: "Lycopene", amount: 2573.0, unit: "mcg", dailyValue: 15000.0),
            .init(name: "Vitamin A", amount: 42.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Folate", amount: 15.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Beta-carotene", amount: 449.0, unit: "mcg", dailyValue: 5000.0)
        ]),
        "cherry tomato": FoodMicronutrients(per100g: [
            .init(name: "Vitamin C", amount: 13.7, unit: "mg", dailyValue: 90.0),
            .init(name: "Vitamin K", amount: 7.9, unit: "mcg", dailyValue: 120.0),
            .init(name: "Potassium", amount: 237.0, unit: "mg", dailyValue: 3500.0),
            .init(name: "Lycopene", amount: 2573.0, unit: "mcg", dailyValue: 15000.0),
            .init(name: "Vitamin A", amount: 42.0, unit: "mcg", dailyValue: 900.0)
        ]),
        
        // CHICKEN
        "chicken": FoodMicronutrients(per100g: [
            .init(name: "Niacin", amount: 8.2, unit: "mg", dailyValue: 16.0),
            .init(name: "Vitamin B6", amount: 0.53, unit: "mg", dailyValue: 1.7),
            .init(name: "Selenium", amount: 27.6, unit: "mcg", dailyValue: 55.0),
            .init(name: "Phosphorus", amount: 228.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin B12", amount: 0.31, unit: "mcg", dailyValue: 2.4),
            .init(name: "Zinc", amount: 1.0, unit: "mg", dailyValue: 11.0),
            .init(name: "Iron", amount: 0.89, unit: "mg", dailyValue: 18.0),
            .init(name: "Potassium", amount: 334.0, unit: "mg", dailyValue: 3500.0)
        ]),
        "chicken breast": FoodMicronutrients(per100g: [
            .init(name: "Niacin", amount: 13.7, unit: "mg", dailyValue: 16.0),
            .init(name: "Vitamin B6", amount: 0.93, unit: "mg", dailyValue: 1.7),
            .init(name: "Selenium", amount: 31.9, unit: "mcg", dailyValue: 55.0),
            .init(name: "Phosphorus", amount: 246.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin B12", amount: 0.21, unit: "mcg", dailyValue: 2.4),
            .init(name: "Zinc", amount: 0.8, unit: "mg", dailyValue: 11.0),
            .init(name: "Potassium", amount: 391.0, unit: "mg", dailyValue: 3500.0)
        ]),
        
        // BEEF
        "beef": FoodMicronutrients(per100g: [
            .init(name: "Vitamin B12", amount: 2.64, unit: "mcg", dailyValue: 2.4),
            .init(name: "Zinc", amount: 6.31, unit: "mg", dailyValue: 11.0),
            .init(name: "Selenium", amount: 26.4, unit: "mcg", dailyValue: 55.0),
            .init(name: "Iron", amount: 2.6, unit: "mg", dailyValue: 18.0),
            .init(name: "Niacin", amount: 4.5, unit: "mg", dailyValue: 16.0),
            .init(name: "Phosphorus", amount: 201.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin B6", amount: 0.35, unit: "mg", dailyValue: 1.7),
            .init(name: "Potassium", amount: 318.0, unit: "mg", dailyValue: 3500.0)
        ]),
        
        // SALMON
        "salmon": FoodMicronutrients(per100g: [
            .init(name: "Vitamin D", amount: 10.9, unit: "mcg", dailyValue: 20.0),
            .init(name: "Vitamin B12", amount: 3.18, unit: "mcg", dailyValue: 2.4),
            .init(name: "Omega-3", amount: 2260.0, unit: "mg", dailyValue: 1600.0),
            .init(name: "Selenium", amount: 36.5, unit: "mcg", dailyValue: 55.0),
            .init(name: "Niacin", amount: 8.67, unit: "mg", dailyValue: 16.0),
            .init(name: "Vitamin B6", amount: 0.82, unit: "mg", dailyValue: 1.7),
            .init(name: "Phosphorus", amount: 252.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Potassium", amount: 490.0, unit: "mg", dailyValue: 3500.0)
        ]),
        
        // RICE
        "rice": FoodMicronutrients(per100g: [
            .init(name: "Manganese", amount: 1.09, unit: "mg", dailyValue: 2.3),
            .init(name: "Selenium", amount: 15.1, unit: "mcg", dailyValue: 55.0),
            .init(name: "Thiamin", amount: 0.07, unit: "mg", dailyValue: 1.2),
            .init(name: "Niacin", amount: 1.62, unit: "mg", dailyValue: 16.0),
            .init(name: "Magnesium", amount: 25.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Phosphorus", amount: 115.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Iron", amount: 0.8, unit: "mg", dailyValue: 18.0),
            .init(name: "Folate", amount: 8.0, unit: "mcg", dailyValue: 400.0)
        ]),
        "brown rice": FoodMicronutrients(per100g: [
            .init(name: "Manganese", amount: 1.9, unit: "mg", dailyValue: 2.3),
            .init(name: "Selenium", amount: 19.1, unit: "mcg", dailyValue: 55.0),
            .init(name: "Magnesium", amount: 43.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Phosphorus", amount: 162.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin B6", amount: 0.29, unit: "mg", dailyValue: 1.7),
            .init(name: "Thiamin", amount: 0.19, unit: "mg", dailyValue: 1.2),
            .init(name: "Fiber", amount: 1.8, unit: "g", dailyValue: 28.0),
            .init(name: "Iron", amount: 0.52, unit: "mg", dailyValue: 18.0)
        ]),
        
        // SPINACH
        "spinach": FoodMicronutrients(per100g: [
            .init(name: "Vitamin K", amount: 482.9, unit: "mcg", dailyValue: 120.0),
            .init(name: "Vitamin A", amount: 469.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Folate", amount: 194.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Iron", amount: 2.71, unit: "mg", dailyValue: 18.0),
            .init(name: "Vitamin C", amount: 28.1, unit: "mg", dailyValue: 90.0),
            .init(name: "Calcium", amount: 99.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Magnesium", amount: 79.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Potassium", amount: 558.0, unit: "mg", dailyValue: 3500.0)
        ]),
        
        // MILK
        "milk": FoodMicronutrients(per100g: [
            .init(name: "Calcium", amount: 113.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Vitamin D", amount: 1.0, unit: "mcg", dailyValue: 20.0),
            .init(name: "Vitamin B12", amount: 0.44, unit: "mcg", dailyValue: 2.4),
            .init(name: "Riboflavin", amount: 0.17, unit: "mg", dailyValue: 1.3),
            .init(name: "Phosphorus", amount: 91.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Potassium", amount: 150.0, unit: "mg", dailyValue: 3500.0),
            .init(name: "Vitamin A", amount: 46.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Selenium", amount: 3.3, unit: "mcg", dailyValue: 55.0)
        ]),
        
        // CHEESE
        "cheese": FoodMicronutrients(per100g: [
            .init(name: "Calcium", amount: 721.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Vitamin B12", amount: 1.1, unit: "mcg", dailyValue: 2.4),
            .init(name: "Phosphorus", amount: 512.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin A", amount: 330.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Zinc", amount: 3.6, unit: "mg", dailyValue: 11.0),
            .init(name: "Selenium", amount: 28.5, unit: "mcg", dailyValue: 55.0),
            .init(name: "Riboflavin", amount: 0.43, unit: "mg", dailyValue: 1.3),
            .init(name: "Sodium", amount: 653.0, unit: "mg", dailyValue: 2300.0)
        ]),
        "cheddar": FoodMicronutrients(per100g: [
            .init(name: "Calcium", amount: 721.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Vitamin B12", amount: 1.1, unit: "mcg", dailyValue: 2.4),
            .init(name: "Phosphorus", amount: 512.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Vitamin A", amount: 330.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Zinc", amount: 3.6, unit: "mg", dailyValue: 11.0)
        ]),
        
        // BREAD
        "bread": FoodMicronutrients(per100g: [
            .init(name: "Selenium", amount: 23.6, unit: "mcg", dailyValue: 55.0),
            .init(name: "Thiamin", amount: 0.48, unit: "mg", dailyValue: 1.2),
            .init(name: "Iron", amount: 3.6, unit: "mg", dailyValue: 18.0),
            .init(name: "Niacin", amount: 4.7, unit: "mg", dailyValue: 16.0),
            .init(name: "Folate", amount: 85.0, unit: "mcg", dailyValue: 400.0),
            .init(name: "Manganese", amount: 0.65, unit: "mg", dailyValue: 2.3),
            .init(name: "Fiber", amount: 2.7, unit: "g", dailyValue: 28.0),
            .init(name: "Sodium", amount: 478.0, unit: "mg", dailyValue: 2300.0)
        ]),
        "whole wheat bread": FoodMicronutrients(per100g: [
            .init(name: "Fiber", amount: 6.8, unit: "g", dailyValue: 28.0),
            .init(name: "Selenium", amount: 30.0, unit: "mcg", dailyValue: 55.0),
            .init(name: "Manganese", amount: 2.0, unit: "mg", dailyValue: 2.3),
            .init(name: "Magnesium", amount: 82.0, unit: "mg", dailyValue: 420.0),
            .init(name: "Phosphorus", amount: 223.0, unit: "mg", dailyValue: 1250.0),
            .init(name: "Iron", amount: 2.5, unit: "mg", dailyValue: 18.0),
            .init(name: "Zinc", amount: 1.8, unit: "mg", dailyValue: 11.0),
            .init(name: "Thiamin", amount: 0.38, unit: "mg", dailyValue: 1.2)
        ]),
        
        // HERBS (even small amounts can be significant for some nutrients)
        "herbs": FoodMicronutrients(per100g: [
            .init(name: "Vitamin K", amount: 1714.0, unit: "mcg", dailyValue: 120.0),
            .init(name: "Iron", amount: 37.0, unit: "mg", dailyValue: 18.0),
            .init(name: "Calcium", amount: 1652.0, unit: "mg", dailyValue: 1300.0),
            .init(name: "Vitamin A", amount: 424.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Vitamin C", amount: 133.0, unit: "mg", dailyValue: 90.0)
        ]),
        "parsley": FoodMicronutrients(per100g: [
            .init(name: "Vitamin K", amount: 1640.0, unit: "mcg", dailyValue: 120.0),
            .init(name: "Vitamin C", amount: 133.0, unit: "mg", dailyValue: 90.0),
            .init(name: "Vitamin A", amount: 421.0, unit: "mcg", dailyValue: 900.0),
            .init(name: "Iron", amount: 6.2, unit: "mg", dailyValue: 18.0),
            .init(name: "Folate", amount: 152.0, unit: "mcg", dailyValue: 400.0)
        ])
    ]
    
    // MARK: - Public Methods
    
    /// Calculate micronutrients for a meal based on its ingredients
    func calculateMicronutrients(for ingredients: [MealAnalysisResult.AnalyzedIngredient]) -> [MealAnalysisResult.MicronutrientInfo] {
        var aggregatedNutrients: [String: (amount: Double, unit: String, dailyValue: Double)] = [:]
        
        for ingredient in ingredients {
            // Convert ingredient amount to grams for calculation
            let gramsAmount = convertToGrams(amount: ingredient.amount, unit: ingredient.unit, foodName: ingredient.name)
            
            // Find matching food in database (fuzzy match)
            if let foodMicronutrients = findBestMatch(for: ingredient.name) {
                // Scale nutrients based on actual amount (database is per 100g)
                let scaleFactor = gramsAmount / 100.0
                
                for nutrient in foodMicronutrients.per100g {
                    if var existing = aggregatedNutrients[nutrient.name] {
                        existing.amount += nutrient.amount * scaleFactor
                        aggregatedNutrients[nutrient.name] = existing
                    } else {
                        aggregatedNutrients[nutrient.name] = (
                            amount: nutrient.amount * scaleFactor,
                            unit: nutrient.unit,
                            dailyValue: nutrient.dailyValue
                        )
                    }
                }
            }
        }
        
        // Convert to MealAnalysisResult format
        var micronutrients: [MealAnalysisResult.MicronutrientInfo] = []
        for (name, data) in aggregatedNutrients {
            let percentRDA = (data.amount / data.dailyValue) * 100
            
            // Only include nutrients that are at least 5% of RDA
            if percentRDA >= 5.0 {
                micronutrients.append(MealAnalysisResult.MicronutrientInfo(
                    name: name,
                    amount: round(data.amount * 10) / 10,  // Round to 1 decimal
                    unit: data.unit,
                    percentRDA: round(percentRDA)
                ))
            }
        }
        
        // Sort by %RDA descending and limit to top 8 (as per spec)
        micronutrients.sort { $0.percentRDA > $1.percentRDA }
        return Array(micronutrients.prefix(8))
    }
    
    // MARK: - Private Methods
    
    private func findBestMatch(for foodName: String) -> FoodMicronutrients? {
        let lowercasedName = foodName.lowercased()
        
        // Direct match
        if let exact = database[lowercasedName] {
            return exact
        }
        
        // Check if food name contains any database key
        for (key, nutrients) in database {
            if lowercasedName.contains(key) || key.contains(lowercasedName) {
                return nutrients
            }
        }
        
        // Check for partial word matches
        let words = lowercasedName.split(separator: " ")
        for word in words {
            if let match = database[String(word)] {
                return match
            }
        }
        
        return nil
    }
    
    private func convertToGrams(amount: String, unit: String, foodName: String) -> Double {
        guard let numericAmount = Double(amount) else { return 100.0 }
        
        switch unit.lowercased() {
        case "g", "grams":
            return numericAmount
        case "oz", "ounce", "ounces":
            return numericAmount * 28.35
        case "ml", "milliliters":
            return numericAmount  // Assume 1ml = 1g for liquids
        case "cup", "cups":
            return estimateCupToGrams(for: foodName) * numericAmount
        case "tbsp", "tablespoon", "tablespoons":
            return 15.0 * numericAmount
        case "tsp", "teaspoon", "teaspoons":
            return 5.0 * numericAmount
        case "slice", "slices":
            return estimateSliceWeight(for: foodName) * numericAmount
        case "piece", "pieces":
            return estimatePieceWeight(for: foodName) * numericAmount
        case "egg", "eggs":
            return 50.0 * numericAmount  // Average egg weight
        case "serving", "servings":
            return estimateServingWeight(for: foodName) * numericAmount
        default:
            return 100.0 * numericAmount  // Default to 100g per unit
        }
    }
    
    private func estimateCupToGrams(for food: String) -> Double {
        let lowercased = food.lowercased()
        
        // Common conversions for 1 cup
        if lowercased.contains("rice") { return 158.0 }  // Cooked rice
        if lowercased.contains("broccoli") { return 91.0 }
        if lowercased.contains("corn") { return 145.0 }
        if lowercased.contains("tomato") { return 180.0 }
        if lowercased.contains("spinach") { return 30.0 }  // Raw spinach
        if lowercased.contains("milk") { return 240.0 }
        
        return 150.0  // Default cup weight
    }
    
    private func estimateSliceWeight(for food: String) -> Double {
        let lowercased = food.lowercased()
        
        if lowercased.contains("bread") { return 28.0 }
        if lowercased.contains("cheese") { return 20.0 }
        if lowercased.contains("tomato") { return 20.0 }
        
        return 30.0  // Default slice weight
    }
    
    private func estimatePieceWeight(for food: String) -> Double {
        let lowercased = food.lowercased()
        
        if lowercased.contains("chicken") { return 100.0 }  // Chicken breast piece
        
        return 50.0  // Default piece weight
    }
    
    private func estimateServingWeight(for food: String) -> Double {
        let lowercased = food.lowercased()
        
        if lowercased.contains("egg") { return 100.0 }  // 2 eggs typically
        if lowercased.contains("chicken") { return 113.0 }  // 4oz serving
        if lowercased.contains("beef") { return 113.0 }
        if lowercased.contains("salmon") { return 113.0 }
        if lowercased.contains("rice") { return 158.0 }  // 1 cup cooked
        
        return 100.0  // Default serving
    }
}