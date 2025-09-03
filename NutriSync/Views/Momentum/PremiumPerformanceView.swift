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
                    VStack(spacing: 20) {
                        headerSection
                        
                        PremiumActivityRings(
                            timingScore: calculateTimingScore(),
                            nutrientScore: calculateNutrientScore(),
                            adherenceScore: calculateAdherenceScore()
                        )
                        .padding(.top, 8)
                        
                        RingLabelsView(
                            timingScore: calculateTimingScore(),
                            nutrientScore: calculateNutrientScore(),
                            adherenceScore: calculateAdherenceScore()
                        )
                        .padding(.horizontal, 40)
                        .padding(.bottom, 8)
                        
                        TodaysSummaryCard()
                            .padding(.horizontal, 20)
                            .environmentObject(viewModel)
                        
                        ProgressTimelineSection(viewModel: timelineVM)
                            .padding(.bottom, 8)
                        
                        QuickStatsGrid(
                            streak: currentStreak,
                            fastingHours: calculateFastingHours(),
                            weeklyAverage: timelineVM.weeklyAverage,
                            trend: timelineVM.trend
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100) // Extra padding for tab bar visibility
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
        // View model loads data automatically in init
        
        await timelineLoad
        await streakLoad
        // Data loading handled by view model
        
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
        guard !viewModel.todaysMeals.isEmpty else { return 0 }
        
        let sortedMeals = viewModel.todaysMeals.sorted { $0.timestamp < $1.timestamp }
        guard let lastMeal = sortedMeals.last else { return 0 }
        
        let hoursSinceLastMeal = Date().timeIntervalSince(lastMeal.timestamp) / 3600
        return max(0, hoursSinceLastMeal)
    }
    
    private func calculateTimingScore() -> Double {
        // Calculate based on how many windows were consumed on time
        guard !viewModel.mealWindows.isEmpty else { return 0 }
        
        let windowsWithMeals = viewModel.mealWindows.filter { window in
            !viewModel.mealsInWindow(window).isEmpty
        }.count
        
        return Double(windowsWithMeals) / Double(viewModel.mealWindows.count)
    }
    
    private func calculateNutrientScore() -> Double {
        // Calculate based on macros achieved
        let calorieProgress = min(Double(viewModel.totalCalories) / Double(viewModel.dailyCalorieTarget), 1.0)
        let proteinProgress = min(Double(viewModel.totalProtein) / Double(viewModel.dailyProteinTarget), 1.0)
        
        return (calorieProgress + proteinProgress) / 2.0
    }
    
    private func calculateAdherenceScore() -> Double {
        // Calculate based on windows completed
        guard !viewModel.mealWindows.isEmpty else { return 0 }
        
        let completedWindows = viewModel.mealWindows.filter { window in
            !viewModel.mealsInWindow(window).isEmpty
        }.count
        
        return Double(completedWindows) / Double(viewModel.mealWindows.count)
    }
}

#Preview {
    PremiumPerformanceView()
}