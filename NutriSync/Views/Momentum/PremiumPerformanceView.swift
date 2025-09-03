//
//  PremiumPerformanceView.swift
//  NutriSync
//
//  Premium performance view with Apple Watch-quality rings and timeline
//

import SwiftUI

struct PremiumPerformanceView: View {
    @StateObject private var viewModel = NutritionDashboardViewModel()
    @StateObject private var timelineVM = ProgressTimelineViewModel()
    
    @State private var currentStreak: Int = 0
    @State private var fastingHours: Double = 0
    @State private var isLoadingStreak = false
    
    private var dataProvider: DataProvider {
        DataSourceProvider.shared.provider
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        
                        PremiumActivityRings(
                            timingScore: viewModel.timingPercentage / 100,
                            nutrientScore: viewModel.nutrientPercentage / 100,
                            adherenceScore: viewModel.adherencePercentage / 100
                        )
                        .padding(.top, 20)
                        
                        RingLabelsView(
                            timingScore: viewModel.timingPercentage / 100,
                            nutrientScore: viewModel.nutrientPercentage / 100,
                            adherenceScore: viewModel.adherencePercentage / 100
                        )
                        .padding(.horizontal, 40)
                        
                        TodaysSummaryCard()
                            .padding(.horizontal, 20)
                            .environmentObject(viewModel)
                        
                        ProgressTimelineSection(viewModel: timelineVM)
                        
                        QuickStatsGrid(
                            streak: currentStreak,
                            fastingHours: calculateFastingHours(),
                            weeklyAverage: timelineVM.weeklyAverage,
                            trend: timelineVM.trend
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Performance")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isLoadingStreak {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
        }
    }
    
    @MainActor
    private func loadData() async {
        isLoadingStreak = true
        
        async let timelineLoad: () = timelineVM.loadLastSevenDays()
        async let streakLoad: () = loadStreak()
        async let mealsLoad: () = viewModel.loadMeals()
        
        await timelineLoad
        await streakLoad
        await mealsLoad
        
        isLoadingStreak = false
    }
    
    @MainActor
    private func loadStreak() async {
        do {
            let (current, _) = try await dataProvider.calculateStreak(until: Date())
            self.currentStreak = current
        } catch {
            print("Failed to load streak: \(error)")
            self.currentStreak = 0
        }
    }
    
    private func calculateFastingHours() -> Double {
        guard !viewModel.meals.isEmpty else { return 0 }
        
        let sortedMeals = viewModel.meals.sorted { $0.timestamp < $1.timestamp }
        guard let lastMeal = sortedMeals.last else { return 0 }
        
        let hoursSinceLastMeal = Date().timeIntervalSince(lastMeal.timestamp) / 3600
        return max(0, hoursSinceLastMeal)
    }
}

#Preview {
    PremiumPerformanceView()
}