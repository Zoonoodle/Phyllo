//
//  OnboardingContainerView.swift
//  Phyllo
//
//  Main container for the onboarding flow
//

import SwiftUI

struct OnboardingContainerView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressBar(progress: coordinator.currentStep.progress)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Content
                Group {
                    switch coordinator.currentStep {
                    case .welcome:
                        WelcomeView()
                    case .goals:
                        GoalsSelectionView(
                            primaryGoal: $coordinator.onboardingData.primaryGoal,
                            secondaryGoals: $coordinator.onboardingData.secondaryGoals
                        )
                    case .profile:
                        ProfileSetupView(data: $coordinator.onboardingData)
                    case .schedule:
                        ScheduleSetupView(data: $coordinator.onboardingData)
                    case .activity:
                        ActivitySetupView(data: $coordinator.onboardingData)
                    case .dietary:
                        DietaryPreferencesView(data: $coordinator.onboardingData)
                    case .challenges:
                        ChallengesView(challenges: $coordinator.onboardingData.currentChallenges)
                    case .preview:
                        PlanPreviewView(data: coordinator.onboardingData)
                    case .permissions:
                        PermissionsView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coordinator.currentStep)
                
                Spacer()
                
                // Navigation Buttons
                OnboardingNavigationButtons(
                    canGoBack: coordinator.currentStep != .welcome,
                    canSkip: coordinator.currentStep.canSkip,
                    canProceed: coordinator.canProceedFromCurrentStep(),
                    onBack: { coordinator.previous() },
                    onSkip: { coordinator.skip() },
                    onNext: { coordinator.next() }
                )
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .environment(coordinator)
        .onChange(of: coordinator.isCompleted) { _, completed in
            if completed {
                dismiss()
            }
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.phylloAccent)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons

struct OnboardingNavigationButtons: View {
    let canGoBack: Bool
    let canSkip: Bool
    let canProceed: Bool
    let onBack: () -> Void
    let onSkip: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            // Back Button
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .opacity(canGoBack ? 1 : 0)
            .disabled(!canGoBack)
            
            Spacer()
            
            // Skip Button
            if canSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Next Button
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(canProceed ? Color.phylloAccent : Color.white.opacity(0.2))
                    )
            }
            .disabled(!canProceed)
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingContainerView()
}

// MARK: - Standalone Preview

struct OnboardingPreviewView: View {
    @State private var showOnboarding = true
    
    var body: some View {
        ZStack {
            // Main app content
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Main App")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Button("Show Onboarding") {
                    showOnboarding = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainerView()
        }
    }
}

#Preview("Standalone") {
    OnboardingPreviewView()
}