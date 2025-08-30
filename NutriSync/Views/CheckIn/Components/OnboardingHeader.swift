//
//  OnboardingHeader.swift
//  NutriSync
//
//  Standardized header component matching onboarding pattern
//

import SwiftUI

struct OnboardingHeader: View {
    let title: String
    let subtitle: String
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            CheckInProgressBar(totalSteps: totalSteps, currentStep: currentStep + 1)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
        }
    }
}

// Renamed to avoid conflict with BodyFatLevelView's ProgressBar
struct CheckInProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == 1 {
                    Rectangle()
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.2))
                        .frame(height: 3)
                } else {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 3, height: 3)
                        Rectangle()
                            .fill(step <= currentStep ? Color.white : Color.white.opacity(0.2))
                            .frame(height: 3)
                    }
                }
            }
        }
        .frame(height: 3)
    }
}