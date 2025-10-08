//
//  AlreadyEatenView.swift
//  NutriSync
//
//  Quick meal logging for already consumed food
//

import SwiftUI
import PhotosUI

struct AlreadyEatenView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var showAddMeal = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= 0 ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("Have you eaten today?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Quick log any meals you've already had")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Quick options
            if viewModel.alreadyEatenMeals.isEmpty {
                VStack(spacing: 12) {
                    Button(action: { 
                        viewModel.nextScreen() 
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                            Text("Haven't eaten yet")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showAddMeal = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add a meal")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nutriSyncAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncAccent.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            
            // Listed meals
            if !viewModel.alreadyEatenMeals.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.alreadyEatenMeals) { meal in
                            QuickMealRow(meal: meal) {
                                viewModel.alreadyEatenMeals.removeAll { $0.id == meal.id }
                            }
                        }
                        
                        // Add another button
                        Button(action: { showAddMeal = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16))
                                Text("Add another")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.nutriSyncAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 300)
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button(action: { viewModel.previousScreen() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                }
                
                Button(action: { viewModel.nextScreen() }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncAccent)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .fullScreenCover(isPresented: $showAddMeal) {
            QuickVoiceAddView { mealDescription in
                // Create a simple meal entry from the voice description
                let meal = QuickMeal(
                    name: mealDescription,
                    time: Date(),
                    estimatedCalories: nil // AI will handle this
                )
                viewModel.alreadyEatenMeals.append(meal)
            }
        }
    }
}

// MARK: - Quick Meal Row
struct QuickMealRow: View {
    let meal: QuickMeal
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Text(meal.time, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let calories = meal.estimatedCalories {
                        Text("\(calories) cal")
                            .font(.system(size: 12))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Quick Meal Entry
struct QuickMealEntry: View {
    @Binding var mealName: String
    @Binding var mealTime: Date
    @Binding var estimatedCalories: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    
    // Common meal suggestions
    let suggestions = [
        "Breakfast",
        "Coffee & Pastry",
        "Protein Shake",
        "Salad",
        "Sandwich",
        "Snack"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: { mealName = suggestion }) {
                                    Text(suggestion)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(mealName == suggestion ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            mealName == suggestion ? 
                                            Color.nutriSyncAccent : Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 16) {
                        // Meal name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What did you eat?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("e.g. Chicken salad", text: $mealName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .focused($isNameFocused)
                        }
                        
                        // Time picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            DatePicker("", selection: $mealTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        // Optional calories
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated calories (optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("e.g. 450", text: $estimatedCalories)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: onSave) {
                        Text("Add Meal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .disabled(mealName.isEmpty)
                    .opacity(mealName.isEmpty ? 0.5 : 1)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Quick Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }
}