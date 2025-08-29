//
//  FirstTimeTutorialNudge.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct FirstTimeTutorialNudge: View {
    let page: Int
    let onContinue: (Int?) -> Void // Pass next page or nil if complete
    
    var body: some View {
        switch page {
        case 1:
            welcomeScreen
        case 2:
            scheduleOverview
        case 3:
            loggingTutorial
        case 4:
            completionScreen
        default:
            EmptyView()
        }
    }
    
    private var welcomeScreen: some View {
        FullScreenNudgeCard(
            icon: "sparkles",
            iconColor: .nutriSyncAccent,
            title: "Welcome to NutriSync",
            subtitle: "Your AI-powered nutrition coach that learns your patterns and helps you optimize your health. Let me show you around!",
            primaryButtonTitle: "Get Started",
            primaryAction: {
                onContinue(2)
            },
            secondaryButtonTitle: "Skip Tour",
            secondaryAction: {
                onContinue(nil)
            },
            showProgress: true,
            currentStep: 1,
            totalSteps: 4
        )
    }
    
    private var scheduleOverview: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack {
                // Title at top
                VStack(spacing: 8) {
                    Text("Your Daily Schedule")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("NutriSync creates personalized meal windows based on your goals and lifestyle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 80)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    Button(action: { onContinue(1) }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                    }
                    
                    Button(action: { onContinue(3) }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                
                // Progress indicator
                ProgressStepsView(currentStep: 2, totalSteps: 4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var loggingTutorial: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.nutriSyncAccent)
                    
                    VStack(spacing: 16) {
                        Text("Easy Meal Logging")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Just take a photo of your meal, and our AI will identify everything instantly")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Navigation
                HStack(spacing: 16) {
                    Button(action: { onContinue(2) }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                    }
                    
                    Button(action: { onContinue(4) }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                
                ProgressStepsView(currentStep: 3, totalSteps: 4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var completionScreen: some View {
        FullScreenNudgeCard(
            icon: "trophy.fill",
            iconColor: .yellow,
            title: "You're All Set!",
            subtitle: "Start by completing your morning check-in to generate today's personalized meal schedule.",
            primaryButtonTitle: "Start My Journey",
            primaryAction: {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                onContinue(nil)
            },
            showProgress: true,
            currentStep: 4,
            totalSteps: 4
        )
    }
}

// Preview
struct FirstTimeTutorialNudge_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeTutorialNudge(page: 1) { nextPage in
            print("Next page: \(String(describing: nextPage))")
        }
    }
}