//
//  NudgeContainer.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct NudgeContainer: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        ZStack {
            // Background dimming overlay
            if nudgeManager.activeNudge != nil {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(10000)
            }
            
            if let activeNudge = nudgeManager.activeNudge {
                switch activeNudge {
                case .morningCheckIn:
                    MorningCheckInNudge(
                        onCheckIn: {
                            mockData.completeMorningCheckIn()
                            nudgeManager.dismissCurrentNudge()
                        },
                        onDismiss: {
                            nudgeManager.dismissCurrentNudge()
                        }
                    )
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .mealLoggedCelebration(let meal):
                    MealCelebrationNudge(
                        meal: meal,
                        onDismiss: {
                            nudgeManager.dismissCurrentNudge()
                        },
                        onViewDetails: {
                            // Post notification to navigate to meal details
                            NotificationCenter.default.post(
                                name: .navigateToMealDetails,
                                object: meal
                            )
                        }
                    )
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .firstTimeTutorial(let page):
                    FirstTimeTutorialNudge(page: page) { nextPage in
                        nudgeManager.dismissCurrentNudge()
                        if let nextPage = nextPage {
                            nudgeManager.triggerNudge(.firstTimeTutorial(page: nextPage))
                        }
                    }
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .missedWindow(let window):
                    MissedWindowNudge(window: window) { ate in
                        nudgeManager.dismissCurrentNudge()
                        if ate {
                            // Switch to scan tab to log meal
                            NotificationCenter.default.post(name: .switchToScanTab, object: nil)
                        }
                    }
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .activeWindowReminder(let window, let timeRemaining):
                    ActiveWindowNudge(
                        window: window,
                        timeRemaining: timeRemaining
                    ) {
                        nudgeManager.dismissCurrentNudge()
                    }
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nudgeManager.activeNudge?.id)
    }
}

// Helper modifier to add nudge container to any view
struct NudgeContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            NudgeContainer()
                .zIndex(10000)
        }
    }
}

extension View {
    func withNudges() -> some View {
        modifier(NudgeContainerModifier())
    }
}