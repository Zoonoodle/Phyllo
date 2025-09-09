//
//  WorkoutNutritionView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Workout Nutrition
//

import SwiftUI

struct WorkoutNutritionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var preworkoutTiming = ""
    @State private var postworkoutTiming = ""
    
    let preworkoutOptions = ["2-3 hours before", "1 hour before", "Fasted training", "No preference"]
    let postworkoutOptions = ["Immediate refuel", "Within 2 hours", "No preference"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 14)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Workout Nutrition")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("How do you fuel your training? This helps us optimize your eating windows for performance and recovery.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Pre-workout preference
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pre-workout meal")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(preworkoutOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    isSelected: preworkoutTiming == option,
                                    action: {
                                        preworkoutTiming = option
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Post-workout preference
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Post-workout priority")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(postworkoutOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    isSelected: postworkoutTiming == option,
                                    action: {
                                        postworkoutTiming = option
                                    }
                                )
                            }
                        }
                    }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    coordinator.previousScreen()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    // Save data to coordinator before proceeding
                    coordinator.preworkoutTiming = preworkoutTiming
                    coordinator.postworkoutTiming = postworkoutTiming
                    
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(canContinue ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(canContinue ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(!canContinue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Initialize state from coordinator
            preworkoutTiming = coordinator.preworkoutTiming
            postworkoutTiming = coordinator.postworkoutTiming
        }
    }
    
    private var canContinue: Bool {
        !preworkoutTiming.isEmpty && !postworkoutTiming.isEmpty
    }
}

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutNutritionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutNutritionView()
    }
}