//
//  FoodAnalysisView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI
import UIKit

enum FoodAnalysisTab: String, CaseIterable {
    case nutrition = "Nutrition"
    case ingredients = "Ingredients"
    case insights = "Insights"
}

struct FoodAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEditView = false
    @State private var confidenceAnimation = false
    @State private var selectedTab: FoodAnalysisTab = .nutrition
    
    let meal: LoggedMeal
    var isFromScan: Bool = false
    var onConfirm: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Food header section (always visible)
                    VStack(spacing: 16) {
                        foodImageSection
                        foodInfoSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Tab content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch selectedTab {
                            case .nutrition:
                                nutritionTabContent
                            case .ingredients:
                                ingredientsTabContent
                            case .insights:
                                insightsTabContent
                            }
                            
                            // Action buttons (always at bottom)
                            actionButtonsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
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
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(FoodAnalysisTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? Color.phylloTabActive : Color.phylloTabInactive)
                        
                        // Underline indicator
                        Rectangle()
                            .fill(selectedTab == tab ? Color.phylloTabActive : Color.clear)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.phylloSecondaryBackground)
        )
    }
    
    // MARK: - Tab Content
    
    private var nutritionTabContent: some View {
        VStack(spacing: 24) {
            nutritionOverviewSection
            
            if isFromScan {
                dailySummarySection
            }
            
            detailedNutritionSection
        }
    }
    
    private var ingredientsTabContent: some View {
        VStack(spacing: 24) {
            ingredientsListSection
            ingredientNutritionBreakdown
        }
    }
    
    private var insightsTabContent: some View {
        VStack(spacing: 24) {
            if let window = mealWindow {
                windowMicronutrientSection(for: window)
            }
            
            mealInsightsSection
        }
    }
    
    // MARK: - Sections
    
    private var foodImageSection: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.phylloElevated)
            .frame(height: 200)
            .overlay(
                Group {
                    if let imageData = meal.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(20)
                    } else {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                            Text("Food image preview")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
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
                .foregroundColor(.phylloAccent)
            
            Text("94% Confident")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.phylloElevated)
                .overlay(
                    Capsule()
                        .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
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
                .fill(Color.phylloElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.phylloBorder, lineWidth: 1)
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
                    .fill(Color.phylloElevated)
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
                        .fill(Color.phylloElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.phylloBorder, lineWidth: 1)
                        )
                )
            }
            
            // Confirm button or View in Timeline
            Button(action: {
                if isFromScan {
                    onConfirm?()
                }
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
                Text("3 meals logged") // TODO: Get from real data source
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
                        consumed: 85, // TODO: Get from real data source
                        target: userDailyProtein,
                        color: .blue
                    )
                    DailyMacroRow(
                        label: "Carbs",
                        consumed: 180, // TODO: Get from real data source
                        target: userDailyCarbs,
                        color: .orange
                    )
                    DailyMacroRow(
                        label: "Fat",
                        consumed: 45, // TODO: Get from real data source
                        target: userDailyFat,
                        color: .yellow
                    )
                }
                .frame(maxWidth: .infinity)
            }
            
            // Remaining calories
            Text("1850 / \(userDailyCalories) calories") // TODO: Get from real data source
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.phylloElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.phylloBorder, lineWidth: 1)
                )
        )
    }
    
    // Window-specific micronutrient section
    private func windowMicronutrientSection(for window: MealWindow) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Window Micronutrients")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Window purpose badge
                Text(windowPurposeDisplayName(window.purpose))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.phylloAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.phylloAccent.opacity(0.15))
                    )
            }
            
            // Get micronutrients for this window purpose
            let windowMicronutrients = getWindowMicronutrients(for: window.purpose)
            
            VStack(spacing: 16) {
                ForEach(windowMicronutrients, id: \.info.name) { nutrient in
                    WindowMicronutrientRow(
                        micronutrient: nutrient,
                        mealContribution: getMealContribution(for: nutrient.info.name)
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.phylloElevated)
            )
        }
    }
    
    // MARK: - Helper Properties
    
    private var mealWindow: MealWindow? {
        guard let windowId = meal.windowId else { return nil }
        // TODO: Get from real data source
        return nil
    }
    
    private var dailyProgress: Double {
        // TODO: Get from real data source
        Double(1850) / Double(userDailyCalories)
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
    
    private func getWindowMicronutrients(for purpose: WindowPurpose) -> [MicronutrientConsumption] {
        // TODO: Get micronutrients from real data source for this window purpose
        return []
    }
    
    private func getMealContribution(for nutrientName: String) -> Double {
        // Get the meal's contribution to this micronutrient
        return meal.micronutrients[nutrientName] ?? 0.0
    }
    
    private func windowPurposeDisplayName(_ purpose: WindowPurpose) -> String {
        switch purpose {
        case .sustainedEnergy: return "Sustained Energy"
        case .focusBoost: return "Focus Boost"
        case .recovery: return "Recovery"
        case .preworkout: return "Pre-Workout"
        case .postworkout: return "Post-Workout"
        case .metabolicBoost: return "Metabolic Boost"
        case .sleepOptimization: return "Sleep Optimization"
        }
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

struct WindowMicronutrientRow: View {
    let micronutrient: MicronutrientConsumption
    let mealContribution: Double
    
    private var mealPercentage: Double {
        mealContribution / micronutrient.info.dailyTarget
    }
    
    private var progressColor: Color {
        switch micronutrient.percentage {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return Color.phylloAccent
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name and icon
            HStack {
                Text("\(micronutrient.info.icon) \(micronutrient.info.name)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Meal contribution
                Text("+\(String(format: "%.1f", mealContribution))\(micronutrient.info.unit.rawValue)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.phylloAccent)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    // Total progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor.opacity(0.5))
                        .frame(width: geometry.size.width * CGFloat(min(micronutrient.percentage, 1)), height: 6)
                    
                    // Meal contribution overlay
                    if mealContribution > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.phylloAccent)
                            .frame(
                                width: geometry.size.width * CGFloat(min(mealPercentage, 1)),
                                height: 6
                            )
                            .offset(x: geometry.size.width * CGFloat(min(micronutrient.percentage - mealPercentage, 1)))
                    }
                }
            }
            .frame(height: 6)
            
            // Values and percentage
            HStack {
                Text(micronutrient.displayString)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(Int(micronutrient.percentage * 100))% of daily target")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - New Sections for Tabs

extension FoodAnalysisView {
    private var ingredientsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(meal.ingredients) { ingredient in
                    FoodIngredientRow(ingredient: ingredient)
                }
            }
        }
    }
    
    private var ingredientNutritionBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition by Ingredient")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(meal.ingredients.filter { $0.calories != nil }) { ingredient in
                        IngredientNutritionCard(ingredient: ingredient)
                    }
                }
            }
        }
    }
    
    private var mealInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InsightRow(icon: "lightbulb.fill", text: "This meal provides \(Int(Double(meal.protein) / Double(userDailyProtein) * 100))% of your daily protein needs", color: .blue)
                
                if meal.calories < 400 {
                    InsightRow(icon: "leaf.fill", text: "Light meal - perfect for maintaining energy without feeling heavy", color: .green)
                }
                
                if let window = mealWindow {
                    InsightRow(icon: "clock.fill", text: "Optimally timed for \(windowPurposeInsight(window.purpose))", color: .orange)
                }
                
                if meal.ingredients.filter({ $0.foodGroup == .vegetable }).count >= 3 {
                    InsightRow(icon: "star.fill", text: "Excellent vegetable variety for micronutrient diversity", color: .yellow)
                }
            }
        }
    }
    
    private func windowPurposeInsight(_ purpose: WindowPurpose) -> String {
        switch purpose {
        case .sustainedEnergy: return "sustained energy throughout your day"
        case .focusBoost: return "enhanced mental clarity and focus"
        case .recovery: return "optimal muscle recovery and repair"
        case .preworkout: return "fueling your upcoming workout"
        case .postworkout: return "maximizing post-workout recovery"
        case .metabolicBoost: return "supporting your metabolic rate"
        case .sleepOptimization: return "promoting restful sleep"
        }
    }
}

// MARK: - Supporting Views

struct FoodIngredientRow: View {
    let ingredient: MealIngredient
    
    var body: some View {
        HStack(spacing: 12) {
            // Color-coded circle
            Circle()
                .fill(ingredient.foodGroup.color.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Ingredient chip
            HStack(spacing: 6) {
                Text(ingredient.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(ingredient.displayString.replacingOccurrences(of: ingredient.name + " ", with: ""))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(ingredient.foodGroup.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(ingredient.foodGroup.color.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
    }
}

struct IngredientNutritionCard: View {
    let ingredient: MealIngredient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ingredient.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let calories = ingredient.calories {
                Text("\(calories) cal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ingredient.foodGroup.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let protein = ingredient.protein {
                    MacroMiniRow(label: "P", value: protein, color: .blue)
                }
                if let carbs = ingredient.carbs {
                    MacroMiniRow(label: "C", value: carbs, color: .orange)
                }
                if let fat = ingredient.fat {
                    MacroMiniRow(label: "F", value: fat, color: .yellow)
                }
            }
        }
        .padding(12)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.phylloElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.phylloBorder, lineWidth: 1)
                )
        )
    }
}

struct MacroMiniRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(color.opacity(0.8))
                .frame(width: 12)
            
            Text(String(format: "%.1fg", value))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.phylloElevated)
        )
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
