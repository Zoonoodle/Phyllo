//
//  NudgeContainer.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct NudgeContainer: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    private let dataProvider = DataSourceProvider.shared.provider
    @State private var showMorningCheckIn = false
    @State private var showPostMealCheckIn = false
    @State private var postMealCheckInMeal: LoggedMeal?
    
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
                            nudgeManager.dismissCurrentNudge()
                            showMorningCheckIn = true
                        },
                        onDismiss: {
                            // Don't allow dismissal - must complete check-in
                            showMorningCheckIn = true
                            nudgeManager.dismissCurrentNudge()
                        }
                    )
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .mealLoggedCelebration(let meal, let metadata):
                    MealCelebrationNudge(
                        meal: meal,
                        metadata: metadata,
                        onDismiss: {
                            nudgeManager.dismissCurrentNudge()
                        },
                        onViewDetails: {
                            // First switch to schedule tab (timeline)
                            NotificationCenter.default.post(name: .switchToScheduleTab, object: nil)
                            
                            // Then navigate to meal details after a small delay to allow tab switch
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: .navigateToMealDetails,
                                    object: meal
                                )
                            }
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
                    
                case .activeWindowReminder(let window, let timeRemaining):
                    ActiveWindowNudge(
                        window: window,
                        timeRemaining: timeRemaining
                    ) {
                        nudgeManager.dismissCurrentNudge()
                    }
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .postMealCheckIn(let meal):
                    PostMealCheckInNudge(
                        meal: meal,
                        onCheckIn: {
                            postMealCheckInMeal = meal
                            nudgeManager.dismissCurrentNudge()
                            showPostMealCheckIn = true
                        },
                        onDismiss: {
                            nudgeManager.dismissCurrentNudge()
                        }
                    )
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    
                case .voiceInputTips:
                    VoiceInputTipsNudge(
                        onDismiss: {
                            nudgeManager.dismissCurrentNudge()
                        }
                    )
                    .zIndex(10001)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nudgeManager.activeNudge?.id)
        .sheet(isPresented: $showMorningCheckIn) {
            MorningCheckInCoordinator(isMandatory: true)
                .interactiveDismissDisabled(true) // Prevent swipe down dismissal
        }
        .sheet(isPresented: $showPostMealCheckIn) {
            if let meal = postMealCheckInMeal {
                PostMealCheckInView(mealId: meal.id.uuidString, mealName: meal.name)
            }
        }
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