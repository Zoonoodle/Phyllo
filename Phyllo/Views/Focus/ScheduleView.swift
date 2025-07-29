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
            Color.phylloBackground.ignoresSafeArea()
            
            VStack(spacing: 2) {
                // Day navigation header with integrated logo and settings
                DayNavigationHeader(
                    selectedDate: $selectedDate,
                    showDeveloperDashboard: $showDeveloperDashboard
                )
                .background(Color.phylloBackground)
                .zIndex(2) // Keep header above everything
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
