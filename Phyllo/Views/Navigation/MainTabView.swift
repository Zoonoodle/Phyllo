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
                .ignoresSafeArea(edges: [.top, .bottom])
                
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
                    .tag(1)
                .ignoresSafeArea(edges: [.top, .bottom])
                
                ScanTabView(showDeveloperDashboard: $showDeveloperDashboard)
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
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}