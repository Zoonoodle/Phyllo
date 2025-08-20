//
//  NutritionDashboardTodayView.swift
//  NutriSync
//
//  TODAY View - Daily nutrition summary
//

import SwiftUI

struct NutritionDashboardTodayView: View {
    @ObservedObject var viewModel: NutritionDashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Daily summary
            dailySummaryCard
            
            // Macros breakdown
            dailyMacrosSection
            
            // Nutrient details
            nutrientBreakdownSection
        }
    }
    
    // MARK: - Daily Summary Card
    
    private var dailySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(formattedDate)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Score badge
                ScoreBadge(score: todayScore)
            }
            
            // Key metrics
            HStack(spacing: 20) {
                SummaryMetric(
                    label: "Windows",
                    value: "\(windowsHit)/\(totalWindows)",
                    color: .green
                )
                
                SummaryMetric(
                    label: "Calories",
                    value: "\(totalCalories)",
                    color: .orange
                )
                
                SummaryMetric(
                    label: "Protein",
                    value: "\(totalProtein)g",
                    color: .blue
                )
                
                SummaryMetric(
                    label: "Check-ins",
                    value: "\(checkInsCompleted)/4",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Daily Macros Section
    
    private var dailyMacrosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                MacroProgressRow(
                    name: "Protein",
                    current: totalProtein,
                    target: dailyProteinTarget,
                    unit: "g",
                    color: .orange,
                    icon: "flame.fill"
                )
                
                MacroProgressRow(
                    name: "Fats",
                    current: totalFat,
                    target: dailyFatTarget,
                    unit: "g",
                    color: .yellow,
                    icon: "drop.fill"
                )
                
                MacroProgressRow(
                    name: "Carbs",
                    current: totalCarbs,
                    target: dailyCarbsTarget,
                    unit: "g",
                    color: .blue,
                    icon: "leaf.fill"
                )
                
                MacroProgressRow(
                    name: "Calories",
                    current: totalCalories,
                    target: dailyCalorieTarget,
                    unit: "cal",
                    color: .green,
                    icon: "bolt.fill"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Nutrient Breakdown Section
    
    private var nutrientBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Micronutrients")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(nutrientsHit)/31 targets")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Top performing nutrients
            VStack(spacing: 12) {
                ForEach(topNutrients.prefix(5)) { nutrient in
                    NutrientRow(nutrient: nutrient)
                }
            }
            
            // Show more button
            NavigationLink(destination: Text("All Nutrients")) {
                HStack {
                    Text("View All Micronutrients")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(.nutriSyncAccent)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nutriSyncAccent.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String { viewModel.formattedDate }
    private var todayScore: Int { viewModel.todayScore }
    private var windowsHit: Int { viewModel.windowsHit }
    private var totalWindows: Int { viewModel.totalWindows }
    private var totalCalories: Int { viewModel.totalCalories }
    private var totalProtein: Int { viewModel.totalProtein }
    private var totalFat: Int { viewModel.totalFat }
    private var totalCarbs: Int { viewModel.totalCarbs }
    private var dailyProteinTarget: Int { viewModel.dailyProteinTarget }
    private var dailyFatTarget: Int { viewModel.dailyFatTarget }
    private var dailyCarbsTarget: Int { viewModel.dailyCarbsTarget }
    private var dailyCalorieTarget: Int { viewModel.dailyCalorieTarget }
    private var checkInsCompleted: Int { viewModel.checkInsCompleted }
    private var nutrientsHit: Int { viewModel.nutrientsHit }
    private var topNutrients: [NutritionDashboardViewModel.NutrientInfo] { viewModel.topNutrients }
}

// MARK: - Supporting Components

struct ScoreBadge: View {
    let score: Int
    
    var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .yellow
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
            
            Text("Score")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 60, height: 60)
        .background(
            Circle()
                .fill(scoreColor.opacity(0.15))
                .overlay(
                    Circle()
                        .strokeBorder(scoreColor.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

struct SummaryMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct MacroProgressRow: View {
    let name: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    let icon: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(current)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("/ \(target)\(unit)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("(\(percentage)%)")
                        .font(.system(size: 12))
                        .foregroundColor(color)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct NutrientRow: View {
    let nutrient: NutritionDashboardViewModel.NutrientInfo
    
    var body: some View {
        VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 12) {
                        // Nutrient icon
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16))
                            .foregroundColor(nutrient.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nutrient.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("\(nutrient.current, specifier: "%.1f")\(nutrient.unit) • \(Int(nutrient.percentage * 100))% RDA")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(nutrient.percentage >= 0.8 ? Color.green : nutrient.percentage >= 0.5 ? Color.yellow : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(nutrient.percentage >= 0.8 ? "Good" : nutrient.percentage >= 0.5 ? "Fair" : "Low")
                            .font(.system(size: 11))
                            .foregroundColor(nutrient.percentage >= 0.8 ? Color.green : nutrient.percentage >= 0.5 ? Color.yellow : Color.red)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
        )
    }
}