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
    @StateObject private var mockData = MockDataManager.shared
    
    var analyzingMeal: AnalyzingMeal?
    var mealResult: LoggedMeal?
    var onComplete: ((LoggedMeal) -> Void)?
    
    // Mock questions
    let questions = [
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
        )
    ]
    
    var currentQuestion: ClarificationQuestion {
        questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Progress dots
                    progressIndicator
                        .padding(.top, 20)
                    
                    // Question section
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question header
                            questionHeader
                            
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
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            Text("Fine-Tune Your Nutrition")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Done") {
                showResults = true
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<questions.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentQuestionIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var questionHeader: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Title
            Text("Quick clarification")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Subtitle
            Text("A few details for accuracy")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
            
            // Question
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "questionmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(currentQuestion.question)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            // Submit button
            Button(action: submitAnswer) {
                Text("Submit Answer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedOptions[currentQuestion.id] != nil ? Color.white : Color.white.opacity(0.3))
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
        // Use the passed meal result or create a new one
        let finalMeal = mealResult ?? createMockMeal()
        
        // Call the completion handler
        onComplete?(finalMeal)
        
        // Dismiss the view
        dismiss()
    }
    
    private func createMockMeal() -> LoggedMeal {
        // Create a mock meal based on the selected options
        return LoggedMeal(
            name: "Custom Prepared Meal",
            calories: 450,
            protein: 25,
            carbs: 45,
            fat: 18,
            timestamp: Date(),
            windowId: mockData.activeWindow?.id
        )
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
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(option.text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .black : .white)
                        
                        if let note = option.note {
                            Text(note)
                                .font(.system(size: 13))
                                .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                                )
                        }
                    }
                    
                    // Impact indicators
                    HStack(spacing: 16) {
                        // Calories
                        if option.calorieImpact != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: option.calorieImpact > 0 ? "plus" : "minus")
                                    .font(.system(size: 11, weight: .medium))
                                Text("\(abs(option.calorieImpact)) cal")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(option.calorieImpact > 50 ? .red : (isSelected ? .black.opacity(0.7) : .white.opacity(0.5)))
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .medium))
                                Text("+0 calories")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.green)
                        }
                        
                        // Macros
                        if option.proteinImpact > 0 {
                            Text("+ \(option.proteinImpact) g P")
                                .font(.system(size: 13))
                                .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.5))
                        }
                        
                        if option.carbImpact > 0 {
                            Text("+ \(option.carbImpact) g C")
                                .font(.system(size: 13))
                                .foregroundColor(option.carbImpact > 20 ? .orange : (isSelected ? .black.opacity(0.7) : .white.opacity(0.5)))
                        }
                        
                        if option.fatImpact > 0 {
                            Text("+ \(option.fatImpact) g F")
                                .font(.system(size: 13))
                                .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.5))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ClarificationQuestionsView()
}