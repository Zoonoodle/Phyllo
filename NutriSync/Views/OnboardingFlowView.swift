//
//  OnboardingFlowView.swift
//  NutriSync
//
//  Extracted from ContentView to reduce compilation complexity
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    @EnvironmentObject private var dataProvider: FirebaseDataProvider

    @Binding var viewModel: NutriSyncOnboardingViewModel
    let existingProgress: OnboardingProgress?
    @Binding var showingGetStarted: Bool
    @Binding var hasSeenGetStarted: Bool
    @Binding var hasInitializedGetStarted: Bool
    let onboardingResetFlag: Int

    var body: some View {
        NavigationStack {
            NutriSyncOnboardingCoordinator(
                viewModel: viewModel,
                existingProgress: existingProgress,
                skipSectionIntro: showingGetStarted
            )
            .environmentObject(firebaseConfig)
            .environmentObject(dataProvider)
        }
        .fullScreenCover(isPresented: $showingGetStarted) {
            GetStartedView()
                .environmentObject(firebaseConfig)
                .environmentObject(dataProvider)
                .onDisappear {
                    hasSeenGetStarted = true
                }
        }
        .onChange(of: viewModel.shouldReturnToGetStarted) { _, newValue in
            if newValue {
                viewModel.shouldReturnToGetStarted = false
                hasSeenGetStarted = false
                showingGetStarted = true
            }
        }
        .onAppear {
            initializeGetStartedFlow()
        }
    }

    private func initializeGetStartedFlow() {
        guard !hasInitializedGetStarted else { return }
        hasInitializedGetStarted = true

        #if DEBUG
        if onboardingResetFlag > 0 && hasSeenGetStarted {
            hasSeenGetStarted = false
            print("🔄 Reset GetStartedView flag for debugging")
        }
        #endif

        let hasProgressBeyondBasics = (existingProgress?.currentSection ?? 0) > 0 ||
                                      (existingProgress?.completedSections.contains(0) ?? false)

        if existingProgress == nil && !hasSeenGetStarted {
            showingGetStarted = true
            print("📱 Showing GetStartedView for new user")
        } else {
            showingGetStarted = !hasSeenGetStarted && !hasProgressBeyondBasics
            print("📱 GetStarted decision: hasSeenGetStarted=\(hasSeenGetStarted), hasProgressBeyondBasics=\(hasProgressBeyondBasics), showing=\(showingGetStarted)")
        }
    }
}
