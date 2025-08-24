//
//  DayNavigationHeader.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import SwiftUI

struct DayNavigationHeader: View {
    @Binding var selectedDate: Date
    @Binding var showDeveloperDashboard: Bool
    let meals: [LoggedMeal]
    let userProfile: UserProfile
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Logo, Title, and Settings in one row
                ZStack {
                    HStack {
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            showDeveloperDashboard = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Title with date centered
                    VStack(spacing: 2) {
                        Text("Today's Schedule")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                
                // Macro bars (MacroFactors style)
                MacroSummaryBar(meals: meals, userProfile: userProfile)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 6)
            
            // Separator line
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private func previousDay() {
        withAnimation(.spring(response: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextDay() {
        guard !isToday else { return }
        withAnimation(.spring(response: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// Macro summary bar like MacroFactors
struct MacroSummaryBar: View {
    let meals: [LoggedMeal]
    let userProfile: UserProfile
    
    // Calculate totals from actual meals
    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Int {
        meals.reduce(0) { $0 + $1.protein }
    }
    
    private var totalFat: Int {
        meals.reduce(0) { $0 + $1.fat }
    }
    
    private var totalCarbs: Int {
        meals.reduce(0) { $0 + $1.carbs }
    }
    
    private var calorieProgress: Double {
        let consumed = Double(totalCalories)
        let target = Double(userProfile.dailyCalorieTarget)
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    
    private var proteinProgress: Double {
        let consumed = Double(totalProtein)
        let target = Double(userProfile.dailyProteinTarget)
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    
    private var fatProgress: Double {
        let consumed = Double(totalFat)
        let target = Double(userProfile.dailyFatTarget)
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    
    private var carbProgress: Double {
        let consumed = Double(totalCarbs)
        let target = Double(userProfile.dailyCarbTarget)
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 8) {  // Further reduced spacing
            // Calories
            MacroProgressItem(
                sfSymbol: "flame.fill",
                value: totalCalories,
                target: userProfile.dailyCalorieTarget,
                progress: calorieProgress,
                color: .nutriSyncAccent
            )
            
            // Protein
            MacroProgressItem(
                label: "P",
                value: totalProtein,
                target: userProfile.dailyProteinTarget,
                progress: proteinProgress,
                color: .orange
            )
            
            // Fat
            MacroProgressItem(
                label: "F",
                value: totalFat,
                target: userProfile.dailyFatTarget,
                progress: fatProgress,
                color: .yellow
            )
            
            // Carbs
            MacroProgressItem(
                label: "C",
                value: totalCarbs,
                target: userProfile.dailyCarbTarget,
                progress: carbProgress,
                color: .blue
            )
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)  // Constrain to available width
    }
}

// Individual macro progress item
struct MacroProgressItem: View {
    var icon: String? = nil
    var sfSymbol: String? = nil
    var label: String? = nil
    let value: Int
    let target: Int
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Text(icon)
                    .font(.system(size: 16))
            } else if let sfSymbol = sfSymbol {
                Image(systemName: sfSymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            } else if let label = label {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text("\(value) / \(target)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.5)  // Allow more shrinking
                .frame(minWidth: 40, maxWidth: 80)  // Constrain width
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 3)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)  // Use flexible width instead of fixed
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack {
            DayNavigationHeader(
                selectedDate: .constant(Date()),
                showDeveloperDashboard: $showDeveloperDashboard,
                meals: [],
                userProfile: UserProfile.defaultProfile
            )
            .background(Color.nutriSyncElevated)
            
            Spacer()
        }
    }
}