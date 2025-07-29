//
//  FullScreenNudgeCard.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct FullScreenNudgeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    var secondaryButtonTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil
    var showProgress: Bool = false
    var currentStep: Int = 1
    var totalSteps: Int = 1
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator at top
                if showProgress {
                    ProgressStepsView(
                        currentStep: currentStep,
                        totalSteps: totalSteps
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                }
                
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: icon)
                            .font(.system(size: 60))
                            .foregroundColor(iconColor)
                    }
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .opacity(animateContent ? 1 : 0)
                    
                    // Text content
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(subtitle)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 40)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Primary button
                    Button(action: primaryAction) {
                        Text(primaryButtonTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.phylloBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.phylloAccent)
                            .cornerRadius(28)
                    }
                    
                    // Secondary button (optional)
                    if let secondaryTitle = secondaryButtonTitle {
                        Button(action: secondaryAction ?? {}) {
                            Text(secondaryTitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
}

// Progress steps indicator
struct ProgressStepsView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.phylloAccent : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}

// Preview
struct FullScreenNudgeCard_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenNudgeCard(
            icon: "sparkles",
            iconColor: .phylloAccent,
            title: "Welcome to Phyllo",
            subtitle: "Your AI-powered nutrition coach that learns your patterns and helps you optimize your health",
            primaryButtonTitle: "Get Started",
            primaryAction: { print("Primary action") },
            secondaryButtonTitle: "I have an account",
            secondaryAction: { print("Secondary action") },
            showProgress: true,
            currentStep: 1,
            totalSteps: 4
        )
    }
}