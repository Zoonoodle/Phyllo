//
//  PostMealCheckInView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct PostMealCheckInView: View {
    let mealId: String
    let mealName: String
    
    @StateObject private var checkInManager = CheckInManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Check-in state
    @State private var currentStep = 1
    @State private var energyLevel: PostMealCheckIn.EnergyLevel?
    @State private var fullnessLevel: PostMealCheckIn.FullnessLevel?
    @State private var moodLevel: MoodLevel?
    
    // Animation states
    @State private var showContent = false
    @State private var showCompletion = false
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            if !showCompletion {
                VStack(spacing: 0) {
                    // Header with progress
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: handleBack) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                            
                            // Skip button
                            Button(action: skipCheckIn) {
                                Text("Skip")
                                    .font(.system(size: 16))
                                    .foregroundColor(.nutriSyncTextSecondary)
                                    .frame(height: 44)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        // Progress bar
                        SegmentedProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                            .padding(.horizontal, 20)
                        
                        // Meal context
                        HStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.nutriSyncAccent)
                            
                            Text(mealName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.nutriSyncTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    
                    // Content
                    if showContent {
                        Group {
                            switch currentStep {
                            case 1:
                                EnergyLevelView(
                                    selectedLevel: $energyLevel,
                                    onContinue: handleNextStep
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            case 2:
                                FullnessScaleView(
                                    selectedLevel: $fullnessLevel,
                                    onContinue: handleNextStep
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            case 3:
                                MoodFocusView(
                                    selectedMood: $moodLevel,
                                    onComplete: completeCheckIn
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            default:
                                EmptyView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            } else {
                // Completion view
                CompletionView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                showContent = true
            }
        }
    }
    
    private func handleBack() {
        guard currentStep > 1 else {
            dismiss()
            return
        }
        
        withAnimation {
            currentStep -= 1
        }
    }
    
    private func handleNextStep() {
        guard currentStep < totalSteps else { return }
        
        withAnimation {
            currentStep += 1
        }
    }
    
    private func skipCheckIn() {
        // Track that user skipped
        dismiss()
    }
    
    private func completeCheckIn() {
        guard let energy = energyLevel,
              let fullness = fullnessLevel,
              let mood = moodLevel else { return }
        
        let checkIn = PostMealCheckIn(
            mealId: mealId,
            mealName: mealName,
            energyLevel: energy,
            fullnessLevel: fullness,
            moodFocus: mood
        )
        
        checkInManager.savePostMealCheckIn(checkIn)
        
        // Show completion animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCompletion = true
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Completion View
struct CompletionView: View {
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Success animation
            CheckInCompletionView()
                .scaleEffect(animateElements ? 1.0 : 0.5)
                .opacity(animateElements ? 1.0 : 0)
            
            // Message
            VStack(spacing: 12) {
                Text("Thanks for checking in!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your feedback helps us optimize your nutrition")
                    .font(.system(size: 16))
                    .foregroundColor(.nutriSyncTextSecondary)
            }
            .opacity(animateElements ? 1.0 : 0)
            .offset(y: animateElements ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateElements = true
            }
        }
    }
}

#Preview {
    PostMealCheckInView(
        mealId: "preview-meal",
        mealName: "Grilled Chicken Salad"
    )
    .preferredColorScheme(.dark)
}