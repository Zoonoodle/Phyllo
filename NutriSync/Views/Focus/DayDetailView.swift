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
    @State private var micronutrientStatus: [ScheduleViewModel.MicronutrientStatus] = []
    @State private var foodTimeline: [ScheduleViewModel.TimelineEntry] = []
    @Environment(\.dismiss) private var dismiss
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Daily nutrition ring
                        DailyNutriSyncRing(dailySummary: dailySummary)
                        
                        // Day Purpose card
                        if let dayPurpose = dailySummary.dayPurpose {
                            DayPurposeCard(dayPurpose: dayPurpose)
                        }
                        
                        // Food Timeline
                        if !foodTimeline.isEmpty {
                            ChronologicalFoodList(foodTimeline: foodTimeline)
                        }
                        
                        // Micronutrients
                        if !micronutrientStatus.isEmpty {
                            DailyMicronutrientStatusView(micronutrientStatus: micronutrientStatus)
                                .padding(.bottom, 32)
                        }
                    }
                    .padding(.top, 10) // Increased padding to avoid Dynamic Island/notch
                    .padding(.horizontal, 16) // Reduced padding for wider cards
                }
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.large)
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
            }
            .toolbarBackground(Color.nutriSyncBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            // Load all data immediately
            Task { @MainActor in
                foodTimeline = viewModel.getDailyFoodTimeline()
                micronutrientStatus = viewModel.calculateMicronutrientStatus()
            }
        }
    }
}

// MARK: - End of DayDetailView