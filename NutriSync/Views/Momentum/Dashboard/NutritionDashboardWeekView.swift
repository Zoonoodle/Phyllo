//
//  NutritionDashboardWeekView.swift
//  NutriSync
//
//  WEEK View - Weekly nutrition trends
//

import SwiftUI

struct NutritionDashboardWeekView: View {
    @ObservedObject var viewModel: NutritionDashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Week overview
            weekOverviewCard
            
            // Weekly achievements
            weeklyAchievementsSection
            
            // Trend charts
            trendChartsSection
        }
    }
    
    // MARK: - Week Overview Card
    
    private var weekOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Performance")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Week average score
                VStack(spacing: 2) {
                    Text("\(weekAverageScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.nutriSyncAccent)
                    
                    Text("avg score")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Mini bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayColor(for: day))
                            .frame(width: 36, height: max(10, weekScoreValues[day] * 60 / 100))
                        
                        Text(dayLabel(for: day))
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(height: 80)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private func dayLabel(for day: Int) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let date = calendar.date(byAdding: .day, value: day - 6, to: today) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func dayColor(for day: Int) -> Color {
        let score = weekScoreValues[day]
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red.opacity(0.6)
        }
    }
    
    // MARK: - Weekly Achievements
    
    private var weeklyAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Achievements")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AchievementCard(
                    icon: "checkmark.circle.fill",
                    title: "Consistency",
                    value: "\(daysLogged)/7",
                    subtitle: "days logged",
                    color: .green
                )
                
                AchievementCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(weekAverageCalories)",
                    subtitle: "daily avg",
                    color: .orange
                )
                
                AchievementCard(
                    icon: "clock.fill",
                    title: "Windows",
                    value: "\(Int(weekWindowAdherence))%",
                    subtitle: "adherence",
                    color: .blue
                )
                
                AchievementCard(
                    icon: "sparkles",
                    title: "Nutrients",
                    value: "\(weekNutrientsAverage)/31",
                    subtitle: "avg targets",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Trend Charts
    
    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Trends")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                TrendChartRow(
                    title: "Timing",
                    values: weekTimingValues,
                    color: .nutriSyncAccent,
                    average: weekTimingValues.reduce(0, +) / Double(weekTimingValues.count)
                )
                
                TrendChartRow(
                    title: "Nutrients",
                    values: weekNutrientValues,
                    color: .blue,
                    average: weekNutrientValues.reduce(0, +) / Double(weekNutrientValues.count)
                )
                
                TrendChartRow(
                    title: "Adherence",
                    values: weekAdherenceValues,
                    color: .purple,
                    average: weekAdherenceValues.reduce(0, +) / Double(weekAdherenceValues.count)
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekAverageScore: Int { viewModel.weekAverageScore }
    private var weekScoreValues: [Double] { viewModel.weekScoreValues }
    private var daysLogged: Int { viewModel.daysLogged }
    private var weekAverageCalories: Int { viewModel.weekAverageCalories }
    private var weekWindowAdherence: Double { viewModel.weekWindowAdherence }
    private var weekNutrientsAverage: Int { viewModel.weekNutrientsAverage }
    private var weekTimingValues: [Double] { viewModel.weekTimingValues }
    private var weekNutrientValues: [Double] { viewModel.weekNutrientValues }
    private var weekAdherenceValues: [Double] { viewModel.weekAdherenceValues }
}

// MARK: - Supporting Components

struct AchievementCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TrendChartRow: View {
    let title: String
    let values: [Double]
    let color: Color
    let average: Double
    
    private var maxValue: Double {
        values.max() ?? 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(average))% avg")
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            // Mini line chart
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    Path { path in
                        let height = geometry.size.height
                        // Horizontal lines
                        for i in 0...4 {
                            let y = height * CGFloat(i) / 4
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    
                    // Chart line
                    Path { path in
                        guard !values.isEmpty else { return }
                        
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let xStep = width / CGFloat(max(values.count - 1, 1))
                        
                        for (index, value) in values.enumerated() {
                            let x = CGFloat(index) * xStep
                            let y = height - (CGFloat(value / maxValue) * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 2)
                    
                    // Average line
                    Path { path in
                        let y = geometry.size.height - (CGFloat(average / maxValue) * geometry.size.height)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
            }
            .frame(height: 60)
        }
    }
}