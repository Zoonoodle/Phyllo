//
//  PreWorkoutNutritionView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Pre-Workout Nutrition
//

import SwiftUI

struct PreWorkoutNutritionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var preworkoutTiming = ""
    
    let preworkoutOptions = [
        "2-3 hours before",
        "1 hour before", 
        "30 minutes before",
        "Fasted training",
        "No preference"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(totalSteps: 23, currentStep: 14)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Pre-Workout Fuel")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        // Subtitle
                        Text("When do you prefer to eat before training? This helps us optimize your energy for peak performance.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 20)
                        
                        // Pre-workout options
                        VStack(spacing: 12) {
                            ForEach(preworkoutOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    subtitle: getSubtitle(for: option),
                                    isSelected: preworkoutTiming == option,
                                    action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            preworkoutTiming = option
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
                            coordinator.preworkoutTiming = preworkoutTiming
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
        }
    }
    
    private var canContinue: Bool {
        !preworkoutTiming.isEmpty
    }
    
    private func getSubtitle(for option: String) -> String? {
        switch option {
        case "2-3 hours before":
            return "Full meal for sustained energy"
        case "1 hour before":
            return "Light meal or snack"
        case "30 minutes before":
            return "Quick carbs for energy boost"
        case "Fasted training":
            return "Train on empty stomach"
        case "No preference":
            return "Flexible timing based on schedule"
        default:
            return nil
        }
    }
}

struct PreWorkoutNutritionView_Previews: PreviewProvider {
    static var previews: some View {
        PreWorkoutNutritionView()
    }
}