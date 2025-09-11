//
//  OnboardingBottomNav.swift
//  NutriSync
//
//  Standardized bottom navigation for onboarding screens
//

import SwiftUI

struct OnboardingBottomNav: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let canGoNext: Bool
    let showBack: Bool
    
    init(
        onBack: @escaping () -> Void = {},
        onNext: @escaping () -> Void,
        canGoNext: Bool = true,
        showBack: Bool = true
    ) {
        self.onBack = onBack
        self.onNext = onNext
        self.canGoNext = canGoNext
        self.showBack = showBack
    }
    
    var body: some View {
        HStack {
            // Back button
            if showBack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(22)
                }
            }
            
            Spacer()
            
            // Next button
            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(canGoNext ? Color.nutriSyncBackground : .white.opacity(0.5))
                .frame(height: 44)
                .padding(.horizontal, 24)
                .background(canGoNext ? Color.white : Color.white.opacity(0.1))
                .cornerRadius(22)
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}

// Convenience modifiers for common patterns
extension View {
    func onboardingNavigation(
        coordinator: NutriSyncOnboardingViewModel,
        canContinue: Bool = true,
        showBack: Bool = true
    ) -> some View {
        self.overlay(
            OnboardingBottomNav(
                onBack: { coordinator.previousScreen() },
                onNext: { coordinator.nextScreen() },
                canGoNext: canContinue,
                showBack: showBack
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
        )
    }
}

struct OnboardingBottomNav_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                OnboardingBottomNav(
                    onBack: {},
                    onNext: {},
                    canGoNext: true
                )
                
                OnboardingBottomNav(
                    onBack: {},
                    onNext: {},
                    canGoNext: false
                )
                
                OnboardingBottomNav(
                    onBack: {},
                    onNext: {},
                    canGoNext: true,
                    showBack: false
                )
            }
        }
        .background(Color.nutriSyncBackground)
    }
}