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
        .onChange(of: selectedActivity) { oldValue, newValue in
            coordinator.dailyActivity = newValue
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

// MARK: - TDEE Calculation Details Popup

struct TDEECalculationDetailsView: View {
    @Binding var isPresented: Bool
    let coordinator: NutriSyncOnboardingViewModel
    let calculatedActivityLevel: TDEECalculator.ActivityLevel
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("How was this calculated?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Your Profile section
                        profileSection
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Activity Levels section
                        activityLevelsSection
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Calculation Method section
                        calculationMethodSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom close button
                Button {
                    isPresented = false
                } label: {
                    Text("Got it")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.nutriSyncBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                profileRow(label: "Age:", value: "\(coordinator.age) years")
                profileRow(label: "Weight:", value: "\(Int(coordinator.weight * 2.20462)) lbs")
                heightRow
                profileRow(label: "Gender:", value: coordinator.gender.capitalized)
            }
        }
    }
    
    private var activityLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Levels")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                profileRow(label: "Exercise Frequency:", value: coordinator.exerciseFrequency)
                profileRow(label: "Daily Activity:", value: coordinator.dailyActivity)
                
                HStack {
                    Text("Calculated Activity Level:")
                        .foregroundColor(.white.opacity(0.6))
                    Text(calculatedActivityLevel.rawValue)
                        .foregroundColor(.nutriSyncAccent)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .font(.system(size: 16))
                .padding(.top, 4)
            }
        }
    }
    
    private var calculationMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calculation Method")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Your TDEE (Total Daily Energy Expenditure) is calculated using the Mifflin-St Jeor equation, which is considered one of the most accurate methods:")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Base Metabolic Rate (BMR) is calculated based on your age, weight, height, and gender")
                Text("2. Your BMR is then multiplied by an activity factor based on your exercise frequency and daily activity level")
                Text("3. The result is your TDEE - the total calories you burn per day")
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.7))
            
            Text("Activity Level Multipliers:")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("• Sedentary: BMR × 1.2")
                Text("• Lightly Active: BMR × 1.375")
                Text("• Moderately Active: BMR × 1.55")
                Text("• Very Active: BMR × 1.725")
                Text("• Extremely Active: BMR × 1.9")
            }
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.system(size: 16))
    }
    
    private var heightRow: some View {
        HStack {
            Text("Height:")
                .foregroundColor(.white.opacity(0.6))
            let feet = Int(coordinator.height / 30.48)
            let inches = Int((coordinator.height.truncatingRemainder(dividingBy: 30.48)) / 2.54)
            Text("\(feet)'\(inches)\"")
                .foregroundColor(.white)
            Spacer()
        }
        .font(.system(size: 16))
    }
}

struct ExpenditureContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var expenditure: Int = 0
    @State private var showAdjustment = false
    @State private var calculatedActivityLevel: TDEECalculator.ActivityLevel = .sedentary
    @State private var isInitialized = false
    @State private var showCalculationDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Daily Calorie Expenditure")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    // Calorie display
                    VStack(spacing: 8) {
                        Text("\(expenditure)")
                            .font(.system(size: 72, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("calories per day")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 20)
                    
                    // How was this calculated button
                    Button {
                        showCalculationDetails = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                            Text("How was this calculated?")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                    
                    if showAdjustment {
                        // Manual adjustment buttons
                        VStack(spacing: 0) {
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
                        .padding(.bottom, 30)
                    }
                
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
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .fullScreenCover(isPresented: $showCalculationDetails) {
            TDEECalculationDetailsView(
                isPresented: $showCalculationDetails,
                coordinator: coordinator,
                calculatedActivityLevel: calculatedActivityLevel
            )
        }
        .onAppear {
            print("[ExpenditureView] onAppear - Loading coordinator data...")
            print("[ExpenditureView] coordinator.weight: \(coordinator.weight) kg (\(Int(coordinator.weight * 2.20462)) lbs)")
            print("[ExpenditureView] coordinator.height: \(coordinator.height) cm (\(Int(coordinator.height / 2.54)) inches)")
            print("[ExpenditureView] coordinator.age: \(coordinator.age) years")
            print("[ExpenditureView] coordinator.gender: '\(coordinator.gender)'")
            print("[ExpenditureView] coordinator.exerciseFrequency: '\(coordinator.exerciseFrequency)'")
            print("[ExpenditureView] coordinator.dailyActivity: '\(coordinator.dailyActivity)'")
            print("[ExpenditureView] coordinator.activityLevel: '\(coordinator.activityLevel)'")
            // Calculate TDEE when view appears
            calculateTDEE()
        }
        .onChange(of: expenditure) { oldValue, newValue in
            // Save the expenditure value whenever it changes
            coordinator.tdee = Double(newValue)
        }
        .onChange(of: coordinator.exerciseFrequency) { oldValue, newValue in
            calculateTDEE()
        }
        .onChange(of: coordinator.dailyActivity) { oldValue, newValue in
            calculateTDEE()
        }
        .onChange(of: coordinator.weight) { oldValue, newValue in
            print("[ExpenditureView] Weight changed, recalculating TDEE...")
            calculateTDEE()
        }
        .onChange(of: coordinator.height) { oldValue, newValue in
            print("[ExpenditureView] Height changed, recalculating TDEE...")
            calculateTDEE()
        }
        .onChange(of: coordinator.age) { oldValue, newValue in
            print("[ExpenditureView] Age changed, recalculating TDEE...")
            calculateTDEE()
        }
        .onChange(of: coordinator.gender) { oldValue, newValue in
            print("[ExpenditureView] Gender changed, recalculating TDEE...")
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

// MARK: - Notice Section Content Views

struct HealthDisclaimerContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var acceptHealthDisclaimer = false
    @State private var acceptPrivacyNotice = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Health Disclaimer")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Please review and accept our health terms")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content
                VStack(alignment: .leading, spacing: 24) {
                    Text("NutriSync optimizes your meal timing to align with your body's natural rhythms and goals. This is educational information, not medical advice or personalized counseling. Always consult a healthcare professional before making significant health decisions. Understand and accept the risks involved with dietary and lifestyle changes. You are responsible for your health decisions and should seek professional guidance when necessary.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Checkboxes
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 12) {
                            // Custom checkbox
                            Button(action: { acceptHealthDisclaimer.toggle() }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if acceptHealthDisclaimer {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I Acknowledge and Accept the Terms of the")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                
                                Text("Health Disclaimer")
                                    .font(.system(size: 17))
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            // Custom checkbox
                            Button(action: { acceptPrivacyNotice.toggle() }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if acceptPrivacyNotice {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I Acknowledge and Accept the Terms of the")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                
                                Text("Consumer Health Privacy Notice")
                                    .font(.system(size: 17))
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 20)
                    
                    // Status text
                    if !acceptHealthDisclaimer || !acceptPrivacyNotice {
                        Text("Please accept both terms to continue")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 16)
                    } else {
                        Text("✓ All terms accepted")
                            .font(.system(size: 15))
                            .foregroundColor(.nutriSyncAccent)
                            .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            // Load any existing acceptance state if needed
        }
    }
}

struct NotToWorryContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Not to worry!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("NutriSync will adapt your eating windows based on your lifestyle and progress. This is just a starting point.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                VStack(spacing: 24) {
                    // Week 1
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 1")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("NutriSync will create your initial eating windows optimized for your daily rhythm.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Week 2
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 2")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("After you log eight consecutive days of meals and check-ins, our algorithm will start optimizing your windows based on your energy patterns and progress.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Week 3 and beyond
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 3 and beyond")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Our algorithm will optimize your meal timing without complex tracking. Your needs change over time, but NutriSync will continue to adapt your eating windows to keep you aligned with your goals.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

// MARK: - Goal Setting Section Content Views

struct GoalSettingIntroContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Let's set your goal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("NutriSync's personalized windows are designed to optimize your nutrition timing. Don't worry – you can update your goal any time.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Visual element
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Information text
                Text("Your goal will help us:")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("Calculate your optimal calorie intake")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("Design your meal window schedule")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("Optimize your macro distribution")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .font(.system(size: 17))
                .padding(.horizontal, 30)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

struct GoalSelectionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedGoal = ""
    @State private var isInitialized = false
    
    let goals = [
        ("Lose Weight", "arrow.down.circle.fill", "Reduce body weight sustainably", Color.red),
        ("Maintain Weight", "equal.circle.fill", "Keep your current weight steady", Color.blue),
        ("Gain Weight", "arrow.up.circle.fill", "Build muscle or increase weight", Color.green)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("What is your goal?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Select your current goal")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Goal options
                VStack(spacing: 16) {
                    ForEach(goals, id: \.0) { goal, icon, description, color in
                        Button {
                            selectedGoal = goal
                            coordinator.goal = goal
                        } label: {
                            HStack(spacing: 16) {
                                // Icon with gradient background
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(color)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(goal)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedGoal == goal ? color : Color.white.opacity(0.2), lineWidth: selectedGoal == goal ? 3 : 1)
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
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if !coordinator.goal.isEmpty {
            selectedGoal = coordinator.goal
        } else {
            selectedGoal = "Lose Weight" // Default
            coordinator.goal = selectedGoal
        }
    }
}

struct MaintenanceStrategyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedStrategy = ""
    @State private var isInitialized = false
    
    let strategies = [
        ("Energy stability", "bolt.circle.fill", "Maintain consistent energy throughout the day", Color.yellow),
        ("Performance optimization", "figure.run.circle.fill", "Optimize nutrition for physical performance", Color.orange),
        ("Better sleep quality", "moon.circle.fill", "Improve sleep through timed nutrition", Color.purple),
        ("Overall health", "heart.circle.fill", "Focus on general health and wellbeing", Color.red)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Maintenance Strategy")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Let's optimize your eating schedule to maintain your current weight")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Strategy options
                VStack(spacing: 16) {
                    ForEach(strategies, id: \.0) { strategy, icon, description, color in
                        Button {
                            selectedStrategy = strategy
                            coordinator.maintenanceStrategy = strategy
                        } label: {
                            HStack(spacing: 16) {
                                // Icon with gradient background
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(color)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(strategy)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedStrategy == strategy ? color : Color.white.opacity(0.2), lineWidth: selectedStrategy == strategy ? 3 : 1)
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
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if !coordinator.maintenanceStrategy.isEmpty {
            selectedStrategy = coordinator.maintenanceStrategy
        } else {
            selectedStrategy = "Energy stability" // Default
            coordinator.maintenanceStrategy = selectedStrategy
        }
    }
}

struct TargetWeightContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var targetWeight: Double = 70
    @State private var isInitialized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Target Weight")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("What weight would you like to achieve?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Current weight display
                VStack(spacing: 8) {
                    Text("Current Weight")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(Int(coordinator.weight * 2.20462)) lbs")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)
                
                // Target weight picker
                VStack(spacing: 16) {
                    Text("Target Weight")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Button {
                            if targetWeight > 30 {
                                targetWeight -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        Text("\(Int(targetWeight * 2.20462))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 100)
                        
                        Button {
                            if targetWeight < 200 {
                                targetWeight += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    
                    Text("lbs")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 40)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // Difference display
                if targetWeight != coordinator.weight {
                    VStack(spacing: 8) {
                        let difference = abs((targetWeight - coordinator.weight) * 2.20462)
                        let isLoss = targetWeight < coordinator.weight
                        
                        Text(isLoss ? "Weight to lose" : "Weight to gain")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 4) {
                            Image(systemName: isLoss ? "arrow.down" : "arrow.up")
                                .foregroundColor(isLoss ? .red : .green)
                            Text("\(Int(difference)) lbs")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isLoss ? .red : .green)
                        }
                    }
                    .padding(.top, 30)
                }
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
        .onChange(of: targetWeight) { oldValue, newValue in
            coordinator.targetWeight = newValue
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if let savedTarget = coordinator.targetWeight {
            targetWeight = savedTarget
        } else {
            // Default to 10 lbs less than current weight for weight loss
            if coordinator.goal.lowercased() == "lose weight" {
                targetWeight = coordinator.weight - 4.5 // ~10 lbs
            } else if coordinator.goal.lowercased() == "gain weight" {
                targetWeight = coordinator.weight + 4.5 // ~10 lbs
            } else {
                targetWeight = coordinator.weight
            }
        }
        coordinator.targetWeight = targetWeight
    }
}

struct WeightLossRateContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedRate: Double = 1.0
    @State private var isInitialized = false
    
    let rates = [
        (0.5, "Gradual", "0.5 lbs per week", "Easier to maintain, minimal muscle loss"),
        (1.0, "Moderate", "1 lb per week", "Good balance of speed and sustainability"),
        (1.5, "Aggressive", "1.5 lbs per week", "Faster results, requires more discipline"),
        (2.0, "Very Aggressive", "2 lbs per week", "Maximum safe rate, very challenging")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Weight Loss Rate")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("How quickly would you like to reach your goal?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Rate options
                VStack(spacing: 16) {
                    ForEach(rates, id: \.0) { rate, title, subtitle, description in
                        Button {
                            selectedRate = rate
                            coordinator.weightLossRate = rate
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(title)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(subtitle)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(rateColor(for: rate))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedRate == rate {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text(description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedRate == rate ? rateColor(for: rate) : Color.white.opacity(0.2), lineWidth: selectedRate == rate ? 3 : 1)
                            )
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Timeline estimate
                if let targetWeight = coordinator.targetWeight {
                    let weightDiff = abs(coordinator.weight - targetWeight) * 2.20462
                    let weeks = Int(weightDiff / selectedRate)
                    
                    VStack(spacing: 8) {
                        Text("Estimated Timeline")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(weeks) weeks")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.nutriSyncAccent)
                    }
                    .padding(.top, 30)
                }
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if let savedRate = coordinator.weightLossRate {
            selectedRate = savedRate
        } else {
            selectedRate = 1.0 // Default to moderate
            coordinator.weightLossRate = selectedRate
        }
    }
    
    private func rateColor(for rate: Double) -> Color {
        switch rate {
        case 0.5: return .green
        case 1.0: return .blue
        case 1.5: return .orange
        case 2.0: return .red
        default: return .white
        }
    }
}

struct PreWorkoutNutritionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedTiming = ""
    @State private var isInitialized = false
    
    let timings = [
        ("30 minutes before", "Quick energy boost"),
        ("1 hour before", "Optimal for most workouts"),
        ("2 hours before", "For larger meals"),
        ("No pre-workout meal", "I prefer fasted training")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Pre-Workout Nutrition")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("When do you prefer to eat before exercising?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Timing options
                VStack(spacing: 16) {
                    ForEach(timings, id: \.0) { timing, description in
                        Button {
                            selectedTiming = timing
                            coordinator.preworkoutTiming = timing
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(timing)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if selectedTiming == timing {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTiming == timing ? Color.white : Color.white.opacity(0.2), lineWidth: selectedTiming == timing ? 3 : 1)
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
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if !coordinator.preworkoutTiming.isEmpty {
            selectedTiming = coordinator.preworkoutTiming
        } else {
            selectedTiming = "1 hour before" // Default
            coordinator.preworkoutTiming = selectedTiming
        }
    }
}

struct PostWorkoutNutritionContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedTiming = ""
    @State private var isInitialized = false
    
    let timings = [
        ("Within 30 minutes", "Maximize recovery window"),
        ("Within 1 hour", "Good for muscle recovery"),
        ("Within 2 hours", "Flexible timing"),
        ("No specific timing", "I eat when convenient")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Post-Workout Nutrition")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("When do you prefer to eat after exercising?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Timing options
                VStack(spacing: 16) {
                    ForEach(timings, id: \.0) { timing, description in
                        Button {
                            selectedTiming = timing
                            coordinator.postworkoutTiming = timing
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(timing)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if selectedTiming == timing {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTiming == timing ? Color.white : Color.white.opacity(0.2), lineWidth: selectedTiming == timing ? 3 : 1)
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
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if !coordinator.postworkoutTiming.isEmpty {
            selectedTiming = coordinator.postworkoutTiming
        } else {
            selectedTiming = "Within 1 hour" // Default
            coordinator.postworkoutTiming = selectedTiming
        }
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