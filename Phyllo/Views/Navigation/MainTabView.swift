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
    @State private var showMealResults = false
    @State private var resultMeal: LoggedMeal?
    @StateObject private var clarificationManager = ClarificationManager.shared
    
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
        .onReceive(NotificationCenter.default.publisher(for: .showMealResults)) { notification in
            if let meal = notification.object as? LoggedMeal {
                resultMeal = meal
                showMealResults = true
            }
        }
        // Global clarification view that works from any tab
        .fullScreenCover(isPresented: $clarificationManager.showClarification) {
            if let analyzingMeal = clarificationManager.pendingAnalyzingMeal,
               let mealResult = clarificationManager.pendingMealResult {
                ClarificationQuestionsView(
                    analyzingMeal: analyzingMeal,
                    mealResult: mealResult,
                    onComplete: { finalMeal in
                        clarificationManager.completeClarification(with: finalMeal)
                    }
                )
            }
        }
        // Global meal results view
        .sheet(isPresented: $showMealResults) {
            if let meal = resultMeal {
                NavigationStack {
                    FoodAnalysisView(meal: meal, isFromScan: true)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Navigate to meal details after closing
                    if !showMealResults {
                        NotificationCenter.default.post(
                            name: .navigateToMealDetails,
                            object: meal
                        )
                        // Reset state
                        resultMeal = nil
                    }
                }
            }
        }
        // Developer Dashboard sheet
        .sheet(isPresented: $showDeveloperDashboard) {
            DeveloperDashboardView()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}