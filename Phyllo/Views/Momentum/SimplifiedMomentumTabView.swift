//
//  SimplifiedMomentumTabView.swift
//  Phyllo
//
//  Simplified, actionable momentum view with minimal aesthetic
//

import SwiftUI

struct SimplifiedMomentumTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @ObservedObject private var mockData = MockDataManager.shared
    @StateObject private var insightsEngine = InsightsEngine.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @State private var phylloScore: InsightsEngine.ScoreBreakdown?
    @State private var micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @State private var expandedSection: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .padding(.top, 60)
                        
                        // PhylloScore with context
                        phylloScoreSection
                        
                        // Today's Focus (actionable)
                        todaysFocusSection
                        
                        // Progress Summary (minimal)
                        progressSummarySection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .overlay(alignment: .topTrailing) {
                settingsButton
                    .padding(.top, 60)
                    .padding(.trailing, 20)
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Momentum")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your nutrition progress at a glance")
                .font(.system(size: 16))
                .foregroundColor(.phylloTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - PhylloScore Section
    
    private var phylloScoreSection: some View {
        VStack(spacing: 20) {
            // Score Display
            HStack(spacing: 20) {
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(phylloScore?.totalScore ?? 0) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(phylloScore?.totalScore ?? 0)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(trendText(phylloScore?.trend) ?? "stable")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                            .textCase(.uppercase)
                    }
                }
                
                // Score Explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("PhylloScore")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Your daily nutrition quality score based on meal timing, balance, and micronutrient density.")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Mini breakdown
                    HStack(spacing: 16) {
                        scoreComponent(value: phylloScore?.mealTimingScore ?? 0, label: "Timing")
                        scoreComponent(value: phylloScore?.macroBalanceScore ?? 0, label: "Balance")
                        scoreComponent(value: phylloScore?.micronutrientScore ?? 0, label: "Density")
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
        }
    }
    
    private func scoreComponent(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.phylloTextTertiary)
        }
    }
    
    // MARK: - Today's Focus
    
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Focus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if let microStatus = micronutrientStatus {
                VStack(spacing: 12) {
                    ForEach(microStatus.topDeficiencies.prefix(3), id: \.nutrient.name) { deficiency in
                        nutrientDeficiencyCard(deficiency: deficiency)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func nutrientDeficiencyCard(deficiency: InsightsEngine.MicronutrientStatus.NutrientStatus) -> some View {
        HStack(spacing: 12) {
            // Progress ring
            nutrientProgressRing(percentage: deficiency.percentageOfRDA, status: deficiency.status)
            
            // Nutrient info
            nutrientInfo(deficiency: deficiency)
            
            Spacer()
            
            // Food suggestion
            if let topFood = getTopFoodSource(for: deficiency.nutrient.name) {
                foodSuggestion(food: topFood)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func nutrientProgressRing(percentage: Double, status: InsightsEngine.MicronutrientStatus.NutrientStatus.Status) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                .frame(width: 44, height: 44)
            
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(status.color, lineWidth: 3)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(percentage))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func nutrientInfo(deficiency: InsightsEngine.MicronutrientStatus.NutrientStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deficiency.nutrient.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("\(Int(deficiency.consumed))/\(Int(deficiency.nutrient.rda)) \(deficiency.nutrient.unit)")
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
        }
    }
    
    @ViewBuilder
    private func foodSuggestion(food: String) -> some View {
        Text(food)
            .font(.system(size: 12))
            .foregroundColor(.phylloAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.phylloAccent.opacity(0.1))
            .cornerRadius(12)
    }
    
    // MARK: - Progress Summary
    
    private var progressSummarySection: some View {
        HStack(spacing: 16) {
            progressCard(
                title: "Streak",
                value: "\(mockData.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            progressCard(
                title: "Avg Energy",
                value: "7.2",
                subtitle: "this week",
                icon: "bolt.fill",
                color: .phylloAccent
            )
            
            progressCard(
                title: "Windows Hit",
                value: "85%",
                subtitle: "this week",
                icon: "clock.fill",
                color: .blue
            )
        }
    }
    
    private func progressCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.8))
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.phylloTextTertiary)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            actionButton(
                title: "View Weekly Report",
                icon: "chart.bar.fill",
                action: { }
            )
            
            actionButton(
                title: "Update Goals",
                icon: "target",
                action: { }
            )
        }
    }
    
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.phylloTextSecondary)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextTertiary)
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Settings Button
    
    private var settingsButton: some View {
        Button(action: { showDeveloperDashboard = true }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Helpers
    
    private var scoreColor: Color {
        guard let score = phylloScore?.totalScore else { return .phylloTextSecondary }
        if score >= 80 { return .green }
        else if score >= 60 { return .phylloAccent }
        else { return .orange }
    }
    
    private func loadData() {
        Task {
            phylloScore = await insightsEngine.calculatePhylloScore(
                todayMeals: mockData.todayMeals,
                mealWindows: mockData.mealWindows,
                checkIns: checkInManager.postMealCheckIns,
                primaryGoal: mockData.userGoals.first ?? .maintainWeight
            )
            
            micronutrientStatus = await insightsEngine.analyzeMicronutrients(
                meals: mockData.todayMeals
            )
        }
    }
    
    private func trendText(_ trend: InsightsEngine.ScoreBreakdown.ScoreTrend?) -> String? {
        guard let trend = trend else { return nil }
        switch trend {
        case .improving: return "improving"
        case .stable: return "stable"
        case .declining: return "declining"
        }
    }
    
    private func getTopFoodSource(for nutrientName: String) -> String? {
        // Return common food sources based on nutrient
        switch nutrientName.lowercased() {
        case "vitamin d": return "Salmon"
        case "vitamin b12": return "Eggs"
        case "iron": return "Spinach"
        case "calcium": return "Greek Yogurt"
        case "magnesium": return "Almonds"
        case "potassium": return "Banana"
        case "vitamin c": return "Orange"
        case "vitamin e": return "Avocado"
        case "vitamin a": return "Carrots"
        case "folate": return "Lentils"
        case "zinc": return "Beef"
        case "selenium": return "Brazil Nuts"
        case "omega-3": return "Walnuts"
        case "fiber": return "Oats"
        default: return nil
        }
    }
}

#Preview {
    SimplifiedMomentumTabView(showDeveloperDashboard: .constant(false))
}