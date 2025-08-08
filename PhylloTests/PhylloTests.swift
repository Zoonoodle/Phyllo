//
//  PhylloTests.swift
//  PhylloTests
//
//  Created by Brennen Price on 7/27/25.
//

import Testing
@testable import Phyllo

struct PhylloTests {

    @Test func clarificationAdjustmentsApplyMacroDeltas() async throws {
        let base = MealAnalysisResult(
            mealName: "Test Meal",
            confidence: 0.7,
            ingredients: [],
            nutrition: .init(calories: 500, protein: 30, carbs: 50, fat: 20),
            micronutrients: [],
            clarifications: [
                .init(
                    question: "Milk type?",
                    options: [
                        .init(text: "Whole milk", calorieImpact: 30, proteinImpact: 0, carbImpact: 0, fatImpact: 3, isRecommended: false, note: nil),
                        .init(text: "Water", calorieImpact: -120, proteinImpact: -8, carbImpact: -12, fatImpact: -5, isRecommended: false, note: nil)
                    ],
                    clarificationType: "liquid_base"
                ),
                .init(
                    question: "Added sugar?",
                    options: [
                        .init(text: "1 tbsp sugar", calorieImpact: 48, proteinImpact: nil, carbImpact: 12, fatImpact: nil, isRecommended: false, note: nil)
                    ],
                    clarificationType: "sweetener"
                )
            ]
        )
        let answers = ["0": "Water", "1": "1_tbsp_sugar"]

        var cal = 0; var p: Double = 0; var c: Double = 0; var f: Double = 0
        for (key, val) in answers {
            guard let idx = Int(key), base.clarifications.indices.contains(idx) else { continue }
            let q = base.clarifications[idx]
            let matched = q.options.first { opt in
                opt.text == val || opt.text.lowercased().replacingOccurrences(of: " ", with: "_") == val.lowercased()
            }
            if let o = matched {
                cal += o.calorieImpact
                p += o.proteinImpact ?? 0
                c += o.carbImpact ?? 0
                f += o.fatImpact ?? 0
            }
        }

        let finalCalories = max(0, base.nutrition.calories + cal)
        let finalProtein = max(0, base.nutrition.protein + p)
        let finalCarbs = max(0, base.nutrition.carbs + c)
        let finalFat = max(0, base.nutrition.fat + f)

        #expect(finalCalories == 428)
        #expect(finalProtein == 22)
        #expect(finalCarbs == 50)
        #expect(finalFat == 15)
    }

    @Test func appliedClarificationsPersistOnMeal() async throws {
        var meal = LoggedMeal(name: "Test", calories: 400, protein: 25, carbs: 40, fat: 15, timestamp: Date())
        meal.appliedClarifications = ["liquid_base": "Water", "sweetener": "1 tbsp sugar"]
        let data = meal.toFirestore()
        let parsed = LoggedMeal.fromFirestore(data)
        #expect(parsed != nil)
        #expect(parsed?.appliedClarifications["liquid_base"] == "Water")
        #expect(parsed?.appliedClarifications["sweetener"] == "1 tbsp sugar")
    }

}
