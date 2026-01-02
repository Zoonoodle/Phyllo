//
//  DayNavigationHeader.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import SwiftUI
import UIKit

struct DayNavigationHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingSettingsMenu: Bool
    @Binding var showDayDetail: Bool
    @Binding var showingDailyScoreDetail: Bool  // NEW: Navigate to DailyScoreDetailView
    let meals: [LoggedMeal]
    let userProfile: UserProfile
    var dailyScore: DailyScore?  // Optional daily adherence score
    
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
                        // Settings button (left side)
                        Button(action: {
                            showingSettingsMenu = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white.opacity(0.35))
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        // Daily Score (1-10 format) - tappable to show detail
                        Button {
                            showingDailyScoreDetail = true
                        } label: {
                            if let score = dailyScore, score.completedWindows > 0 {
                                DailyScoreMini(score: score)
                            } else {
                                // Analyzing state - show when no score yet
                                AnalyzingRing(size: 40)
                            }
                        }
                        .frame(width: 48, height: 48)
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
                
                // Macro bars (MacroFactors style) - now tappable
                VStack(spacing: 6) {
                    MacroSummaryBar(meals: meals, userProfile: userProfile)
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())  // Make entire area tappable
                .onTapGesture {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.prepare()
                    impact.impactOccurred()
                    showDayDetail = true
                }
                .overlay(
                    // Add subtle chevron to indicate tappability
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.trailing, 4)
                    }
                )
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
                label: "Cal",
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
                color: .orange,
                unit: "g"
            )

            // Fat
            MacroProgressItem(
                label: "F",
                value: totalFat,
                target: userProfile.dailyFatTarget,
                progress: fatProgress,
                color: .yellow,
                unit: "g"
            )

            // Carbs
            MacroProgressItem(
                label: "C",
                value: totalCarbs,
                target: userProfile.dailyCarbTarget,
                progress: carbProgress,
                color: .blue,
                unit: "g"
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
    var unit: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Text(icon)
                    .font(.system(size: 16))
            } else if let sfSymbol = sfSymbol {
                Image(systemName: sfSymbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            } else if let label = label {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text("\(value) / \(target)\(unit)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)  // Adjust shrinking for larger font
                .frame(minWidth: 50, maxWidth: 90)  // Slightly wider for larger text
            
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

// MARK: - Daily Score Mini (1-10 format, compact)

struct DailyScoreMini: View {
    let score: DailyScore

    private var displayScore: Double {
        score.displayScore
    }

    private var scoreColor: Color {
        switch displayScore {
        case 8.5...10.0: return .nutriSyncAccent
        case 7.0..<8.5: return Color(hex: "A8E063")
        case 5.0..<7.0: return Color(hex: "FFD93D")
        case 3.0..<5.0: return Color(hex: "FFA500")
        default: return Color(hex: "FF6B6B")
        }
    }

    var body: some View {
        ZStack {
            // Background circle with progress
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: CGFloat(displayScore) / 10.0)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))

            // Score text
            Text(String(format: "%.1f", displayScore))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Daily Score Badge (Legacy - keeping for compatibility)

struct DailyScoreBadge: View {
    let score: Int

    // Score color based on value
    private var scoreColor: Color {
        switch score {
        case 85...100: return .nutriSyncAccent
        case 70..<85: return Color(hex: "A8E063") // Soft green
        case 50..<70: return Color(hex: "FFD93D") // Yellow
        case 25..<50: return Color(hex: "FFA500") // Orange
        default: return Color(hex: "FF6B6B") // Soft red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(scoreColor)

            Text("\(score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(scoreColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(scoreColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    @Previewable @State var showingSettingsMenu = false
    @Previewable @State var showingDailyScoreDetail = false

    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack {
            DayNavigationHeader(
                selectedDate: .constant(Date()),
                showingSettingsMenu: $showingSettingsMenu,
                showDayDetail: .constant(false),
                showingDailyScoreDetail: $showingDailyScoreDetail,
                meals: [],
                userProfile: UserProfile.defaultProfile
            )
            .background(Color.nutriSyncElevated)

            Spacer()
        }
    }
}