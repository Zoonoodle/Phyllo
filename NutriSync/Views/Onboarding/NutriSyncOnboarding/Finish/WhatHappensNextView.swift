//
//  WhatHappensNextView.swift
//  NutriSync
//
//  Expectations and CTA screen for onboarding completion
//

import SwiftUI

struct WhatHappensNextView: View {
    let viewModel: OnboardingCompletionViewModel
    @Environment(NutriSyncOnboardingViewModel.self) var coordinator
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text("What Happens Next")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your journey to better nutrition starts now")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        
                        // Experience sections
                        VStack(spacing: 24) {
                            NextStepSection(
                                title: "Daily Experience",
                                items: [
                                    "Personalized meal windows",
                                    "AI meal photo analysis",
                                    "Real-time macro tracking",
                                    "Smart reminders"
                                ]
                            )
                            
                            NextStepSection(
                                title: "Your Plan Adapts",
                                items: [
                                    "Weekly progress adjustments",
                                    "Schedule flexibility",
                                    "Preference learning",
                                    "Automatic optimization"
                                ]
                            )
                            
                            NextStepSection(
                                title: "We Track Success",
                                items: [
                                    "Window adherence",
                                    "Macro accuracy",
                                    "Energy patterns",
                                    "Goal progress"
                                ]
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Key features highlight
                        VStack(spacing: 16) {
                            FeatureHighlight(
                                icon: "camera.fill",
                                title: "Quick Meal Logging",
                                description: "Just snap a photo and our AI handles the rest"
                            )
                            
                            FeatureHighlight(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Weekly Adjustments",
                                description: "Your plan evolves based on your progress"
                            )
                            
                            FeatureHighlight(
                                icon: "bell.badge.fill",
                                title: "Smart Notifications",
                                description: "Gentle reminders aligned with your schedule"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Motivational message
                        Text("You can adjust your schedule anytime")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 100)
                    }
                }
                
                // Bottom CTA
                VStack(spacing: 12) {
                    Button(action: { 
                        Task {
                            await coordinator.completeOnboarding()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.nutriSyncAccent)
                                .frame(height: 56)
                            
                            Text("Start Day 1")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Text("Ready to begin your journey")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [
                            Color.nutriSyncBackground.opacity(0),
                            Color.nutriSyncBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                    .offset(y: -50)
                )
            }
        }
    }
}

// MARK: - Next Step Section
struct NextStepSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title with underline
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }
            
            // Items
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.nutriSyncAccent)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

// MARK: - Feature Highlight
struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.nutriSyncAccent.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.nutriSyncAccent)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}