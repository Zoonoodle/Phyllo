//
//  OnboardingContentViews.swift
//  NutriSync
//
//  Content views for onboarding screens carousel
//

import SwiftUI

// MARK: - Basics Section

struct ActivityLevelContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedActivity = "Mostly Sedentary"
    @State private var isInitialized = false
    
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
                            coordinator.dailyActivity = selectedActivity
                            print("[ActivityLevel] Selected: \(selectedActivity)")
                            print("[ActivityLevel] Saved to coordinator.dailyActivity: \(coordinator.dailyActivity)")
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
        .onAppear {
            loadDataFromCoordinator()
        }
        .onChange(of: selectedActivity) { _ in
            coordinator.dailyActivity = selectedActivity
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Load existing value from coordinator if it exists
        if !coordinator.dailyActivity.isEmpty {
            selectedActivity = coordinator.dailyActivity
        } else if !coordinator.activityLevel.isEmpty && 
                  (coordinator.activityLevel == "Mostly Sedentary" || 
                   coordinator.activityLevel == "Moderately Active" || 
                   coordinator.activityLevel == "Very Active") {
            // Migration: If dailyActivity is empty but activityLevel has a valid daily activity value, use it
            selectedActivity = coordinator.activityLevel
            coordinator.dailyActivity = selectedActivity
        }
    }
}

struct ExpenditureContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var expenditure: Int = 0
    @State private var showAdjustment = false
    @State private var calculatedActivityLevel: TDEECalculator.ActivityLevel = .sedentary
    @State private var isInitialized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Daily Calorie Expenditure")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Show calculation details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Based on your profile:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Age:")
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(coordinator.age) years")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Weight:")
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(Int(coordinator.weight * 2.20462)) lbs")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Height:")
                                .foregroundColor(.white.opacity(0.6))
                            let feet = Int(coordinator.height / 30.48)
                            let inches = Int((coordinator.height.truncatingRemainder(dividingBy: 30.48)) / 2.54)
                            Text("\(feet)'\(inches)\"")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Exercise:")
                                .foregroundColor(.white.opacity(0.6))
                            Text(coordinator.exerciseFrequency)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Daily Activity:")
                                .foregroundColor(.white.opacity(0.6))
                            Text(coordinator.dailyActivity)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Overall Activity Level:")
                                .foregroundColor(.white.opacity(0.6))
                            Text(calculatedActivityLevel.rawValue)
                                .foregroundColor(.nutriSyncAccent)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 14))
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                // Calorie display
                VStack(spacing: 8) {
                    Text("\(expenditure)")
                        .font(.system(size: 72, weight: .light))
                        .foregroundColor(.white)
                    
                    Text("calories per day")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                    
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
                        
                        Text("Adjust in increments of 50")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 30)
                
                // Description
                Text("This is your Total Daily Energy Expenditure (TDEE) - the calories you burn each day to maintain your current weight.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                
                // Action buttons
                VStack(spacing: 16) {
                    if !showAdjustment {
                        Button {
                            // User disagrees - show adjustment controls
                            showAdjustment = true
                        } label: {
                            HStack {
                                Text("Adjust manually")
                                    .font(.system(size: 18, weight: .medium))
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16))
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
                                Text("Looks good")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                    } else {
                        // Back button
                        Button {
                            // Reset to calculated value
                            showAdjustment = false
                            calculateTDEE()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.backward")
                                    .font(.system(size: 14))
                                Text("Reset to calculated")
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
                                Text("Save adjusted value")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
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
            print("[ExpenditureView] onAppear - coordinator.exerciseFrequency: '\(coordinator.exerciseFrequency)'")
            print("[ExpenditureView] onAppear - coordinator.dailyActivity: '\(coordinator.dailyActivity)'")
            print("[ExpenditureView] onAppear - coordinator.activityLevel: '\(coordinator.activityLevel)'")
            // Always recalculate when view appears
            isInitialized = false
            calculateTDEE()
        }
        .onDisappear {
            // Save final TDEE value
            coordinator.tdee = Double(expenditure)
        }
    }
    
    private func calculateTDEE() {
        print("[TDEE Calculation] Starting calculation...")
        print("[TDEE] Input - Exercise: \(coordinator.exerciseFrequency)")
        print("[TDEE] Input - Daily Activity: \(coordinator.dailyActivity)")
        print("[TDEE] Input - Weight: \(coordinator.weight) kg, Height: \(coordinator.height) cm, Age: \(coordinator.age)")
        
        // Determine combined activity level based on exercise frequency and daily activity
        let activityLevel = determineActivityLevel()
        calculatedActivityLevel = activityLevel
        
        print("[TDEE] Calculated Activity Level: \(activityLevel.rawValue)")
        
        // Get gender enum value
        let gender: TDEECalculator.Gender = coordinator.gender.lowercased() == "female" ? .female : .male
        
        // Calculate TDEE using the data from coordinator
        let tdee = TDEECalculator.calculate(
            weight: coordinator.weight,
            height: coordinator.height,
            age: coordinator.age,
            gender: gender,
            activityLevel: activityLevel
        )
        
        print("[TDEE] Raw TDEE calculation: \(tdee)")
        
        // Round to nearest 5
        expenditure = Int((tdee / 5).rounded()) * 5
        
        print("[TDEE] Final expenditure: \(expenditure)")
        
        // Save activity level to coordinator
        coordinator.activityLevel = activityLevel.rawValue
    }
    
    private func determineActivityLevel() -> TDEECalculator.ActivityLevel {
        print("[ActivityLevel] Starting determination...")
        
        // Exercise frequency scoring (0-3 points)
        let exerciseScore: Int
        switch coordinator.exerciseFrequency {
        case "0 sessions / week":
            exerciseScore = 0
        case "1-3 sessions / week":
            exerciseScore = 1
        case "4-6 sessions / week":
            exerciseScore = 2
        case "7+ sessions / week":
            exerciseScore = 3
        default:
            exerciseScore = 0
        }
        
        print("[ActivityLevel] Exercise frequency: '\(coordinator.exerciseFrequency)' = score \(exerciseScore)")
        
        // Daily activity scoring (0-2 points)
        let activityScore: Int
        // Check dailyActivity first, then fall back to activityLevel if needed for migration
        let dailyActivityValue = !coordinator.dailyActivity.isEmpty ? coordinator.dailyActivity : 
                                 (coordinator.activityLevel == "Mostly Sedentary" || 
                                  coordinator.activityLevel == "Moderately Active" || 
                                  coordinator.activityLevel == "Very Active") ? coordinator.activityLevel : "Mostly Sedentary"
        
        print("[ActivityLevel] Daily activity value: '\(dailyActivityValue)'")
        
        if dailyActivityValue.contains("Very Active") {
            activityScore = 2
        } else if dailyActivityValue.contains("Moderately Active") {
            activityScore = 1
        } else {
            activityScore = 0  // Mostly Sedentary
        }
        
        print("[ActivityLevel] Daily activity score: \(activityScore)")
        
        // Combine scores (max 5 points)
        let totalScore = exerciseScore + activityScore
        
        print("[ActivityLevel] Total score: \(totalScore) (\(exerciseScore) + \(activityScore))")
        
        // Map total score to activity level
        // This ensures proper progression based on both factors
        let combinedLevel: TDEECalculator.ActivityLevel
        switch totalScore {
        case 0:
            combinedLevel = .sedentary           // No exercise + sedentary
        case 1:
            combinedLevel = .lightlyActive        // Light exercise OR moderate daily activity
        case 2:
            combinedLevel = .moderatelyActive     // Moderate exercise OR very active daily
        case 3:
            combinedLevel = .moderatelyActive     // Good combination of both
        case 4:
            combinedLevel = .veryActive           // High exercise + active daily
        case 5:
            combinedLevel = .veryActive           // Maximum regular activity (7+ exercise + very active)
        default:
            combinedLevel = .extremelyActive      // 6+ (impossible with current scoring, but future-proof)
        }
        
        print("[ActivityLevel] Final result: \(combinedLevel.rawValue)")
        
        return combinedLevel
    }
}

// MARK: - Notice Section Content Views (Placeholders)

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

// MARK: - Goal Setting Section Content Views (Placeholders)

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

// MARK: - Program Section Content Views (Placeholders)

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

// MARK: - Finish Section Content Views (Placeholders)

struct ReviewProgramContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Review Program Content")
            .foregroundColor(.white)
    }
}