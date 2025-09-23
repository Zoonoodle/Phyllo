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
            // Background - match app theme
            Color.nutriSyncBackground
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
                            .background(Color.white.opacity(0.1))
                        
                        // Activity Levels section
                        activityLevelsSection
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
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
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nutriSyncAccent)
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
                .font(.system(size: 20, weight: .semibold))
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
                .font(.system(size: 20, weight: .semibold))
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Your TDEE (Total Daily Energy Expenditure) is calculated using the Mifflin-St Jeor equation, which is considered one of the most accurate methods:")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 12) {
                calculationStep(number: "1", text: "Base Metabolic Rate (BMR) is calculated based on your age, weight, height, and gender")
                calculationStep(number: "2", text: "Your BMR is then multiplied by an activity factor based on your exercise frequency and daily activity level")
                calculationStep(number: "3", text: "The result is your TDEE - the total calories you burn per day")
            }
            
            // Activity Level Multipliers Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Level Multipliers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    multiplierRow(level: "Sedentary", value: "1.2")
                    multiplierRow(level: "Lightly Active", value: "1.375")
                    multiplierRow(level: "Moderately Active", value: "1.55", isHighlighted: calculatedActivityLevel == .moderatelyActive)
                    multiplierRow(level: "Very Active", value: "1.725", isHighlighted: calculatedActivityLevel == .veryActive)
                    multiplierRow(level: "Extremely Active", value: "1.9")
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
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
    
    private func calculationStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 20, height: 20)
                .background(Color.nutriSyncAccent.opacity(0.2))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    private func multiplierRow(level: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(level)
                .font(.system(size: 14))
                .foregroundColor(isHighlighted ? .nutriSyncAccent : .white.opacity(0.7))
            
            Spacer()
            
            Text("BMR × \(value)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isHighlighted ? .nutriSyncAccent : .white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHighlighted ? Color.nutriSyncAccent.opacity(0.1) : Color.clear)
        .cornerRadius(6)
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
                            Button(action: { coordinator.acceptHealthDisclaimer.toggle() }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if coordinator.acceptHealthDisclaimer {
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
                            Button(action: { coordinator.acceptPrivacyNotice.toggle() }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if coordinator.acceptPrivacyNotice {
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
                    if !coordinator.acceptHealthDisclaimer || !coordinator.acceptPrivacyNotice {
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
        ("Lose Weight", "minus"),
        ("Maintain Weight", "equal"),
        ("Gain Weight", "plus")
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
                    .padding(.bottom, 40)
                
                // Goal options
                VStack(spacing: 16) {
                    ForEach(goals, id: \.0) { goal, icon in
                        Button {
                            selectedGoal = goal
                            coordinator.goal = goal
                        } label: {
                            HStack(spacing: 16) {
                                // Left icon - meaningful symbol for each goal
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                // Goal text
                                Text(goal)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Radio button on the right
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 14, height: 14)
                                            .opacity(selectedGoal == goal ? 1 : 0)
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
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
        
        // Only load existing selection if there is one, don't set a default
        if !coordinator.goal.isEmpty {
            selectedGoal = coordinator.goal
        }
        // Remove the default selection - user must explicitly pick one
    }
}

struct TrendWeightContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var targetTrendWeight: Double = 0
    @State private var isInitialized = false
    
    private var currentWeightLbs: Int {
        Int(coordinator.weight * 2.20462)
    }
    
    private var weightRange: ClosedRange<Double> {
        Double(currentWeightLbs - 10)...Double(currentWeightLbs + 10)
    }
    
    private var validRange: ClosedRange<Double> {
        // For all goal types, allow full range
        weightRange
    }
    
    private var calorieRange: String {
        // Calculate TDEE
        let tdee = calculateTDEE()
        
        // For dynamic maintenance, show a range
        let lower = Int(tdee - 125)
        let upper = Int(tdee + 150)
        
        return "\(lower) - \(upper) kcal"
    }
    
    private func calculateTDEE() -> Double {
        // BMR calculation (Mifflin-St Jeor)
        let weightKg = coordinator.weight
        let heightCm = coordinator.height
        let age = coordinator.age
        
        var bmr: Double
        if coordinator.gender == "Male" {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
        
        // Activity multiplier
        let activityMultiplier: Double = {
            switch coordinator.activityLevel {
            case "Mostly Sedentary": return 1.2
            case "Lightly Active": return 1.375
            case "Moderately Active": return 1.55
            case "Very Active": return 1.725
            case "Extremely Active": return 1.9
            default: return 1.2
            }
        }()
        
        return bmr * activityMultiplier
    }
    
    private var explanationText: String {
        switch coordinator.goal.lowercased() {
        case "maintain weight":
            return "Dynamic maintenance will continuously adjust your targets to keep your trend weight within the target range."
        case "lose weight":
            return "We'll create a sustainable calorie deficit to help you reach your target weight safely."
        case "gain weight":
            return "We'll create a controlled calorie surplus to help you reach your target weight effectively."
        default:
            return "We'll adjust your nutrition plan to help you reach your target weight."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Set New Goal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Calorie range card (for maintenance)
                if coordinator.goal.lowercased() == "maintain weight" {
                    VStack(spacing: 8) {
                        Text(calorieRange)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("initial dynamic calorie range")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                // Explanation section
                VStack(alignment: .leading, spacing: 20) {
                    Text("What is dynamic \(coordinator.goal.lowercased() == "maintain weight" ? "maintenance" : "adjustment")?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("NutriSync's \(coordinator.goal.lowercased() == "maintain weight" ? "maintenance mode" : "goal mode") is dynamic. It will monitor your weight and metabolism and make small adjustments to your weekly macro plan to move your trend weight to the chosen target. That means that NutriSync may recommend a slight surplus or deficit even during \(coordinator.goal.lowercased() == "maintain weight" ? "maintenance" : "your journey").")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                
                // Target trend weight section
                VStack(alignment: .leading, spacing: 20) {
                    Text("What is your target trend weight?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    // Display selected weight
                    Text("\(Int(targetTrendWeight)) lbs")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 20)
                    
                    // Ruler Slider
                    RulerSlider(
                        value: $targetTrendWeight,
                        range: weightRange,
                        validRange: validRange,
                        step: 1.0
                    ) { newValue in
                        coordinator.targetWeight = newValue / 2.20462 // Convert to kg for storage
                    }
                    .frame(height: 60)
                }
                
                Spacer(minLength: 100)
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if let savedTarget = coordinator.targetWeight {
            targetTrendWeight = savedTarget * 2.20462 // Convert from kg to lbs
        } else {
            targetTrendWeight = Double(currentWeightLbs)
            coordinator.targetWeight = coordinator.weight // Set to current weight by default
        }
    }
}

struct GoalSummaryContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    private var currentWeightLbs: Int {
        Int(coordinator.weight * 2.20462)
    }
    
    private var targetWeightLbs: Int {
        Int((coordinator.targetWeight ?? coordinator.weight) * 2.20462)
    }
    
    private var targetRange: String {
        let target = Double(targetWeightLbs)
        let lower = target - 1.5
        let upper = target + 1.5
        return "\(String(format: "%.1f", lower)) - \(String(format: "%.1f", upper)) lbs"
    }
    
    private var goalTypeText: String {
        switch coordinator.goal.lowercased() {
        case "maintain weight":
            return "Maintenance"
        case "lose weight":
            return "Weight Loss"
        case "gain weight":
            return "Weight Gain"
        default:
            return coordinator.goal
        }
    }
    
    private var initialApproachTitle: String {
        switch coordinator.goal.lowercased() {
        case "maintain weight":
            let difference = currentWeightLbs - targetWeightLbs
            if abs(difference) <= 2 {
                return "Maintenance"
            } else if difference > 0 {
                return "Slow Weight Loss"
            } else {
                return "Slow Weight Gain"
            }
        case "lose weight":
            return "Sustainable Weight Loss"
        case "gain weight":
            return "Controlled Weight Gain"
        default:
            return "Personalized Approach"
        }
    }
    
    private var initialApproachDescription: String {
        let difference = currentWeightLbs - targetWeightLbs
        
        switch coordinator.goal.lowercased() {
        case "maintain weight":
            if abs(difference) <= 2 {
                return "Your trend weight is currently at \(currentWeightLbs) lbs, which is within your target range. We will maintain your current weight with dynamic adjustments to keep you within \(targetRange)."
            } else if difference > 0 {
                return "Your trend weight is currently \(currentWeightLbs) lbs, but you chose to maintain your weight at \(targetWeightLbs). We will set up your program to slowly lose weight at the rate of 0.15% of your body weight per week until you are within your target maintenance range. Then, we will update your plan weekly to keep you there."
            } else {
                return "Your trend weight is currently \(currentWeightLbs) lbs, but you chose to maintain your weight at \(targetWeightLbs). We will set up your program to slowly gain weight at the rate of 0.15% of your body weight per week until you are within your target maintenance range. Then, we will update your plan weekly to keep you there."
            }
            
        case "lose weight":
            return "Your current weight is \(currentWeightLbs) lbs, and your target weight is \(targetWeightLbs) lbs. We will set up your program to help you lose weight sustainably at a rate of 0.5-1% of your body weight per week. NutriSync will monitor your progress and adjust your calories dynamically to ensure steady, healthy weight loss while maintaining your energy and muscle mass."
            
        case "gain weight":
            return "Your current weight is \(currentWeightLbs) lbs, and your target weight is \(targetWeightLbs) lbs. We will set up your program to help you gain weight effectively at a rate of 0.25-0.5% of your body weight per week. NutriSync will monitor your progress and adjust your calories dynamically to promote lean muscle growth while minimizing excess fat gain."
            
        default:
            return "We will set up your program to help you reach your goals with dynamic adjustments based on your progress."
        }
    }
    
    private var mainExplanation: String {
        switch coordinator.goal.lowercased() {
        case "maintain weight":
            return "The maintenance mode is dynamic, and will continuously adjust your targets to keep your trend weight within the target range. Once your trend weight deviates from the target range, NutriSync will automatically suggest calories that correspond with a slow rate of weight gain or weight loss to move your trend weight back into the range."
        case "lose weight":
            return "The weight loss mode is dynamic, and will continuously adjust your targets to help you lose weight sustainably. NutriSync will monitor your progress and metabolism to ensure you're losing weight at a healthy rate while maintaining your energy levels and performance."
        case "gain weight":
            return "The weight gain mode is dynamic, and will continuously adjust your targets to help you gain weight effectively. NutriSync will monitor your progress to ensure you're gaining weight at a controlled rate while optimizing muscle growth and minimizing fat gain."
        default:
            return "NutriSync will dynamically adjust your nutrition plan based on your progress and goals."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Set New Goal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Goal Summary title
                HStack {
                    Text("Goal summary")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Goal type and target weight card
                HStack {
                    Text(goalTypeText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(targetWeightLbs) lbs")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Target Range section
                VStack(spacing: 20) {
                    HStack {
                        Text("Target Range")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(targetRange)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    
                    Text(mainExplanation)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Initial Approach section
                VStack(spacing: 20) {
                    HStack {
                        Text("Initial Approach")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(initialApproachTitle)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    
                    Text(initialApproachDescription)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
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

struct WeightGoalContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    // State
    @State private var targetWeight: Double = 0
    @State private var goalRate: Double = 0.75
    @State private var isInitialized = false
    
    // Computed properties
    var currentWeightLbs: Int {
        Int(coordinator.weight * 2.20462)
    }
    
    var targetWeightLbs: Int {
        Int(targetWeight)
    }
    
    var weightDifferenceLbs: Int {
        targetWeightLbs - currentWeightLbs
    }
    
    var dailyCalorieBudget: Int {
        let tdee = calculateTDEE()
        let weeklyGainLbs = goalRate
        let dailySurplus = (weeklyGainLbs * 3500) / 7
        
        if coordinator.goal.lowercased() == "gain weight" {
            return Int(tdee + dailySurplus)
        } else {
            return Int(tdee - dailySurplus)
        }
    }
    
    var projectedEndDate: Date {
        let totalChangeLbs = abs(Double(weightDifferenceLbs))
        let weeksToGoal = totalChangeLbs / goalRate
        return Date().addingTimeInterval(weeksToGoal * 7 * 86400)
    }
    
    var weightRange: ClosedRange<Double> {
        66.0...440.0 // 30kg to 200kg in lbs
    }
    
    var validWeightRange: ClosedRange<Double> {
        if coordinator.goal.lowercased() == "gain weight" {
            let maxGain = Double(currentWeightLbs + 75)
            return Double(currentWeightLbs)...min(440.0, maxGain)
        } else if coordinator.goal.lowercased() == "lose weight" {
            let maxLoss = Double(currentWeightLbs - 100)
            return max(66.0, maxLoss)...Double(currentWeightLbs)
        }
        return weightRange
    }
    
    var rateRange: ClosedRange<Double> {
        coordinator.goal.lowercased() == "gain weight" ? 0.5...1.0 : 0.5...2.0
    }
    
    var rateStep: Double {
        0.25
    }
    
    var shouldShowWarning: Bool {
        if coordinator.goal.lowercased() == "gain weight" {
            return abs(weightDifferenceLbs) > 50 || goalRate >= 1.0
        } else {
            return abs(weightDifferenceLbs) > 50 || goalRate >= 2.0
        }
    }
    
    var warningMessage: String {
        if abs(weightDifferenceLbs) > 50 {
            return "This is an ambitious goal. Consider consulting a nutritionist."
        } else if coordinator.goal.lowercased() == "gain weight" && goalRate >= 1.0 {
            return "Maximum safe gain rate selected"
        } else if coordinator.goal.lowercased() == "lose weight" && goalRate >= 2.0 {
            return "Maximum safe loss rate selected"
        }
        return ""
    }
    
    var rateLabel: String {
        if goalRate <= 0.5 {
            return "Gradual"
        } else if goalRate <= 0.75 {
            return "Standard (Recommended)"
        } else if goalRate <= 1.0 {
            return "Moderate"
        } else if goalRate <= 1.5 {
            return "Aggressive"
        } else {
            return "Very Aggressive"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Weight Goal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Info cards
                HStack(spacing: 12) {
                    InfoCard(
                        title: "initial daily budget",
                        value: "\(dailyCalorieBudget) kcal"
                    )
                    
                    InfoCard(
                        title: "projected end date",
                        value: formatDate(projectedEndDate)
                    )
                }
                .padding(.horizontal, 20)
                
                // Target weight section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is your target weight?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        Spacer()
                        Text("\(targetWeightLbs)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text("lbs")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                        Spacer()
                    }
                    
                    RulerSlider(
                        value: $targetWeight,
                        range: weightRange,
                        validRange: validWeightRange,
                        step: 1.0,
                        onChanged: { newValue in
                            saveToCoordinator()
                        }
                    )
                    .frame(height: 60)
                }
                .padding(.horizontal, 20)
                
                // Goal rate section with increased spacing
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is your target goal rate?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    Text(rateLabel)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    
                    Slider(
                        value: $goalRate,
                        in: rateRange
                    ) { _ in
                        // onEditingChanged - not needed
                    }
                    .tint(Color(hex: "C0FF73"))
                    .onChange(of: goalRate) { oldValue, newValue in
                        saveToCoordinator()
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(coordinator.goal.lowercased() == "gain weight" ? "+" : "-")\(String(format: "%.2f", goalRate)) lbs")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Per Week")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(coordinator.goal.lowercased() == "gain weight" ? "+" : "-")\(String(format: "%.1f", goalRate * 4.33)) lbs")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Per Month")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Warning banner if needed
                if shouldShowWarning && !warningMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text(warningMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 80)
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Initialize target weight
        if let savedTarget = coordinator.targetWeight {
            targetWeight = savedTarget * 2.20462 // Convert kg to lbs
        } else {
            // Set default based on goal
            if coordinator.goal.lowercased() == "lose weight" {
                targetWeight = Double(currentWeightLbs - 10)
            } else if coordinator.goal.lowercased() == "gain weight" {
                targetWeight = Double(currentWeightLbs + 10)
            } else {
                targetWeight = Double(currentWeightLbs)
            }
        }
        
        // Initialize goal rate
        if let savedRate = coordinator.weightLossRate {
            goalRate = savedRate
        } else {
            // Set default based on goal
            if coordinator.goal.lowercased() == "gain weight" {
                goalRate = 0.75 // Standard for gain
            } else {
                goalRate = 1.0 // Moderate for loss
            }
        }
        
        saveToCoordinator()
    }
    
    private func saveToCoordinator() {
        coordinator.targetWeight = targetWeight / 2.20462 // Convert lbs to kg
        coordinator.weightLossRate = goalRate
    }
    
    private func calculateTDEE() -> Double {
        // Use existing TDEE if available
        if let tdee = coordinator.tdee {
            return tdee
        }
        
        // Otherwise calculate based on current data
        let activityLevel = determineActivityLevel()
        let gender: TDEECalculator.Gender = coordinator.gender.lowercased() == "female" ? .female : .male
        
        return TDEECalculator.calculate(
            weight: coordinator.weight,
            height: coordinator.height,
            age: coordinator.age,
            gender: gender,
            activityLevel: activityLevel
        )
    }
    
    private func determineActivityLevel() -> TDEECalculator.ActivityLevel {
        // Simple mapping based on exercise frequency
        switch coordinator.exerciseFrequency {
        case "0 sessions / week":
            return .sedentary
        case "1-3 sessions / week":
            return .lightlyActive
        case "4-6 sessions / week":
            return .moderatelyActive
        case "7+ sessions / week":
            return .veryActive
        default:
            return .sedentary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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

struct DietPreferenceContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedDiet: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("What's Your Diet Style?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Select the approach that fits your lifestyle")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Diet options
                VStack(spacing: 12) {
                    // Diet option cards
                    ForEach([
                        ("Balanced", "Flexible approach with all food groups", "scale.3d"),
                        ("Keto", "High fat, low carb for ketosis", "flame"),
                        ("Paleo", "Whole foods, no processed items", "leaf"),
                        ("Mediterranean", "Heart-healthy fats and lean proteins", "heart"),
                        ("Plant-Based", "Vegetarian or vegan focused", "carrot"),
                        ("Custom", "Create your own approach", "slider.horizontal.3")
                    ], id: \.0) { diet, description, icon in
                        Button(action: {
                            selectedDiet = diet
                            coordinator.dietPreference = diet
                        }) {
                            HStack(spacing: 16) {
                                // Icon
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "C0FF73"))
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(diet)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                Image(systemName: selectedDiet == diet ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedDiet == diet ? .white : .white.opacity(0.3))
                            }
                            .padding(16)
                            .background(Color.white.opacity(selectedDiet == diet ? 0.08 : 0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedDiet == diet ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

struct TrainingPlanContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedFrequency: String? = nil
    @State private var selectedTime: String? = nil
    
    var canProceed: Bool {
        selectedFrequency != nil && selectedTime != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Training Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Help us optimize your meal timing around workouts")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Training plan options
                VStack(spacing: 20) {
                    // Training frequency selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How often do you train?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(spacing: 12) {
                            ForEach([
                                ("None", "No regular training", "figure.stand"),
                                ("1-2x/week", "Light activity", "figure.walk"),
                                ("3-4x/week", "Moderate training", "figure.run"),
                                ("5-6x/week", "Frequent training", "flame.fill"),
                                ("Daily", "Training every day", "bolt.fill")
                            ], id: \.0) { frequency, description, icon in
                                Button(action: {
                                    selectedFrequency = frequency
                                    coordinator.trainingFrequency = frequency
                                }) {
                                    HStack {
                                        // Add lime green icon
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(.nutriSyncAccent)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(frequency)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            Text(description)
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        Spacer()
                                        Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedFrequency == frequency ? .nutriSyncAccent : .white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(selectedFrequency == frequency ? 0.08 : 0.05))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedFrequency == frequency ? Color.nutriSyncAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Training time preference
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred training time")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 8) {
                            ForEach(["Morning", "Afternoon", "Evening", "Varies"], id: \.self) { time in
                                Button(action: {
                                    selectedTime = time
                                    coordinator.trainingTime = time
                                }) {
                                    Text(time)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedTime == time ? Color.nutriSyncBackground : .white.opacity(0.7))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedTime == time ? Color.nutriSyncAccent : Color.white.opacity(0.08))
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedTime == time ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                        .fixedSize()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

struct SleepScheduleContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var bedtimeHour: Int = 23  // 11 PM default
    @State private var bedtimeMinute: Int = 0
    @State private var wakeTimeHour: Int = 7  // 7 AM default
    @State private var wakeTimeMinute: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Sleep Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Optimize meal timing for better sleep and recovery")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Sleep schedule input
                VStack(spacing: 32) {
                    // Bedtime selector
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.nutriSyncAccent)
                            Text("Usual Bedtime")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        // Custom time picker
                        HStack(spacing: 0) {
                            // Hour picker
                            Picker("", selection: $bedtimeHour) {
                                ForEach(0..<24) { hour in
                                    Text(String(format: "%02d", hour))
                                        .tag(hour)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                            
                            Text(":")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                            
                            // Minute picker (15-min intervals)
                            Picker("", selection: $bedtimeMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                            
                            // AM/PM indicator
                            Text(bedtimeHour < 12 ? "AM" : "PM")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    
                    // Wake time selector
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.nutriSyncAccent)
                            Text("Wake Up Time")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        // Custom time picker
                        HStack(spacing: 0) {
                            // Hour picker
                            Picker("", selection: $wakeTimeHour) {
                                ForEach(0..<24) { hour in
                                    Text(String(format: "%02d", hour))
                                        .tag(hour)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                            
                            Text(":")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                            
                            // Minute picker (15-min intervals)
                            Picker("", selection: $wakeTimeMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                            
                            // AM/PM indicator
                            Text(wakeTimeHour < 12 ? "AM" : "PM")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    
                    // Sleep duration indicator
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.nutriSyncAccent.opacity(0.6))
                            Text("About \(calculateSleepDuration()) of sleep")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            // Load saved times if available
            if let bedtime = coordinator.bedTime {
                let calendar = Calendar.current
                bedtimeHour = calendar.component(.hour, from: bedtime)
                bedtimeMinute = calendar.component(.minute, from: bedtime)
            }
            if let wakeTime = coordinator.wakeTime {
                let calendar = Calendar.current
                wakeTimeHour = calendar.component(.hour, from: wakeTime)
                wakeTimeMinute = calendar.component(.minute, from: wakeTime)
            }
        }
        .onDisappear {
            // Save selected times when leaving the screen
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let bedtimeComponents = DateComponents(hour: bedtimeHour, minute: bedtimeMinute)
            if let bedtime = calendar.date(from: bedtimeComponents) {
                coordinator.bedTime = bedtime
            }
            
            let wakeTimeComponents = DateComponents(hour: wakeTimeHour, minute: wakeTimeMinute)
            if let wakeTime = calendar.date(from: wakeTimeComponents) {
                coordinator.wakeTime = wakeTime
            }
        }
    }
    
    private func calculateSleepDuration() -> String {
        var sleepMinutes: Int
        
        // Calculate total minutes, accounting for crossing midnight
        if bedtimeHour < wakeTimeHour || (bedtimeHour == wakeTimeHour && bedtimeMinute < wakeTimeMinute) {
            // Normal case: bedtime is after midnight or wake time is after bedtime same day
            let bedtimeTotal = bedtimeHour * 60 + bedtimeMinute
            let wakeTimeTotal = wakeTimeHour * 60 + wakeTimeMinute
            sleepMinutes = wakeTimeTotal - bedtimeTotal
        } else {
            // Crossing midnight case
            let minutesUntilMidnight = (24 * 60) - (bedtimeHour * 60 + bedtimeMinute)
            let minutesAfterMidnight = wakeTimeHour * 60 + wakeTimeMinute
            sleepMinutes = minutesUntilMidnight + minutesAfterMidnight
        }
        
        let hours = sleepMinutes / 60
        let minutes = sleepMinutes % 60
        
        if minutes == 0 {
            return "\(hours) hours"
        } else if minutes == 15 {
            return "\(hours)¼ hours"
        } else if minutes == 30 {
            return "\(hours)½ hours"
        } else {
            return "\(hours)¾ hours"
        }
    }
}

struct MealFrequencyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedMealCount: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("How Often Do You Eat?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Choose your ideal number of daily meals")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Meal frequency options
                VStack(spacing: 20) {
                    // Meal frequency grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach([
                            ("2 Meals", "Intermittent fasting"),
                            ("3 Meals", "Traditional approach"),
                            ("4 Meals", "Balanced frequency"),
                            ("5 Meals", "Frequent feeding"),
                            ("6 Meals", "Bodybuilder style"),
                            ("Flexible", "Varies by day")
                        ], id: \.0) { meals, style in
                            Button(action: {
                                selectedMealCount = meals
                                coordinator.mealFrequency = meals
                            }) {
                                VStack(spacing: 8) {
                                    Text(meals)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(style)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(Color.white.opacity(selectedMealCount == meals ? 0.08 : 0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedMealCount == meals ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: selectedMealCount == meals ? 2 : 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Info section
                    VStack(spacing: 12) {
                        Text("Consider your schedule")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text("We'll optimize your meal windows based on your daily routine and training schedule")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

struct EatingWindowContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedWindow: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Define Your Eating Window")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Set your daily fasting and eating periods")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Eating window configuration
                VStack(spacing: 28) {
                    // Visual window display
                    VStack(spacing: 16) {
                        // 24-hour timeline visualization
                        VStack(spacing: 12) {
                            HStack {
                                Text("12 AM")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("12 PM")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("11 PM")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            // Timeline bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Full day track
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    // Eating window (example: 12 PM to 8 PM)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.nutriSyncAccent.opacity(0.6)) // Lime green for eating window
                                        .frame(width: geometry.size.width * 0.33)
                                        .offset(x: geometry.size.width * 0.5)
                                }
                            }
                            .frame(height: 40)
                        }
                        
                        // Window stats
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("16")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("hours fasting")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            VStack(spacing: 4) {
                                Text("8")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("hours eating")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Preset options
                    VStack(spacing: 12) {
                        Text("Popular Windows")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 10) {
                            ForEach([
                                ("16:8", "Fast 16 hrs, eat 8 hrs"),
                                ("18:6", "Fast 18 hrs, eat 6 hrs"),
                                ("14:10", "Fast 14 hrs, eat 10 hrs"),
                                ("Custom", "Set your own window")
                            ], id: \.0) { window, description in
                                Button(action: {
                                    selectedWindow = window
                                }) {
                                    HStack {
                                        Text(window)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                        Spacer()
                                        Image(systemName: selectedWindow == window ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedWindow == window ? .nutriSyncAccent : .white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(selectedWindow == window ? 0.08 : 0.05))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedWindow == window ? Color.nutriSyncAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
    }
}

struct DietaryRestrictionsContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedRestrictions: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Dietary Restrictions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Tell us what foods to avoid in your meal plans")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Main content - Dietary restrictions list
                VStack(spacing: 20) {
                    // Restrictions checklist
                    VStack(spacing: 12) {
                        ForEach([
                            ("Dairy-Free", "lactose", "allergens"),
                            ("Gluten-Free", "wheat", "wheat.circle"),
                            ("Nut-Free", "tree nuts", "allergens.fill"),
                            ("Shellfish-Free", "seafood", "fish"),
                            ("Soy-Free", "soy products", "leaf"),
                            ("Egg-Free", "eggs", "oval"),
                            ("Low Sodium", "salt restricted", "drop.triangle"),
                            ("Sugar-Free", "added sugars", "cube.fill")
                        ], id: \.0) { restriction, detail, icon in
                            Button(action: {
                                if selectedRestrictions.contains(restriction) {
                                    selectedRestrictions.remove(restriction)
                                } else {
                                    selectedRestrictions.insert(restriction)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // Add lime green icon
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(.nutriSyncAccent)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(restriction)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Avoid \(detail)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedRestrictions.contains(restriction) ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22))
                                        .foregroundColor(selectedRestrictions.contains(restriction) ? .nutriSyncAccent : .white.opacity(0.3))
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Skip option
                    Button(action: {}) {
                        Text("No restrictions")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
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