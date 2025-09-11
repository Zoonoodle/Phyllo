//
//  PostWorkoutNutritionView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Post-Workout Nutrition
//

import SwiftUI

struct PostWorkoutNutritionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var postworkoutTiming = ""
    
    let postworkoutOptions = [
        "Immediate refuel",
        "Within 30 minutes",
        "Within 2 hours",
        "Within 4 hours",
        "No preference"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(totalSteps: 24, currentStep: 13)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Post-Workout Recovery")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        // Subtitle
                        Text("When do you like to refuel after training? This helps us optimize your recovery window.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 20)
                        
                        // Post-workout options
                        VStack(spacing: 12) {
                            ForEach(postworkoutOptions, id: \.self) { option in
                                OnboardingOptionButton(
                                    title: option,
                                    subtitle: getSubtitle(for: option),
                                    isSelected: postworkoutTiming == option,
                                    action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            postworkoutTiming = option
                                        }
                                    }
                                )
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
            postworkoutTiming = coordinator.postworkoutTiming
        }
    }
    
    private var canContinue: Bool {
        !postworkoutTiming.isEmpty
    }
    
    private func getSubtitle(for option: String) -> String? {
        switch option {
        case "Immediate refuel":
            return "Within 15 minutes for max recovery"
        case "Within 30 minutes":
            return "Quick protein and carbs"
        case "Within 2 hours":
            return "Standard recovery window"
        case "Within 4 hours":
            return "Extended recovery period"
        case "No preference":
            return "Flexible based on hunger"
        default:
            return nil
        }
    }
}


struct PostWorkoutNutritionView_Previews: PreviewProvider {
    static var previews: some View {
        PostWorkoutNutritionView()
    }
}