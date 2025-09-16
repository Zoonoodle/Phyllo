//
//  OnboardingContentViews.swift
//  NutriSync
//
//  Placeholder content views for onboarding screens
//

import SwiftUI

// These are temporary placeholder views for the content-only versions
// They will be replaced with actual content views as screens are updated

struct ActivityLevelContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedActivity = "Mostly Sedentary"
    
    let activityLevels = [
        ("Mostly Sedentary", "figure.stand", "In many cases, this would correspond to less than 5,000 steps a day."),
        ("Moderately Active", "figure.walk", "In many cases, this would correspond to 5,000 - 15,000 steps a day."),
        ("Very Active", "figure.run", "In many cases, this would correspond to more than 15,000 steps a day.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("How active are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Select your level of daily physical activity outside of exercise (during work, leisure time, etc).")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Activity level options
                VStack(spacing: 16) {
                    ForEach(activityLevels, id: \.0) { level, icon, description in
                        Button {
                            selectedActivity = level
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 30, alignment: .center)
                                    .padding(.top, 4)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(level)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedActivity == level ? Color.white : Color.white.opacity(0.2), lineWidth: selectedActivity == level ? 3 : 1)
                            )
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onDisappear {
            // Save activity level to coordinator
            coordinator.activityLevel = selectedActivity
        }
    }
}

struct ExpenditureContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var expenditure: Int = 0
    @State private var showAdjustment = false
    @State private var selectedActivityLevel: TDEECalculator.ActivityLevel = .moderatelyActive
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("We estimated your initial expenditure.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                if !showAdjustment {
                    // Activity level selection
                    VStack(spacing: 12) {
                        Text("Select your activity level:")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        ForEach(TDEECalculator.ActivityLevel.allCases, id: \.self) { level in
                            Button {
                                selectedActivityLevel = level
                                calculateTDEE()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(level.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(level.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    selectedActivityLevel == level ?
                                    Color.nutriSyncAccent.opacity(0.2) :
                                    Color.white.opacity(0.05)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedActivityLevel == level ?
                                            Color.nutriSyncAccent :
                                            Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                // Calorie display
                VStack(spacing: 8) {
                    Text("\(expenditure) kcal")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                    
                    if showAdjustment {
                        // Manual adjustment buttons
                        HStack(spacing: 40) {
                            Button {
                                expenditure = max(1200, expenditure - 50)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Button {
                                expenditure = min(5000, expenditure + 50)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 20)
                        
                        Text("Adjust your daily expenditure")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 40)
                
                // Question
                Text("Does this look right to you?")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                // Description
                Text("Expenditure is the number of calories you would need to consume to maintain your current weight.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                
                // Action buttons
                VStack(spacing: 16) {
                    if !showAdjustment {
                        Button {
                            // User disagrees - show adjustment controls
                            showAdjustment = true
                        } label: {
                            HStack {
                                Text("No, let me adjust")
                                    .font(.system(size: 18, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                        }
                        
                        Button {
                            // User agrees with the estimate
                            coordinator.tdee = Double(expenditure)
                        } label: {
                            HStack {
                                Text("Yes, looks good")
                                    .font(.system(size: 18, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                        }
                        
                        Button {
                            // User is not sure - proceed with estimate
                            coordinator.tdee = Double(expenditure)
                        } label: {
                            HStack {
                                Text("Not Sure, continue")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                    } else {
                        // Back to selection button
                        Button {
                            showAdjustment = false
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back to Selection")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                        }
                        
                        // Save adjusted value
                        Button {
                            coordinator.tdee = Double(expenditure)
                        } label: {
                            HStack {
                                Text("Save and Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            calculateTDEE()
        }
        .onDisappear {
            // Save final TDEE value if not already saved
            if coordinator.tdee == nil {
                coordinator.tdee = Double(expenditure)
            }
        }
    }
    
    private func calculateTDEE() {
        // Get gender enum value
        let gender: TDEECalculator.Gender = coordinator.gender.lowercased() == "female" ? .female : .male
        
        // Calculate TDEE using the data from coordinator
        let tdee = TDEECalculator.calculate(
            weight: coordinator.weight,
            height: coordinator.height,
            age: coordinator.age,
            gender: gender,
            activityLevel: selectedActivityLevel
        )
        
        // Round to nearest 5
        expenditure = Int((tdee / 5).rounded()) * 5
        
        // Save activity level to coordinator
        coordinator.activityLevel = selectedActivityLevel.rawValue
    }
}

struct HealthDisclaimerContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Health Disclaimer Content")
            .foregroundColor(.white)
    }
}

struct NotToWorryContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Not To Worry Content")
            .foregroundColor(.white)
    }
}

struct GoalSettingIntroContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Goal Setting Intro Content")
            .foregroundColor(.white)
    }
}

struct GoalSelectionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Goal Selection Content")
            .foregroundColor(.white)
    }
}

struct MaintenanceStrategyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Maintenance Strategy Content")
            .foregroundColor(.white)
    }
}

struct TargetWeightContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Target Weight Content")
            .foregroundColor(.white)
    }
}

struct WeightLossRateContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Weight Loss Rate Content")
            .foregroundColor(.white)
    }
}

struct PreWorkoutNutritionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Pre-Workout Nutrition Content")
            .foregroundColor(.white)
    }
}

struct PostWorkoutNutritionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Post-Workout Nutrition Content")
            .foregroundColor(.white)
    }
}

struct AlmostThereContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Almost There Content")
            .foregroundColor(.white)
    }
}

struct DietPreferenceContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Diet Preference Content")
            .foregroundColor(.white)
    }
}

struct TrainingPlanContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Training Plan Content")
            .foregroundColor(.white)
    }
}

struct CalorieFloorContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Calorie Floor Content")
            .foregroundColor(.white)
    }
}

struct SleepScheduleContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Sleep Schedule Content")
            .foregroundColor(.white)
    }
}

struct MealFrequencyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Meal Frequency Content")
            .foregroundColor(.white)
    }
}

struct EatingWindowContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Eating Window Content")
            .foregroundColor(.white)
    }
}

struct DietaryRestrictionsContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Dietary Restrictions Content")
            .foregroundColor(.white)
    }
}

struct MealTimingPreferenceContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Meal Timing Preference Content")
            .foregroundColor(.white)
    }
}

struct WindowFlexibilityContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Window Flexibility Content")
            .foregroundColor(.white)
    }
}

struct ReviewProgramContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Review Program Content")
            .foregroundColor(.white)
    }
}