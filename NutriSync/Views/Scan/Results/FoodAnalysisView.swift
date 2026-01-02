//
//  FoodAnalysisView.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI
import UIKit

enum FoodAnalysisTab: String, CaseIterable {
    case nutrition = "Nutrition"
    case ingredients = "Ingredients"
}

enum NutrientCategory: String, CaseIterable {
    case carbBreakdown = "Carb Breakdown"
    case fatBreakdown = "Fat Breakdown"
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case other = "Other"

    static func category(for nutrientName: String) -> NutrientCategory {
        let name = nutrientName.lowercased()

        // Carb Breakdown
        if name.contains("carb") || name.contains("fiber") || name.contains("starch") ||
           name.contains("sugar") || name == "net carbs" {
            return .carbBreakdown
        }

        // Fat Breakdown
        if name.contains("fat") || name.contains("saturated") || name.contains("trans") ||
           name.contains("monounsaturated") || name.contains("polyunsaturated") ||
           name.contains("cholesterol") {
            return .fatBreakdown
        }

        // Vitamins
        if name.contains("vitamin") || name.contains("thiamin") || name.contains("riboflavin") ||
           name.contains("niacin") || name.contains("folate") || name.contains("b1") ||
           name.contains("b2") || name.contains("b3") || name.contains("b6") || name.contains("b12") {
            return .vitamins
        }

        // Minerals
        if name.contains("calcium") || name.contains("iron") || name.contains("magnesium") ||
           name.contains("phosphorus") || name.contains("potassium") || name.contains("sodium") ||
           name.contains("zinc") || name.contains("copper") || name.contains("manganese") ||
           name.contains("selenium") {
            return .minerals
        }

        return .other
    }
}

enum NutrientStatus {
    case low       // < 50%
    case adequate  // 50-100%
    case high      // > 100%

    var color: Color {
        switch self {
        case .low: return .orange
        case .adequate: return .green
        case .high: return .red
        }
    }

    static func status(percentage: Double, isAntiNutrient: Bool = false) -> NutrientStatus {
        if isAntiNutrient {
            // For anti-nutrients, high is bad
            if percentage > 1.0 { return .high }
            if percentage > 0.7 { return .adequate }
            return .low
        } else {
            // For good nutrients, higher is better until 100%
            if percentage < 0.5 { return .low }
            if percentage <= 1.0 { return .adequate }
            return .high
        }
    }
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
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Food header section (always visible)
                    VStack(spacing: 16) {
                        if meal.imageData != nil {
                            foodImageSection
                        }
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
                            .foregroundColor(selectedTab == tab ? Color.nutriSyncTabActive : Color.nutriSyncTabInactive)
                        
                        // Underline indicator
                        Rectangle()
                            .fill(selectedTab == tab ? Color.nutriSyncTabActive : Color.clear)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nutriSyncSecondaryBackground)
        )
    }
    
    // MARK: - Tab Content
    
    private var nutritionTabContent: some View {
        VStack(spacing: 24) {
            nutritionOverviewSection

            mealScoreSection

            dailyImpactSection

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
    
    
    // MARK: - Sections
    
    @ViewBuilder
    private var foodImageSection: some View {
        if let imageData = meal.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(20)
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
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.nutriSyncAccent)
            
            Text("94% Confident")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.nutriSyncElevated)
                .overlay(
                    Capsule()
                        .stroke(Color.nutriSyncAccent.opacity(0.3), lineWidth: 1)
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)

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
                .fill(Color.nutriSyncElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Meal Score Section

    @State private var showScoreBreakdown = false

    private var mealScoreSection: some View {
        Group {
            if let healthScore = meal.healthScore {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    Text("MEAL SCORE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(0.5)

                    // Score display
                    VStack(alignment: .leading, spacing: 8) {
                        ScoreText(score: healthScore.displayScore, size: .medium, showTotal: true)
                        ScoreProgressBar.fromInternal(healthScore.score)
                    }

                    // Contributing factors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONTRIBUTING FACTORS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .tracking(0.5)

                        FactorChipGrid(factors: healthScoreFactors)
                    }

                    // Expandable breakdown
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showScoreBreakdown.toggle()
                        }
                    }) {
                        HStack {
                            Text("See full breakdown")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            Image(systemName: showScoreBreakdown ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 8)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Expanded breakdown
                    if showScoreBreakdown {
                        scoreBreakdownView(healthScore: healthScore)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.nutriSyncElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.nutriSyncBorder, lineWidth: 1)
                        )
                )
            }
        }
    }

    // Generate factor chips from health score
    private var healthScoreFactors: [FactorChipData] {
        guard let healthScore = meal.healthScore else { return [] }

        // If we have detailed breakdown, use it
        if let breakdown = healthScore.breakdown {
            return [
                FactorChipData(label: "Macro balance", value: breakdown.macroBalance.subtotal),
                FactorChipData(label: "Food quality", value: breakdown.foodQuality.subtotal),
                FactorChipData(label: "Protein efficiency", value: breakdown.proteinEfficiency.subtotal),
                FactorChipData(label: "Micronutrients", value: breakdown.micronutrients.subtotal)
            ]
        }

        // Fallback: Generate factors from existing data
        var factors: [FactorChipData] = []

        // Protein factor - based on protein per 100 cal
        let proteinPer100Cal = meal.calories > 0 ? Double(meal.protein) / Double(meal.calories) * 100 : 0
        let proteinScore = min(proteinPer100Cal / 7.0, 2.0) - 1.0  // Target: 7g protein per 100 cal
        factors.append(FactorChipData(label: "Protein balance", value: proteinScore))

        // Macro balance - based on P/C/F ratio
        let totalMacroGrams = Double(meal.protein + meal.carbs + meal.fat)
        if totalMacroGrams > 0 {
            let proteinRatio = Double(meal.protein) / totalMacroGrams
            let carbRatio = Double(meal.carbs) / totalMacroGrams
            let fatRatio = Double(meal.fat) / totalMacroGrams

            // Ideal: ~30% protein, 40% carbs, 30% fat (by grams, not calories)
            let proteinDev = abs(proteinRatio - 0.30)
            let carbDev = abs(carbRatio - 0.40)
            let fatDev = abs(fatRatio - 0.30)
            let avgDev = (proteinDev + carbDev + fatDev) / 3.0
            let balanceScore = (0.15 - avgDev) / 0.15 * 1.5  // Max +1.5 if perfectly balanced
            factors.append(FactorChipData(label: "Macro balance", value: balanceScore))
        }

        // Fiber factor (if available)
        if let fiber = meal.micronutrients["Dietary Fiber"] ?? meal.micronutrients["Fiber"] {
            let fiberScore = min(fiber / 5.0, 1.5) - 0.5  // Target: 5g fiber per meal
            factors.append(FactorChipData(label: "Fiber content", value: fiberScore))
        }

        // Caloric density - reasonable portion size
        let portionScore: Double
        if meal.calories < 200 {
            portionScore = 0.3  // Light meal
        } else if meal.calories <= 600 {
            portionScore = 0.5  // Good portion
        } else if meal.calories <= 900 {
            portionScore = 0.2  // Moderate
        } else {
            portionScore = -0.3  // Heavy meal
        }
        factors.append(FactorChipData(label: "Portion size", value: portionScore))

        return factors
    }

    // Detailed score breakdown view
    @ViewBuilder
    private func scoreBreakdownView(healthScore: HealthScore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Base score
            HStack {
                Text("Base Score")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("5.0")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Factor breakdown
            ForEach(healthScoreFactors) { factor in
                HStack {
                    Text(factor.label)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(factor.value >= 0 ? "+\(String(format: "%.1f", factor.value))" : String(format: "%.1f", factor.value))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(factor.value >= 0 ? .factorPositive : .factorNegative)
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Final score
            HStack {
                Text("Final Score")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                ScoreText(score: healthScore.displayScore, size: .small)
            }

            // Insight if available
            if let insightText = healthScore.insight, !insightText.isEmpty {
                InsightBox(title: "Insight", text: insightText, icon: "lightbulb")
            } else if let reasoning = healthScore.reasoning, !reasoning.isEmpty {
                InsightBox(title: "Insight", text: reasoning, icon: "lightbulb")
            }
        }
        .padding(.top, 8)
    }

    private var dailyImpactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Impact on Targets")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                ImpactCircle(
                    label: "Calories",
                    percentage: Double(meal.calories) / Double(userDailyCalories),
                    color: .blue
                )
                ImpactCircle(
                    label: "Protein",
                    percentage: Double(meal.protein) / Double(userDailyProtein),
                    color: .blue
                )
                ImpactCircle(
                    label: "Fat",
                    percentage: Double(meal.fat) / Double(userDailyFat),
                    color: .yellow
                )
                ImpactCircle(
                    label: "Carbs",
                    percentage: Double(meal.carbs) / Double(userDailyCarbs),
                    color: .orange
                )
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nutriSyncElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
    }

    private var detailedNutritionSection: some View {
        VStack(spacing: 24) {
            // Group nutrients by category
            ForEach(NutrientCategory.allCases, id: \.self) { category in
                let nutrients = nutrientsForCategory(category)
                if !nutrients.isEmpty {
                    NutrientCategorySection(
                        title: category.rawValue,
                        nutrients: nutrients
                    )
                }
            }
        }
    }

    private func nutrientsForCategory(_ category: NutrientCategory) -> [(name: String, value: Double, unit: String, target: Double?, isAntiNutrient: Bool)] {
        var result: [(name: String, value: Double, unit: String, target: Double?, isAntiNutrient: Bool)] = []

        switch category {
        case .carbBreakdown:
            // Add main carbs from meal
            result.append((name: "Carbs", value: Double(meal.carbs), unit: "g", target: Double(userDailyCarbs), isAntiNutrient: false))
            // Add fiber if available
            if let fiber = meal.micronutrients["Dietary Fiber"] ?? meal.micronutrients["Fiber"] {
                result.append((name: "Fiber", value: fiber, unit: "g", target: 28, isAntiNutrient: false))
            }
            // Net carbs (carbs - fiber)
            let fiber = meal.micronutrients["Dietary Fiber"] ?? meal.micronutrients["Fiber"] ?? 0
            result.append((name: "Net Carbs", value: Double(meal.carbs) - fiber, unit: "g", target: nil, isAntiNutrient: false))
            // Sugars
            if let sugars = meal.micronutrients["Sugars"] ?? meal.micronutrients["Sugar"] {
                result.append((name: "Sugars", value: sugars, unit: "g", target: 50, isAntiNutrient: true))
            }

        case .fatBreakdown:
            // Add main fat from meal
            result.append((name: "Fat", value: Double(meal.fat), unit: "g", target: Double(userDailyFat), isAntiNutrient: false))
            // Saturated fat
            if let satFat = meal.micronutrients["Saturated Fat"] {
                result.append((name: "Saturated Fat", value: satFat, unit: "g", target: 20, isAntiNutrient: true))
            }
            // Trans fat
            if let transFat = meal.micronutrients["Trans Fat"] {
                result.append((name: "Trans Fat", value: transFat, unit: "g", target: 2, isAntiNutrient: true))
            }
            // Cholesterol
            if let chol = meal.micronutrients["Cholesterol"] {
                result.append((name: "Cholesterol", value: chol, unit: "mg", target: 300, isAntiNutrient: true))
            }

        case .vitamins:
            // Filter and add vitamins from micronutrients
            for (name, value) in meal.micronutrients {
                if NutrientCategory.category(for: name) == .vitamins {
                    let info = MicronutrientData.getNutrient(byName: name)
                    let unit = info?.unit ?? "mg"
                    let isAnti = info?.isAntiNutrient ?? false
                    let target: Double? = isAnti ? info?.dailyLimit : info?.averageRDA
                    result.append((name: name, value: value, unit: unit, target: target, isAntiNutrient: isAnti))
                }
            }

        case .minerals:
            // Filter and add minerals from micronutrients
            for (name, value) in meal.micronutrients {
                if NutrientCategory.category(for: name) == .minerals {
                    let info = MicronutrientData.getNutrient(byName: name)
                    let unit = info?.unit ?? "mg"
                    let isAnti = info?.isAntiNutrient ?? false
                    let target: Double? = isAnti ? info?.dailyLimit : info?.averageRDA
                    result.append((name: name, value: value, unit: unit, target: target, isAntiNutrient: isAnti))
                }
            }

        case .other:
            // Add protein (not shown in other categories)
            result.append((name: "Protein", value: Double(meal.protein), unit: "g", target: Double(userDailyProtein), isAntiNutrient: false))
            // Calories
            result.append((name: "Calories", value: Double(meal.calories), unit: "kcal", target: Double(userDailyCalories), isAntiNutrient: false))
            // Add any other micronutrients not in above categories
            for (name, value) in meal.micronutrients {
                let cat = NutrientCategory.category(for: name)
                if cat == .other && name != "Calories" {
                    let info = MicronutrientData.getNutrient(byName: name)
                    let unit = info?.unit ?? "mg"
                    let isAnti = info?.isAntiNutrient ?? false
                    let target: Double? = isAnti ? info?.dailyLimit : info?.averageRDA
                    result.append((name: name, value: value, unit: unit, target: target, isAntiNutrient: isAnti))
                }
            }
        }

        return result.sorted { $0.value > $1.value }
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
                        .fill(Color.nutriSyncElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.nutriSyncBorder, lineWidth: 1)
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
                    Image(systemName: isFromScan ? "checkmark.circle.fill" : "calendar.day.timeline.left")
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
                            Color.nutriSyncAccent,
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
                .fill(Color.nutriSyncElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
    }
    
    
    // MARK: - Helper Properties
    
    private var mealWindow: MealWindow? {
        guard meal.windowId != nil else { return nil }
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
    
    
    private func getMicronutrientUnit(for nutrient: String) -> String {
        // Common micronutrient units
        let units: [String: String] = [
            "Vitamin A": "μg",
            "Vitamin C": "mg",
            "Vitamin D": "μg",
            "Vitamin E": "mg",
            "Vitamin K": "μg",
            "Thiamin (B1)": "mg",
            "Riboflavin (B2)": "mg",
            "Niacin (B3)": "mg",
            "Vitamin B6": "mg",
            "Folate": "μg",
            "Vitamin B12": "μg",
            "Calcium": "mg",
            "Iron": "mg",
            "Magnesium": "mg",
            "Phosphorus": "mg",
            "Potassium": "mg",
            "Sodium": "mg",
            "Zinc": "mg",
            "Copper": "mg",
            "Manganese": "mg",
            "Selenium": "μg",
            "Dietary Fiber": "g",
            "Sugars": "g",
            "Cholesterol": "mg"
        ]
        return units[nutrient] ?? "mg"
    }
    
    private func getMicronutrientDailyTarget(for nutrient: String) -> Double {
        // Standard daily targets (RDA)
        let targets: [String: Double] = [
            "Vitamin A": 900,
            "Vitamin C": 90,
            "Vitamin D": 20,
            "Vitamin E": 15,
            "Vitamin K": 120,
            "Thiamin (B1)": 1.2,
            "Riboflavin (B2)": 1.3,
            "Niacin (B3)": 16,
            "Vitamin B6": 1.7,
            "Folate": 400,
            "Vitamin B12": 2.4,
            "Calcium": 1000,
            "Iron": 8,
            "Magnesium": 420,
            "Phosphorus": 700,
            "Potassium": 3400,
            "Sodium": 2300,
            "Zinc": 11,
            "Copper": 0.9,
            "Manganese": 2.3,
            "Selenium": 55,
            "Dietary Fiber": 28,
            "Sugars": 50,
            "Cholesterol": 300
        ]
        return targets[nutrient] ?? 100
    }
    
    private func getMicronutrientColor(for nutrient: String) -> Color {
        // Color coding for different types of nutrients
        if nutrient.contains("Vitamin") {
            switch nutrient {
            case let n where n.contains("A"): return .orange
            case let n where n.contains("B"): return .blue
            case let n where n.contains("C"): return .yellow
            case let n where n.contains("D"): return .purple
            case let n where n.contains("E"): return .green
            case let n where n.contains("K"): return .teal
            default: return .cyan
            }
        } else {
            switch nutrient {
            case "Calcium", "Iron", "Magnesium", "Zinc": return .pink
            case "Dietary Fiber": return .green
            case "Sugars": return .red
            case "Cholesterol": return .orange
            case "Sodium", "Potassium": return .cyan
            default: return .gray
            }
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

struct ImpactCircle: View {
    let label: String
    let percentage: Double
    let color: Color

    private var displayPercentage: Int {
        Int(percentage * 100)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: min(percentage, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Text("\(displayPercentage)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutrientProgressRow: View {
    let name: String
    let value: Double
    let unit: String
    let target: Double?
    let isAntiNutrient: Bool

    init(name: String, value: Double, unit: String, target: Double? = nil, isAntiNutrient: Bool = false) {
        self.name = name
        self.value = value
        self.unit = unit
        self.target = target
        self.isAntiNutrient = isAntiNutrient
    }

    private var percentage: Double? {
        guard let target = target, target > 0 else { return nil }
        return value / target
    }

    private var status: NutrientStatus {
        guard let pct = percentage else { return .adequate }
        return NutrientStatus.status(percentage: pct, isAntiNutrient: isAntiNutrient)
    }

    private var valueString: String {
        if value >= 1000 {
            return String(format: "%.0f%@", value, unit)
        } else if value >= 100 {
            return String(format: "%.0f%@", value, unit)
        } else if value >= 10 {
            return String(format: "%.1f%@", value, unit)
        } else {
            return String(format: "%.1f%@", value, unit)
        }
    }

    private var targetString: String {
        guard let target = target else { return "" }
        return String(format: "/ %.0f%@", target, unit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if let target = target {
                    HStack(spacing: 4) {
                        Text(valueString)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("/ \(Int(target))\(unit)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    Text(valueString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                if let pct = percentage {
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(status.color)
                        .frame(width: 40, alignment: .trailing)
                } else {
                    Text("No Target")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 60, alignment: .trailing)
                }
            }

            if let pct = percentage {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(status.color)
                            .frame(width: geometry.size.width * min(CGFloat(pct), 1.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

struct NutrientCategorySection: View {
    let title: String
    let nutrients: [(name: String, value: Double, unit: String, target: Double?, isAntiNutrient: Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ForEach(nutrients, id: \.name) { nutrient in
                    NutrientProgressRow(
                        name: nutrient.name,
                        value: nutrient.value,
                        unit: nutrient.unit,
                        target: nutrient.target,
                        isAntiNutrient: nutrient.isAntiNutrient
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.nutriSyncElevated)
            )
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

            if meal.ingredients.isEmpty {
                Text("No ingredient details available")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.nutriSyncElevated)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(meal.ingredients) { ingredient in
                        IngredientMacroRow(
                            ingredient: ingredient,
                            mealTotals: (
                                calories: meal.calories,
                                protein: meal.protein,
                                carbs: meal.carbs,
                                fat: meal.fat
                            )
                        )
                    }
                }
            }
        }
    }

    private var ingredientNutritionBreakdown: some View {
        EmptyView()
    }

}

// MARK: - Supporting Views

struct MiniMacroBar: View {
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(CGFloat(percentage), 1.0))
                }
            }
            .frame(height: 4)

            Text("\(Int(percentage * 100))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 28, alignment: .trailing)
        }
    }
}

struct IngredientMacroRow: View {
    let ingredient: MealIngredient
    let mealTotals: (calories: Int, protein: Int, carbs: Int, fat: Int)

    private var quantityString: String {
        if ingredient.quantity == floor(ingredient.quantity) {
            return "\(Int(ingredient.quantity)) \(ingredient.unit)"
        } else {
            return String(format: "%.1f %@", ingredient.quantity, ingredient.unit)
        }
    }

    private var hasNutritionData: Bool {
        ingredient.calories != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: food group dot, name, and quantity
            HStack {
                Circle()
                    .fill(ingredient.foodGroup.color)
                    .frame(width: 8, height: 8)

                Text(ingredient.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text(quantityString)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Nutrition data row
            if hasNutritionData {
                HStack(spacing: 0) {
                    // Calories
                    if let cal = ingredient.calories {
                        HStack(spacing: 3) {
                            Text("\(cal)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("cal")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(width: 60, alignment: .leading)
                    }

                    Spacer()

                    // Macros in compact pill format
                    HStack(spacing: 8) {
                        if let protein = ingredient.protein {
                            MacroPill(value: protein, label: "P", color: .blue)
                        }
                        if let carbs = ingredient.carbs {
                            MacroPill(value: carbs, label: "C", color: .orange)
                        }
                        if let fat = ingredient.fat {
                            MacroPill(value: fat, label: "F", color: .yellow)
                        }
                    }
                }
                .padding(.leading, 16) // Align with text after the dot
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nutriSyncElevated)
        )
    }
}

// Compact macro display pill
struct MacroPill: View {
    let value: Double
    let label: String
    let color: Color

    private var valueString: String {
        if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(valueString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
        )
    }
}

#Preview("From Timeline") {
    let meal: LoggedMeal = {
        var m = LoggedMeal(
            name: "Grilled Chicken Salad",
            calories: 420,
            protein: 35,
            carbs: 12,
            fat: 28,
            timestamp: Date()
        )
        
        // Add ingredients
        m.ingredients = [
            MealIngredient(name: "Grilled Chicken", quantity: 4, unit: "oz", foodGroup: .protein, calories: 180, protein: 35.0, carbs: 0.0, fat: 4.0),
            MealIngredient(name: "Mixed Greens", quantity: 2, unit: "cups", foodGroup: .vegetable, calories: 20, protein: 2.0, carbs: 4.0, fat: 0.0),
            MealIngredient(name: "Cherry Tomatoes", quantity: 0.5, unit: "cup", foodGroup: .vegetable, calories: 15, protein: 1.0, carbs: 3.0, fat: 0.0),
            MealIngredient(name: "Ranch Dressing", quantity: 2, unit: "tbsp", foodGroup: .condimentSauce, calories: 140, protein: 0.0, carbs: 2.0, fat: 15.0)
        ]
        
        // Add micronutrients
        m.micronutrients = [
            "Vitamin C": 45.2,
            "Vitamin A": 850,
            "Iron": 3.5,
            "Calcium": 120,
            "Dietary Fiber": 8,
            "Potassium": 980,
            "Vitamin B12": 1.2,
            "Folate": 125,
            "Magnesium": 85
        ]
        
        return m
    }()
    
    FoodAnalysisView(
        meal: meal,
        isFromScan: false
    )
}

#Preview("From Scan") {
    let meal: LoggedMeal = {
        var m = LoggedMeal(
            name: "Pasta with Sausage Sauce",
            calories: 750,
            protein: 35,
            carbs: 85,
            fat: 30,
            timestamp: Date()
        )
        
        // Add ingredients
        m.ingredients = [
            MealIngredient(name: "Pasta", quantity: 2, unit: "cups", foodGroup: .grain, calories: 400, protein: 14.0, carbs: 80.0, fat: 2.0),
            MealIngredient(name: "Italian Sausage", quantity: 4, unit: "oz", foodGroup: .protein, calories: 250, protein: 18.0, carbs: 2.0, fat: 20.0),
            MealIngredient(name: "Tomato Sauce", quantity: 0.5, unit: "cup", foodGroup: .condimentSauce, calories: 60, protein: 2.0, carbs: 8.0, fat: 2.0),
            MealIngredient(name: "Parmesan Cheese", quantity: 2, unit: "tbsp", foodGroup: .dairy, calories: 40, protein: 3.0, carbs: 1.0, fat: 3.0)
        ]
        
        // Add micronutrients
        m.micronutrients = [
            "Dietary Fiber": 8,
            "Sugars": 3,
            "Sodium": 320,
            "Cholesterol": 85,
            "Vitamin C": 12,
            "Iron": 4.2,
            "Calcium": 180,
            "Potassium": 650,
            "Vitamin B6": 0.8,
            "Zinc": 3.5
        ]
        
        return m
    }()
    
    FoodAnalysisView(
        meal: meal,
        isFromScan: true
    )
}
