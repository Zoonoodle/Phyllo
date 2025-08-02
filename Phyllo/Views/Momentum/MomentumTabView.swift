//
//  MomentumTabView.swift
//  Phyllo
//
//  Created on 1/31/25.
//
//  The Momentum tab tells a compelling data story through chapters
//  showing the user's nutrition journey from beginning to future.
//

import SwiftUI

struct MomentumTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var mockData = MockDataManager.shared
    @StateObject private var insightsEngine = InsightsEngine.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @State private var currentChapter: StoryChapter = .yourPlan
    @State private var animateContent = false
    @State private var expandedInsight: String? = nil
    @State private var phylloScore: InsightsEngine.ScoreBreakdown?
    @State private var micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @State private var insights: [InsightsEngine.Insight] = []
    
    enum StoryChapter: String, CaseIterable {
        case yourPlan = "Your Plan"
        case firstWeek = "First Week"
        case patterns = "Your Patterns"
        case peakState = "Peak State"
        
        var chapterId: String {
            switch self {
            case .yourPlan: return "yourPlan"
            case .firstWeek: return "firstWeek"
            case .patterns: return "patterns"
            case .peakState: return "peakState"
            }
        }
        
        var icon: String {
            switch self {
            case .yourPlan: return "doc.text.fill"
            case .firstWeek: return "calendar.badge.clock"
            case .patterns: return "chart.line.uptrend.xyaxis"
            case .peakState: return "star.fill"
            }
        }
        
        var lockedIcon: String {
            switch self {
            case .yourPlan: return icon // Never locked
            case .firstWeek: return "lock.fill"
            case .patterns: return "lock.fill"
            case .peakState: return "lock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .yourPlan: return .phylloAccent
            case .firstWeek: return .blue
            case .patterns: return .purple
            case .peakState: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background gradient based on chapter
                LinearGradient(
                    colors: [
                        currentChapter.color.opacity(0.15),
                        Color.phylloBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: currentChapter)
                
                VStack(spacing: 0) {
                    // Custom navigation bar with transparent background
                    HStack(spacing: 16) {
                        // Title positioned like Scan view
                        Text("Your Story")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
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
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Chapter Navigation
                            ChapterNavigator(
                                currentChapter: $currentChapter,
                                onChapterChange: {
                                    withAnimation(.spring(response: 0.5)) {
                                        animateContent = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.spring(response: 0.8)) {
                                            animateContent = true
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Chapter Content
                            ZStack {
                                if mockData.storyChapterProgress.isChapterUnlocked(currentChapter.chapterId) {
                                    switch currentChapter {
                                    case .yourPlan:
                                        YourPlanChapter(
                                            animateContent: $animateContent,
                                            scoreBreakdown: phylloScore,
                                            micronutrientStatus: micronutrientStatus
                                        )
                                    case .firstWeek:
                                        FirstWeekChapter(
                                            animateContent: $animateContent,
                                            scoreBreakdown: phylloScore,
                                            micronutrientStatus: micronutrientStatus
                                        )
                                    case .patterns:
                                        PatternsChapter(
                                            animateContent: $animateContent,
                                            expandedInsight: $expandedInsight,
                                            scoreBreakdown: phylloScore,
                                            micronutrientStatus: micronutrientStatus
                                        )
                                    case .peakState:
                                        PeakStateChapter(
                                            animateContent: $animateContent,
                                            scoreBreakdown: phylloScore,
                                            micronutrientStatus: micronutrientStatus,
                                            insights: insights
                                        )
                                    }
                                } else {
                                    LockedChapterView(
                                        chapter: currentChapter,
                                        progress: mockData.storyChapterProgress
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.3)) {
                animateContent = true
            }
            calculateRealData()
        }
    }
    
    // MARK: - Real Data Calculation
    
    private func calculateRealData() {
        // Get today's meals
        let todayMeals = mockData.todayMeals
        
        // Get meal windows
        let windows = mockData.mealWindows
        
        // Get check-ins
        let checkIns = checkInManager.postMealCheckIns.filter { checkIn in
            Calendar.current.isDateInToday(checkIn.timestamp)
        }
        
        // Calculate PhylloScore
        phylloScore = insightsEngine.calculatePhylloScore(
            todayMeals: todayMeals,
            mealWindows: windows,
            checkIns: checkIns,
            primaryGoal: mockData.userProfile.primaryGoal
        )
        
        // Analyze micronutrients
        micronutrientStatus = insightsEngine.analyzeMicronutrients(meals: todayMeals)
        
        // Generate insights
        if let score = phylloScore, let microStatus = micronutrientStatus {
            insights = insightsEngine.generateInsights(
                meals: todayMeals,
                checkIns: checkIns,
                microStatus: microStatus,
                score: score
            )
        }
    }
}

// MARK: - Chapter Navigator

struct ChapterNavigator: View {
    @Binding var currentChapter: MomentumTabView.StoryChapter
    let onChapterChange: () -> Void
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MomentumTabView.StoryChapter.allCases, id: \.self) { chapter in
                ChapterTab(
                    chapter: chapter,
                    isSelected: currentChapter == chapter,
                    isUnlocked: mockData.storyChapterProgress.isChapterUnlocked(chapter.chapterId),
                    action: {
                        if currentChapter != chapter {
                            currentChapter = chapter
                            onChapterChange()
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ChapterTab: View {
    let chapter: MomentumTabView.StoryChapter
    let isSelected: Bool
    let isUnlocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Image(systemName: isUnlocked ? chapter.icon : chapter.lockedIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : (isUnlocked ? chapter.color : .phylloTextTertiary))
                    
                    if !isUnlocked && chapter != .yourPlan {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.phylloTextTertiary)
                            .offset(x: 8, y: 8)
                    }
                }
                
                Text(chapter.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : (isUnlocked ? .phylloTextSecondary : .phylloTextTertiary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected && isUnlocked ? chapter.color : Color.clear)
            )
            .opacity(isUnlocked ? 1.0 : 0.7)
        }
    }
}

// MARK: - Chapter: First Week (Previously Beginning)

struct FirstWeekChapter: View {
    @Binding var animateContent: Bool
    let scoreBreakdown: InsightsEngine.ScoreBreakdown?
    let micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @StateObject private var mockData = MockDataManager.shared
    
    private let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    
    // Mock starting data for comparison
    private let startingScore = 42
    private let startingDeficiencies = 5
    
    private func trendText(_ trend: InsightsEngine.ScoreBreakdown.ScoreTrend?) -> String? {
        guard let trend = trend else { return nil }
        switch trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
    
    @ViewBuilder
    private var storyIntroduction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("It all started...")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            Text("30 days ago, you began your journey with Phyllo. Here's how far you've come.")
                .font(.system(size: 18))
                .foregroundColor(.phylloTextSecondary)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var startingStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StartingStatCard(
                    title: "Initial Score",
                    value: "\(startingScore)",
                    subtitle: "Room to grow",
                    icon: "chart.line.uptrend.xyaxis",
                    delay: 0.3
                )
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
                
                StartingStatCard(
                    title: "Current Score",
                    value: "\(scoreBreakdown?.totalScore ?? 0)",
                    subtitle: trendText(scoreBreakdown?.trend) ?? "Improving",
                    icon: "star.fill",
                    delay: 0.4,
                    color: scoreBreakdown?.trend.color ?? .green
                )
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
            }
            
            // First Week Summary
            FirstWeekCard()
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.spring(response: 0.8).delay(0.5), value: animateContent)
        }
    }
    
    @ViewBuilder
    private var scoreProgressSection: some View {
        if let score = scoreBreakdown {
            PhylloScoreComparison(
                startScore: startingScore,
                currentScore: score.totalScore,
                daysElapsed: 7
            )
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.spring(response: 0.8).delay(0.65), value: animateContent)
        }
    }
    
    @ViewBuilder
    private var nutritionalImprovements: some View {
        if let microStatus = micronutrientStatus {
            VStack(spacing: 16) {
                SectionHeader(title: "Nutritional Improvements", icon: "leaf.fill")
                
                nutritionalComparisonCard(microStatus: microStatus)
                
                if microStatus.topDeficiencies.count < startingDeficiencies {
                    improvementMessage(microStatus: microStatus)
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.spring(response: 0.8).delay(0.7), value: animateContent)
        }
    }
    
    @ViewBuilder
    private func nutritionalComparisonCard(microStatus: InsightsEngine.MicronutrientStatus) -> some View {
        HStack(spacing: 12) {
            // Start deficiencies
            nutritionalStatusColumn(
                title: "Week 1",
                count: startingDeficiencies,
                color: .red
            )
            
            Image(systemName: "arrow.right")
                .font(.system(size: 20))
                .foregroundColor(.phylloTextTertiary)
            
            // Current deficiencies
            nutritionalStatusColumn(
                title: "Now",
                count: microStatus.topDeficiencies.count,
                color: microStatus.topDeficiencies.count < startingDeficiencies ? .green : .orange
            )
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func nutritionalStatusColumn(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
            
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Text("deficiencies")
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func improvementMessage(microStatus: InsightsEngine.MicronutrientStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text("You've addressed \(startingDeficiencies - microStatus.topDeficiencies.count) nutritional gaps!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(20)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            storyIntroduction
            startingStats
            
            // Milestone Timeline
            MilestoneTimeline()
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.8).delay(0.6), value: animateContent)
            
            scoreProgressSection
            nutritionalImprovements
        }
    }
}

struct StartingStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let delay: Double
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextTertiary)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct FirstWeekCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Your First Week", systemImage: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                FirstWeekStat(label: "Meals Logged", value: "21", trend: .positive)
                FirstWeekStat(label: "Avg Energy", value: "5.2 → 6.8", trend: .positive)
                FirstWeekStat(label: "Windows Hit", value: "14/21", trend: .neutral)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FirstWeekStat: View {
    let label: String
    let value: String
    let trend: Trend
    
    enum Trend {
        case positive, neutral, negative
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .orange
            case .negative: return .red
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(trend.color)
        }
    }
}

struct MilestoneTimeline: View {
    let milestones = [
        Milestone(day: 1, title: "Started Journey", icon: "flag.fill", color: .blue),
        Milestone(day: 7, title: "First Week Complete", icon: "checkmark.circle.fill", color: .green),
        Milestone(day: 14, title: "Habits Forming", icon: "bolt.fill", color: .orange),
        Milestone(day: 21, title: "Breakthrough Week", icon: "star.fill", color: .yellow),
        Milestone(day: 30, title: "Today", icon: "location.fill", color: .phylloAccent)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Milestones")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(milestones) { milestone in
                    HStack(alignment: .top, spacing: 16) {
                        // Timeline line and dot
                        VStack(spacing: 0) {
                            Circle()
                                .fill(milestone.color)
                                .frame(width: 12, height: 12)
                            
                            if milestone.day < 30 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 2, height: 40)
                            }
                        }
                        
                        // Milestone content
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: milestone.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(milestone.color)
                                
                                Text(milestone.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Day \(milestone.day)")
                                .font(.system(size: 12))
                                .foregroundColor(.phylloTextTertiary)
                        }
                        .padding(.bottom, milestone.day < 30 ? 20 : 0)
                        
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct Milestone: Identifiable {
    let id = UUID()
    let day: Int
    let title: String
    let icon: String
    let color: Color
}

// MARK: - Chapter: Peak State (Previously Now)

struct PeakStateChapter: View {
    @Binding var animateContent: Bool
    let scoreBreakdown: InsightsEngine.ScoreBreakdown?
    let micronutrientStatus: InsightsEngine.MicronutrientStatus?
    let insights: [InsightsEngine.Insight]
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Chapter Title
            VStack(alignment: .leading, spacing: 16) {
                Text("This is Now")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("A real-time snapshot of your current state.")
                    .font(.system(size: 18))
                    .foregroundColor(.phylloTextSecondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Live Dashboard
            LiveDashboard(scoreBreakdown: scoreBreakdown)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.95)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
            
            // Micronutrient Status
            if let microStatus = micronutrientStatus {
                MicronutrientStatusView(status: microStatus)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.35), value: animateContent)
            }
            
            // Today's Insights
            if !insights.isEmpty {
                VStack(spacing: 16) {
                    SectionHeader(title: "Today's Insights", icon: "lightbulb.fill")
                    
                    ForEach(insights.prefix(3)) { insight in
                        InsightCard(insight: insight)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
                    }
                }
            } else {
                // Fallback to static content if no insights yet
                VStack(spacing: 16) {
                    SectionHeader(title: "Your Current State", icon: "location.fill")
                    
                    HStack(spacing: 16) {
                        StrengthCard(
                            title: "Getting Started",
                            items: [
                                "Log more meals",
                                "Complete check-ins",
                                "Track consistently"
                            ],
                            color: .blue
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(x: animateContent ? 0 : -20)
                        .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
                    }
                }
            }
            
            // Real-time Recommendations
            RecommendationsCard()
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.spring(response: 0.8).delay(0.6), value: animateContent)
        }
    }
}

struct LiveDashboard: View {
    let scoreBreakdown: InsightsEngine.ScoreBreakdown?
    @State private var pulseAnimation = false
    
    private var displayScore: Int {
        scoreBreakdown?.totalScore ?? 0
    }
    
    private var scoreColor: Color {
        if displayScore >= 80 { return .green }
        else if displayScore >= 60 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Score with Live Indicator
            ZStack {
                // Pulsing background
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.5)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("\(displayScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        if let trend = scoreBreakdown?.trend {
                            Image(systemName: trend.icon)
                                .font(.system(size: 12))
                                .foregroundColor(trend.color)
                        }
                        Text("PhylloScore")
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
            
            // Live Stats Grid - Score Breakdown
            if let breakdown = scoreBreakdown {
                VStack(spacing: 8) {
                    Text("Score Breakdown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.phylloTextTertiary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ScoreComponentCard(
                            label: "Meal Timing",
                            value: breakdown.mealTimingScore,
                            maxValue: 25,
                            icon: "clock.fill"
                        )
                        ScoreComponentCard(
                            label: "Macro Balance",
                            value: breakdown.macroBalanceScore,
                            maxValue: 25,
                            icon: "chart.pie.fill"
                        )
                        ScoreComponentCard(
                            label: "Micronutrients",
                            value: breakdown.micronutrientScore,
                            maxValue: 25,
                            icon: "leaf.fill"
                        )
                        ScoreComponentCard(
                            label: "Consistency",
                            value: breakdown.consistencyScore,
                            maxValue: 25,
                            icon: "repeat.circle.fill"
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.15), Color.phylloAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            pulseAnimation = true
        }
    }
}

struct ScoreComponentCard: View {
    let label: String
    let value: Int
    let maxValue: Int
    let icon: String
    
    private var percentage: Double {
        Double(value) / Double(maxValue)
    }
    
    private var color: Color {
        if percentage >= 0.8 { return .green }
        else if percentage >= 0.6 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            Text("\(value)/\(maxValue)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LiveStatCard: View {
    let label: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.phylloTextTertiary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.phylloTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StrengthCard: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct OpportunityCard: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RecommendationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Recommendations", systemImage: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                RecommendationRow(
                    icon: "clock.fill",
                    text: "Next window opens in 45 minutes - plan your meal",
                    priority: .high
                )
                
                RecommendationRow(
                    icon: "drop.fill",
                    text: "Increase water intake by 500ml before dinner",
                    priority: .medium
                )
                
                RecommendationRow(
                    icon: "moon.fill",
                    text: "Last meal 3 hours before sleep for better rest",
                    priority: .low
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .yellow
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(priority.color)
                .frame(width: 32, height: 32)
                .background(priority.color.opacity(0.15))
                .cornerRadius(8)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Chapter: Future Vision (Bonus content for Peak State)

struct FutureVisionSection: View {
    @Binding var animateContent: Bool
    @State private var selectedGoal: FutureGoal? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Chapter Title
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Future Awaits")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("Based on your journey, here's what's possible.")
                    .font(.system(size: 18))
                    .foregroundColor(.phylloTextSecondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Projection Visualization
            ProjectionChart()
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.9)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
            
            // Future Goals
            VStack(spacing: 16) {
                SectionHeader(title: "Choose Your Next Adventure", icon: "flag.fill")
                
                ForEach(futureGoals) { goal in
                    FutureGoalCard(
                        goal: goal,
                        isSelected: selectedGoal?.id == goal.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = selectedGoal?.id == goal.id ? nil : goal
                            }
                        }
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : 30)
                    .animation(.spring(response: 0.8).delay(0.4 + Double(goal.delay) * 0.1), value: animateContent)
                }
            }
            
            // Call to Action
            if selectedGoal != nil {
                CTACard()
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.5), value: selectedGoal)
            }
        }
    }
    
    private var futureGoals: [FutureGoal] {
        [
            FutureGoal(
                id: "master",
                title: "Nutrition Master",
                description: "Achieve 90+ PhylloScore for 30 days",
                timeframe: "8 weeks",
                icon: "crown.fill",
                color: .yellow,
                delay: 0
            ),
            FutureGoal(
                id: "optimizer",
                title: "Energy Optimizer",
                description: "Consistent 8+ energy levels",
                timeframe: "6 weeks",
                icon: "bolt.fill",
                color: .orange,
                delay: 1
            ),
            FutureGoal(
                id: "habit-hero",
                title: "Habit Hero",
                description: "100-day streak achievement",
                timeframe: "88 days to go",
                icon: "flame.fill",
                color: .red,
                delay: 2
            )
        ]
    }
}

struct FutureGoal: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let timeframe: String
    let icon: String
    let color: Color
    let delay: Int
    
    static func == (lhs: FutureGoal, rhs: FutureGoal) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProjectionChart: View {
    @State private var animateChart = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Trajectory")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 16) {
                    LegendItem(color: .phylloAccent, label: "Current Path")
                    LegendItem(color: .orange, label: "Optimized Path")
                }
            }
            
            // Chart
            GeometryReader { geometry in
                ZStack {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                                .background(Color.white.opacity(0.1))
                            if true { Spacer() }
                        }
                    }
                    
                    // Current trajectory
                    Path { path in
                        let points = generateCurrentPath(in: geometry.size)
                        for (index, point) in points.enumerated() {
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .trim(from: 0, to: animateChart ? 1 : 0)
                    .stroke(Color.phylloAccent, lineWidth: 3)
                    .animation(.easeInOut(duration: 1.5), value: animateChart)
                    
                    // Optimized trajectory
                    Path { path in
                        let points = generateOptimizedPath(in: geometry.size)
                        for (index, point) in points.enumerated() {
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .trim(from: 0, to: animateChart ? 1 : 0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                    .animation(.easeInOut(duration: 1.5).delay(0.3), value: animateChart)
                }
            }
            .frame(height: 200)
            
            // Time labels
            HStack {
                Text("Today")
                Spacer()
                Text("30 Days")
                Spacer()
                Text("60 Days")
                Spacer()
                Text("90 Days")
            }
            .font(.system(size: 12))
            .foregroundColor(.phylloTextTertiary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            animateChart = true
        }
    }
    
    private func generateCurrentPath(in size: CGSize) -> [CGPoint] {
        let points = 10
        return (0..<points).map { i in
            let x = size.width * CGFloat(i) / CGFloat(points - 1)
            let progress = CGFloat(i) / CGFloat(points - 1)
            let y = size.height - (size.height * (0.5 + progress * 0.3))
            return CGPoint(x: x, y: y)
        }
    }
    
    private func generateOptimizedPath(in size: CGSize) -> [CGPoint] {
        let points = 10
        return (0..<points).map { i in
            let x = size.width * CGFloat(i) / CGFloat(points - 1)
            let progress = CGFloat(i) / CGFloat(points - 1)
            let y = size.height - (size.height * (0.5 + progress * 0.45))
            return CGPoint(x: x, y: y)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 3)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.phylloTextSecondary)
        }
    }
}

struct FutureGoalCard: View {
    let goal: FutureGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: goal.icon)
                .font(.system(size: 28))
                .foregroundColor(goal.color)
                .frame(width: 56, height: 56)
                .background(goal.color.opacity(0.15))
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(goal.description)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(goal.timeframe)
                        .font(.system(size: 12))
                }
                .foregroundColor(.phylloTextTertiary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? goal.color : .phylloTextTertiary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? goal.color.opacity(0.5) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                )
        )
        .onTapGesture(perform: onTap)
    }
}

struct CTACard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Ready to Level Up?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Select a goal above and we'll create a personalized plan to get you there.")
                .font(.system(size: 16))
                .foregroundColor(.phylloTextSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    Text("Create My Plan")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.phylloAccent)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.2), Color.phylloAccent.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Helper Components

struct InsightCard: View {
    let insight: InsightsEngine.Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: insight.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(insight.type.color)
                    .frame(width: 36, height: 36)
                    .background(insight.type.color.opacity(0.15))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(insight.message)
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            if let evidence = insight.evidence {
                Text(evidence)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
            }
            
            if let action = insight.action {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(insight.type.color)
                    
                    Text(action)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(insight.type.color)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.phylloAccent)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
        .preferredColorScheme(.dark)
}