//
//  DailyScoreDetailView.swift
//  NutriSync
//
//  Detailed daily score view with day navigation and stats breakdown.
//  WHOOP-inspired design with clean statistics (no AI-generated text).
//

import SwiftUI

struct DailyScoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DailyScoreViewModel

    init(initialDate: Date = Date(), scheduleViewModel: ScheduleViewModel) {
        _viewModel = StateObject(wrappedValue: DailyScoreViewModel(
            initialDate: initialDate,
            scheduleViewModel: scheduleViewModel
        ))
    }

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Day Navigation
                    dayNavigationHeader

                    // Large Score Ring
                    scoreRingSection

                    // Stats Breakdown
                    statsBreakdownSection

                    // Window Scores
                    windowScoresSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Daily Score")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Day Navigation

    private var dayNavigationHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.dayLabel)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(viewModel.dateString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.canGoToNextDay ? .white.opacity(0.7) : .white.opacity(0.2))
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.canGoToNextDay)
        }
        .padding(.top, 20)
    }

    // MARK: - Score Section (1-10 format)

    private var scoreRingSection: some View {
        VStack(spacing: 16) {
            if let score = viewModel.dailyScore {
                VStack(spacing: 12) {
                    // Large score text (1-10 format)
                    ScoreText(score: score.displayScore, size: .large, showTotal: true)

                    // Progress bar
                    ScoreProgressBar.fromInternal(score.score)
                        .padding(.horizontal, 40)

                    // Label
                    Text("DAILY SCORE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)
                }
                .padding(.vertical, 20)

                // Daily insight
                if let insight = score.insight {
                    InsightBox(title: "Daily Summary", text: insight, icon: "chart.bar")
                        .padding(.top, 8)
                } else {
                    InsightBox(
                        title: "Daily Summary",
                        text: viewModel.generatedDailyInsight,
                        icon: "chart.bar"
                    )
                    .padding(.top, 8)
                }
            } else {
                // No score yet
                VStack(spacing: 12) {
                    Text("--")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))

                    Text("NO DATA")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    Text("Complete a meal window to see your daily score")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Stats Breakdown Section

    private var statsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCORE FACTORS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)

            VStack(alignment: .leading, spacing: 16) {
                // Factor chips showing contribution
                FactorChipGrid(factors: viewModel.dailyScoreFactors)

                // Detailed breakdown with progress bars
                VStack(spacing: 12) {
                    // Adherence Score
                    DailyStatRow(
                        label: "Window Adherence",
                        displayScore: viewModel.adherenceDisplayScore,
                        detail: "\(viewModel.completedWindows)/\(viewModel.totalWindows) windows"
                    )

                    // Food Quality Score
                    DailyStatRow(
                        label: "Food Quality",
                        displayScore: viewModel.qualityDisplayScore,
                        detail: "Avg meal score: \(viewModel.avgMealScoreFormatted)"
                    )

                    // Timing Score
                    DailyStatRow(
                        label: "Timing",
                        displayScore: viewModel.timingDisplayScore,
                        detail: viewModel.timingDetail
                    )

                    // Consistency Score
                    DailyStatRow(
                        label: "Consistency",
                        displayScore: viewModel.consistencyDisplayScore,
                        detail: viewModel.consistencyDetail
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.nutriSyncElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Window Scores Section

    private var windowScoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WINDOW SCORES")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)

            if viewModel.windowScores.isEmpty {
                Text("No windows for this day")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.windowScores, id: \.windowId) { windowScore in
                        WindowScoreRow(windowScore: windowScore)
                    }
                }
            }
        }
    }

}

// MARK: - Daily Score Header Card (Compact for Focus tab)

struct DailyScoreHeaderCard: View {
    let dailyScore: DailyScore?
    let completedWindows: Int
    let totalWindows: Int
    var onTap: (() -> Void)? = nil

    private var displayScore: Double {
        dailyScore?.displayScore ?? 0.0
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

    private var insightText: String {
        guard dailyScore != nil else {
            return "Complete a window to start tracking"
        }

        if displayScore >= 8.5 {
            return "Outstanding day so far!"
        } else if displayScore >= 7.0 {
            return "Great progress today"
        } else if displayScore >= 5.0 {
            return "Solid effort, keep it up"
        } else {
            return "Room to improve"
        }
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: dailyScore != nil ? CGFloat(displayScore) / 10.0 : 0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    if dailyScore != nil {
                        Text(String(format: "%.1f", displayScore))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("--")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Score")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(insightText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))

                    // Windows progress
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))

                        Text("\(completedWindows)/\(totalWindows) windows")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.nutriSyncElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(scoreColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Window Score Row (1-10 format)

struct WindowScoreRow: View {
    let windowScore: WindowScoreData

    private var displayScore: Double {
        Double(windowScore.score) / 10.0
    }

    var body: some View {
        HStack(spacing: 16) {
            // Score text (1-10 format)
            ScoreText(score: displayScore, size: .small)

            // Window info
            VStack(alignment: .leading, spacing: 4) {
                Text(windowScore.windowName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(windowScore.timeString)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    Text("·")
                        .foregroundColor(.white.opacity(0.4))

                    Text("\(windowScore.consumedCalories) / \(windowScore.targetCalories) cal")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Status indicator
            if windowScore.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.nutriSyncAccent)
            } else if windowScore.isUpcoming {
                Text("upcoming")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nutriSyncElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Daily Stat Row

struct DailyStatRow: View {
    let label: String
    let displayScore: Double  // 1-10 scale
    let detail: String

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
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text(String(format: "%.1f", displayScore))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
            }

            HStack {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(scoreColor)
                            .frame(width: geo.size.width * CGFloat(displayScore) / 10.0, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: displayScore)
                    }
                }
                .frame(height: 4)

                // Detail text
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 100, alignment: .trailing)
            }
        }
    }
}

// MARK: - Window Score Data Model

struct WindowScoreData: Identifiable {
    let id = UUID()
    let windowId: String
    let windowName: String
    let timeString: String
    let score: Int
    let consumedCalories: Int
    let targetCalories: Int
    let purposeColor: Color
    let isCompleted: Bool
    let isUpcoming: Bool
}

// MARK: - View Model

@MainActor
class DailyScoreViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var dailyScore: DailyScore?
    @Published var windowScores: [WindowScoreData] = []

    private let scheduleViewModel: ScheduleViewModel
    private let calendar = Calendar.current

    // Stats computed from daily score
    var completedWindows: Int {
        dailyScore?.completedWindows ?? 0
    }

    var totalWindows: Int {
        dailyScore?.totalWindows ?? windowScores.count
    }

    // MARK: - Display Scores (1-10 scale)

    var adherenceDisplayScore: Double {
        guard let breakdown = dailyScore?.breakdown else {
            // Fallback calculation
            guard totalWindows > 0 else { return 0.0 }
            return Double(completedWindows) / Double(totalWindows) * 10.0
        }
        return breakdown.adherenceDisplayScore
    }

    var qualityDisplayScore: Double {
        guard let breakdown = dailyScore?.breakdown else {
            // Fallback: average meal health scores
            return Double(dailyScore?.averageHealthScore ?? 0) / 10.0
        }
        return breakdown.qualityDisplayScore
    }

    var timingDisplayScore: Double {
        guard let breakdown = dailyScore?.breakdown else {
            // Fallback calculation
            let onTimeWindows = windowScores.filter { $0.isCompleted }.count
            guard totalWindows > 0 else { return 0.0 }
            return Double(onTimeWindows) / Double(totalWindows) * 10.0
        }
        return breakdown.timingDisplayScore
    }

    var consistencyDisplayScore: Double {
        guard let breakdown = dailyScore?.breakdown else {
            // Fallback: calculate from variance
            return 6.5 // Default moderate score
        }
        return breakdown.consistencyDisplayScore
    }

    var avgMealScoreFormatted: String {
        let avg = Double(dailyScore?.averageHealthScore ?? 0) / 10.0
        return String(format: "%.1f", avg)
    }

    var timingDetail: String {
        dailyScore?.breakdown?.timingDetail ?? "Meals within windows"
    }

    var consistencyDetail: String {
        dailyScore?.breakdown?.consistencyDetail ?? "Calorie distribution"
    }

    // MARK: - Factor Chips

    var dailyScoreFactors: [FactorChipData] {
        // Convert scores to factor contributions
        func toContribution(_ score: Double) -> Double {
            // 10 = +2.5, 5 = 0, 0 = -2.5
            return (score - 5.0) / 2.0
        }

        return [
            FactorChipData(label: "Adherence", value: toContribution(adherenceDisplayScore)),
            FactorChipData(label: "Quality", value: toContribution(qualityDisplayScore)),
            FactorChipData(label: "Timing", value: toContribution(timingDisplayScore)),
            FactorChipData(label: "Consistency", value: toContribution(consistencyDisplayScore))
        ]
    }

    // MARK: - Generated Insight

    var generatedDailyInsight: String {
        guard let score = dailyScore else {
            return "Complete a meal window to start tracking your daily score."
        }

        let displayScore = score.displayScore

        if displayScore >= 8.5 {
            return "Outstanding day! You hit \(completedWindows) of \(totalWindows) windows with excellent adherence."
        } else if displayScore >= 7.0 {
            return "Great progress today. \(completedWindows) of \(totalWindows) windows completed with good macro balance."
        } else if displayScore >= 5.0 {
            let weakArea = findWeakestArea()
            return "Solid effort today. Focus on \(weakArea) to improve your score."
        } else {
            let weakArea = findWeakestArea()
            return "Room to improve. \(weakArea) impacted your score the most."
        }
    }

    private func findWeakestArea() -> String {
        let scores = [
            ("window adherence", adherenceDisplayScore),
            ("food quality", qualityDisplayScore),
            ("meal timing", timingDisplayScore),
            ("consistency", consistencyDisplayScore)
        ]
        let weakest = scores.min(by: { $0.1 < $1.1 })
        return weakest?.0 ?? "macro balance"
    }

    // Day navigation
    var dayLabel: String {
        if calendar.isDateInToday(selectedDate) {
            return "TODAY"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "YESTERDAY"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate).uppercased()
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    var canGoToNextDay: Bool {
        !calendar.isDateInToday(selectedDate)
    }

    init(initialDate: Date, scheduleViewModel: ScheduleViewModel) {
        self.selectedDate = initialDate
        self.scheduleViewModel = scheduleViewModel
        loadScoreData()
    }

    func goToPreviousDay() {
        if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
            loadScoreData()
        }
    }

    func goToNextDay() {
        guard canGoToNextDay else { return }
        if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
            loadScoreData()
        }
    }

    private func loadScoreData() {
        // For today, use live data from scheduleViewModel
        if calendar.isDateInToday(selectedDate) {
            loadTodayData()
        } else {
            // For past days, would load from Firebase
            // For now, show empty state
            dailyScore = nil
            windowScores = []
        }
    }

    private func loadTodayData() {
        let windows = scheduleViewModel.mealWindows
        let meals = scheduleViewModel.todaysMeals

        // Calculate daily score
        dailyScore = ScoringService.shared.calculateDailyScore(
            windows: windows,
            meals: meals,
            date: selectedDate
        )

        // Build window score data
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        windowScores = windows.map { window in
            let windowMeals = meals.filter { $0.windowId?.uuidString == window.id }
            let consumedCalories = windowMeals.reduce(0) { $0 + $1.calories }
            let windowScore = window.windowScore?.score ?? 0
            let isPast = window.endTime < Date()
            let hasMeals = !windowMeals.isEmpty

            return WindowScoreData(
                windowId: window.id,
                windowName: window.name,
                timeString: timeFormatter.string(from: window.startTime),
                score: windowScore,
                consumedCalories: consumedCalories,
                targetCalories: window.effectiveCalories,
                purposeColor: window.purpose.color,
                isCompleted: isPast && hasMeals,
                isUpcoming: !isPast
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyScoreDetailView(scheduleViewModel: ScheduleViewModel())
    }
    .preferredColorScheme(.dark)
}
