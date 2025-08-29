//
//  RingSegmentDetailView.swift
//  NutriSync
//
//  Ring segment detail view for Performance dashboard
//

import SwiftUI

struct RingSegmentDetailView: View {
    let segment: NutritionDashboardView.RingSegment
    @ObservedObject var viewModel: NutritionDashboardViewModel
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Ring visualization
                        ringVisualization
                            .padding(.top, 20)
                        
                        // Score breakdown
                        scoreBreakdown
                        
                        // Detailed metrics
                        detailedMetrics
                        
                        // Recommendations
                        recommendations
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(segmentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private var segmentTitle: String {
        switch segment {
        case .timing:
            return "Timing Score"
        case .nutrients:
            return "Nutrient Score"
        case .adherence:
            return "Adherence Score"
        }
    }
    
    private var ringVisualization: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(segmentColor.opacity(0.2), lineWidth: 30)
                .frame(width: 200, height: 200)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animateIn ? segmentProgress : 0)
                .stroke(
                    LinearGradient(
                        colors: [segmentColor, segmentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: animateIn)
            
            // Center content
            VStack(spacing: 8) {
                Text("\(Int(segmentScore))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Image(systemName: segmentIcon)
                    .font(.system(size: 24))
                    .foregroundColor(segmentColor)
            }
        }
    }
    
    private var scoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(breakdownItems, id: \.title) { item in
                    ScoreBreakdownRow(item: item)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var detailedMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Analysis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(analysisItems, id: \.title) { item in
                    AnalysisRow(item: item)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(recommendationItems, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundColor(segmentColor)
                            .frame(width: 24)
                        
                        Text(recommendation)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    // MARK: - Computed Properties
    
    private var segmentColor: Color {
        switch segment {
        case .timing:
            return Color(hex: "FF3B30")
        case .nutrients:
            return Color(hex: "34C759")
        case .adherence:
            return Color(hex: "007AFF")
        }
    }
    
    private var segmentIcon: String {
        switch segment {
        case .timing:
            return "clock.fill"
        case .nutrients:
            return "leaf.fill"
        case .adherence:
            return "checkmark.circle.fill"
        }
    }
    
    private var segmentProgress: Double {
        switch segment {
        case .timing:
            return timingPercentage / 100
        case .nutrients:
            return nutrientPercentage / 100
        case .adherence:
            return adherencePercentage / 100
        }
    }
    
    private var segmentScore: Double {
        switch segment {
        case .timing:
            return timingPercentage
        case .nutrients:
            return nutrientPercentage
        case .adherence:
            return adherencePercentage
        }
    }
    
    private var breakdownItems: [ScoreBreakdownItem] {
        switch segment {
        case .timing:
            return [
                ScoreBreakdownItem(title: "Meals within window", value: "85%", color: .green),
                ScoreBreakdownItem(title: "Early meals", value: "10%", color: .orange),
                ScoreBreakdownItem(title: "Late meals", value: "5%", color: .red)
            ]
        case .nutrients:
            return [
                ScoreBreakdownItem(title: "Calorie accuracy", value: "\(Int(calorieAccuracyScore * 100))%", color: calorieAccuracyColor),
                ScoreBreakdownItem(title: "Macro balance", value: "\(Int(macroBalanceScore * 100))%", color: macroBalanceColor),
                ScoreBreakdownItem(title: "Micronutrient coverage", value: "\(Int(micronutrientScore * 100))%", color: micronutrientColor)
            ]
        case .adherence:
            return [
                ScoreBreakdownItem(title: "Meal frequency", value: "\(viewModel.todaysMeals.count)/\(viewModel.mealWindows.count)", color: mealFrequencyColor),
                ScoreBreakdownItem(title: "Window utilization", value: "\(windowsHit)/\(viewModel.mealWindows.count)", color: windowUtilizationColor),
                ScoreBreakdownItem(title: "Consistent spacing", value: "\(Int(consistencyScore * 100))%", color: consistencyColor)
            ]
        }
    }
    
    private var analysisItems: [AnalysisItem] {
        switch segment {
        case .timing:
            return [
                AnalysisItem(
                    title: "Average meal timing",
                    value: averageMealTiming,
                    trend: timingTrend
                ),
                AnalysisItem(
                    title: "Most consistent window",
                    value: mostConsistentWindow,
                    trend: .stable
                ),
                AnalysisItem(
                    title: "Timing improvement",
                    value: "+15% this week",
                    trend: .up
                )
            ]
        case .nutrients:
            return [
                AnalysisItem(
                    title: "Daily average calories",
                    value: "\(totalCalories) cal",
                    trend: calorieTrend
                ),
                AnalysisItem(
                    title: "Protein intake",
                    value: "\(totalProtein)g",
                    trend: proteinTrend
                ),
                AnalysisItem(
                    title: "Micronutrient variety",
                    value: "\(nutrientsHit)/18",
                    trend: micronutrientTrend
                )
            ]
        case .adherence:
            return [
                AnalysisItem(
                    title: "Current streak",
                    value: "\(viewModel.currentStreak) days",
                    trend: .up
                ),
                AnalysisItem(
                    title: "Weekly adherence",
                    value: "85%",
                    trend: .stable
                ),
                AnalysisItem(
                    title: "Missed windows",
                    value: "2 this week",
                    trend: .down
                )
            ]
        }
    }
    
    private var recommendationItems: [String] {
        switch segment {
        case .timing:
            return [
                "Try setting meal reminders 15 minutes before your window starts",
                "Your best timing is during lunch - maintain this consistency",
                "Consider shifting dinner 30 minutes earlier for better alignment"
            ]
        case .nutrients:
            return [
                "Add 20g more protein to hit your daily target consistently",
                "Include more iron-rich foods like spinach or lean red meat",
                "Your fiber intake is low - add more vegetables and whole grains"
            ]
        case .adherence:
            return [
                "Pre-plan your weekend meals to maintain consistency",
                "Space meals 3-4 hours apart for optimal energy levels",
                "Your morning routine is strong - keep it up!"
            ]
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private var timingPercentage: Double {
        // Calculate timing score (same logic as parent view)
        37 // Placeholder - should match parent calculation
    }
    
    private var nutrientPercentage: Double {
        // Calculate nutrient score (same logic as parent view)
        38 // Placeholder - should match parent calculation
    }
    
    private var adherencePercentage: Double {
        // Calculate adherence score (same logic as parent view)
        48 // Placeholder - should match parent calculation
    }
    
    private var totalCalories: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.protein }
    }
    
    private var nutrientsHit: Int {
        // Simplified calculation
        3
    }
    
    private var windowsHit: Int {
        viewModel.mealWindows.filter { window in
            viewModel.todaysMeals.contains { meal in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }.count
    }
    
    // Score calculations
    private var calorieAccuracyScore: Double { 0.85 }
    private var macroBalanceScore: Double { 0.75 }
    private var micronutrientScore: Double { 0.65 }
    private var consistencyScore: Double { 0.80 }
    
    // Colors
    private var calorieAccuracyColor: Color { calorieAccuracyScore > 0.8 ? .green : .orange }
    private var macroBalanceColor: Color { macroBalanceScore > 0.7 ? .green : .orange }
    private var micronutrientColor: Color { micronutrientScore > 0.6 ? .green : .red }
    private var mealFrequencyColor: Color { .green }
    private var windowUtilizationColor: Color { .orange }
    private var consistencyColor: Color { consistencyScore > 0.75 ? .green : .orange }
    
    // Analysis values
    private var averageMealTiming: String { "12 min early" }
    private var mostConsistentWindow: String { "Lunch (95%)" }
    private var timingTrend: AnalysisItem.Trend { .up }
    private var calorieTrend: AnalysisItem.Trend { .stable }
    private var proteinTrend: AnalysisItem.Trend { .down }
    private var micronutrientTrend: AnalysisItem.Trend { .up }
}

// MARK: - Supporting Types

struct ScoreBreakdownItem {
    let title: String
    let value: String
    let color: Color
}

struct ScoreBreakdownRow: View {
    let item: ScoreBreakdownItem
    
    var body: some View {
        HStack {
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
            
            Text(item.title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(item.value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct AnalysisItem {
    let title: String
    let value: String
    let trend: Trend
    
    enum Trend {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .yellow
            }
        }
    }
}

struct AnalysisRow: View {
    let item: AnalysisItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(item.value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Image(systemName: item.trend.icon)
                .font(.system(size: 20))
                .foregroundColor(item.trend.color)
        }
    }
}

#Preview {
    RingSegmentDetailView(
        segment: .timing,
        viewModel: NutritionDashboardViewModel(),
        onDismiss: {}
    )
}