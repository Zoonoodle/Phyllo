//
//  TodaysSummaryCard.swift
//  NutriSync
//
//  Today's performance summary card for Performance tab
//

import SwiftUI

struct TodaysSummaryCard: View {
    @EnvironmentObject var viewModel: NutritionDashboardViewModel
    
    private var completedWindows: Int {
        viewModel.currentDayWindows.filter { $0.status == .logged }.count
    }
    
    private var totalWindows: Int {
        viewModel.currentDayWindows.count
    }
    
    private var mealsLogged: Int {
        viewModel.meals.count
    }
    
    private var calories: Int {
        viewModel.meals.reduce(0) { total, meal in
            total + (meal.analysis?.nutrition.calories ?? 0)
        }
    }
    
    private var targetCalories: Int {
        viewModel.userProfile?.nutritionGoals.dailyCalories ?? 2400
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("TODAY'S PERFORMANCE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.5)
                Spacer()
            }
            
            HStack(spacing: 20) {
                MetricItem(
                    label: "Windows",
                    value: "\(completedWindows)/\(totalWindows)",
                    icon: "clock.badge.checkmark.fill",
                    color: Color.nutriSyncAccent
                )
                
                Divider()
                    .frame(height: 40)
                    .overlay(Color.white.opacity(0.1))
                
                MetricItem(
                    label: "Meals",
                    value: "\(mealsLogged)",
                    icon: "fork.knife",
                    color: Color(hex: "007AFF")
                )
                
                Divider()
                    .frame(height: 40)
                    .overlay(Color.white.opacity(0.1))
                
                MetricItem(
                    label: "Calories",
                    value: "\(calories)",
                    subtitle: "/ \(targetCalories)",
                    icon: "flame.fill",
                    color: Color.orange
                )
            }
        }
        .padding(20)
        .background(Color.nutriSyncElevated)
        .cornerRadius(16)
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        TodaysSummaryCard()
            .padding()
            .environmentObject(NutritionDashboardViewModel())
    }
}