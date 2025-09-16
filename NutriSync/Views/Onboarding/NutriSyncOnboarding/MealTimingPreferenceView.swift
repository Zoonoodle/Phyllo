//
//  MealTimingPreferenceView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Meal Timing Preference (Split from CircadianOptimizationView)
//

import SwiftUI

struct MealTimingPreferenceView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var largerMealPreference = ""
    
    let mealSizeOptions = ["Morning", "Midday", "Evening", "No preference"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            OnboardingSectionProgressBar()
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Meal Timing")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // Subtitle
                Text("When do you prefer to have your larger meals?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                
                // Meal size preference
                VStack(alignment: .leading, spacing: 12) {
                    Text("Larger Meal Preference")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(mealSizeOptions, id: \.self) { option in
                            OnboardingOptionButton(
                                title: option,
                                isSelected: largerMealPreference == option,
                                action: {
                                    largerMealPreference = option
                                }
                            )
                        }
                    }
                }
                
                // Info text
                Text("This helps us distribute your daily nutrition optimally across your eating windows.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 20)
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
                    coordinator.largerMealPreference = largerMealPreference
                    
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(!largerMealPreference.isEmpty ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(!largerMealPreference.isEmpty ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(largerMealPreference.isEmpty)
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
            largerMealPreference = coordinator.largerMealPreference
        }
    }
}

struct MealTimingPreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        MealTimingPreferenceView()
    }
}