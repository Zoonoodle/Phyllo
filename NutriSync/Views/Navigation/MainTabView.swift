//
//  MainTabView.swift
//  NutriSync
//
//  Simple tab view structure
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0 {
        didSet {
            let tabName = getTabName(for: selectedTab)
            Task { @MainActor in
                DebugLogger.shared.navigation("Tab switched from \(getTabName(for: oldValue)) to \(tabName)")
            }
        }
    }
    @State private var showDeveloperDashboard = false
    @State private var scrollToAnalyzingMeal: AnalyzingMeal?
    @State private var pendingTabSwitch: Int?
    @State private var showMealResults = false
    @State private var resultMeal: LoggedMeal?
    @StateObject private var clarificationManager = ClarificationManager.shared
    
    private func getTabName(for index: Int) -> String {
        switch index {
        case 0: return "Schedule"
        case 1: return "Momentum"
        case 2: return "Scan"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Tab content
            TabView(selection: $selectedTab) {
                AIScheduleView(
                    showDeveloperDashboard: $showDeveloperDashboard,
                    scrollToAnalyzingMeal: $scrollToAnalyzingMeal
                )
                .tag(0)
                .ignoresSafeArea(edges: [.top, .bottom])
                
                PremiumPerformanceView()
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
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .switchToTimelineWithScroll)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received switchToTimelineWithScroll notification")
            }
            if let analyzingMeal = notification.object as? AnalyzingMeal {
                Task { @MainActor in
                    DebugLogger.shared.navigation("Switching to timeline with analyzing meal: \(analyzingMeal.id)")
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .switchToScheduleTab)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let userInfo = notification.userInfo,
               let tab = userInfo["tab"] as? String {
                Task { @MainActor in
                    DebugLogger.shared.notification("Navigating to tab: \(tab)")
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    switch tab {
                    case "schedule":
                        selectedTab = 0
                    case "momentum":
                        selectedTab = 1
                    case "scan":
                        selectedTab = 2
                    default:
                        break
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showMealResults)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received showMealResults notification")
            }
            if let meal = notification.object as? LoggedMeal {
                Task { @MainActor in
                    DebugLogger.shared.ui("Showing meal results for: \(meal.name) (\(meal.id))")
                }
                resultMeal = meal
                showMealResults = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealAnalysisClarificationNeeded)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received mealAnalysisClarificationNeeded notification")
            }
            if let analyzingMeal = notification.object as? AnalyzingMeal,
               let result = notification.userInfo?["result"] as? MealAnalysisResult {
                Task { @MainActor in
                    DebugLogger.shared.mealAnalysis("Presenting clarification for: \(analyzingMeal.id)")
                    clarificationManager.presentClarification(for: analyzingMeal, with: result)
                }
            }
        }
        // Global clarification view that works from any tab
        .fullScreenCover(isPresented: $clarificationManager.showClarification) {
            if let analyzingMeal = clarificationManager.pendingAnalyzingMeal,
               let analysisResult = clarificationManager.pendingAnalysisResult {
                // Convert MealAnalysisResult to LoggedMeal for ClarificationQuestionsView
                let tempMeal = LoggedMeal(
                    name: analysisResult.mealName,
                    calories: analysisResult.nutrition.calories,
                    protein: Int(analysisResult.nutrition.protein),
                    carbs: Int(analysisResult.nutrition.carbs),
                    fat: Int(analysisResult.nutrition.fat),
                    timestamp: analyzingMeal.timestamp
                )
                
                ClarificationQuestionsView(
                    analyzingMeal: analyzingMeal,
                    mealResult: tempMeal,
                    clarificationQuestions: analysisResult.clarifications,
                    onComplete: { finalMeal in
                        clarificationManager.completeClarification()
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