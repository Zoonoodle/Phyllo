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
    @State private var micronutrientStatus: [(nutrient: String, status: ScheduleViewModel.MicronutrientStatus)] = []
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
                            DailyNutriSyncRing(summary: dailySummary)
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
                            ChronologicalFoodList(timeline: foodTimeline)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Phase 4: Micronutrients (1.5s delay)
                        if micronutrientsLoaded && !micronutrientStatus.isEmpty {
                            MicronutrientStatusView(nutrients: micronutrientStatus)
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

// MARK: - Shimmer Effect for Loading
extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width)
                }
                .mask(Rectangle())
            )
    }
}

// MARK: - Placeholder Components (will be replaced with actual implementations)

// Temporary placeholder for DailyNutriSyncRing
struct DailyNutriSyncRing: View {
    let summary: ScheduleViewModel.DailyNutritionSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Totals")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(summary.totalCalories)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nutriSyncAccent)
                    Text("Calories")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 4) {
                    Text("\(summary.totalProtein)g")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Protein")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 4) {
                    Text("\(summary.totalCarbs)g")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Carbs")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 4) {
                    Text("\(summary.totalFat)g")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("Fat")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.phylloCard)
        .cornerRadius(16)
    }
}

// Temporary placeholder for DayPurposeCard
struct DayPurposeCard: View {
    let dayPurpose: DayPurpose
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Strategy")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(dayPurpose.nutritionalStrategy)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.phylloCard)
        .cornerRadius(12)
    }
}

// Temporary placeholder for ChronologicalFoodList
struct ChronologicalFoodList: View {
    let timeline: [ScheduleViewModel.TimelineEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foods Logged Today")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(timeline, id: \.timestamp) { entry in
                HStack {
                    Text(entry.meal.name)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(entry.meal.totalCalories) cal")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.phylloCard)
        .cornerRadius(12)
    }
}

// Temporary placeholder for MicronutrientStatusView
struct MicronutrientStatusView: View {
    let nutrients: [(nutrient: String, status: ScheduleViewModel.MicronutrientStatus)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Micronutrient Status")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(nutrients, id: \.nutrient) { item in
                HStack {
                    Text(item.nutrient)
                        .foregroundColor(.white)
                    Spacer()
                    
                    switch item.status {
                    case .deficient(let percentage, _):
                        Text("\(Int(percentage))%")
                            .foregroundColor(.red)
                    case .excess(let percentage, _):
                        Text("\(Int(percentage))%")
                            .foregroundColor(.orange)
                    case .optimal(let percentage):
                        Text("\(Int(percentage))%")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.phylloCard)
        .cornerRadius(12)
    }
}