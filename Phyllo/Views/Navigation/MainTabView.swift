//
//  MainTabView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showDeveloperDashboard = false
    @State private var scrollToAnalyzingMeal: AnalyzingMeal?
    
    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            // Content based on selected tab
            switch selectedTab {
            case 0:
                ScheduleView(
                    showDeveloperDashboard: $showDeveloperDashboard,
                    scrollToAnalyzingMeal: $scrollToAnalyzingMeal
                )
            case 1:
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
            case 2:
                ScanView(showDeveloperDashboard: $showDeveloperDashboard)
            default:
                ScheduleView(
                    showDeveloperDashboard: $showDeveloperDashboard,
                    scrollToAnalyzingMeal: $scrollToAnalyzingMeal
                )
            }
            
            // Custom tab bar at bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showDeveloperDashboard) {
            DeveloperDashboardView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToScanTab)) { _ in
            selectedTab = 2 // Switch to scan tab
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTimelineWithScroll)) { notification in
            if let analyzingMeal = notification.object as? AnalyzingMeal {
                selectedTab = 0 // Switch to timeline tab
                scrollToAnalyzingMeal = analyzingMeal
            }
        }
        .onAppear {
            // Check if first time user
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NudgeManager.shared.triggerNudge(.firstTimeTutorial(page: 1))
                }
            }
        }
    }
}


#Preview {
    MainTabView()
}