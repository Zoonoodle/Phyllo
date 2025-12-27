//
//  MainTabView.swift
//  NutriSync
//
//  Single-screen schedule view with FAB for meal actions
//

import SwiftUI

struct MainTabView: View {
    @State private var showDeveloperDashboard = false
    @State private var scrollToAnalyzingMeal: AnalyzingMeal?
    @State private var showMealResults = false
    @State private var resultMeal: LoggedMeal?
    @StateObject private var clarificationManager = ClarificationManager.shared

    // FAB state
    @State private var isFABExpanded = false

    // Action sheets/covers
    @State private var showScanView = false
    @State private var showVoiceLogView = false
    @State private var showTweakTodaySheet = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Main schedule view (single screen)
            AIScheduleView(
                showDeveloperDashboard: $showDeveloperDashboard,
                scrollToAnalyzingMeal: $scrollToAnalyzingMeal
            )
            .ignoresSafeArea(edges: [.top, .bottom])

            // FAB overlay
            QuickActionFAB(isExpanded: $isFABExpanded) { action in
                handleQuickAction(action)
            }
        }
        .ignoresSafeArea()
        // Notification handlers
        .onReceive(NotificationCenter.default.publisher(for: .switchToTimelineWithScroll)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received switchToTimelineWithScroll notification")
            }
            if let analyzingMeal = notification.object as? AnalyzingMeal {
                Task { @MainActor in
                    DebugLogger.shared.navigation("Scrolling to analyzing meal: \(analyzingMeal.id)")
                }
                scrollToAnalyzingMeal = analyzingMeal
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToScanTab)) { _ in
            // Open scan view instead of switching tabs
            showScanView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToScheduleTab)) { _ in
            // Already on schedule, no action needed
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let userInfo = notification.userInfo,
               let tab = userInfo["tab"] as? String {
                Task { @MainActor in
                    DebugLogger.shared.notification("Navigating to: \(tab)")
                }
                // Handle legacy tab navigation
                if tab == "scan" {
                    showScanView = true
                }
                // "schedule" and "momentum" both just stay on schedule now
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
        // Clarification flow
        .fullScreenCover(isPresented: $clarificationManager.showClarification) {
            if let analyzingMeal = clarificationManager.pendingAnalyzingMeal,
               let analysisResult = clarificationManager.pendingAnalysisResult {
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
                    onComplete: { _ in
                        clarificationManager.completeClarification()
                    }
                )
            }
        }
        // Scan view (camera + voice)
        .fullScreenCover(isPresented: $showScanView) {
            ScanFlowView(
                scrollToAnalyzingMeal: $scrollToAnalyzingMeal,
                onDismiss: {
                    showScanView = false
                }
            )
        }
        // Voice-only log view
        .fullScreenCover(isPresented: $showVoiceLogView) {
            VoiceOnlyLogView {
                showVoiceLogView = false
            }
        }
        // Tweak today sheet
        .sheet(isPresented: $showTweakTodaySheet) {
            TweakTodaySheet()
        }
        // Meal results view
        .sheet(isPresented: $showMealResults) {
            if let meal = resultMeal {
                NavigationStack {
                    FoodAnalysisView(meal: meal, isFromScan: true)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    if !showMealResults {
                        NotificationCenter.default.post(
                            name: .navigateToMealDetails,
                            object: meal
                        )
                        resultMeal = nil
                    }
                }
            }
        }
        // Developer Dashboard
        .sheet(isPresented: $showDeveloperDashboard) {
            DeveloperDashboardView()
        }
    }

    // MARK: - Action Handling

    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .scanMeal:
            showScanView = true
        case .voiceLog:
            showVoiceLogView = true
        case .logPastMeal:
            // TODO: Implement past meal logging view
            showVoiceLogView = true // Fallback to voice log for now
        case .tweakToday:
            showTweakTodaySheet = true
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}