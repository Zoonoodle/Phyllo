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
                
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
                    .tag(1)
                
                ScanTabView(showDeveloperDashboard: $showDeveloperDashboard)
                    .tag(2)
            }
            
            // Custom tab bar overlay
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}