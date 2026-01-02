//
//  WindowFoodsList.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowFoodsList: View {
    let window: MealWindow
    @Binding var selectedMealId: String?
    @ObservedObject var viewModel: ScheduleViewModel
    
    // Filter meals for this window
    private var windowMeals: [LoggedMeal] {
        viewModel.mealsInWindow(window)
    }
    
    // Check if there's an analyzing meal for this window
    private var analyzingMeal: AnalyzingMeal? {
        viewModel.analyzingMealsInWindow(window).first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Logged Foods")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("(\(windowMeals.count))")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                
                Spacer()
                
                Button {
                    // Navigate to scan/add food
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.nutriSyncAccent)
                }
            }
            
            if windowMeals.isEmpty && analyzingMeal == nil {
                // Empty state
                EmptyFoodsView()
            } else {
                // Food items
                VStack(spacing: 12) {
                    // Show analyzing meal if present
                    if let analyzing = analyzingMeal {
                        AnalyzingMealCard(timestamp: analyzing.timestamp, metadata: nil, window: window)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Show logged meals
                    ForEach(windowMeals) { meal in
                        FoodItemCard(meal: meal, isSelected: selectedMealId == meal.id.uuidString)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: windowMeals.count)
                            .onAppear {
                                // Auto-open meal analysis if this is the selected meal
                                if selectedMealId == meal.id.uuidString {
                                    // Clear the selection after showing analysis
                                    selectedMealId = nil
                                }
                            }
                    }
                }
            }
        }
    }
}

struct FoodItemCard: View {
    let meal: LoggedMeal
    let isSelected: Bool
    @State private var showFoodAnalysis = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: {
                showFoodAnalysis = true
            }) {
                HStack(spacing: 16) {
                    // Emoji
                    Text(meal.emoji)
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(TimelineTypography.foodName)
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text("\(meal.calories) cal")
                                .font(TimelineTypography.foodCalories)
                                .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .layoutPriority(1)

                            Text("•")
                                .foregroundColor(.white.opacity(TimelineOpacity.quaternary))

                            Text(timeString(from: meal.timestamp))
                                .font(TimelineTypography.timestamp)
                                .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                                .lineLimit(1)
                        }

                        Text(meal.macroSummary)
                            .font(TimelineTypography.macroLabel)
                            .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                    }

                    Spacer()

                    // Health score (1-10 format)
                    if let healthScore = meal.healthScore {
                        ScoreText(score: healthScore.displayScore, size: .small)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable ingredients section
            if !meal.ingredients.isEmpty {
                VStack(spacing: 0) {
                    // Separator line
                    Rectangle()
                        .fill(Color.nutriSyncBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    // Expand/collapse button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("View ingredients")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.nutriSyncTabInactive)
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.nutriSyncTabInactive)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Ingredients list
                    if isExpanded {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(meal.ingredients) { ingredient in
                                    IngredientChip(ingredient: ingredient)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
        .sheet(isPresented: $showFoodAnalysis) {
            NavigationStack {
                FoodAnalysisView(meal: meal)
            }
        }
        .onAppear {
            if isSelected {
                // Auto-open the food analysis view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showFoodAnalysis = true
                }
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyFoodsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No meals logged yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
            
            Text("Tap + to add your first meal")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(TimelineOpacity.quaternary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nutriSyncBorder.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

struct IngredientChip: View {
    let ingredient: MealIngredient
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ingredient.foodGroup.color.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(ingredient.displayString)
                .font(TimelineTypography.macroLabel)
                .foregroundColor(.white.opacity(TimelineOpacity.secondary))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(ingredient.foodGroup.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(ingredient.foodGroup.color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        if let window = viewModel.mealWindows.first {
            WindowFoodsList(
                window: window,
                selectedMealId: .constant(nil),
                viewModel: viewModel
            )
            .padding()
        }
    }
}