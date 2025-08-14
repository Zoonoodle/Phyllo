//
//  MissedMealsRecoveryView.swift
//  NutriSync
//
//  Created on 8/12/25.
//

import SwiftUI

struct MissedMealsRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ScheduleViewModel
    
    @State private var mealDescription = ""
    @State private var isProcessing = false
    @State private var showVoiceInput = false
    @State private var selectedQuickOptions: Set<String> = []
    
    let missedWindows: [MealWindow]
    
    // Quick meal options for easy selection
    let quickMealOptions = [
        "🥣 Breakfast/Cereal",
        "🥚 Eggs & Toast",
        "🥗 Salad",
        "🥪 Sandwich",
        "🍕 Pizza",
        "🍝 Pasta",
        "🍗 Chicken & Rice",
        "🥤 Protein Shake",
        "🍎 Fruit/Snacks"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header with context
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.nutriSyncAccent)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Catch Up on Today's Meals")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("You've missed \(missedWindows.count) meal windows. Let's quickly log what you've eaten today.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Quick options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Add (tap multiple):")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(quickMealOptions, id: \.self) { option in
                                QuickMealOptionButton(
                                    option: option,
                                    isSelected: selectedQuickOptions.contains(option),
                                    action: {
                                        if selectedQuickOptions.contains(option) {
                                            selectedQuickOptions.remove(option)
                                        } else {
                                            selectedQuickOptions.insert(option)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Text input area
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or describe your meals:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            TextField("e.g., Had eggs for breakfast, sandwich for lunch...", text: $mealDescription, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .lineLimit(3...6)
                            
                            Button(action: { showVoiceInput = true }) {
                                Image(systemName: "mic.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.nutriSyncAccent)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: processMeals) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Log Meals")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.nutriSyncAccent)
                            .foregroundColor(.black)
                            .cornerRadius(26)
                        }
                        .disabled(isProcessing || (mealDescription.isEmpty && selectedQuickOptions.isEmpty))
                        
                        Button(action: {
                            // Mark as intentional fasting
                            viewModel.markWindowsAsFasted(missedWindows)
                            dismiss()
                        }) {
                            Text("I was fasting")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showVoiceInput) {
            // Voice input modal would go here
            Text("Voice Input (To Be Implemented)")
        }
    }
    
    private func processMeals() {
        isProcessing = true
        
        // Combine quick options with text description
        let quickMealsText = selectedQuickOptions.joined(separator: ", ")
        let fullDescription = [quickMealsText, mealDescription]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
        
        Task {
            // Process with AI to distribute meals
            await viewModel.processRetrospectiveMeals(
                description: fullDescription,
                missedWindows: missedWindows
            )
            
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }
}

struct QuickMealOptionButton: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.clear : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    // Create some mock missed windows for preview
    let mockWindows = [
        MealWindow(
            startTime: Date().addingTimeInterval(-7200), // 2 hours ago
            endTime: Date().addingTimeInterval(-3600),   // 1 hour ago
            targetCalories: 400,
            targetMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
            purpose: .metabolicBoost,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        ),
        MealWindow(
            startTime: Date().addingTimeInterval(-14400), // 4 hours ago
            endTime: Date().addingTimeInterval(-10800),   // 3 hours ago
            targetCalories: 500,
            targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 20),
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        )
    ]
    
    return MissedMealsRecoveryView(
        viewModel: ScheduleViewModel(),
        missedWindows: mockWindows
    )
}