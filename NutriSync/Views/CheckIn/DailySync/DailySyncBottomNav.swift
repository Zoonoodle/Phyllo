//
//  DailySyncBottomNav.swift
//  NutriSync
//
//  Standardized bottom navigation for Daily Sync screens matching onboarding style
//

import SwiftUI

struct DailySyncBottomNav: View {
    let onBack: (() -> Void)?
    let onNext: () -> Void
    let nextButtonTitle: String
    let canGoNext: Bool
    let showBack: Bool
    
    init(
        onBack: (() -> Void)? = nil,
        onNext: @escaping () -> Void,
        nextButtonTitle: String = "Continue",
        canGoNext: Bool = true,
        showBack: Bool = true
    ) {
        self.onBack = onBack
        self.onNext = onNext
        self.nextButtonTitle = nextButtonTitle
        self.canGoNext = canGoNext
        self.showBack = showBack
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Back arrow button (matches onboarding style)
            if showBack, let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            
            // Continue button (prominent green, matches onboarding)
            Button(action: onNext) {
                Text(nextButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(canGoNext ? .black : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canGoNext ? Color.nutriSyncAccent : Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(canGoNext ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Matches onboarding padding
    }
}

// Convenience view modifier for consistent application
extension View {
    func dailySyncNavigation(
        viewModel: DailySyncViewModel,
        canContinue: Bool = true,
        showBack: Bool = true,
        nextButtonTitle: String = "Continue"
    ) -> some View {
        self.overlay(
            DailySyncBottomNav(
                onBack: showBack ? { viewModel.previousScreen() } : nil,
                onNext: { viewModel.nextScreen() },
                nextButtonTitle: nextButtonTitle,
                canGoNext: canContinue,
                showBack: showBack
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
        )
    }
}

// Progress dots component matching onboarding style
struct DailySyncProgressDots: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index < currentStep ? Color.white : Color.white.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
}

// Standard header matching onboarding style
struct DailySyncHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
    }
}

// Option button matching onboarding style
struct DailySyncOptionButton: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Radio button style from onboarding
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
            )
        }
    }
}

struct DailySyncBottomNav_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // With back button
                DailySyncBottomNav(
                    onBack: {},
                    onNext: {},
                    canGoNext: true
                )
                
                // Without back button
                DailySyncBottomNav(
                    onBack: nil,
                    onNext: {},
                    canGoNext: true,
                    showBack: false
                )
                
                // Disabled state
                DailySyncBottomNav(
                    onBack: {},
                    onNext: {},
                    canGoNext: false
                )
                
                // Custom button title
                DailySyncBottomNav(
                    onBack: {},
                    onNext: {},
                    nextButtonTitle: "Get Started",
                    canGoNext: true
                )
            }
        }
        .background(Color.nutriSyncBackground)
    }
}