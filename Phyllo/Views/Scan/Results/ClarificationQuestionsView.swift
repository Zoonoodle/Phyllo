//
//  ClarificationQuestionsView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ClarificationQuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedOptions: [Int: String] = [:]
    @State private var showResults = false
    @State private var isCompleted = false
    @StateObject private var clarificationManager = ClarificationManager.shared
    
    var analyzingMeal: AnalyzingMeal?
    var mealResult: LoggedMeal?
    var clarificationQuestions: [MealAnalysisResult.ClarificationQuestion]?
    var onComplete: ((LoggedMeal) -> Void)?
    
    // Use AI-provided questions or fall back to mock questions
    var questions: [ClarificationQuestion] {
        if let aiQuestions = clarificationQuestions, !aiQuestions.isEmpty {
            // Convert AI questions to view-compatible format
            return aiQuestions.enumerated().map { index, aiQuestion in
                ClarificationQuestion(
                    id: index,
                    question: aiQuestion.question,
                    options: aiQuestion.options.map { aiOption in
                        ClarificationOption(
                            id: aiOption.text.lowercased().replacingOccurrences(of: " ", with: "_"),
                            text: aiOption.text,
                            icon: getIconForOption(aiOption.text),
                            calorieImpact: aiOption.calorieImpact,
                            proteinImpact: Int(aiOption.proteinImpact ?? 0),
                            carbImpact: Int(aiOption.carbImpact ?? 0),
                            fatImpact: Int(aiOption.fatImpact ?? 0),
                            isRecommended: aiOption.isRecommended ?? false,
                            note: aiOption.note
                        )
                    }
                )
            }
        } else {
            // Fall back to mock questions
            return [
                ClarificationQuestion(
            id: 0,
            question: "Was any sugar, syrup, or sweetener added?",
            options: [
                ClarificationOption(
                    id: "none",
                    text: "No sweetener added",
                    icon: "xmark.circle",
                    calorieImpact: 0,
                    carbImpact: 0,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "small",
                    text: "1 teaspoon sugar/honey",
                    icon: "drop.fill",
                    calorieImpact: 16,
                    carbImpact: 4,
                    isRecommended: true,
                    note: "Most common"
                ),
                ClarificationOption(
                    id: "medium",
                    text: "1 tablespoon sugar/syrup",
                    icon: "drop.fill",
                    calorieImpact: 48,
                    carbImpact: 12,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "large",
                    text: "2+ tablespoons sugar/syrup",
                    icon: "drop.fill",
                    calorieImpact: 100,
                    carbImpact: 26,
                    isRecommended: false
                )
            ]
        ),
        ClarificationQuestion(
            id: 1,
            question: "What type of milk was used?",
            options: [
                ClarificationOption(
                    id: "whole",
                    text: "Whole milk",
                    icon: "drop.circle",
                    calorieImpact: 150,
                    proteinImpact: 8,
                    fatImpact: 8,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "2percent",
                    text: "2% milk",
                    icon: "drop.circle",
                    calorieImpact: 120,
                    proteinImpact: 8,
                    fatImpact: 5,
                    isRecommended: true,
                    note: "Most common"
                ),
                ClarificationOption(
                    id: "almond",
                    text: "Almond milk",
                    icon: "leaf.fill",
                    calorieImpact: 40,
                    proteinImpact: 1,
                    fatImpact: 3,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "oat",
                    text: "Oat milk",
                    icon: "leaf.fill",
                    calorieImpact: 120,
                    proteinImpact: 3,
                    carbImpact: 16,
                    isRecommended: false
                )
            ]
        ),
        ClarificationQuestion(
            id: 1,
            question: "What type of milk was used?",
            options: [
                ClarificationOption(
                    id: "whole",
                    text: "Whole milk",
                    icon: "drop.circle",
                    calorieImpact: 150,
                    proteinImpact: 8,
                    fatImpact: 8,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "2percent",
                    text: "2% milk",
                    icon: "drop.circle",
                    calorieImpact: 120,
                    proteinImpact: 8,
                    fatImpact: 5,
                    isRecommended: true,
                    note: "Most common"
                ),
                ClarificationOption(
                    id: "almond",
                    text: "Almond milk",
                    icon: "leaf.fill",
                    calorieImpact: 40,
                    proteinImpact: 1,
                    fatImpact: 3,
                    isRecommended: false
                ),
                ClarificationOption(
                    id: "oat",
                    text: "Oat milk",
                    icon: "leaf.fill",
                    calorieImpact: 120,
                    proteinImpact: 3,
                    carbImpact: 16,
                    isRecommended: false
                )
            ]
        )
            ]
        }
    }
    
    var currentQuestion: ClarificationQuestion {
        questions[currentQuestionIndex]
    }
    
    // Helper function to get icon based on option text
    private func getIconForOption(_ text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("no ") || lowercased.contains("none") || lowercased.contains("without") {
            return "xmark.circle"
        } else if lowercased.contains("milk") || lowercased.contains("cream") {
            return "drop.circle"
        } else if lowercased.contains("sugar") || lowercased.contains("syrup") || lowercased.contains("honey") {
            return "drop.fill"
        } else if lowercased.contains("sauce") || lowercased.contains("dressing") {
            return "drop.triangle.fill"
        } else if lowercased.contains("cheese") {
            return "circle.fill"
        } else if lowercased.contains("oil") || lowercased.contains("butter") {
            return "drop.fill"
        } else if lowercased.contains("vegetable") || lowercased.contains("plant") || lowercased.contains("almond") || lowercased.contains("oat") || lowercased.contains("soy") {
            return "leaf.fill"
        } else {
            return "info.circle"
        }
    }

    // Derive a better leading icon from the question text
    private func iconForQuestion(_ question: String) -> String {
        let q = question.lowercased()
        if q.contains("protein") { return "bolt.fill" }
        if q.contains("milk") || q.contains("dairy") { return "drop.circle" }
        if q.contains("sweet") || q.contains("sugar") { return "cube.fill" }
        if q.contains("oil") || q.contains("butter") { return "drop.fill" }
        if q.contains("cooking") || q.contains("grilled") || q.contains("fried") { return "flame.fill" }
        if q.contains("portion") || q.contains("amount") || q.contains("size") { return "ruler" }
        if q.contains("bread") || q.contains("wrap") || q.contains("bun") { return "baguette" }
        if q.contains("vegetable") || q.contains("plant") { return "leaf.fill" }
        return "info.circle"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header at top
                    headerSection
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                    
                    // Progress dots
                    progressIndicator
                    
                    // Question section
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question
                            questionSection
                            
                            // Options
                            VStack(spacing: 12) {
                                ForEach(currentQuestion.options) { option in
                                    OptionRow(
                                        option: option,
                                        isSelected: selectedOptions[currentQuestion.id] == option.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedOptions[currentQuestion.id] = option.id
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 120)
                    }
                    
                    // Bottom buttons
                    bottomButtons
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            // If the view is dismissed without completion, cancel the analyzing meal
            if !isCompleted, let analyzingMeal = analyzingMeal {
                // TODO: Implement real meal cancellation logic
                print("Cancelling analyzing meal: \(analyzingMeal.id)")
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick clarification")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("A few details for accuracy")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var progressIndicator: some View {
        // Smooth capsule progress; use white accent per design
        GeometryReader { geo in
            let progress = CGFloat(max(1, currentQuestionIndex + 1)) / CGFloat(max(1, questions.count))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var questionSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                Image(systemName: iconForQuestion(currentQuestion.question))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(currentQuestion.question)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                Text("Choose the closest option")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            // Submit button
            Button(action: submitAnswer) {
                Text("Submit Answer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(selectedOptions[currentQuestion.id] != nil ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedOptions[currentQuestion.id] != nil ? Color(hex: "15E065").opacity(0.08) : Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedOptions[currentQuestion.id] != nil ? Color(hex: "15E065").opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .disabled(selectedOptions[currentQuestion.id] == nil)
            
            // Skip button
            Button(action: skipQuestion) {
                Text("I don't know")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func submitAnswer() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            completeClarification()
        }
    }
    
    private func skipQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            completeClarification()
        }
    }
    
    private func completeClarification() {
        // Store clarification answers in the manager
        clarificationManager.clarificationAnswers = Dictionary(
            uniqueKeysWithValues: selectedOptions.map { (String($0.key), $0.value) }
        )
        
        // Use the passed meal result or create a new one
        let finalMeal = mealResult ?? createMockMeal()
        
        // Mark as completed to prevent cleanup on dismiss
        isCompleted = true
        
        // Call the completion handler
        onComplete?(finalMeal)
        
        // Dismiss the view
        dismiss()
    }
    
    private func createMockMeal() -> LoggedMeal {
        // Create a mock meal based on the selected options
        // TODO: Get actual active window from real data source
        let activeWindow: MealWindow? = nil
        
        // Generate micronutrients based on window purpose
        var micronutrients: [String: Double] = [:]
        if let windowPurpose = activeWindow?.purpose {
            // Mock micronutrient values based on window purpose
            switch windowPurpose {
            case .sustainedEnergy:
                micronutrients["B12"] = 0.6
                micronutrients["Iron"] = 3.5
                micronutrients["Magnesium"] = 85.0
            case .focusBoost:
                micronutrients["Omega-3"] = 0.35
                micronutrients["B6"] = 0.3
                micronutrients["Vitamin D"] = 140.0
            case .recovery:
                micronutrients["Vitamin C"] = 25.0
                micronutrients["Zinc"] = 2.5
                micronutrients["Potassium"] = 600.0
            case .preworkout:
                micronutrients["B-Complex"] = 11.5
                micronutrients["Caffeine"] = 70.0
                micronutrients["L-Arginine"] = 1.2
            case .postworkout:
                micronutrients["Protein"] = 11.5
                micronutrients["Leucine"] = 0.6
                micronutrients["Magnesium"] = 85.0
            case .metabolicBoost:
                micronutrients["Green Tea"] = 45.0
                micronutrients["Chromium"] = 7.5
                micronutrients["L-Carnitine"] = 0.45
            case .sleepOptimization:
                micronutrients["Magnesium"] = 80.0
                micronutrients["Tryptophan"] = 60.0
                micronutrients["B6"] = 0.3
            }
        }
        
        // Generate generic ingredients for the custom meal
        let ingredients = [
            MealIngredient(name: "Lean Protein", quantity: 4, unit: "oz", foodGroup: .protein, calories: 140, protein: 25.0, carbs: 0.0, fat: 3.0),
            MealIngredient(name: "Mixed Vegetables", quantity: 1.5, unit: "cups", foodGroup: .vegetable, calories: 40, protein: 2.0, carbs: 8.0, fat: 0.5),
            MealIngredient(name: "Brown Rice", quantity: 0.5, unit: "cup", foodGroup: .grain, calories: 110, protein: 2.5, carbs: 23.0, fat: 1.0),
            MealIngredient(name: "Olive Oil", quantity: 1, unit: "tbsp", foodGroup: .fat, calories: 120, protein: 0.0, carbs: 0.0, fat: 14.0),
            MealIngredient(name: "Seasoning Blend", quantity: 1, unit: "tsp", foodGroup: .other, calories: 5, protein: 0.2, carbs: 1.0, fat: 0.1)
        ]
        
        var meal = LoggedMeal(
            name: "Custom Prepared Meal",
            calories: 450,
            protein: 25,
            carbs: 45,
            fat: 18,
            timestamp: Date(),
            windowId: activeWindow?.id
        )
        meal.micronutrients = micronutrients
        meal.ingredients = ingredients
        return meal
    }
}

struct ClarificationQuestion {
    let id: Int
    let question: String
    let options: [ClarificationOption]
}

struct ClarificationOption: Identifiable {
    let id: String
    let text: String
    let icon: String
    let calorieImpact: Int
    var proteinImpact: Int = 0
    var carbImpact: Int = 0
    var fatImpact: Int = 0
    let isRecommended: Bool
    var note: String? = nil
}

struct OptionRow: View {
    let option: ClarificationOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)
                    Image(systemName: option.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.8))
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(option.text)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if option.isRecommended {
                            Text("Recommended")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.phylloAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.phylloAccent.opacity(0.15)))
                        } else if let note = option.note {
                            Text(note)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                    }
                    // Impact row
                    HStack(spacing: 14) {
                        Group {
                            if option.calorieImpact == 0 {
                                Label("+0 cal", systemImage: "checkmark")
                                    .labelStyle(.titleAndIcon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: option.calorieImpact > 0 ? "plus" : "minus")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("\(abs(option.calorieImpact)) cal")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(option.calorieImpact > 80 ? .red : .orange)
                            }
                        }
                        if option.proteinImpact > 0 {
                            Text("+ \(option.proteinImpact) g P")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        if option.carbImpact > 0 {
                            Text("+ \(option.carbImpact) g C")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        if option.fatImpact > 0 {
                            Text("+ \(option.fatImpact) g F")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ClarificationQuestionsView()
}
