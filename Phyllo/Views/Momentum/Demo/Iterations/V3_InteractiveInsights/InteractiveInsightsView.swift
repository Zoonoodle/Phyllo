//
//  InteractiveInsightsView.swift
//  Phyllo - Momentum Redesign V3
//
//  Created on 1/31/25.
//
//  This is V3 of the Momentum tab redesign, focusing on interactive
//  data exploration with gestures, filters, and dynamic visualizations.
//

import SwiftUI
import Charts

struct InteractiveInsightsView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedMetric: MetricType = .phylloScore
    @State private var timeRange: TimeRange = .week
    @State private var showFilters = false
    @State private var selectedInsight: InsightType? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    enum MetricType: String, CaseIterable {
        case phylloScore = "PhylloScore"
        case energy = "Energy"
        case consistency = "Consistency"
        case macros = "Macros"
        
        var icon: String {
            switch self {
            case .phylloScore: return "chart.line.uptrend.xyaxis"
            case .energy: return "bolt.fill"
            case .consistency: return "clock.fill"
            case .macros: return "chart.pie.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .phylloScore: return .phylloAccent
            case .energy: return .yellow
            case .consistency: return .blue
            case .macros: return .purple
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    enum InsightType: String, CaseIterable {
        case patterns = "Patterns"
        case correlations = "Correlations"
        case predictions = "Predictions"
        case recommendations = "Actions"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation bar
                    PhylloNavigationBar(
                        title: "Insights Lab",
                        showSettingsButton: true,
                        onSettingsTap: {
                            showDeveloperDashboard = true
                        }
                    )
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Interactive Controls
                            VStack(spacing: 16) {
                                // Metric Selector
                                MetricSelector(selectedMetric: $selectedMetric)
                                    .padding(.horizontal)
                                
                                // Time Range and Filters
                                HStack {
                                    TimeRangeSelector(timeRange: $timeRange)
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            showFilters.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "line.3.horizontal.decrease.circle")
                                            Text("Filters")
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(showFilters ? .black : .phylloTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(showFilters ? Color.phylloAccent : Color.phylloElevated)
                                        .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 20)
                            
                            // Filter Panel
                            if showFilters {
                                FilterPanel()
                                    .padding(.horizontal)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Interactive Chart
                            InteractiveChart(
                                metric: selectedMetric,
                                timeRange: timeRange,
                                dragOffset: $dragOffset,
                                isDragging: $isDragging
                            )
                            .padding(.horizontal)
                            
                            // Insight Cards
                            InsightTabs(selectedInsight: $selectedInsight)
                                .padding(.horizontal)
                            
                            // Dynamic Insight Content
                            if let insight = selectedInsight {
                                InsightContent(type: insight, metric: selectedMetric)
                                    .padding(.horizontal)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                            
                            // AI Assistant
                            AIAssistantCard(metric: selectedMetric)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Metric Selector

struct MetricSelector: View {
    @Binding var selectedMetric: InteractiveInsightsView.MetricType
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(InteractiveInsightsView.MetricType.allCases, id: \.self) { metric in
                MetricButton(
                    metric: metric,
                    isSelected: selectedMetric == metric,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMetric = metric
                        }
                    }
                )
            }
        }
    }
}

struct MetricButton: View {
    let metric: InteractiveInsightsView.MetricType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? metric.color : Color.phylloElevated)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: metric.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .black : metric.color)
                }
                
                Text(metric.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .phylloTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Time Range Selector

struct TimeRangeSelector: View {
    @Binding var timeRange: InteractiveInsightsView.TimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(InteractiveInsightsView.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        timeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(timeRange == range ? .black : .phylloTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            timeRange == range ? Color.phylloAccent : Color.clear
                        )
                }
            }
        }
        .background(Color.phylloElevated)
        .cornerRadius(20)
    }
}

// MARK: - Filter Panel

struct FilterPanel: View {
    @State private var includeWeekends = true
    @State private var minScore = 0.0
    @State private var selectedGoals: Set<String> = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Weekend Filter
            HStack {
                Label("Include Weekends", systemImage: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                Spacer()
                
                Toggle("", isOn: $includeWeekends)
                    .labelsHidden()
                    .tint(.phylloAccent)
            }
            
            // Score Filter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Minimum Score", systemImage: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(minScore))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Slider(value: $minScore, in: 0...100, step: 10)
                    .tint(.phylloAccent)
            }
            
            // Goal Filter
            VStack(alignment: .leading, spacing: 8) {
                Label("Filter by Goals", systemImage: "target")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Weight Loss", "Muscle Gain", "Better Sleep", "Overall Health"], id: \.self) { goal in
                            FilterChip(
                                title: goal,
                                isSelected: selectedGoals.contains(goal),
                                action: {
                                    if selectedGoals.contains(goal) {
                                        selectedGoals.remove(goal)
                                    } else {
                                        selectedGoals.insert(goal)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.phylloElevated)
        .cornerRadius(16)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .black : .phylloTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.phylloAccent : Color.white.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - Interactive Chart

struct InteractiveChart: View {
    let metric: InteractiveInsightsView.MetricType
    let timeRange: InteractiveInsightsView.TimeRange
    @Binding var dragOffset: CGSize
    @Binding var isDragging: Bool
    @State private var selectedDataPoint: DataPoint? = nil
    @State private var chartData: [DataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Tap and drag to explore")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextTertiary)
                }
                
                Spacer()
                
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatValue(selected.value, for: metric))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(metric.color)
                        
                        Text(formatDate(selected.date))
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
            
            // Interactive Chart View
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [metric.color.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Chart
                    if #available(iOS 16.0, *) {
                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(metric.color)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [metric.color.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            if selectedDataPoint?.id == point.id {
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(metric.color)
                                .symbolSize(150)
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color.phylloTextTertiary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color.phylloTextTertiary)
                                AxisGridLine()
                                    .foregroundStyle(Color.white.opacity(0.1))
                            }
                        }
                    } else {
                        // Fallback for older iOS versions
                        CustomChartView(
                            data: chartData,
                            color: metric.color,
                            selectedPoint: $selectedDataPoint
                        )
                    }
                    
                    // Gesture overlay
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                    
                                    // Find nearest data point
                                    let xPosition = value.location.x
                                    let index = Int((xPosition / geometry.size.width) * CGFloat(chartData.count))
                                    if index >= 0 && index < chartData.count {
                                        selectedDataPoint = chartData[index]
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    dragOffset = .zero
                                }
                        )
                }
            }
            .frame(height: 200)
            .padding(.vertical, 8)
            
            // Quick Stats
            HStack(spacing: 16) {
                QuickChartStat(
                    label: "Average",
                    value: calculateAverage(),
                    color: metric.color
                )
                
                QuickChartStat(
                    label: "Trend",
                    value: calculateTrend(),
                    color: trendColor()
                )
                
                QuickChartStat(
                    label: "Best",
                    value: "\(Int(chartData.max(by: { $0.value < $1.value })?.value ?? 0))",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(24)
        .onAppear {
            generateChartData()
        }
        .onChange(of: timeRange) { _, _ in
            generateChartData()
        }
        .onChange(of: metric) { _, _ in
            generateChartData()
        }
    }
    
    private func generateChartData() {
        chartData = (0..<timeRange.days).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let baseValue: Double
            
            switch metric {
            case .phylloScore:
                baseValue = 75 + Double.random(in: -20...25)
            case .energy:
                baseValue = 6.5 + Double.random(in: -2...3)
            case .consistency:
                baseValue = 0.7 + Double.random(in: -0.3...0.3)
            case .macros:
                baseValue = 0.8 + Double.random(in: -0.2...0.2)
            }
            
            return DataPoint(
                date: date,
                value: min(100, max(0, baseValue * (metric == .energy ? 10 : metric == .consistency || metric == .macros ? 100 : 1)))
            )
        }.reversed()
    }
    
    private func formatValue(_ value: Double, for metric: InteractiveInsightsView.MetricType) -> String {
        switch metric {
        case .phylloScore:
            return "\(Int(value))"
        case .energy:
            return String(format: "%.1f", value / 10)
        case .consistency, .macros:
            return "\(Int(value))%"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func calculateAverage() -> String {
        let avg = chartData.reduce(0) { $0 + $1.value } / Double(chartData.count)
        return formatValue(avg, for: metric)
    }
    
    private func calculateTrend() -> String {
        guard chartData.count > 1 else { return "→" }
        let firstHalf = Array(chartData.prefix(chartData.count / 2))
        let secondHalf = Array(chartData.suffix(chartData.count / 2))
        
        let firstAvg = firstHalf.reduce(0) { $0 + $1.value } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.value } / Double(secondHalf.count)
        
        let difference = ((secondAvg - firstAvg) / firstAvg) * 100
        
        if abs(difference) < 5 {
            return "→"
        } else if difference > 0 {
            return "↑\(Int(difference))%"
        } else {
            return "↓\(Int(abs(difference)))%"
        }
    }
    
    private func trendColor() -> Color {
        let trend = calculateTrend()
        if trend.contains("↑") {
            return .green
        } else if trend.contains("↓") {
            return .red
        } else {
            return .orange
        }
    }
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct QuickChartStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Custom chart for older iOS versions
struct CustomChartView: View {
    let data: [DataPoint]
    let color: Color
    @Binding var selectedPoint: DataPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Line path
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let maxValue = data.map { $0.value }.max() ?? 100
                    let minValue = data.map { $0.value }.min() ?? 0
                    let range = maxValue - minValue
                    
                    for (index, point) in data.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geometry.size.height - (geometry.size.height * (point.value - minValue) / range)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 3)
                
                // Selected point
                if let selected = selectedPoint,
                   let index = data.firstIndex(where: { $0.id == selected.id }) {
                    let maxValue = data.map { $0.value }.max() ?? 100
                    let minValue = data.map { $0.value }.min() ?? 0
                    let range = maxValue - minValue
                    
                    let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geometry.size.height - (geometry.size.height * (selected.value - minValue) / range)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Insight Tabs

struct InsightTabs: View {
    @Binding var selectedInsight: InteractiveInsightsView.InsightType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InteractiveInsightsView.InsightType.allCases, id: \.self) { insight in
                    InsightTab(
                        type: insight,
                        isSelected: selectedInsight == insight,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedInsight = selectedInsight == insight ? nil : insight
                            }
                        }
                    )
                }
            }
        }
    }
}

struct InsightTab: View {
    let type: InteractiveInsightsView.InsightType
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch type {
        case .patterns: return "waveform"
        case .correlations: return "link"
        case .predictions: return "arrow.up.forward"
        case .recommendations: return "lightbulb"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .phylloTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.phylloAccent : Color.phylloElevated)
            .cornerRadius(20)
        }
    }
}

// MARK: - Insight Content

struct InsightContent: View {
    let type: InteractiveInsightsView.InsightType
    let metric: InteractiveInsightsView.MetricType
    
    var body: some View {
        VStack(spacing: 16) {
            switch type {
            case .patterns:
                PatternInsights(metric: metric)
            case .correlations:
                CorrelationInsights(metric: metric)
            case .predictions:
                PredictionInsights(metric: metric)
            case .recommendations:
                RecommendationInsights(metric: metric)
            }
        }
    }
}

struct PatternInsights: View {
    let metric: InteractiveInsightsView.MetricType
    @State private var expandedPattern: String? = nil
    
    var patterns: [(id: String, title: String, description: String, strength: Double)] {
        switch metric {
        case .phylloScore:
            return [
                ("weekly", "Weekly Cycle", "Scores peak mid-week, dip on weekends", 0.85),
                ("meal-timing", "Meal Timing Impact", "Early meals correlate with +12% higher scores", 0.72),
                ("streak-effect", "Streak Momentum", "3+ day streaks boost next day by 8 points", 0.68)
            ]
        case .energy:
            return [
                ("morning", "Morning Boost", "Breakfast before 9 AM = +1.5 energy points", 0.90),
                ("afternoon", "Afternoon Dip", "3 PM energy drops by 2.1 points on average", 0.78),
                ("protein", "Protein Power", "High protein lunches prevent afternoon crashes", 0.65)
            ]
        case .consistency:
            return [
                ("weekday", "Weekday Warrior", "85% consistency Mon-Fri vs 62% weekends", 0.88),
                ("planning", "Planning Pays", "Pre-logged meals have 94% completion rate", 0.92),
                ("window", "Window Success", "Morning windows hit 78% more often", 0.70)
            ]
        case .macros:
            return [
                ("balance", "Macro Balance", "Best days: 40% carbs, 30% protein, 30% fat", 0.82),
                ("timing", "Carb Timing", "Pre-workout carbs improve performance metrics", 0.75),
                ("protein", "Protein Distribution", "Even distribution beats end-loading", 0.69)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discovered Patterns")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(patterns, id: \.id) { pattern in
                PatternCard(
                    title: pattern.title,
                    description: pattern.description,
                    strength: pattern.strength,
                    isExpanded: expandedPattern == pattern.id,
                    color: metric.color,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedPattern = expandedPattern == pattern.id ? nil : pattern.id
                        }
                    }
                )
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
    }
}

struct PatternCard: View {
    let title: String
    let description: String
    let strength: Double
    let isExpanded: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !isExpanded {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Strength indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: strength)
                        .stroke(color, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(strength * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                    
                    // Pattern visualization
                    PatternVisualization(type: title, color: color)
                        .frame(height: 80)
                        .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .onTapGesture(perform: onTap)
    }
}

struct PatternVisualization: View {
    let type: String
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if type.contains("Weekly") {
                // Weekly pattern bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(weekdayHeight(day)))
                                .frame(height: geometry.size.height * weekdayHeight(day))
                            
                            Text(day)
                                .font(.system(size: 10))
                                .foregroundColor(.phylloTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Generic wave pattern
                InsightWaveShape()
                    .stroke(color, lineWidth: 2)
            }
        }
    }
    
    private func weekdayHeight(_ day: String) -> Double {
        switch day {
        case "M": return 0.7
        case "T": return 0.8
        case "W": return 0.9
        case "T": return 0.85
        case "F": return 0.75
        case "S": return 0.6
        case "S": return 0.55
        default: return 0.5
        }
    }
}

struct InsightWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let wavelength = rect.width / 3
        let amplitude = rect.height / 3
        let midY = rect.height / 2
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = midY + amplitude * sin(2 * .pi * x / wavelength)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct CorrelationInsights: View {
    let metric: InteractiveInsightsView.MetricType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Correlations Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Correlation matrix visualization
            CorrelationMatrix(metric: metric)
            
            // Key correlations
            VStack(spacing: 12) {
                CorrelationRow(
                    factor1: "\(metric.rawValue)",
                    factor2: "Sleep Quality",
                    correlation: 0.73,
                    insight: "Better \(metric.rawValue.lowercased()) leads to improved sleep"
                )
                
                CorrelationRow(
                    factor1: "\(metric.rawValue)",
                    factor2: "Meal Timing",
                    correlation: 0.68,
                    insight: "Consistent timing boosts \(metric.rawValue.lowercased())"
                )
                
                CorrelationRow(
                    factor1: "\(metric.rawValue)",
                    factor2: "Hydration",
                    correlation: 0.52,
                    insight: "Moderate positive relationship observed"
                )
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
    }
}

struct CorrelationMatrix: View {
    let metric: InteractiveInsightsView.MetricType
    
    let factors = ["Sleep", "Energy", "Timing", "Hydration", "Exercise"]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(factors, id: \.self) { factor in
                HStack(spacing: 8) {
                    Text(factor)
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextSecondary)
                        .frame(width: 60, alignment: .trailing)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(correlationColor(for: Double.random(in: 0.3...0.9)))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func correlationColor(for value: Double) -> Color {
        if value > 0.7 {
            return metric.color
        } else if value > 0.5 {
            return metric.color.opacity(0.6)
        } else {
            return metric.color.opacity(0.3)
        }
    }
}

struct CorrelationRow: View {
    let factor1: String
    let factor2: String
    let correlation: Double
    let insight: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(factor1)
                        .font(.system(size: 14, weight: .medium))
                    
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    Text(factor2)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                
                Text(insight)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            Spacer()
            
            Text("\(Int(correlation * 100))%")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(correlationStrengthColor(correlation))
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func correlationStrengthColor(_ value: Double) -> Color {
        if value > 0.7 {
            return .green
        } else if value > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct PredictionInsights: View {
    let metric: InteractiveInsightsView.MetricType
    @State private var selectedTimeframe = 0
    
    let timeframes = ["Next Week", "Next Month", "Next Quarter"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Predictions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(0..<timeframes.count, id: \.self) { index in
                        Text(timeframes[index])
                            .tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Prediction visualization
            PredictionChart(metric: metric, timeframe: timeframes[selectedTimeframe])
            
            // Confidence indicators
            VStack(spacing: 12) {
                PredictionRow(
                    scenario: "Continue Current Path",
                    prediction: predictValue(for: metric, scenario: .current),
                    confidence: 0.82,
                    trend: .neutral
                )
                
                PredictionRow(
                    scenario: "With Improvements",
                    prediction: predictValue(for: metric, scenario: .improved),
                    confidence: 0.75,
                    trend: .positive
                )
                
                PredictionRow(
                    scenario: "If Patterns Break",
                    prediction: predictValue(for: metric, scenario: .declined),
                    confidence: 0.68,
                    trend: .negative
                )
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
    }
    
    enum Scenario {
        case current, improved, declined
    }
    
    private func predictValue(for metric: InteractiveInsightsView.MetricType, scenario: Scenario) -> String {
        switch metric {
        case .phylloScore:
            switch scenario {
            case .current: return "82"
            case .improved: return "91"
            case .declined: return "68"
            }
        case .energy:
            switch scenario {
            case .current: return "7.2"
            case .improved: return "8.5"
            case .declined: return "5.8"
            }
        case .consistency:
            switch scenario {
            case .current: return "78%"
            case .improved: return "88%"
            case .declined: return "62%"
            }
        case .macros:
            switch scenario {
            case .current: return "75%"
            case .improved: return "85%"
            case .declined: return "60%"
            }
        }
    }
}

struct PredictionChart: View {
    let metric: InteractiveInsightsView.MetricType
    let timeframe: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Confidence bands
                Path { path in
                    // Upper confidence band
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.1),
                        control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.25),
                        control2: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.15)
                    )
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.4))
                    path.addCurve(
                        to: CGPoint(x: 0, y: geometry.size.height * 0.6),
                        control1: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.45),
                        control2: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.55)
                    )
                    path.closeSubpath()
                }
                .fill(metric.color.opacity(0.2))
                
                // Prediction line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.45))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.25),
                        control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4),
                        control2: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.3)
                    )
                }
                .stroke(metric.color, lineWidth: 3)
                
                // Current position marker
                Circle()
                    .fill(metric.color)
                    .frame(width: 8, height: 8)
                    .position(x: 0, y: geometry.size.height * 0.45)
            }
        }
        .frame(height: 120)
        .padding(.vertical, 8)
    }
}

struct PredictionRow: View {
    let scenario: String
    let prediction: String
    let confidence: Double
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
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .neutral: return "equal.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: trend.icon)
                .font(.system(size: 20))
                .foregroundColor(trend.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text("Confidence:")
                        .font(.system(size: 12))
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.phylloTextSecondary)
            }
            
            Spacer()
            
            Text(prediction)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(trend.color)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct RecommendationInsights: View {
    let metric: InteractiveInsightsView.MetricType
    @State private var acceptedRecommendations: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Priority actions
            ForEach(recommendations(for: metric), id: \.id) { recommendation in
                ActionCard(
                    recommendation: recommendation,
                    isAccepted: acceptedRecommendations.contains(recommendation.id),
                    onAccept: {
                        withAnimation(.spring(response: 0.3)) {
                            if acceptedRecommendations.contains(recommendation.id) {
                                acceptedRecommendations.remove(recommendation.id)
                            } else {
                                acceptedRecommendations.insert(recommendation.id)
                            }
                        }
                    }
                )
            }
            
            // Impact preview
            if !acceptedRecommendations.isEmpty {
                ImpactPreview(
                    acceptedCount: acceptedRecommendations.count,
                    metric: metric
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
    }
    
    private func recommendations(for metric: InteractiveInsightsView.MetricType) -> [Recommendation] {
        switch metric {
        case .phylloScore:
            return [
                Recommendation(
                    id: "meal-timing",
                    title: "Optimize Meal Timing",
                    description: "Eat breakfast 30 min earlier",
                    impact: "+5 points",
                    effort: .low,
                    category: .timing
                ),
                Recommendation(
                    id: "protein-dist",
                    title: "Distribute Protein",
                    description: "Split protein across 4 meals",
                    impact: "+8 points",
                    effort: .medium,
                    category: .nutrition
                ),
                Recommendation(
                    id: "weekend-plan",
                    title: "Weekend Planning",
                    description: "Pre-log Saturday meals",
                    impact: "+12 points",
                    effort: .low,
                    category: .planning
                )
            ]
        case .energy:
            return [
                Recommendation(
                    id: "hydration",
                    title: "Morning Hydration",
                    description: "500ml water before breakfast",
                    impact: "+0.8 energy",
                    effort: .low,
                    category: .hydration
                ),
                Recommendation(
                    id: "afternoon-snack",
                    title: "Strategic Snacking",
                    description: "Protein snack at 3 PM",
                    impact: "+1.2 energy",
                    effort: .medium,
                    category: .nutrition
                ),
                Recommendation(
                    id: "sleep-window",
                    title: "Sleep Window",
                    description: "Last meal 3h before bed",
                    impact: "+1.5 energy",
                    effort: .high,
                    category: .timing
                )
            ]
        case .consistency:
            return [
                Recommendation(
                    id: "reminders",
                    title: "Smart Reminders",
                    description: "Enable meal window alerts",
                    impact: "+15% consistency",
                    effort: .low,
                    category: .planning
                ),
                Recommendation(
                    id: "batch-prep",
                    title: "Batch Preparation",
                    description: "Sunday meal prep routine",
                    impact: "+22% consistency",
                    effort: .high,
                    category: .planning
                ),
                Recommendation(
                    id: "flexibility",
                    title: "Flexible Windows",
                    description: "Allow 30min buffer time",
                    impact: "+10% consistency",
                    effort: .low,
                    category: .timing
                )
            ]
        case .macros:
            return [
                Recommendation(
                    id: "tracking",
                    title: "Precise Tracking",
                    description: "Weigh protein portions",
                    impact: "+18% accuracy",
                    effort: .medium,
                    category: .nutrition
                ),
                Recommendation(
                    id: "balance",
                    title: "Macro Templates",
                    description: "Use balanced meal templates",
                    impact: "+12% balance",
                    effort: .low,
                    category: .nutrition
                ),
                Recommendation(
                    id: "timing",
                    title: "Carb Cycling",
                    description: "Higher carbs on workout days",
                    impact: "+15% optimization",
                    effort: .high,
                    category: .timing
                )
            ]
        }
    }
}

struct Recommendation: Identifiable {
    let id: String
    let title: String
    let description: String
    let impact: String
    let effort: Effort
    let category: Category
    
    enum Effort {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var label: String {
            switch self {
            case .low: return "Easy"
            case .medium: return "Moderate"
            case .high: return "Challenging"
            }
        }
    }
    
    enum Category {
        case timing, nutrition, planning, hydration
        
        var icon: String {
            switch self {
            case .timing: return "clock.fill"
            case .nutrition: return "fork.knife"
            case .planning: return "calendar"
            case .hydration: return "drop.fill"
            }
        }
    }
}

struct ActionCard: View {
    let recommendation: Recommendation
    let isAccepted: Bool
    let onAccept: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: recommendation.category.icon)
                .font(.system(size: 24))
                .foregroundColor(.phylloAccent)
                .frame(width: 44, height: 44)
                .background(Color.phylloAccent.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("• \(recommendation.effort.label)")
                        .font(.system(size: 12))
                        .foregroundColor(recommendation.effort.color)
                }
                
                Text(recommendation.description)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                HStack(spacing: 8) {
                    Label(recommendation.impact, systemImage: "arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: onAccept) {
                Image(systemName: isAccepted ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isAccepted ? .green : .phylloTextTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isAccepted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct ImpactPreview: View {
    let acceptedCount: Int
    let metric: InteractiveInsightsView.MetricType
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Expected Impact")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(acceptedCount) actions selected • \(estimatedImpact())")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Start Plan")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.phylloAccent)
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.2), Color.phylloAccent.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    private func estimatedImpact() -> String {
        switch metric {
        case .phylloScore:
            return "+\(acceptedCount * 8) points potential"
        case .energy:
            return "+\(acceptedCount).2 energy boost"
        case .consistency:
            return "+\(acceptedCount * 15)% improvement"
        case .macros:
            return "+\(acceptedCount * 12)% accuracy"
        }
    }
}

// MARK: - AI Assistant

struct AIAssistantCard: View {
    let metric: InteractiveInsightsView.MetricType
    @State private var showingAssistant = false
    @State private var userQuestion = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Insights Assistant")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Ask me anything about your \(metric.rawValue.lowercased()) data")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showingAssistant.toggle()
                    }
                }) {
                    Image(systemName: showingAssistant ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.phylloTextTertiary)
                }
            }
            
            if showingAssistant {
                VStack(spacing: 12) {
                    // Suggested questions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedQuestions(for: metric), id: \.self) { question in
                                Button(action: {
                                    userQuestion = question
                                }) {
                                    Text(question)
                                        .font(.system(size: 12))
                                        .foregroundColor(.phylloTextSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    // Input field
                    HStack {
                        TextField("Ask about your data...", text: $userQuestion)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                        
                        Button(action: {}) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.phylloAccent)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func suggestedQuestions(for metric: InteractiveInsightsView.MetricType) -> [String] {
        switch metric {
        case .phylloScore:
            return [
                "What affects my score most?",
                "How can I reach 90+?",
                "Why do weekends differ?"
            ]
        case .energy:
            return [
                "When is my energy lowest?",
                "What foods boost energy?",
                "How to avoid crashes?"
            ]
        case .consistency:
            return [
                "What breaks my streaks?",
                "Best time for habits?",
                "How to stay consistent?"
            ]
        case .macros:
            return [
                "Am I hitting targets?",
                "Best macro timing?",
                "How to balance better?"
            ]
        }
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    InteractiveInsightsView(showDeveloperDashboard: $showDeveloperDashboard)
        .preferredColorScheme(.dark)
}