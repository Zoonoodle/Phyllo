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
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedDate = Date()
    @State private var selectedWindow: MealWindow?
    @State private var showWindowDetail = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // Background color that extends to edges
            VStack(spacing: 0) {
                // Top area with same color as tab bar
                Color(red: 0.11, green: 0.11, blue: 0.12)
                    .frame(maxHeight: 150)
                
                // Rest of the view
                Color.phylloBackground
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add safe area padding at top
                Color.clear
                    .frame(height: 50)
                
                VStack(spacing: 2) {
                    // Day navigation header with integrated logo and settings
                    DayNavigationHeader(
                        selectedDate: $selectedDate,
                        showDeveloperDashboard: $showDeveloperDashboard
                    )
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .zIndex(2) // Keep header above timeline content
                    .opacity(showWindowDetail ? 0 : 1)
                    
                    // Timeline view
                    TimelineView(
                        selectedWindow: $selectedWindow,
                        showWindowDetail: $showWindowDetail,
                        animationNamespace: animationNamespace,
                        scrollToAnalyzingMeal: $scrollToAnalyzingMeal
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
                    showWindowDetail: $showWindowDetail,
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
                if let window = mockData.mealWindows.first(where: { window in
                    meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }) {
                    // Navigate to window detail
                    selectedWindow = window
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showWindowDetail = true
                    }
                }
                // If meal is not in any window, just stay on timeline
            }
        }
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
