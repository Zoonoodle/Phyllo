//
//  ScheduleView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct ScheduleView: View {
    @Binding var showDeveloperDashboard: Bool
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Date()
    @State private var selectedWindow: MealWindow?
    @State private var showWindowDetail = false
    @State private var selectedMealId: String?
    @State private var showMissedMealsRecovery = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // Background color that extends to edges
            Color.phylloBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add safe area padding at top
                Color.clear
                    .frame(height: 50)
                
                VStack(spacing: 2) {
                    // Day navigation header with integrated logo and settings
                    DayNavigationHeader(
                        selectedDate: $selectedDate,
                        showDeveloperDashboard: $showDeveloperDashboard,
                        meals: viewModel.meals,
                        userProfile: viewModel.userProfile
                    )
                    .background(Color.phylloBackground)
                    .zIndex(2) // Keep header above timeline content
                    .opacity(showWindowDetail ? 0 : 1)
                    
                    // Timeline view
                    TimelineView(
                        selectedWindow: $selectedWindow,
                        showWindowDetail: $showWindowDetail,
                        animationNamespace: animationNamespace,
                        scrollToAnalyzingMeal: $scrollToAnalyzingMeal,
                        viewModel: viewModel
                    )
                    .opacity(showWindowDetail ? 0 : 1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        
        .overlay(alignment: .center) {
            // Window detail overlay
            if showWindowDetail, let window = selectedWindow {
                WindowDetailOverlay(
                    window: window,
                    viewModel: viewModel,
                    showWindowDetail: $showWindowDetail,
                    selectedMealId: $selectedMealId,
                    animationNamespace: animationNamespace
                )
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .opacity.animation(.easeInOut(duration: 0.2))
                ))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToMealDetails)) { notification in
            if let meal = notification.object as? LoggedMeal {
                // Find the window containing this meal
                if let window = viewModel.mealWindows.first(where: { window in
                    meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }) {
                    // Navigate to window detail with specific meal selected
                    selectedWindow = window
                    selectedMealId = meal.id.uuidString
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showWindowDetail = true
                    }
                }
                // If meal is not in any window, just stay on timeline
            }
        }
        .onAppear {
            checkForMissedMeals()
        }
        .sheet(isPresented: $showMissedMealsRecovery) {
            MissedMealsRecoveryView(
                viewModel: viewModel,
                missedWindows: viewModel.missedWindows
            )
        }
    }
    
    private func checkForMissedMeals() {
        // Only show on first appearance, not every time tab switches
        if viewModel.needsMissedMealsRecovery && !UserDefaults.standard.bool(forKey: "missedMealsPromptShown_\(Date().dateString)") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showMissedMealsRecovery = true
                UserDefaults.standard.set(true, forKey: "missedMealsPromptShown_\(Date().dateString)")
            }
        }
    }
}

// Helper extension for date formatting
private extension Date {
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    @Previewable @State var scrollToAnalyzingMeal: AnalyzingMeal?
    ScheduleView(
        showDeveloperDashboard: $showDeveloperDashboard,
        scrollToAnalyzingMeal: $scrollToAnalyzingMeal
    )
    .preferredColorScheme(.dark)
}
