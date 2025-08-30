//
//  CheckInScreenTemplate.swift
//  NutriSync
//
//  Template wrapper for all check-in screens
//

import SwiftUI

struct CheckInScreenTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onNext: () -> Void
    let canGoNext: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Standardized header
            OnboardingHeader(
                title: title,
                subtitle: subtitle,
                currentStep: currentStep,
                totalSteps: totalSteps
            )
            
            // Screen-specific content
            content
            
            Spacer()
            
            // Standardized navigation
            OnboardingNavigation(
                onBack: onBack,
                onNext: onNext,
                canGoBack: currentStep > 0,
                canGoNext: canGoNext,
                isLastStep: currentStep == totalSteps - 1
            )
        }
        .background(Color.nutriSyncBackground)
    }
}