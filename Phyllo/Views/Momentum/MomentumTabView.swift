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
    @State private var currentChapter: StoryChapter = .beginning
    @State private var animateContent = false
    @State private var expandedInsight: String? = nil
    @State private var phylloScore: InsightsEngine.ScoreBreakdown?
    @State private var micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @State private var insights: [InsightsEngine.Insight] = []
    
    enum StoryChapter: String, CaseIterable {
        case beginning = "The Beginning"
        case journey = "Your Journey"
        case now = "Where You Are"
        case future = "What's Next"
        
        var icon: String {
            switch self {
            case .beginning: return "book.fill"
            case .journey: return "map.fill"
            case .now: return "location.fill"
            case .future: return "arrow.up.forward.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .beginning: return .blue
            case .journey: return .purple
            case .now: return .phylloAccent
            case .future: return .orange
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
                            Group {
                                switch currentChapter {
                                case .beginning:
                                    BeginningChapter(animateContent: $animateContent)
                                case .journey:
                                    JourneyChapter(
                                        animateContent: $animateContent,
                                        expandedInsight: $expandedInsight
                                    )
                                case .now:
                                    NowChapter(
                                        animateContent: $animateContent,
                                        scoreBreakdown: phylloScore,
                                        micronutrientStatus: micronutrientStatus,
                                        insights: insights
                                    )
                                case .future:
                                    FutureChapter(animateContent: $animateContent)
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
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MomentumTabView.StoryChapter.allCases, id: \.self) { chapter in
                ChapterTab(
                    chapter: chapter,
                    isSelected: currentChapter == chapter,
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: chapter.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : chapter.color)
                
                Text(chapter.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .phylloTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? chapter.color : Color.clear)
            )
        }
    }
}

// MARK: - Chapter: The Beginning

struct BeginningChapter: View {
    @Binding var animateContent: Bool
    @StateObject private var mockData = MockDataManager.shared
    
    private let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    
    var body: some View {
        VStack(spacing: 24) {
            // Story Introduction
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
            
            // Starting Stats
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    StartingStatCard(
                        title: "Initial Score",
                        value: "42",
                        subtitle: "Room to grow",
                        icon: "chart.line.uptrend.xyaxis",
                        delay: 0.3
                    )
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
                    
                    StartingStatCard(
                        title: "First Goal",
                        value: mockData.primaryGoal.displayName,
                        subtitle: "Your focus",
                        icon: "target",
                        delay: 0.4
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
            
            // Milestone Timeline
            MilestoneTimeline()
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.8).delay(0.6), value: animateContent)
        }
    }
}

struct StartingStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
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

// MARK: - Chapter: Your Journey

struct JourneyChapter: View {
    @Binding var animateContent: Bool
    @Binding var expandedInsight: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Chapter Title
            VStack(alignment: .leading, spacing: 16) {
                Text("The Path You've Taken")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("Every day tells a story. Let's explore your patterns.")
                    .font(.system(size: 18))
                    .foregroundColor(.phylloTextSecondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Interactive Journey Map
            JourneyMapView()
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.9)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
            
            // Pattern Discoveries
            VStack(spacing: 16) {
                SectionHeader(title: "What We've Discovered", icon: "lightbulb.fill")
                
                ForEach(journeyInsights) { insight in
                    JourneyInsightCard(
                        insight: insight,
                        isExpanded: expandedInsight == insight.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                expandedInsight = expandedInsight == insight.id ? nil : insight.id
                            }
                        }
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : -20)
                    .animation(.spring(response: 0.8).delay(0.4 + Double(insight.delay) * 0.1), value: animateContent)
                }
            }
        }
    }
    
    private var journeyInsights: [JourneyInsight] {
        [
            JourneyInsight(
                id: "weekday-warrior",
                title: "Weekday Warrior",
                summary: "You excel Monday through Friday",
                detail: "Your scores are 23% higher on weekdays. This suggests your routine supports better nutrition choices during the work week.",
                icon: "briefcase.fill",
                color: .blue,
                delay: 0
            ),
            JourneyInsight(
                id: "morning-momentum",
                title: "Morning Momentum",
                summary: "Early meals set your day's tone",
                detail: "Days when you eat breakfast before 9 AM show 15% higher overall scores. Your body responds well to early nutrition.",
                icon: "sunrise.fill",
                color: .orange,
                delay: 1
            ),
            JourneyInsight(
                id: "consistency-key",
                title: "Consistency is Your Superpower",
                summary: "3+ meals = better days",
                detail: "When you log 3 or more meals, your energy ratings average 7.8/10 compared to 5.2/10 on days with fewer meals.",
                icon: "repeat.circle.fill",
                color: .purple,
                delay: 2
            )
        ]
    }
}

struct JourneyInsight: Identifiable {
    let id: String
    let title: String
    let summary: String
    let detail: String
    let icon: String
    let color: Color
    let delay: Int
}

struct JourneyInsightCard: View {
    let insight: JourneyInsight
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: insight.icon)
                    .font(.system(size: 24))
                    .foregroundColor(insight.color)
                    .frame(width: 44, height: 44)
                    .background(insight.color.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(insight.summary)
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.phylloTextTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            if isExpanded {
                Text(insight.detail)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
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
        .onTapGesture(perform: onTap)
    }
}

struct JourneyMapView: View {
    @State private var selectedWeek = 3
    
    let weekData = [
        WeekData(week: 1, avgScore: 58, highlight: "Getting Started"),
        WeekData(week: 2, avgScore: 65, highlight: "Finding Rhythm"),
        WeekData(week: 3, avgScore: 78, highlight: "Breakthrough!"),
        WeekData(week: 4, avgScore: 82, highlight: "Strong Finish")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Visual Journey Path
            GeometryReader { geometry in
                ZStack {
                    // Path line
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepWidth = width / CGFloat(weekData.count - 1)
                        
                        for (index, week) in weekData.enumerated() {
                            let x = CGFloat(index) * stepWidth
                            let y = height - (CGFloat(week.avgScore - 40) / 60.0 * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple, Color.phylloAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 3
                    )
                    
                    // Week nodes
                    ForEach(Array(weekData.enumerated()), id: \.offset) { index, week in
                        let stepWidth = geometry.size.width / CGFloat(weekData.count - 1)
                        let x = CGFloat(index) * stepWidth
                        let y = geometry.size.height - (CGFloat(week.avgScore - 40) / 60.0 * geometry.size.height)
                        
                        WeekNode(
                            week: week,
                            isSelected: selectedWeek == week.week,
                            position: CGPoint(x: x, y: y)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedWeek = week.week
                            }
                        }
                    }
                }
            }
            .frame(height: 150)
            
            // Selected Week Details
            if let selected = weekData.first(where: { $0.week == selectedWeek }) {
                WeekDetailCard(week: selected)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.phylloAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WeekData: Identifiable {
    let id = UUID()
    let week: Int
    let avgScore: Int
    let highlight: String
}

struct WeekNode: View {
    let week: WeekData
    let isSelected: Bool
    let position: CGPoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 40, height: 40)
                .scaleEffect(isSelected ? 1.3 : 1.0)
            
            Circle()
                .stroke(Color.purple, lineWidth: 3)
                .frame(width: 40, height: 40)
                .scaleEffect(isSelected ? 1.3 : 1.0)
            
            Text("W\(week.week)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .position(position)
    }
}

struct WeekDetailCard: View {
    let week: WeekData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Week \(week.week)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(week.highlight)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(week.avgScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                
                Text("Avg Score")
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Chapter: Where You Are Now

struct NowChapter: View {
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
            
            // Current Strengths & Opportunities
            VStack(spacing: 16) {
                SectionHeader(title: "Your Current State", icon: "location.fill")
                
                HStack(spacing: 16) {
                    StrengthCard(
                        title: "Strengths",
                        items: [
                            "Consistent meal timing",
                            "Great protein intake",
                            "Energy levels rising"
                        ],
                        color: .green
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : -20)
                    .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
                    
                    OpportunityCard(
                        title: "Opportunities",
                        items: [
                            "Weekend consistency",
                            "Hydration tracking",
                            "Evening windows"
                        ],
                        color: .orange
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.5), value: animateContent)
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

// MARK: - Chapter: What's Next

struct FutureChapter: View {
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