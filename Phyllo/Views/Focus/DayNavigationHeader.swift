//
//  DayNavigationHeader.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct DayNavigationHeader: View {
    @Binding var selectedDate: Date
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var mockData = MockDataManager.shared
    
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
                        // Phyllo logo
                        Image("Image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 35) // 28 * 1.25 = 35
                            .offset(y: -3) // Move up slightly
                        
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
                .padding(.horizontal, 24)
                
                // Macro bars (MacroFactors style)
                MacroSummaryBar()
                    .padding(.horizontal, 24)
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
    @StateObject private var mockData = MockDataManager.shared
    
    private var calorieProgress: Double {
        let consumed = Double(mockData.todaysCaloriesConsumed)
        let target = Double(mockData.userProfile.dailyCalorieTarget)
        return min(consumed / target, 1.0)
    }
    
    private var proteinProgress: Double {
        let consumed = Double(mockData.todaysProteinConsumed)
        let target = Double(mockData.userProfile.dailyProteinTarget)
        return min(consumed / target, 1.0)
    }
    
    private var fatProgress: Double {
        let consumed = Double(mockData.todaysFatConsumed)
        let target = Double(mockData.userProfile.dailyFatTarget)
        return min(consumed / target, 1.0)
    }
    
    private var carbProgress: Double {
        let consumed = Double(mockData.todaysCarbsConsumed)
        let target = Double(mockData.userProfile.dailyCarbTarget)
        return min(consumed / target, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {  // Reduced spacing
            // Calories
            MacroProgressItem(
                sfSymbol: "flame.fill",
                value: mockData.todaysCaloriesConsumed,
                target: mockData.userProfile.dailyCalorieTarget,
                progress: calorieProgress,
                color: .phylloAccent
            )
            
            // Protein
            MacroProgressItem(
                label: "P",
                value: mockData.todaysProteinConsumed,
                target: mockData.userProfile.dailyProteinTarget,
                progress: proteinProgress,
                color: .orange
            )
            
            // Fat
            MacroProgressItem(
                label: "F",
                value: mockData.todaysFatConsumed,
                target: mockData.userProfile.dailyFatTarget,
                progress: fatProgress,
                color: .yellow
            )
            
            // Carbs
            MacroProgressItem(
                label: "C",
                value: mockData.todaysCarbsConsumed,
                target: mockData.userProfile.dailyCarbTarget,
                progress: carbProgress,
                color: .blue
            )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
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
                }
            }
            .frame(height: 3)
        }
        .frame(width: 70)  // Fixed width for each macro item
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack {
            DayNavigationHeader(
                selectedDate: .constant(Date()),
                showDeveloperDashboard: $showDeveloperDashboard
            )
            .background(Color.phylloElevated)
            
            Spacer()
        }
    }
}