//
//  JourneyTimelineView.swift
//  Phyllo - Momentum Redesign V1
//
//  Created on 1/31/25.
//
//  This is V1 of the Momentum tab redesign, focusing on a horizontal
//  journey timeline that tells the user's nutrition story through data.
//

import SwiftUI

struct JourneyTimelineView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedDay: Date? = nil
    @State private var timeRange: TimeRange = .week
    @State private var animateHero = false
    @State private var scrollToToday = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }
    
    // Mock journey data
    private var journeyData: [JourneyDay] {
        (0..<timeRange.days).map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            let score = generateMockScore(for: daysAgo)
            let energy = generateMockEnergy(for: daysAgo)
            let goalProgress = generateMockProgress(for: daysAgo)
            
            return JourneyDay(
                date: date,
                phylloScore: score,
                energyLevel: energy,
                goalProgress: goalProgress,
                mealCount: daysAgo == 0 ? mockData.mealsLoggedToday.count : Int.random(in: 3...5),
                note: generateMockNote(for: daysAgo, score: score)
            )
        }.reversed()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Navigation bar
                        PhylloNavigationBar(
                            title: "Journey",
                            showSettingsButton: true,
                            onSettingsTap: {
                                showDeveloperDashboard = true
                            }
                        )
                        
                        VStack(spacing: 24) {
                            // Hero Section - Today's Story
                            TodayStoryHero(
                                todayData: journeyData.last!,
                                animateHero: $animateHero
                            )
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Time Range Selector
                            Picker("Time Range", selection: $timeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Journey Timeline
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Your Journey")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            scrollToToday.toggle()
                                        }
                                    }) {
                                        Text("Today")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.phylloAccent)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Horizontal Timeline
                                ScrollViewReader { proxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(journeyData) { day in
                                                TimelineNode(
                                                    day: day,
                                                    isSelected: selectedDay == day.date,
                                                    isToday: Calendar.current.isDateInToday(day.date)
                                                )
                                                .id(day.id)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        selectedDay = selectedDay == day.date ? nil : day.date
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                    .onChange(of: scrollToToday) { _, _ in
                                        if let todayId = journeyData.last?.id {
                                            withAnimation {
                                                proxy.scrollTo(todayId, anchor: .trailing)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Selected Day Details
                            if let selected = selectedDay,
                               let dayData = journeyData.first(where: { $0.date == selected }) {
                                DayDetailCard(day: dayData)
                                    .padding(.horizontal)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                            
                            // Pattern Insights
                            PatternInsightsSection(journeyData: journeyData)
                                .padding(.horizontal)
                            
                            // Predictions
                            PredictiveInsightsSection(currentScore: journeyData.last?.phylloScore ?? 0)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8)) {
                animateHero = true
            }
            // Auto-scroll to today on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scrollToToday = true
            }
        }
    }
    
    // Mock data generators
    private func generateMockScore(for daysAgo: Int) -> Int {
        let baseScore = 75
        let variance = Int.random(in: -15...20)
        let weekendPenalty = isWeekend(daysAgo: daysAgo) ? -10 : 0
        return min(100, max(40, baseScore + variance + weekendPenalty))
    }
    
    private func generateMockEnergy(for daysAgo: Int) -> Double {
        let base = 6.5
        let variance = Double.random(in: -1.5...2.0)
        return min(10, max(3, base + variance))
    }
    
    private func generateMockProgress(for daysAgo: Int) -> Double {
        let base = 0.7
        let variance = Double.random(in: -0.2...0.3)
        return min(1.0, max(0.3, base + variance))
    }
    
    private func isWeekend(daysAgo: Int) -> Bool {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private func generateMockNote(for daysAgo: Int, score: Int) -> String? {
        if daysAgo == 0 { return nil }
        
        if score >= 90 {
            return ["Great macro balance!", "Perfect timing!", "Excellent choices!"].randomElement()
        } else if score >= 75 {
            return ["Good consistency", "Solid progress", "Keep it up!"].randomElement()
        } else if score >= 60 {
            return ["Room to improve", "Missed some windows", "Off target slightly"].randomElement()
        } else {
            return ["Challenging day", "Reset tomorrow", "Learning opportunity"].randomElement()
        }
    }
}

// MARK: - Journey Data Model
struct JourneyDay: Identifiable {
    let id = UUID()
    let date: Date
    let phylloScore: Int
    let energyLevel: Double
    let goalProgress: Double
    let mealCount: Int
    let note: String?
}

// MARK: - Components

struct TodayStoryHero: View {
    let todayData: JourneyDay
    @Binding var animateHero: Bool
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Score with context
            ZStack {
                // Animated background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [scoreColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                VStack(spacing: 8) {
                    Text("\(todayData.phylloScore)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(animateHero ? 1 : 0.5)
                        .opacity(animateHero ? 1 : 0)
                    
                    Text("Today's Score")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                }
            }
            
            // Motivational message
            VStack(spacing: 8) {
                Text(motivationalMessage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(contextMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.phylloTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateHero ? 1 : 0)
            .offset(y: animateHero ? 0 : 20)
            .animation(.spring(response: 0.8).delay(0.3), value: animateHero)
            
            // Quick stats
            HStack(spacing: 16) {
                QuickStat(
                    icon: "bolt.fill",
                    value: String(format: "%.1f", todayData.energyLevel),
                    label: "Energy"
                )
                
                QuickStat(
                    icon: "target",
                    value: "\(Int(todayData.goalProgress * 100))%",
                    label: "Goal"
                )
                
                QuickStat(
                    icon: "fork.knife",
                    value: "\(todayData.mealCount)",
                    label: "Meals"
                )
            }
            .opacity(animateHero ? 1 : 0)
            .animation(.spring(response: 0.8).delay(0.5), value: animateHero)
        }
        .padding(24)
        .background(Color.phylloElevated)
        .cornerRadius(24)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var scoreColor: Color {
        if todayData.phylloScore >= 80 {
            return .phylloAccent
        } else if todayData.phylloScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var motivationalMessage: String {
        if todayData.phylloScore >= 90 {
            return "Outstanding Performance! 🌟"
        } else if todayData.phylloScore >= 80 {
            return "Great Progress Today!"
        } else if todayData.phylloScore >= 70 {
            return "Solid Foundation Built"
        } else if todayData.phylloScore >= 60 {
            return "Room to Grow"
        } else {
            return "Reset & Refocus"
        }
    }
    
    private var contextMessage: String {
        if todayData.mealCount >= 4 {
            return "Consistent meal timing is paying off"
        } else if todayData.energyLevel >= 7 {
            return "Your energy levels are thriving"
        } else if todayData.goalProgress >= 0.8 {
            return "You're crushing your goals"
        } else {
            return "Every step forward counts"
        }
    }
}

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.phylloAccent)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct TimelineNode: View {
    let day: JourneyDay
    let isSelected: Bool
    let isToday: Bool
    
    private var dayLabel: String {
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(day.date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: day.date)
        }
    }
    
    private var scoreColor: Color {
        if day.phylloScore >= 80 {
            return .phylloAccent
        } else if day.phylloScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(scoreColor, lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Text("\(day.phylloScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.2 : (isToday ? 1.1 : 1.0))
            
            // Day label
            Text(dayLabel)
                .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? .white : .phylloTextSecondary)
            
            // Date
            Text(day.date.formatted(.dateTime.day().month()))
                .font(.system(size: 10))
                .foregroundColor(.phylloTextTertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday ? scoreColor : Color.clear, lineWidth: 2)
        )
    }
}

struct DayDetailCard: View {
    let day: JourneyDay
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: day.date))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let note = day.note {
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(day.phylloScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Stats grid
            HStack(spacing: 12) {
                DetailStat(label: "Energy", value: String(format: "%.1f/10", day.energyLevel))
                DetailStat(label: "Goal", value: "\(Int(day.goalProgress * 100))%")
                DetailStat(label: "Meals", value: "\(day.mealCount)")
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DetailStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PatternInsightsSection: View {
    let journeyData: [JourneyDay]
    
    private var bestDays: [JourneyDay] {
        journeyData.sorted { $0.phylloScore > $1.phylloScore }.prefix(3).map { $0 }
    }
    
    private var averageScore: Int {
        let total = journeyData.reduce(0) { $0 + $1.phylloScore }
        return total / journeyData.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns & Insights")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PatternInsightCard(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Best Performance Days",
                    description: "Your top scores were on \(formatBestDays())"
                )
                
                PatternInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .phylloAccent,
                    title: "Average Score: \(averageScore)",
                    description: "Trending \(trendDirection()) over this period"
                )
                
                PatternInsightCard(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "Weekend Pattern",
                    description: weekendPattern()
                )
            }
        }
    }
    
    private func formatBestDays() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return bestDays.map { formatter.string(from: $0.date) }.joined(separator: ", ")
    }
    
    private func trendDirection() -> String {
        let firstHalf = Array(journeyData.prefix(journeyData.count / 2))
        let secondHalf = Array(journeyData.suffix(journeyData.count / 2))
        
        let firstAvg = firstHalf.reduce(0) { $0 + $1.phylloScore } / firstHalf.count
        let secondAvg = secondHalf.reduce(0) { $0 + $1.phylloScore } / secondHalf.count
        
        if secondAvg > firstAvg + 5 {
            return "upward ↑"
        } else if secondAvg < firstAvg - 5 {
            return "downward ↓"
        } else {
            return "steady →"
        }
    }
    
    private func weekendPattern() -> String {
        let weekendDays = journeyData.filter { day in
            let weekday = Calendar.current.component(.weekday, from: day.date)
            return weekday == 1 || weekday == 7
        }
        
        let weekdayDays = journeyData.filter { day in
            let weekday = Calendar.current.component(.weekday, from: day.date)
            return weekday != 1 && weekday != 7
        }
        
        let weekendAvg = weekendDays.isEmpty ? 0 : weekendDays.reduce(0) { $0 + $1.phylloScore } / weekendDays.count
        let weekdayAvg = weekdayDays.isEmpty ? 0 : weekdayDays.reduce(0) { $0 + $1.phylloScore } / weekdayDays.count
        
        if weekendAvg < weekdayAvg - 10 {
            return "Scores drop on weekends - plan ahead!"
        } else if weekendAvg > weekdayAvg + 10 {
            return "Great weekend consistency!"
        } else {
            return "Consistent performance throughout the week"
        }
    }
}

struct PatternInsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.phylloElevated)
        .cornerRadius(16)
    }
}

struct PredictiveInsightsSection: View {
    let currentScore: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("If You Continue Like This...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PredictionCard(
                    timeframe: "In 7 days",
                    prediction: "Score could reach \(min(100, currentScore + 8))",
                    icon: "arrow.up.forward",
                    color: .phylloAccent
                )
                
                PredictionCard(
                    timeframe: "In 30 days",
                    prediction: "You'll build strong nutrition habits",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
                
                PredictionCard(
                    timeframe: "Goal Achievement",
                    prediction: "On track to reach your goal in 6 weeks",
                    icon: "target",
                    color: .orange
                )
            }
        }
    }
}

struct PredictionCard: View {
    let timeframe: String
    let prediction: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(timeframe)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.phylloTextTertiary)
                
                Text(prediction)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    JourneyTimelineView(showDeveloperDashboard: $showDeveloperDashboard)
        .preferredColorScheme(.dark)
}