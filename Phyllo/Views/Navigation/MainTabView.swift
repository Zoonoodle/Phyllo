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
    
    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            // Content based on selected tab
            switch selectedTab {
            case 0:
                ScheduleView(showDeveloperDashboard: $showDeveloperDashboard)
            case 1:
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
            case 2:
                ScanView(showDeveloperDashboard: $showDeveloperDashboard)
            default:
                ScheduleView(showDeveloperDashboard: $showDeveloperDashboard)
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
    }
}


#Preview {
    MainTabView()
}