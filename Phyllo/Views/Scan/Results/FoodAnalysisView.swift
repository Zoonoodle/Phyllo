//
//  FoodAnalysisView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct FoodAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEditView = false
    @State private var confidenceAnimation = false
    @StateObject private var mockData = MockDataManager.shared
    
    let meal: LoggedMeal
    var isFromScan: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Food image
                        foodImageSection
                        
                        // Food name and confidence
                        foodInfoSection
                        
                        // Nutrition overview
                        nutritionOverviewSection
                        
                        // Daily summary (if from scan)
                        if isFromScan {
                            dailySummarySection
                        }
                        
                        // Detailed nutrition
                        detailedNutritionSection
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Analysis Results")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showEditView) {
            MealDetailsEditView(meal: meal)
        }
    }
    
    // MARK: - Sections
    
    private var foodImageSection: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.05))
            .frame(height: 250)
            .overlay(
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Food image preview")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            )
            .overlay(
                // Confidence badge
                VStack {
                    HStack {
                        Spacer()
                        if isFromScan {
                            confidenceBadge
                        }
                    }
                    Spacer()
                }
                .padding(16)
            )
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text("94% Confident")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(confidenceAnimation ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                confidenceAnimation = true
            }
        }
    }
    
    private var foodInfoSection: some View {
        VStack(spacing: 8) {
            Text(meal.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            if let window = mealWindow {
                Text("\(windowName(for: window)) • \(timeString(from: meal.timestamp))")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text(timeString(from: meal.timestamp))
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var nutritionOverviewSection: some View {
        VStack(spacing: 16) {
            // Calories
            HStack {
                Text("\(meal.calories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("calories")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: 8)
            }
            
            // Macros
            HStack(spacing: 24) {
                MacroView(value: meal.protein, label: "Protein", color: .blue)
                MacroView(value: meal.carbs, label: "Carbs", color: .orange)
                MacroView(value: meal.fat, label: "Fat", color: .yellow)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private var detailedNutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Nutrition")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NutritionRow(label: "Dietary Fiber", value: "8g", color: .green)
                NutritionRow(label: "Sugars", value: "3g", color: .pink)
                NutritionRow(label: "Sodium", value: "320mg", color: .cyan)
                NutritionRow(label: "Cholesterol", value: "85mg", color: .orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Edit details button
            Button(action: { showEditView = true }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Edit Details")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Confirm button or View in Timeline
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: isFromScan ? "checkmark.circle.fill" : "timeline")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isFromScan ? "Confirm & Log" : "View in Timeline")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            }
        }
    }
    
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Daily Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(mockData.todaysMeals.count) meals logged")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Progress ring and macros
            HStack(spacing: 32) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: dailyProgress)
                        .stroke(
                            Color.phylloAccent,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(dailyProgress * 100))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("Complete")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Daily macros
                VStack(alignment: .leading, spacing: 12) {
                    DailyMacroRow(
                        label: "Protein",
                        consumed: mockData.todaysProteinConsumed,
                        target: userDailyProtein,
                        color: .blue
                    )
                    DailyMacroRow(
                        label: "Carbs",
                        consumed: mockData.todaysCarbsConsumed,
                        target: userDailyCarbs,
                        color: .orange
                    )
                    DailyMacroRow(
                        label: "Fat",
                        consumed: mockData.todaysFatConsumed,
                        target: userDailyFat,
                        color: .yellow
                    )
                }
                .frame(maxWidth: .infinity)
            }
            
            // Remaining calories
            Text("\(mockData.todaysCaloriesConsumed) / \(userDailyCalories) calories")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Properties
    
    private var mealWindow: MealWindow? {
        guard let windowId = meal.windowId else { return nil }
        return mockData.mealWindows.first { $0.id == windowId }
    }
    
    private var dailyProgress: Double {
        Double(mockData.todaysCaloriesConsumed) / Double(userDailyCalories)
    }
    
    private var userDailyCalories: Int {
        2500 // TODO: Get from user profile
    }
    
    private var userDailyProtein: Int {
        150 // TODO: Get from user profile
    }
    
    private var userDailyCarbs: Int {
        280 // TODO: Get from user profile
    }
    
    private var userDailyFat: Int {
        83 // TODO: Get from user profile
    }
    
    // MARK: - Helper Methods
    
    private func windowName(for window: MealWindow) -> String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...14: return "Lunch"
        case 15...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Late Snack"
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DailyMacroRow: View {
    let label: String
    let consumed: Int
    let target: Int
    let color: Color
    
    var progress: Double {
        Double(consumed) / Double(target)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1), height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(consumed)g")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 35, alignment: .trailing)
        }
    }
}

struct MacroView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview("From Timeline") {
    FoodAnalysisView(
        meal: LoggedMeal(
            name: "Grilled Chicken Salad",
            calories: 420,
            protein: 35,
            carbs: 12,
            fat: 28,
            timestamp: Date()
        ),
        isFromScan: false
    )
}

#Preview("From Scan") {
    FoodAnalysisView(
        meal: LoggedMeal(
            name: "Grilled Chicken Salad",
            calories: 420,
            protein: 35,
            carbs: 12,
            fat: 28,
            timestamp: Date()
        ),
        isFromScan: true
    )
}