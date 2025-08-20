//
//  NutritionDashboardNowView.swift
//  NutriSync
//
//  NOW View - Real-time nutrition status
//

import SwiftUI

struct NutritionDashboardNowView: View {
    @ObservedObject var viewModel: NutritionDashboardViewModel
    @Binding var ringAnimations: NutritionDashboardView.RingAnimationState
    @Binding var infoPopupData: NutritionDashboardView.InfoPopupData?
    
    var body: some View {
        VStack(spacing: 20) {
            // Activity rings with nutrition focus
            activityRingsSection
            
            // Live metrics
            liveMetricsGrid
            
            // Current window status
            currentWindowCard
            
            // Window timeline preview
            windowTimelinePreview
            
            // Quick actions
            quickActionsRow
        }
    }
    
    // MARK: - Activity Rings Section
    
    private var activityRingsSection: some View {
        VStack(spacing: 12) {
            // Rings
            ZStack {
                ForEach(ringData, id: \.id) { ring in
                    ActivityRing(
                        progress: ringProgress(for: ring.id),
                        color: ringColor(for: ring.id),
                        diameter: ring.diameter,
                        lineWidth: 14
                    )
                    .opacity(ring.id == "timing" ? 1.0 : 0.9)
                }
                
                // Center stats
                VStack(spacing: 4) {
                    Text("\(totalPercentage)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Overall")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(nutrientsHit)/31")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.nutriSyncAccent)
                    
                    Text(nutrientsStatus)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(height: 240)
            
            // Ring legends
            HStack(spacing: 20) {
                ringLabelWithInfo(
                    color: .nutriSyncAccent,
                    label: "Timing",
                    value: "\(Int(timingPercentage))%",
                    infoTitle: "Meal Timing Score",
                    infoDescription: "How well you're hitting your meal windows:\n\n• Eating within windows: +points\n• Consistent timing: +bonus\n• Missing windows: -points\n\nGood timing optimizes energy and metabolism."
                )
                
                ringLabelWithInfo(
                    color: .blue,
                    label: "Nutrients",
                    value: "\(Int(nutrientPercentage))%",
                    infoDescription: "Complete nutrition assessment:\n\n• 20% - Calorie accuracy\n• 30% - Macro balance (protein, fat, carbs)\n• 50% - Micronutrient coverage (vitamins & minerals)\n\nBalanced nutrition supports all body functions."
                )
                
                ringLabelWithInfo(
                    color: .purple,
                    label: "Adherence",
                    value: "\(Int(adherencePercentage))%",
                    infoTitle: "Weekly Consistency",
                    infoDescription: "Your 7-day consistency score:\n\n• Daily logging: 40%\n• Window adherence: 30%\n• Nutrient targets: 30%\n\nConsistency compounds into lasting results."
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private func ringLabelWithInfo(
        color: Color,
        label: String,
        value: String,
        infoTitle: String? = nil,
        infoDescription: String
    ) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                infoPopupData = NutritionDashboardView.InfoPopupData(
                    title: infoTitle ?? label,
                    description: infoDescription,
                    color: color,
                    position: .zero
                )
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
    
    // MARK: - Live Metrics Grid
    
    private var liveMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "flame",
                title: "Energy",
                value: "\(totalCalories)",
                subtitle: "of \(dailyCalorieTarget) cal",
                progress: dailyCalorieProgress,
                color: .orange
            )
            
            MetricCard(
                icon: "clock",
                title: "Fasting",
                value: fastingTime,
                subtitle: fastingStatus,
                progress: fastingProgress,
                color: .cyan
            )
            
            MetricCard(
                icon: "checkmark.circle",
                title: "Windows Hit",
                value: "\(windowsHit)/\(totalWindows)",
                subtitle: "today",
                progress: Double(windowsHit) / Double(max(totalWindows, 1)),
                color: .green
            )
            
            MetricCard(
                icon: "sparkle",
                title: "Today Score",
                value: "\(todayScore)",
                subtitle: "points",
                progress: Double(todayScore) / 100.0,
                color: .purple
            )
        }
    }
    
    // MARK: - Current Window Card
    
    private var currentWindowCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Window")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(currentWindowStatus.mainText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(currentWindowStatus.subText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Window icon
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 28))
                    .foregroundColor(.nutriSyncAccent)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.nutriSyncAccent)
                        .frame(width: geometry.size.width * currentWindowStatus.progress, height: 8)
                }
            }
            .frame(height: 8)
            
            // Next window info
            if let nextTime = timeUntilNextWindow {
                HStack {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Next: \(nextWindowName) in \(nextTime)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Window Timeline Preview
    
    private var windowTimelinePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 40)
                    
                    // Windows
                    ForEach(viewModel.todayWindows) { window in
                        if let position = windowPosition(for: window, in: geometry.size.width) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(windowColor(for: window))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(windowBorderColor(for: window), lineWidth: 1.5)
                                )
                                .frame(width: position.width, height: 32)
                                .offset(x: position.offset)
                        }
                    }
                    
                    // Current time indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 2, height: 40)
                        .offset(x: currentTimePosition(in: geometry.size.width))
                }
            }
            .frame(height: 40)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(["Past", "Active", "Upcoming", "Missed"], id: \.self) { label in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(legendColor(for: label))
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "camera.fill",
                title: "Log Meal",
                color: .nutriSyncAccent,
                action: {
                    // Navigate to scan
                }
            )
            
            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Check-in",
                color: .blue,
                action: {
                    // Show check-in
                }
            )
            
            QuickActionButton(
                icon: "book.fill",
                title: "Plan",
                color: .purple,
                action: {
                    // Show meal plan
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var ringData: [(id: String, diameter: CGFloat)] {
        [
            (id: "timing", diameter: 240),
            (id: "nutrients", diameter: 200),
            (id: "adherence", diameter: 160)
        ]
    }
    
    private func ringProgress(for id: String) -> Double {
        switch id {
        case "timing": return ringAnimations.timingProgress
        case "nutrients": return ringAnimations.nutrientProgress
        case "adherence": return ringAnimations.adherenceProgress
        default: return 0
        }
    }
    
    private func ringColor(for id: String) -> Color {
        switch id {
        case "timing": return .nutriSyncAccent
        case "nutrients": return .blue
        case "adherence": return .purple
        default: return .gray
        }
    }
    
    // Delegate computed properties to viewModel
    private var timingPercentage: Double { viewModel.timingPercentage }
    private var nutrientPercentage: Double { viewModel.nutrientPercentage }
    private var adherencePercentage: Double { viewModel.adherencePercentage }
    private var totalPercentage: Int { viewModel.totalPercentage }
    private var nutrientsHit: Int { viewModel.nutrientsHit }
    private var nutrientsStatus: String { viewModel.nutrientsStatus }
    private var currentWindowStatus: (mainText: String, subText: String, progress: Double) { viewModel.currentWindowStatus }
    private var totalCalories: Int { viewModel.totalCalories }
    private var dailyCalorieTarget: Int { viewModel.dailyCalorieTarget }
    private var dailyCalorieProgress: Double { viewModel.dailyCalorieProgress }
    private var fastingTime: String { viewModel.fastingTime }
    private var fastingStatus: String { viewModel.fastingStatus }
    private var fastingProgress: Double { viewModel.fastingProgress }
    private var windowsHit: Int { viewModel.windowsHit }
    private var totalWindows: Int { viewModel.totalWindows }
    private var todayScore: Int { viewModel.todayScore }
    private var nextWindowName: String { viewModel.nextWindowName }
    private var timeUntilNextWindow: String? { viewModel.timeUntilNextWindow }
    
    private func windowPosition(for window: MealWindow, in width: CGFloat) -> (offset: CGFloat, width: CGFloat)? {
        viewModel.windowPosition(for: window, in: width)
    }
    
    private func windowColor(for window: MealWindow) -> Color {
        viewModel.windowColor(for: window)
    }
    
    private func windowBorderColor(for window: MealWindow) -> Color {
        viewModel.windowBorderColor(for: window)
    }
    
    private func legendColor(for label: String) -> Color {
        viewModel.legendColor(for: label)
    }
    
    private func currentTimePosition(in width: CGFloat) -> CGFloat {
        viewModel.currentTimePosition(in: width)
    }
}

// MARK: - Supporting Components

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}