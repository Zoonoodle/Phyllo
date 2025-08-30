# Plan: Meal Scanning Clarification System Fixes
## Date: 2025-08-30
## Phase 2: Planning

## User-Approved Design Decisions

1. **Data Format**: Option B - Update service to match against `option.id`
2. **Transformation Logic**: Option B - Full transformation system with rules
3. **Implementation Scope**: Option B - Complete fix (data format + transformations)
4. **Testing Strategy**: Option B - Manual testing with specific scenarios

## Implementation Plan

### Step 1: Fix Option Matching Logic
**File**: `NutriSync/Services/MealCaptureService.swift`
**Lines**: 400-416

Update the option matching to handle both `option.id` and `option.text`:

```swift
private func findMatchingOption(in question: ClarificationQuestion, for selectedId: String) -> ClarificationOption? {
    return question.options.first { option in
        // Strategy 1: Direct text match
        if option.text == selectedId { return true }
        
        // Strategy 2: Direct ID match (if option has an id field)
        if let optionId = option.id, optionId == selectedId { return true }
        
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
```

### Step 2: Add Meal Transformation System
**File**: `NutriSync/Services/MealCaptureService.swift`
**Location**: After line 425 (in `applySelectedClarifications`)

Create transformation logic based on clarification type:

```swift
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
                Ingredient(
                    name: "Black Coffee",
                    amount: extractAmount(from: selectedOption) ?? "12",
                    unit: "oz",
                    foodGroup: "Beverage",
                    calories: 5,
                    protein: 0,
                    carbs: 1,
                    fat: 0
                )
            ]
        } else if selectedOption.lowercased().contains("water") {
            transformedName = "Water"
            transformedIngredients = [
                Ingredient(
                    name: "Water",
                    amount: extractAmount(from: selectedOption) ?? "16",
                    unit: "oz",
                    foodGroup: "Beverage",
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0
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
            var scaled = ingredient
            if let amount = Double(ingredient.amount) {
                scaled.amount = String(amount * scale)
            }
            return scaled
        }
        
    case "cooking_method":
        // Adjust based on cooking method
        if selectedOption.lowercased().contains("fried") {
            // Add oil to ingredients
            transformedIngredients.append(
                Ingredient(
                    name: "Cooking Oil",
                    amount: "1",
                    unit: "tbsp",
                    foodGroup: "Fats",
                    calories: 120,
                    protein: 0,
                    carbs: 0,
                    fat: 14
                )
            )
        }
        
    default:
        break
    }
    
    // Apply nutrition deltas and create result
    return MealAnalysisResult(
        mealName: transformedName,
        ingredients: transformedIngredients,
        totalCalories: max(0, original.totalCalories + nutritionDeltas.cal),
        totalProtein: max(0, original.totalProtein + nutritionDeltas.protein),
        totalCarbs: max(0, original.totalCarbs + nutritionDeltas.carbs),
        totalFat: max(0, original.totalFat + nutritionDeltas.fat),
        confidence: original.confidence,
        clarificationQuestions: []  // Already answered
    )
}

// Helper functions
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

private func addDeluxeIngredients(to ingredients: [Ingredient]) -> [Ingredient] {
    var updated = ingredients
    
    // Add typical deluxe ingredients if not present
    let hasLettuce = ingredients.contains { $0.name.lowercased().contains("lettuce") }
    let hasTomato = ingredients.contains { $0.name.lowercased().contains("tomato") }
    let hasCheese = ingredients.contains { $0.name.lowercased().contains("cheese") }
    
    if !hasLettuce {
        updated.append(Ingredient(
            name: "Lettuce",
            amount: "1",
            unit: "leaf",
            foodGroup: "Vegetables",
            calories: 5,
            protein: 0.3,
            carbs: 1,
            fat: 0
        ))
    }
    
    if !hasTomato {
        updated.append(Ingredient(
            name: "Tomato",
            amount: "2",
            unit: "slices",
            foodGroup: "Vegetables",
            calories: 10,
            protein: 0.5,
            carbs: 2,
            fat: 0
        ))
    }
    
    if !hasCheese {
        updated.append(Ingredient(
            name: "American Cheese",
            amount: "1",
            unit: "slice",
            foodGroup: "Dairy",
            calories: 60,
            protein: 4,
            carbs: 1,
            fat: 5
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
```

### Step 3: Update applySelectedClarifications Method
**File**: `NutriSync/Services/MealCaptureService.swift`
**Lines**: 394-442

Integrate the new matching and transformation:

```swift
func applySelectedClarifications(
    to originalResult: MealAnalysisResult,
    selections: [String: String]
) -> MealAnalysisResult {
    
    guard !selections.isEmpty else { return originalResult }
    
    var adjustedResult = originalResult
    
    for question in originalResult.clarificationQuestions {
        guard let selectedOptionId = selections[question.id] else { continue }
        
        // Use new robust matching
        guard let matchedOption = findMatchingOption(in: question, for: selectedOptionId) else {
            print("⚠️ No matching option found for '\(selectedOptionId)' in question '\(question.id)'")
            continue
        }
        
        // Calculate nutrition deltas
        let deltas = (
            cal: matchedOption.nutritionImpact.calories,
            protein: matchedOption.nutritionImpact.protein,
            carbs: matchedOption.nutritionImpact.carbs,
            fat: matchedOption.nutritionImpact.fat
        )
        
        // Apply transformation based on clarification type
        adjustedResult = transformMealBasedOnClarification(
            original: adjustedResult,
            clarificationType: question.clarificationType ?? "general",
            selectedOption: matchedOption.text,
            nutritionDeltas: deltas
        )
        
        print("✅ Applied clarification: \(matchedOption.text)")
        print("   Deltas: \(deltas)")
        print("   New name: \(adjustedResult.mealName)")
        print("   Ingredients: \(adjustedResult.ingredients.count) items")
    }
    
    return adjustedResult
}
```

### Step 4: Update ClarificationQuestion Model (if needed)
**File**: `NutriSync/Models/MealAnalysisResult.swift`

Add clarificationType field if not present:

```swift
struct ClarificationQuestion: Codable {
    let id: String
    let question: String
    let options: [ClarificationOption]
    let clarificationType: String?  // Add this if missing
}

struct ClarificationOption: Codable {
    let id: String?  // Add this for normalized ID
    let text: String
    let nutritionImpact: NutritionImpact
}
```

### Step 5: Update UI to Include Option ID
**File**: `NutriSync/Views/Scan/Results/ClarificationQuestionsView.swift`
**Line**: 33-34

Ensure option has both text and normalized ID:

```swift
// Keep existing normalized ID generation
let normalizedId = option.text.lowercased()
    .replacingOccurrences(of: " ", with: "_")
    .replacingOccurrences(of: "(", with: "")
    .replacingOccurrences(of: ")", with: "")
    .replacingOccurrences(of: "/", with: "_")

// Store the normalized ID (current behavior is correct)
selectedOptions[currentQuestion.id] = normalizedId
```

### Step 6: Testing Protocol

#### Test Scenarios:

1. **Black Coffee Selection**
   - Scan protein shake image
   - Select "Black coffee (approx. 12 oz / 350 ml)"
   - Verify: 5 cal, 0g protein, name = "Black Coffee"

2. **Spicy Deluxe Selection**
   - Scan Chick-fil-A sandwich
   - Select "Spicy Deluxe Chicken Sandwich"
   - Verify: 560 cal, name includes "Spicy Deluxe", has lettuce/tomato/cheese

3. **Multiple Clarifications**
   - Scan meal with 2+ questions
   - Answer both
   - Verify both transformations applied

4. **Edge Cases**
   - Very long option text
   - Special characters in options
   - Null clarificationType

#### Compilation Test:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Services/MealCaptureService.swift \
  NutriSync/Views/Scan/Results/ClarificationQuestionsView.swift \
  NutriSync/Models/MealAnalysisResult.swift
```

### Step 7: Debug Logging

Add comprehensive logging to track the fix:

```swift
// In applySelectedClarifications
print("📊 Clarification Debug:")
print("   Question: \(question.question)")
print("   Selected ID: \(selectedOptionId)")
print("   Matched: \(matchedOption?.text ?? "NONE")")
print("   Type: \(question.clarificationType ?? "unknown")")
print("   Before: \(originalResult.mealName) - \(originalResult.totalCalories) cal")
print("   After: \(adjustedResult.mealName) - \(adjustedResult.totalCalories) cal")
```

## Implementation Order

1. **Update MealCaptureService.swift** - Core logic fixes
2. **Test compilation** - Ensure no syntax errors
3. **Manual testing** - Black coffee scenario
4. **Manual testing** - Spicy Deluxe scenario
5. **Fix any issues found**
6. **Final verification** - All test scenarios
7. **Clean up debug logs**
8. **Commit changes**

## Success Criteria

- ✅ Black coffee selection changes meal to 5 calories
- ✅ Spicy Deluxe updates name and ingredients
- ✅ All clarification types work correctly
- ✅ No regression in existing functionality
- ✅ Clean compilation with no warnings
- ✅ User confirms fixes work in app

## Risk Mitigation

1. **If matching still fails**: Add more debug logging to identify exact mismatch
2. **If transformations break**: Keep original data as fallback
3. **If ingredients missing**: Use nutrition deltas as minimum change
4. **If performance degrades**: Cache normalized IDs

## Time Estimate

- Step 1-3 (Core logic): 30 minutes
- Step 4-5 (Model updates): 10 minutes
- Step 6 (Testing): 30 minutes
- Step 7 (Debug/cleanup): 15 minutes

**Total**: ~85 minutes

## Context Window Status
Planning phase at approximately 30% context usage. Ready for implementation in Phase 3.

---

**PHASE 2: PLANNING COMPLETE**
Start NEW session for Phase 3 Implementation with:
- @plan-clarification-issues.md
- @research-clarification-issues.md