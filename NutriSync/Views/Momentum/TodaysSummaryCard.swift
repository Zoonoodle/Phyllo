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
        // Count windows that have meals logged in them
        viewModel.mealWindows.filter { window in
            !viewModel.mealsInWindow(window).isEmpty
        }.count
    }
    
    private var totalWindows: Int {
        viewModel.mealWindows.count
    }
    
    private var mealsLogged: Int {
        viewModel.todaysMeals.count
    }
    
    private var calories: Int {
        viewModel.totalCalories
    }
    
    private var targetCalories: Int {
        viewModel.dailyCalorieTarget
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