//
//  WindowFoodsList.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowFoodsList: View {
    let window: MealWindow
    @StateObject private var mockData = MockDataManager.shared
    
    // Filter meals for this window
    private var windowMeals: [LoggedMeal] {
        mockData.todaysMeals.filter { meal in
            // Check if meal was logged during this window
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
    
    // Check if there's an analyzing meal for this window
    private var analyzingMeal: AnalyzingMeal? {
        mockData.analyzingMealInWindow(window)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Logged Foods")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("(\(windowMeals.count))")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button {
                    // Navigate to scan/add food
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.phylloAccent)
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
                        AnalyzingMealCard(timestamp: analyzing.timestamp)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Show logged meals
                    ForEach(windowMeals) { meal in
                        FoodItemCard(meal: meal)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: windowMeals.count)
                    }
                }
            }
        }
    }
}

struct FoodItemCard: View {
    let meal: LoggedMeal
    @State private var showFoodAnalysis = false
    
    var body: some View {
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(meal.calories) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(timeString(from: meal.timestamp))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Text(meal.macroSummary)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.phylloBorder, lineWidth: 1)
                    )
            )
        }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showFoodAnalysis) {
            NavigationStack {
                FoodAnalysisView(meal: meal)
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Tap + to add your first meal")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.phylloBorder.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        WindowFoodsList(window: MockDataManager.shared.mealWindows[0])
            .padding()
    }
    .onAppear {
        MockDataManager.shared.completeMorningCheckIn()
        MockDataManager.shared.simulateTime(hour: 12)
        MockDataManager.shared.addMockMeal()
        MockDataManager.shared.addMockMeal()
    }
}