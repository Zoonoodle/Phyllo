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
    @State private var expandedNutrient: String? = nil
    
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
        let isExpanded = expandedNutrient == deficiency.nutrient.name
        let benefit = getNutrientBenefit(for: deficiency.nutrient.name)
        let timing = getOptimalTiming(for: deficiency.nutrient.name)
        let foodSources = getAllFoodSources(for: deficiency.nutrient.name)
        
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 12) {
                // Progress ring
                nutrientProgressRing(percentage: deficiency.percentageOfRDA, status: deficiency.status)
                
                // Nutrient info with benefit
                VStack(alignment: .leading, spacing: 6) {
                    Text(deficiency.nutrient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(benefit)
                        .font(.system(size: 13))
                        .foregroundColor(.phylloTextSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(Int(deficiency.consumed))/\(Int(deficiency.nutrient.rda)) \(deficiency.nutrient.unit)")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextTertiary)
                        
                        if !isExpanded {
                            Text("•")
                                .foregroundColor(.phylloTextTertiary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                Text(timing.shortLabel)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.phylloAccent.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Right side: Food suggestion or expand chevron
                if !isExpanded, let topFood = foodSources.first {
                    Text(topFood)
                        .font(.system(size: 12))
                        .foregroundColor(.phylloAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.phylloAccent.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.phylloTextTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(16)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Timing recommendation
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.phylloAccent)
                            .frame(width: 32, height: 32)
                            .background(Color.phylloAccent.opacity(0.1))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Best Time: \(timing.windowName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(timing.reason)
                                .font(.system(size: 12))
                                .foregroundColor(.phylloTextSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Food sources
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food Sources")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.phylloTextSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(foodSources.prefix(3), id: \.self) { food in
                                Text(food)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                expandedNutrient = expandedNutrient == deficiency.nutrient.name ? nil : deficiency.nutrient.name
            }
        }
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
    
    private func getNutrientBenefit(for nutrientName: String) -> String {
        switch nutrientName.lowercased() {
        case "vitamin d": return "For immune health & mood"
        case "vitamin b12": return "For energy & brain function"
        case "iron": return "For oxygen transport & energy"
        case "calcium": return "For bone health & muscle function"
        case "magnesium": return "For better sleep & muscle recovery"
        case "potassium": return "For stable energy & heart health"
        case "vitamin c": return "For immunity & skin health"
        case "vitamin e": return "For cell protection & skin"
        case "vitamin a": return "For vision & immune function"
        case "folate": return "For cell growth & energy"
        case "zinc": return "For immunity & healing"
        case "selenium": return "For thyroid & metabolism"
        case "omega-3": return "For brain & heart health"
        case "fiber": return "For sustained fullness & gut health"
        default: return "For overall health"
        }
    }
    
    private func getOptimalTiming(for nutrientName: String) -> (windowName: String, shortLabel: String, reason: String) {
        // Get current time and active windows
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch nutrientName.lowercased() {
        case "magnesium":
            return ("Evening", "Evening", "Promotes relaxation and better sleep quality when taken with dinner")
        case "vitamin d", "calcium":
            return ("Morning", "Morning", "Best absorbed with breakfast fats for all-day benefits")
        case "iron":
            return ("Morning", "Morning", "Optimal absorption on empty stomach or with vitamin C")
        case "vitamin b12", "vitamin c":
            return ("Morning", "Morning", "Boosts energy and immunity for the day ahead")
        case "potassium":
            return ("Lunch", "Midday", "Maintains stable energy through afternoon hours")
        case "fiber":
            return ("Throughout", "All meals", "Spread across meals for sustained fullness")
        case "omega-3":
            return ("Lunch/Dinner", "With meals", "Better absorbed with meal fats")
        case "zinc":
            return ("Evening", "Evening", "Best taken away from calcium-rich foods")
        default:
            return ("Anytime", "Flexible", "Can be consumed at any meal")
        }
    }
    
    private func getAllFoodSources(for nutrientName: String) -> [String] {
        switch nutrientName.lowercased() {
        case "vitamin d": return ["Salmon", "Egg yolks", "Mushrooms"]
        case "vitamin b12": return ["Eggs", "Greek yogurt", "Nutritional yeast"]
        case "iron": return ["Spinach", "Lentils", "Dark chocolate"]
        case "calcium": return ["Greek yogurt", "Almonds", "Kale"]
        case "magnesium": return ["Almonds", "Dark chocolate", "Avocado"]
        case "potassium": return ["Banana", "Sweet potato", "Spinach"]
        case "vitamin c": return ["Orange", "Bell peppers", "Strawberries"]
        case "vitamin e": return ["Avocado", "Almonds", "Sunflower seeds"]
        case "vitamin a": return ["Carrots", "Sweet potato", "Spinach"]
        case "folate": return ["Lentils", "Asparagus", "Avocado"]
        case "zinc": return ["Beef", "Pumpkin seeds", "Chickpeas"]
        case "selenium": return ["Brazil nuts", "Tuna", "Eggs"]
        case "omega-3": return ["Walnuts", "Chia seeds", "Flax seeds"]
        case "fiber": return ["Oats", "Chia seeds", "Berries"]
        default: return ["Varied whole foods"]
        }
    }
    
    private func getTopFoodSource(for nutrientName: String) -> String? {
        getAllFoodSources(for: nutrientName).first
    }
}

#Preview {
    SimplifiedMomentumTabView(showDeveloperDashboard: .constant(false))
}