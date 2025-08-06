//
//  OnboardingDemo.swift
//  Phyllo
//
//  Standalone demo for onboarding flow
//

import SwiftUI

struct OnboardingDemo: View {
    @State private var showOnboarding = false
    @State private var completedOnboarding = false
    @State private var savedData: OnboardingData?
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                VStack(spacing: 8) {
                    Text("Onboarding Demo")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Test the isolated onboarding flow")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Status
                if completedOnboarding {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Onboarding Complete!")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let data = savedData {
                            OnboardingSummaryCard(data: data)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: { showOnboarding = true }) {
                        Label("Start Onboarding", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.phylloAccent)
                            )
                    }
                    
                    if completedOnboarding {
                        Button(action: resetOnboarding) {
                            Label("Reset", systemImage: "arrow.clockwise")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainerView()
                .onDisappear {
                    // Simulate saving data
                    completedOnboarding = true
                    savedData = createMockSavedData()
                }
        }
    }
    
    private func resetOnboarding() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            completedOnboarding = false
            savedData = nil
        }
    }
    
    private func createMockSavedData() -> OnboardingData {
        var data = OnboardingData()
        data.name = "Demo User"
        data.primaryGoal = .performanceFocus
        data.secondaryGoals = [.betterSleep]
        data.activityLevel = .moderate
        data.preferredMealCount = 4
        return data
    }
}

// MARK: - Summary Card

struct OnboardingSummaryCard: View {
    let data: OnboardingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saved Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                if !data.name.isEmpty {
                    SummaryRow(label: "Name", value: data.name)
                }
                
                if let goal = data.primaryGoal {
                    SummaryRow(label: "Primary Goal", value: goal.displayName)
                }
                
                if !data.secondaryGoals.isEmpty {
                    SummaryRow(
                        label: "Secondary Goals",
                        value: data.secondaryGoals.map { $0.displayName }.joined(separator: ", ")
                    )
                }
                
                SummaryRow(label: "Activity Level", value: data.activityLevel.rawValue)
                
                if let schedule = data.workSchedule {
                    SummaryRow(label: "Work Schedule", value: schedule.rawValue)
                }
                
                SummaryRow(label: "Meal Count", value: "\(data.preferredMealCount) meals/day")
                
                if let fasting = data.fastingProtocol {
                    SummaryRow(label: "Fasting", value: fasting.rawValue)
                }
                
                if !data.currentChallenges.isEmpty {
                    SummaryRow(
                        label: "Challenges",
                        value: "\(data.currentChallenges.count) selected"
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal, 40)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Demo") {
    OnboardingDemo()
}

// MARK: - Individual Screen Previews

#Preview("Welcome") {
    ZStack {
        Color.black.ignoresSafeArea()
        WelcomeView()
    }
}

#Preview("Goals") {
    struct PreviewWrapper: View {
        @State private var primary: NutritionGoal?
        @State private var secondary: [NutritionGoal] = []
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                GoalsSelectionView(primaryGoal: $primary, secondaryGoals: $secondary)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Profile") {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ProfileSetupView(data: $data)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Schedule") {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ScheduleSetupView(data: $data)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Activity") {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ActivitySetupView(data: $data)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Dietary") {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                DietaryPreferencesView(data: $data)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Challenges") {
    struct PreviewWrapper: View {
        @State private var challenges: Set<HealthChallenge> = []
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ChallengesView(challenges: $challenges)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Permissions") {
    ZStack {
        Color.black.ignoresSafeArea()
        PermissionsView()
    }
}