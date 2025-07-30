//
//  MainTabView.swift
//  Phyllo
//
//  Simple tab view structure
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showDeveloperDashboard = false
    @State private var scrollToAnalyzingMeal: AnalyzingMeal?
    @State private var pendingTabSwitch: Int?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Tab content
            TabView(selection: $selectedTab) {
                ScheduleView(
                    showDeveloperDashboard: $showDeveloperDashboard,
                    scrollToAnalyzingMeal: $scrollToAnalyzingMeal
                )
                .tag(0)
                .ignoresSafeArea(edges: [.top, .bottom])
                
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
                    .tag(1)
                .ignoresSafeArea(edges: [.top, .bottom])
                
                ScanTabView(
                    showDeveloperDashboard: $showDeveloperDashboard,
                    selectedTab: $selectedTab,
                    scrollToAnalyzingMeal: $scrollToAnalyzingMeal
                )
                    .tag(2)
                .ignoresSafeArea(edges: [.top, .bottom])
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Floating tab bar overlay
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .switchToTimelineWithScroll)) { notification in
            if let analyzingMeal = notification.object as? AnalyzingMeal {
                // Store the analyzing meal to scroll to
                scrollToAnalyzingMeal = analyzingMeal
                // Switch to timeline tab with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToScanTab)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 2
            }
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}