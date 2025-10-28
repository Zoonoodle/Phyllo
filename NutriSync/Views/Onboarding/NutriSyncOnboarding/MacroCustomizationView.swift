//
//  MacroCustomizationView.swift
//  NutriSync
//
//  Created on 10/15/25.
//  Macro ratio customization screen for onboarding
//

import SwiftUI

struct MacroCustomizationContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var viewModel

    // Local state for macro sliders
    @State private var proteinPercentage: Double = 30.0
    @State private var carbPercentage: Double = 40.0
    @State private var fatPercentage: Double = 30.0

    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Customize Your Macro Split")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Adjust your protein, carbs, and fat distribution based on your preferences. We've set research-backed defaults for your goal.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 8)

                // Recommended Profile Card
                if let recommendedProfile = getRecommendedProfile() {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.nutriSyncAccent)
                            Text("Recommended for \(viewModel.goal)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 16) {
                            MacroPreviewBubble(
                                nutrient: "Protein",
                                percentage: recommendedProfile.proteinPercentageInt,
                                color: .blue
                            )
                            MacroPreviewBubble(
                                nutrient: "Carbs",
                                percentage: recommendedProfile.carbPercentageInt,
                                color: .orange
                            )
                            MacroPreviewBubble(
                                nutrient: "Fat",
                                percentage: recommendedProfile.fatPercentageInt,
                                color: .purple
                            )
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                }

                // Macro Sliders
                VStack(spacing: 24) {
                    MacroSlider(
                        label: "Protein",
                        percentage: $proteinPercentage,
                        grams: calculateGrams(percentage: proteinPercentage, isFat: false),
                        color: .blue,
                        range: 15...50
                    )

                    MacroSlider(
                        label: "Carbs",
                        percentage: $carbPercentage,
                        grams: calculateGrams(percentage: carbPercentage, isFat: false),
                        color: .orange,
                        range: 15...60
                    )

                    MacroSlider(
                        label: "Fat",
                        percentage: $fatPercentage,
                        grams: calculateGrams(percentage: fatPercentage, isFat: true),
                        color: .purple,
                        range: 15...50
                    )
                }

                // Total Validation
                HStack {
                    Text("Total:")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    let total = Int(proteinPercentage + carbPercentage + fatPercentage)
                    Text("\(total)%")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(total == 100 ? .nutriSyncAccent : .red)

                    if total == 100 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.nutriSyncAccent)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Preset Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Presets")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(MacroCalculationService.commonPresets.keys.sorted()), id: \.self) { presetName in
                            PresetButton(
                                name: presetName,
                                action: {
                                    applyPreset(MacroCalculationService.commonPresets[presetName]!)
                                }
                            )
                        }
                    }
                }

                // Educational Tip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.nutriSyncAccent)
                        Text("Why These Ratios?")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text(getEducationalTip())
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.nutriSyncBackground)
        .onAppear {
            // Calculate TDEE if not available (fallback for resumed onboarding)
            if viewModel.tdee == nil || viewModel.tdee == 0 {
                let calculated = calculateFallbackTDEE()
                viewModel.tdee = calculated
                print("[MacroCustomization] Calculated and saved TDEE: \(Int(calculated)) cal")
            }

            // Initialize with recommended values for goal
            if let recommended = getRecommendedProfile() {
                proteinPercentage = Double(recommended.proteinPercentageInt)
                carbPercentage = Double(recommended.carbPercentageInt)
                fatPercentage = Double(recommended.fatPercentageInt)
            }
        }
        .onDisappear {
            // Save the macro profile when leaving this screen
            saveMacroProfile()
        }
    }

    // MARK: - Helper Methods

    private func getRecommendedProfile() -> MacroProfile? {
        guard let goal = UserGoals.Goal(rawValue: viewModel.goal) else { return nil }
        return MacroCalculationService.getProfile(for: goal)
    }

    private func calculateGrams(percentage: Double, isFat: Bool) -> Int {
        // Get TDEE - either from viewModel or calculate it
        let tdee: Double
        if let existingTDEE = viewModel.tdee, existingTDEE > 0 {
            tdee = existingTDEE
        } else {
            // Calculate TDEE on the fly if not available
            tdee = calculateFallbackTDEE()
            print("[MacroCustomization] Using fallback TDEE calculation: \(Int(tdee)) cal")
        }

        // Calculate calories from percentage
        let caloriesFromPercentage = tdee * (percentage / 100.0)

        // Convert to grams based on macro type
        // Protein and Carbs: 4 calories per gram
        // Fat: 9 calories per gram
        let grams = isFat ? caloriesFromPercentage / 9.0 : caloriesFromPercentage / 4.0

        let result = Int(round(grams))
        print("[MacroCustomization] Calculate: \(Int(percentage))% of \(Int(tdee)) cal = \(Int(caloriesFromPercentage)) cal = \(result)g (isFat: \(isFat))")
        return result
    }

    private func calculateFallbackTDEE() -> Double {
        // Use TDEECalculator to compute TDEE from user's basic info
        let gender: TDEECalculator.Gender = viewModel.gender.lowercased() == "female" ? .female : .male

        // Determine activity level from exercise frequency and daily activity
        let activityLevel = determineActivityLevel()

        return TDEECalculator.calculate(
            weight: viewModel.weight,
            height: viewModel.height,
            age: viewModel.age,
            gender: gender,
            activityLevel: activityLevel
        )
    }

    private func determineActivityLevel() -> TDEECalculator.ActivityLevel {
        // Map exercise frequency and daily activity to TDEE activity level
        let exerciseSessions: Int
        if let freq = Int(viewModel.exerciseFrequency) {
            exerciseSessions = freq
        } else if viewModel.exerciseFrequency.contains("0") {
            exerciseSessions = 0
        } else if viewModel.exerciseFrequency.contains("1-2") {
            exerciseSessions = 2
        } else if viewModel.exerciseFrequency.contains("3-4") {
            exerciseSessions = 4
        } else if viewModel.exerciseFrequency.contains("5-6") {
            exerciseSessions = 6
        } else if viewModel.exerciseFrequency.contains("7") {
            exerciseSessions = 7
        } else {
            exerciseSessions = 0
        }

        // Combine exercise and daily activity
        if exerciseSessions >= 6 || viewModel.dailyActivity == "Very Active" {
            return .veryActive
        } else if exerciseSessions >= 4 || viewModel.dailyActivity == "Moderately Active" {
            return .moderatelyActive
        } else if exerciseSessions >= 2 {
            return .lightlyActive
        } else if viewModel.dailyActivity == "Mostly Sedentary" && exerciseSessions == 0 {
            return .sedentary
        } else {
            return .lightlyActive
        }
    }

    private func applyPreset(_ preset: (protein: Double, carbs: Double, fat: Double)) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            proteinPercentage = preset.protein * 100
            carbPercentage = preset.carbs * 100
            fatPercentage = preset.fat * 100
        }
    }

    private func saveMacroProfile() {
        guard let goal = UserGoals.Goal(rawValue: viewModel.goal) else { return }

        print("[MacroCustomization] ========== SAVING MACRO PROFILE ==========")
        print("[MacroCustomization] Current slider values:")
        print("[MacroCustomization]   proteinPercentage: \(proteinPercentage)%")
        print("[MacroCustomization]   carbPercentage: \(carbPercentage)%")
        print("[MacroCustomization]   fatPercentage: \(fatPercentage)%")

        let profile = MacroProfile(
            proteinPercentage: proteinPercentage / 100,
            carbPercentage: carbPercentage / 100,
            fatPercentage: fatPercentage / 100,
            goal: goal,
            isCustomized: true
        )

        print("[MacroCustomization] Created profile object:")
        print("[MacroCustomization]   proteinPercentage: \(profile.proteinPercentage) (\(profile.proteinPercentageInt)%)")
        print("[MacroCustomization]   carbPercentage: \(profile.carbPercentage) (\(profile.carbPercentageInt)%)")
        print("[MacroCustomization]   fatPercentage: \(profile.fatPercentage) (\(profile.fatPercentageInt)%)")

        // Validate before saving
        let validation = MacroCalculationService.validate(profile: profile)
        switch validation {
        case .success:
            viewModel.macroProfile = profile
            print("[MacroCustomization] ✅ Profile saved to viewModel.macroProfile")
            print("[MacroCustomization] Total: \(profile.totalPercentage * 100)%")
        case .failure(let error):
            showValidationError = true
            validationMessage = error.localizedDescription
            print("[MacroCustomization] ❌ Validation error: \(error.localizedDescription)")
        }
        print("[MacroCustomization] ================================================")
    }

    private func getEducationalTip() -> String {
        guard let goal = UserGoals.Goal(rawValue: viewModel.goal) else {
            return "Balanced macros support overall health and energy levels."
        }

        switch goal {
        case .loseWeight:
            return "Higher protein (35%) preserves muscle mass during weight loss and increases satiety. Higher fat (35%) keeps you feeling full longer, while moderate carbs (30%) provide energy."
        case .buildMuscle:
            return "Moderate-high protein (30%) supports muscle growth, while high carbs (45%) provide energy for intense training. Lower fat (25%) allows more calories for protein and carbs."
        case .improvePerformance:
            return "High carbs (50%) fuel peak athletic performance and quick energy. Moderate protein (25%) supports recovery, with lower fat (25%) for efficient energy utilization."
        case .betterSleep:
            return "Higher fat (35%) and moderate protein (30%) promote satiety throughout the night. Lower carbs (35%) help avoid insulin spikes that can disrupt sleep."
        case .overallHealth, .maintainWeight:
            return "A balanced approach (30% protein, 40% carbs, 30% fat) supports overall health, energy levels, and sustainable nutrition habits."
        }
    }
}

// MARK: - Supporting Components

struct MacroSlider: View {
    let label: String
    @Binding var percentage: Double
    let grams: Int
    let color: Color
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)

                    Text("~\(grams)g per day")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Slider(value: $percentage, in: range, step: 1)
                .tint(color)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct MacroPreviewBubble: View {
    let nutrient: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(percentage)%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(nutrient)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

struct PresetButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

struct MacroCustomizationView_Previews: PreviewProvider {
    static var previews: some View {
        MacroCustomizationContentView()
            .environment(NutriSyncOnboardingViewModel())
    }
}
