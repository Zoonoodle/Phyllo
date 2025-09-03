//
//  ProgressTimelineViewModel.swift
//  NutriSync
//
//  View model for historical progress timeline
//

import SwiftUI
import Observation

@Observable
class ProgressTimelineViewModel: ObservableObject {
    var dailyAnalytics: [DailyAnalytics] = []
    var isLoading = false
    var errorMessage: String?
    
    private let dataProvider = DataSourceProvider.shared.provider
    private let calendar = Calendar.current
    
    var weeklyAverage: Double {
        guard !dailyAnalytics.isEmpty else { return 0 }
        let totalScore = dailyAnalytics.reduce(0) { $0 + $1.overallScore }
        return (totalScore / Double(dailyAnalytics.count)) * 100
    }
    
    var trend: TrendDirection {
        guard dailyAnalytics.count >= 3 else { return .stable }
        
        let recentDays = dailyAnalytics.suffix(3)
        let recentAverage = recentDays.reduce(0) { $0 + $1.overallScore } / Double(recentDays.count)
        
        let olderDays = dailyAnalytics.dropLast(3)
        guard !olderDays.isEmpty else { return .stable }
        let olderAverage = olderDays.reduce(0) { $0 + $1.overallScore } / Double(olderDays.count)
        
        let difference = recentAverage - olderAverage
        
        if difference > 0.1 { return .improving }
        else if difference < -0.1 { return .declining }
        else { return .stable }
    }
    
    enum TrendDirection {
        case improving
        case declining
        case stable
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var text: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Needs Focus"
            case .stable: return "Stable"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return Color(hex: "04DE71")
            case .declining: return Color(hex: "FF3B30")
            case .stable: return Color.orange
            }
        }
    }
    
    @MainActor
    func loadLastSevenDays() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            
            if let analytics = try await dataProvider.getDailyAnalyticsRange(from: startDate, to: endDate) {
                self.dailyAnalytics = analytics.sorted { $0.date < $1.date }
            } else {
                self.dailyAnalytics = generateMockData()
            }
        } catch {
            errorMessage = error.localizedDescription
            self.dailyAnalytics = generateMockData()
        }
        
        isLoading = false
    }
    
    func calculateDailyScore(for analytics: DailyAnalytics) -> Double {
        return analytics.overallScore
    }
    
    private func generateMockData() -> [DailyAnalytics] {
        var analytics: [DailyAnalytics] = []
        
        for dayOffset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            let isToday = dayOffset == 0
            let mockData = DailyAnalytics(
                date: date,
                mealsLogged: isToday ? 2 : Int.random(in: 3...5),
                targetMeals: 5,
                timingScore: isToday ? 1.0 : Double.random(in: 0.6...1.0),
                nutrientScore: isToday ? 0.19 : Double.random(in: 0.4...0.9),
                adherenceScore: isToday ? 0.34 : Double.random(in: 0.5...0.95),
                windowsCompleted: isToday ? 2 : Int.random(in: 3...5),
                totalWindows: 5,
                caloriesConsumed: isToday ? 821 : Int.random(in: 1800...2600),
                targetCalories: 2400
            )
            
            analytics.append(mockData)
        }
        
        return analytics
    }
}