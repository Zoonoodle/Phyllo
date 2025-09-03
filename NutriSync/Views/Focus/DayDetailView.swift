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
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Safe area padding
                Color.clear
                    .frame(height: 50)
                
                // Navigation bar
                customNavigationBar
                    .padding(.top, 8)
                    .background(Color.nutriSyncBackground)
                
                // Scrollable content with progressive loading
                ScrollView {
                    VStack(spacing: 24) {
                        // Phase 1: Basic stats (immediate)
                        if basicDataLoaded {
                            DailyNutriSyncRing(dailySummary: dailySummary)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            // Loading placeholder for ring
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.phylloCard)
                                .frame(height: 200)
                                .padding(.horizontal, 16)
                                .shimmer()
                        }
                        
                        // Phase 2: Day Purpose (0.5s delay)
                        if dayPurposeLoaded, let dayPurpose = dailySummary.dayPurpose {
                            DayPurposeCard(dayPurpose: dayPurpose)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Phase 3: Food Timeline (1s delay)
                        if timelineLoaded && !foodTimeline.isEmpty {
                            ChronologicalFoodList(foodTimeline: foodTimeline)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Phase 4: Micronutrients (1.5s delay)
                        if micronutrientsLoaded && !micronutrientStatus.isEmpty {
                            DailyMicronutrientStatusView(micronutrientStatus: micronutrientStatus)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 32)
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .onAppear {
            startProgressiveLoading()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private var customNavigationBar: some View {
        HStack {
            // Back button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDayDetail = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Title
            Text("Daily Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Date
            Text(dateFormatter.string(from: Date()))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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