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
                    .zIndex(1000)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .mealLoggedCelebration(let meal):
                    MealCelebrationNudge(meal: meal) {
                        nudgeManager.dismissCurrentNudge()
                    }
                    .zIndex(1000)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .firstTimeTutorial(let page):
                    // TODO: Implement FirstTimeTutorialNudge
                    EmptyView()
                    
                case .missedWindow(let window):
                    // TODO: Implement MissedWindowNudge
                    EmptyView()
                    
                case .activeWindowReminder(let window, let timeRemaining):
                    // TODO: Implement ActiveWindowNudge
                    EmptyView()
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
            NudgeContainer()
        }
    }
}

extension View {
    func withNudges() -> some View {
        modifier(NudgeContainerModifier())
    }
}