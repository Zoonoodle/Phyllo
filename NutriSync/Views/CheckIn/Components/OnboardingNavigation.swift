//
//  OnboardingNavigation.swift
//  NutriSync
//
//  Standardized navigation component matching onboarding pattern
//

import SwiftUI

struct OnboardingNavigation: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let canGoBack: Bool
    let canGoNext: Bool
    let isLastStep: Bool
    
    init(onBack: @escaping () -> Void, 
         onNext: @escaping () -> Void, 
         canGoBack: Bool, 
         canGoNext: Bool,
         isLastStep: Bool = false) {
        self.onBack = onBack
        self.onNext = onNext
        self.canGoBack = canGoBack
        self.canGoNext = canGoNext
        self.isLastStep = isLastStep
    }
    
    var body: some View {
        HStack {
            if canGoBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text(isLastStep ? "Complete" : "Next")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(canGoNext ? Color.nutriSyncBackground : .white)
                .padding(.horizontal, 24)
                .frame(height: 44)
                .background(canGoNext ? Color.white : Color.white.opacity(0.1))
                .cornerRadius(22)
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}