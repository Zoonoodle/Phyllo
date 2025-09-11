//
//  DayDetailView.swift
//  NutriSync
//
//  Comprehensive daily nutrition overview with progressive loading
//

import SwiftUI

struct DayDetailView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var showDayDetail: Bool
    @State private var animateContent = false
    @State private var isLoadingDetails = true
    @State private var micronutrientStatus: [ScheduleViewModel.MicronutrientStatus] = []
    @State private var foodTimeline: [ScheduleViewModel.TimelineEntry] = []
    @Environment(\.dismiss) private var dismiss
    
    // Progressive loading states
    @State private var basicDataLoaded = false
    @State private var dayPurposeLoaded = false
    @State private var micronutrientsLoaded = false
    @State private var timelineLoaded = false
    
    private var dailySummary: ScheduleViewModel.DailyNutritionSummary {
        viewModel.aggregateDailyNutrition()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                // Scrollable content with progressive loading
                ScrollView {
                    VStack(spacing: 24) {
                        // Phase 1: Basic stats (immediate)
                        if basicDataLoaded {
                            DailyNutriSyncRing(dailySummary: dailySummary)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            // Loading placeholder for ring
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.phylloCard)
                                .frame(height: 200)
                                .shimmer()
                        }
                        
                        // Phase 2: Day Purpose (0.5s delay)
                        if dayPurposeLoaded, let dayPurpose = dailySummary.dayPurpose {
                            DayPurposeCard(dayPurpose: dayPurpose)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Phase 3: Food Timeline (1s delay)
                        if timelineLoaded && !foodTimeline.isEmpty {
                            ChronologicalFoodList(foodTimeline: foodTimeline)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Phase 4: Micronutrients (1.5s delay)
                        if micronutrientsLoaded && !micronutrientStatus.isEmpty {
                            DailyMicronutrientStatusView(micronutrientStatus: micronutrientStatus)
                                .padding(.bottom, 32)
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, 10) // Increased padding to avoid Dynamic Island/notch
                    .padding(.horizontal, 32) // Add consistent horizontal padding to entire content
                }
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDayDetail = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(dateFormatter.string(from: Date()))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color.nutriSyncBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .opacity(animateContent ? 1 : 0)
        .onAppear {
            startProgressiveLoading()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private func startProgressiveLoading() {
        // Phase 1: Basic data (immediate)
        withAnimation(.easeOut(duration: 0.3)) {
            basicDataLoaded = true
        }
        
        // Phase 2: Day Purpose (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                dayPurposeLoaded = true
            }
        }
        
        // Phase 3: Food Timeline (1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task { @MainActor in
                foodTimeline = viewModel.getDailyFoodTimeline()
                withAnimation(.easeOut(duration: 0.3)) {
                    timelineLoaded = true
                }
            }
        }
        
        // Phase 4: Micronutrients (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Task { @MainActor in
                micronutrientStatus = viewModel.calculateMicronutrientStatus()
                withAnimation(.easeOut(duration: 0.3)) {
                    micronutrientsLoaded = true
                }
            }
        }
    }
}

// MARK: - End of DayDetailView