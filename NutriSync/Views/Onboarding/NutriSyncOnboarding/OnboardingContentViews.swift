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

        // Daily activity scoring (0-4 points, WEIGHTED MORE HEAVILY)
        // Rationale: Daily activity is 24/7 (~168 hrs/week) while exercise is only a few hours/week
        // Someone sedentary all day shouldn't be "moderately active" just from 5 hours of weekly exercise
        let activityScore: Int
        // Check dailyActivity first, then fall back to activityLevel if needed for migration
        let dailyActivityValue = !coordinator.dailyActivity.isEmpty ? coordinator.dailyActivity :
                                 (coordinator.activityLevel == "Mostly Sedentary" ||
                                  coordinator.activityLevel == "Moderately Active" ||
                                  coordinator.activityLevel == "Very Active") ? coordinator.activityLevel : "Mostly Sedentary"

        print("[ActivityLevel] Daily activity value: '\(dailyActivityValue)'")

        if dailyActivityValue.contains("Very Active") {
            activityScore = 4  // Weighted double (was 2) - standing/moving most of the day
        } else if dailyActivityValue.contains("Moderately Active") {
            activityScore = 2  // Weighted double (was 1) - mix of sitting and movement
        } else {
            activityScore = 0  // Mostly Sedentary - desk job, minimal movement
        }

        print("[ActivityLevel] Daily activity score: \(activityScore) (weighted)")

        // Combine scores (max 7 points now)
        let totalScore = exerciseScore + activityScore

        print("[ActivityLevel] Total score: \(totalScore) (\(exerciseScore) exercise + \(activityScore) daily activity)")

        // Map total score to activity level
        // Daily activity weight reflects that it affects calorie burn more than occasional exercise
        let combinedLevel: TDEECalculator.ActivityLevel
        switch totalScore {
        case 0:
            combinedLevel = .sedentary           // No exercise + sedentary
        case 1...2:
            combinedLevel = .lightlyActive       // Light-moderate exercise + sedentary, OR light exercise + moderate daily
        case 3...4:
            combinedLevel = .moderatelyActive    // Moderate exercise + moderate daily, OR heavy exercise + sedentary
        case 5...6:
            combinedLevel = .veryActive          // Heavy exercise + moderate daily, OR moderate exercise + very active daily
        case 7:
            combinedLevel = .veryActive          // Maximum (7+ exercise + very active daily)
        default:
            combinedLevel = .sedentary
        }

        print("[ActivityLevel] Final result: \(combinedLevel.rawValue) (multiplier: \(combinedLevel.multiplier)x)")

        return combinedLevel
    }
}

// MARK: - Story Section Content Views

struct WelcomeToNutriSyncContentView: View {
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer(minLength: 40)

                // Large logo visual
                ZStack {
                    // Subtle radial gradient background (reduced glow)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.nutriSyncAccent.opacity(0.12),
                                    Color.nutriSyncAccent.opacity(0.04),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 180, height: 180)

                    // Use actual app logo (bigger)
                    Image("appLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                }
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)

                // Headline
                Text("Welcome to NutriSync")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Subtitle
                Text("Your daily meal plan, personalized and ready")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Value props
                VStack(alignment: .leading, spacing: 16) {
                    ValuePropRow(icon: "calendar.badge.checkmark", text: "Get a complete daily eating plan, not just a calorie target")
                    ValuePropRow(icon: "lightbulb.fill", text: "Know exactly what to eat, when, and how much")
                    ValuePropRow(icon: "arrow.triangle.2.circlepath", text: "AI adapts your plan as your life changes")
                    ValuePropRow(icon: "chart.xyaxis.line", text: "Science-backed meal timing optimization")
                }
                .padding(.horizontal, 30)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct ValuePropRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 30)

            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

struct PlanAdvantageContentView: View {
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("The NutriSync Difference")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .opacity(showContent ? 1 : 0)

                // Subtitle
                Text("More than a calorie target")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .opacity(showContent ? 1 : 0)

                // Problem section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red.opacity(0.85))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Traditional Apps")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))

                            Text("\"Hit 2,500 calories today\"")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PainPointQuestionRow(
                            prefix: "But ",
                            painpoint: "when",
                            suffix: " should I eat?"
                        )
                        PainPointQuestionRow(
                            prefix: "",
                            painpoint: "How much",
                            suffix: " per meal?"
                        )
                        PainPointQuestionRow(
                            prefix: "What if I get ",
                            painpoint: "hungry",
                            suffix: " between meals?"
                        )
                        PainPointQuestionRow(
                            prefix: "Should I eat ",
                            painpoint: "before or after",
                            suffix: " my workout?"
                        )
                    }
                    .padding(.leading, 40)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                )
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)

                // Arrow indicator
                Image(systemName: "arrow.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.nutriSyncAccent)
                    .padding(.bottom, 24)
                    .opacity(showContent ? 1 : 0)

                // Solution section - NutriSync (mimics actual app components)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.nutriSyncAccent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("NutriSync")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.nutriSyncAccent)

                            Text("Your complete daily plan")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }

                    // Mini schedule preview (mimics actual app window cards)
                    VStack(spacing: 8) {
                        MiniWindowCard(
                            time: "7:00 AM",
                            calories: 450,
                            label: "Breakfast",
                            purpose: "Kickstart metabolism",
                            icon: "sunrise.fill",
                            color: .orange
                        )

                        MiniWindowCard(
                            time: "12:30 PM",
                            calories: 650,
                            label: "Pre-workout",
                            purpose: "Fuel performance",
                            icon: "figure.run",
                            color: .blue
                        )

                        MiniWindowCard(
                            time: "6:00 PM",
                            calories: 850,
                            label: "Dinner",
                            purpose: "Recovery & repair",
                            icon: "moon.stars.fill",
                            color: .purple
                        )

                        MiniWindowCard(
                            time: "8:30 PM",
                            calories: 400,
                            label: "Evening",
                            purpose: "Light & satisfying",
                            icon: "sparkles",
                            color: Color.nutriSyncAccent
                        )
                    }

                    Divider()
                        .background(Color.nutriSyncAccent.opacity(0.4))
                        .padding(.vertical, 8)

                    HStack {
                        Text("Total:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Text("2,350 calories")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.nutriSyncAccent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nutriSyncAccent, lineWidth: 2)
                )
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .opacity(showContent ? 1 : 0)

                // Key benefits
                VStack(spacing: 16) {
                    PlanBenefitRow(icon: "brain.head.profile", text: "No more decision fatigue")
                    PlanBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Optimized for your goals")
                    PlanBenefitRow(icon: "sparkles", text: "AI adapts to your life")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// Mini window card that mimics the actual app's window component design
struct MiniWindowCard: View {
    let time: String
    let calories: Int
    let label: String
    let purpose: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle (like the real app)
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(time)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(calories) cal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.nutriSyncAccent)

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))

                    Text(label)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(purpose)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// New helper views for redesigned screen
struct QuestionRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.white.opacity(0.5))

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
                .italic()
        }
    }
}

// Painpoint question row with red highlighted keywords
struct PainPointQuestionRow: View {
    let prefix: String
    let painpoint: String
    let suffix: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 5)

            (Text(prefix)
                .foregroundColor(.white.opacity(0.75))
             + Text(painpoint)
                .foregroundColor(.red.opacity(0.9))
                .bold()
             + Text(suffix)
                .foregroundColor(.white.opacity(0.75))
            )
            .font(.system(size: 16, weight: .medium))
            .italic()
        }
    }
}

struct PlanDetailRow: View {
    let time: String
    let calories: String
    let label: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(time)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text(calories)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nutriSyncAccent)

                    Text("• \(label)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
    }
}

struct PlanBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

struct MealPlanRow: View {
    let time: String
    let calories: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.nutriSyncAccent)

            Text("\(time) - \(calories)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text("(\(label))")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

            Spacer()
        }
    }
}

struct ComparisonRow: View {
    let before: String
    let after: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(before)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(.nutriSyncAccent)

            Text(after)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Personalized Windows Preview View Model

@MainActor
class PersonalizedWindowsPreviewViewModel: ObservableObject {
    @Published var previewWindows: [MealWindow] = []
    @Published var previewMeals: [LoggedMeal] = []

    // Create a mock ScheduleViewModel for ExpandableWindowBanner
    let scheduleViewModel = ScheduleViewModel()

    init() {
        generatePreviewData()
    }

    deinit {
        // Reset time simulation when view model is destroyed
        Task { @MainActor in
            TimeProvider.shared.resetToRealTime()
        }
    }

    private func generatePreviewData() {
        let calendar = Calendar.current
        let now = Date()

        // Simulate current time as 2:30 PM today for preview purposes
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 14
        components.minute = 30
        let simulatedNow = calendar.date(from: components)!

        // Set simulated time so ExpandableWindowBanner shows correct states
        TimeProvider.shared.setSimulatedTime(simulatedNow)

        // 1. Completed Breakfast Window (7:00-8:30 AM) - Past, with meals
        components.hour = 7
        components.minute = 0
        let breakfastStart = calendar.date(from: components)!
        components.hour = 8
        components.minute = 30
        let breakfastEnd = calendar.date(from: components)!

        var breakfastWindow = MealWindow(
            name: "Morning Fuel",
            startTime: breakfastStart,
            endTime: breakfastEnd,
            targetCalories: 450,
            targetProtein: 35,
            targetCarbs: 45,
            targetFat: 12,
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            type: .regular,
            foodSuggestions: ["Oatmeal", "Greek Yogurt", "Berries"],
            micronutrientFocus: ["Fiber", "Vitamin B"],
            rationale: "Start your day with sustained energy"
        )

        // Mark breakfast as consumed
        breakfastWindow.consumed = MealWindow.ConsumedMacros(
            calories: 420,
            protein: 32,
            carbs: 48,
            fat: 10
        )

        // Create a meal for breakfast
        components.hour = 7
        components.minute = 15
        let breakfastMealTime = calendar.date(from: components)!

        let breakfastMeal = LoggedMeal(
            name: "Oatmeal with berries and almonds",
            calories: 420,
            protein: 32,
            carbs: 48,
            fat: 10,
            timestamp: breakfastMealTime,
            windowId: UUID(uuidString: breakfastWindow.id)
        )

        // 2. Missed Lunch Window (12:30-1:30 PM) - Past, no meals, with redistribution
        components.hour = 12
        components.minute = 30
        let lunchStart = calendar.date(from: components)!
        components.hour = 13
        components.minute = 30
        let lunchEnd = calendar.date(from: components)!

        var lunchWindow = MealWindow(
            name: "Pre-Gym Power",
            startTime: lunchStart,
            endTime: lunchEnd,
            targetCalories: 550,
            targetProtein: 40,
            targetCarbs: 60,
            targetFat: 15,
            purpose: .preWorkout,
            flexibility: .moderate,
            type: .regular,
            foodSuggestions: ["Grilled Chicken", "Sweet Potato", "Vegetables"],
            micronutrientFocus: ["Protein", "Complex Carbs"],
            rationale: "Fuel up before afternoon workout"
        )

        // Mark as having redistribution
        lunchWindow.redistributionReason = .missedWindow

        // 3. Upcoming Afternoon Window (3:00-4:00 PM) - Active/Upcoming
        components.hour = 15
        components.minute = 0
        let afternoonStart = calendar.date(from: components)!
        components.hour = 16
        components.minute = 0
        let afternoonEnd = calendar.date(from: components)!

        let afternoonWindow = MealWindow(
            name: "Brain Food",
            startTime: afternoonStart,
            endTime: afternoonEnd,
            targetCalories: 350,
            targetProtein: 25,
            targetCarbs: 35,
            targetFat: 12,
            purpose: .focusBoost,
            flexibility: .flexible,
            type: .snack,
            foodSuggestions: ["Protein Shake", "Nuts", "Fruit"],
            micronutrientFocus: ["Quick Energy"],
            rationale: "Light snack to maintain focus"
        )

        previewWindows = [breakfastWindow, lunchWindow, afternoonWindow]
        previewMeals = [breakfastMeal]

        // Set the windows in the schedule view model for proper rendering
        scheduleViewModel.mealWindows = previewWindows
        scheduleViewModel.todaysMeals = previewMeals
    }

    func mealsForWindow(_ window: MealWindow) -> [LoggedMeal] {
        previewMeals.filter { meal in
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
}

struct YourDayOptimizedContentView: View {
    @State private var showContent = false
    @StateObject private var mockViewModel = PersonalizedWindowsPreviewViewModel()
    @Namespace private var animationNamespace
    @State private var selectedWindow: MealWindow?
    @State private var showWindowDetail = false

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Personalized Windows")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .opacity(showContent ? 1 : 0)

                // Subtitle with time context
                Text("Here's what your day looks like")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                    .opacity(showContent ? 1 : 0)

                // Current time indicator
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text("Current time: 2:30 PM")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.nutriSyncAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.nutriSyncAccent.opacity(0.15))
                .cornerRadius(20)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)

                // Real window previews using ExpandableWindowBanner
                VStack(spacing: 12) {
                    ForEach(mockViewModel.previewWindows) { window in
                        ExpandableWindowBanner(
                            window: window,
                            meals: mockViewModel.mealsForWindow(window),
                            selectedWindow: $selectedWindow,
                            showWindowDetail: $showWindowDetail,
                            animationNamespace: animationNamespace,
                            viewModel: mockViewModel.scheduleViewModel,
                            bannerHeight: nil
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)

                // Simplified "Never Fall Behind" callout
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.nutriSyncAccent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Never Fall Behind")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text("Missed calories automatically redistribute to keep you on track")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.nutriSyncAccent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.nutriSyncAccent.opacity(0.25), lineWidth: 1.5)
                )
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// Compact window card for the example
struct CompactWindowCard: View {
    let time: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(time)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    Label("\(calories) cal", systemImage: "flame.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.nutriSyncAccent)

                    Text("\(protein)g P")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Text("\(carbs)g C")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// Benefit card for the grid
struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1.5)
        )
        .cornerRadius(12)
    }
}

struct TimelineWindow: View {
    let time: String
    let icon: String
    let title: String
    let calories: String
    let description: String
    var isOptional: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time + Icon column
            VStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.nutriSyncAccent)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.nutriSyncAccent)
            }
            .frame(width: 80)

            // Content column
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(calories)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)

                if isOptional {
                    Text("Optional")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nutriSyncAccent.opacity(0.8))
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct ReadyToBuildContentView: View {
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Ready to Build Your Plan?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("We'll do the hard part (AI meal planning).\nYou answer 3 quick questions:")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Three cards
                VStack(spacing: 20) {
                    QuestionCard(
                        icon: "chart.bar.fill",
                        title: "Your Energy System",
                        subtitle: "How many calories you burn daily",
                        note: "(We'll calculate it for you)"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

                    QuestionCard(
                        icon: "target",
                        title: "Your Goal",
                        subtitle: "What you're working toward",
                        note: "(Weight, performance, or balance)"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

                    QuestionCard(
                        icon: "clock.fill",
                        title: "Your Rhythm",
                        subtitle: "When you wake, sleep, and move",
                        note: "(So we can time everything perfectly)"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Time estimate
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundColor(.nutriSyncAccent)

                    Text("Takes 2 minutes. Your personalized plan is on the other side.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 30)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct QuestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let note: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))

                Text(note)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
            }

            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
}

// MARK: - Notice Section Content Views

struct HealthDisclaimerContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var showAIDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Terms & AI Consent")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Please review and accept our terms")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                // AI Notice Box (Prominent)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.nutriSyncAccent)
                        Text("AI-Powered App")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("NutriSync uses artificial intelligence to analyze your meals and create personalized eating schedules. **AI features are required** to use this app.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: { showAIDetails.toggle() }) {
                        HStack {
                            Text(showAIDetails ? "Hide Details" : "Learn More About AI")
                                .font(.system(size: 15, weight: .medium))
                            Image(systemName: showAIDetails ? "chevron.up" : "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.nutriSyncAccent)
                    }

                    if showAIDetails {
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.vertical, 8)

                            AIDetailItem(
                                icon: "camera.fill",
                                title: "AI Meal Analysis",
                                description: "We analyze your meal photos and voice descriptions using Google's Gemini AI to estimate calories, macros, and ingredients."
                            )

                            AIDetailItem(
                                icon: "calendar",
                                title: "AI Meal Window Generation",
                                description: "We use AI to create personalized eating schedules that tell you when to eat based on your goals, sleep schedule, and preferences."
                            )

                            AIDetailItem(
                                icon: "network",
                                title: "Data Shared with Google",
                                description: "Your meal photos, dietary restrictions, nutrition goals, and meal history are sent to Google Vertex AI for processing. Google does not store your meal photos permanently."
                            )

                            AIDetailItem(
                                icon: "hand.raised.fill",
                                title: "Your Control",
                                description: "You can delete your account and all data at any time in Settings > Account. This will remove your information from our systems and Google's AI."
                            )
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Checkboxes
                VStack(alignment: .leading, spacing: 20) {
                    // Health Disclaimer
                    ConsentCheckbox(
                        isChecked: coordinator.acceptHealthDisclaimer,
                        title: "Health Disclaimer",
                        description: "I understand this is educational information, not medical advice. I will consult healthcare professionals for medical decisions.",
                        linkText: nil,
                        linkAction: nil
                    ) {
                        coordinator.acceptHealthDisclaimer.toggle()
                    }

                    // Privacy Notice
                    ConsentCheckbox(
                        isChecked: coordinator.acceptPrivacyNotice,
                        title: "Consumer Health Privacy Notice",
                        description: "I acknowledge that NutriSync collects sensitive health information to provide personalized nutrition guidance.",
                        linkText: nil,
                        linkAction: nil
                    ) {
                        coordinator.acceptPrivacyNotice.toggle()
                    }

                    // AI Consent (NEW - Required)
                    ConsentCheckbox(
                        isChecked: coordinator.acceptAIConsent,
                        title: "AI Processing & Data Sharing",
                        description: "I consent to AI analysis of my meals and sharing my data with Google Vertex AI. I understand AI features are required to use NutriSync.",
                        linkText: "Learn More About AI",
                        linkAction: { showAIDetails = true },
                        isRequired: true
                    ) {
                        coordinator.acceptAIConsent.toggle()
                    }
                }
                .padding(.horizontal, 20)

                // Status text
                if !allTermsAccepted {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Please accept all terms to continue")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 24)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.nutriSyncAccent)
                        Text("All terms accepted")
                            .font(.system(size: 15))
                            .foregroundColor(.nutriSyncAccent)
                    }
                    .padding(.top, 24)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 40)
        }
    }

    private var allTermsAccepted: Bool {
        coordinator.acceptHealthDisclaimer &&
        coordinator.acceptPrivacyNotice &&
        coordinator.acceptAIConsent
    }
}

// MARK: - Helper Views for AI Consent

/// Detail item for explaining AI features
struct AIDetailItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Consent checkbox with description and optional link
struct ConsentCheckbox: View {
    let isChecked: Bool
    let title: String
    let description: String
    let linkText: String?
    let linkAction: (() -> Void)?
    var isRequired: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button(action: action) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isChecked ? Color.nutriSyncAccent : Color.white.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.nutriSyncAccent)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        if isRequired {
                            Text("REQUIRED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.nutriSyncAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.nutriSyncAccent.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    if let linkText = linkText {
                        Button(action: { linkAction?() }) {
                            Text(linkText)
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct YourPlanEvolvesContentView: View {
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Plan Evolves With You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("This isn't a rigid meal plan. It's a living system that learns your patterns.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Timeline scenarios
                VStack(spacing: 24) {
                    // Monday: Normal Schedule
                    DayScenario(
                        day: "Monday: Normal Schedule",
                        times: ["7:00 AM", "12:30 PM", "6:00 PM", "8:30 PM"],
                        description: "Perfect for your usual routine"
                    )

                    // Tuesday: Stuck in Meetings
                    DayScenario(
                        day: "Tuesday: Stuck in Meetings",
                        times: ["9:30 AM", "2:00 PM", "7:30 PM"],
                        description: "Windows automatically shift 2 hours later",
                        isHighlighted: true
                    )

                    // Weekend: Sleeping In
                    DayScenario(
                        day: "Weekend: Sleeping In",
                        times: ["10:00 AM", "1:00 PM", "8:00 PM"],
                        description: "Adjusted for relaxed mornings"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Real scenarios
                VStack(alignment: .leading, spacing: 16) {
                    Text("Real scenarios where NutriSync adapts:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        AdaptationScenario(text: "Morning meeting runs long? First window shifts")
                        AdaptationScenario(text: "Gym time changes? Pre-workout nutrition moves with it")
                        AdaptationScenario(text: "Late dinner with friends? Evening window flexes")
                        AdaptationScenario(text: "Traveling across time zones? Plan adjusts automatically")
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 80)
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct DayScenario: View {
    let day: String
    let times: [String]
    let description: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isHighlighted ? .nutriSyncAccent : .white)

            HStack(spacing: 8) {
                ForEach(times, id: \.self) { time in
                    Text(time)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isHighlighted ? .nutriSyncAccent : .white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isHighlighted ? Color.nutriSyncAccent.opacity(0.15) : Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
            }

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .italic()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

struct AdaptationScenario: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// Keep old view name for backward compatibility during transition
typealias NotToWorryContentView = YourPlanEvolvesContentView

// MARK: - Goal Setting Section Content Views

struct YourTransformationContentView: View {
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Your Transformation Journey")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("What changes when you optimize meal timing")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Week-by-week breakdown
                VStack(spacing: 24) {
                    OnboardingTransformationPhase(
                        weeks: "Week 1-2: Foundation",
                        benefits: [
                            "No more \"what should I eat now?\" decisions",
                            "Energy stabilizes throughout the day",
                            "Sleep quality improves (better timing = better recovery)"
                        ]
                    )

                    OnboardingTransformationPhase(
                        weeks: "Week 3-6: Momentum",
                        benefits: [
                            "Cravings decrease (your body knows when food is coming)",
                            "Progress stays consistent without extreme hunger",
                            "Workouts feel stronger (nutrition timed right)"
                        ],
                        isHighlighted: true
                    )

                    OnboardingTransformationPhase(
                        weeks: "Week 7-12: Transformation",
                        benefits: [
                            "Reach your goals while maintaining muscle",
                            "Eating feels effortless, not restrictive",
                            "Habits locked in - no more yo-yo dieting"
                        ]
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Science note
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundColor(.nutriSyncAccent)

                        Text("The Science")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.nutriSyncAccent)
                    }

                    Text("Studies show circadian-aligned nutrition can improve results by 30% compared to random eating patterns, while preserving muscle mass.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.nutriSyncAccent.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)

                Spacer(minLength: 80)
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct OnboardingTransformationPhase: View {
    let weeks: String
    let benefits: [String]
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weeks)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isHighlighted ? .nutriSyncAccent : .white)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isHighlighted ? .nutriSyncAccent : .white.opacity(0.8))
                            .padding(.top, 2)

                        Text(benefit)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(isHighlighted ? Color.nutriSyncAccent.opacity(0.08) : Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.nutriSyncAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// Keep old view name for backward compatibility during transition
typealias GoalSettingIntroContentView = YourTransformationContentView

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
                Text("What are your weight goals?")
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
                            .background(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedGoal == goal ? Color.white : Color.white.opacity(0.2), lineWidth: selectedGoal == goal ? 2 : 1)
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
                                // Radio button (left side)
                                ZStack {
                                    Circle()
                                        .stroke(selectedDiet == diet ? Color(hex: "C0FF73") : Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 24, height: 24)

                                    if selectedDiet == diet {
                                        Circle()
                                            .fill(Color(hex: "C0FF73"))
                                            .frame(width: 12, height: 12)
                                    }
                                }

                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(diet)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)

                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "C0FF73"))
                                    }

                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(selectedDiet == diet ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedDiet == diet ? Color(hex: "C0FF73").opacity(0.5) : Color.clear, lineWidth: 1.5)
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
            let calendar = Calendar.current
            bedtimeHour = calendar.component(.hour, from: coordinator.bedTime)
            bedtimeMinute = calendar.component(.minute, from: coordinator.bedTime)
            wakeTimeHour = calendar.component(.hour, from: coordinator.wakeTime)
            wakeTimeMinute = calendar.component(.minute, from: coordinator.wakeTime)
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
                VStack(spacing: 16) {
                    // Meal frequency cards with icons
                    ForEach([
                        ("2-3 Meals", "3", "Intermittent fasting style • Longer periods between meals", "moon.stars.fill", Color.blue),
                        ("3-4 Meals", "4", "Recommended • Balanced approach for most goals", "sun.max.fill", Color(hex: "C0FF73")),
                        ("5-6 Meals", "6", "Frequent feeding • Ideal for muscle gain and active lifestyles", "flame.fill", Color.orange)
                    ], id: \.0) { display, value, description, icon, iconColor in
                        Button(action: {
                            selectedMealCount = display
                            coordinator.mealFrequency = value
                            print("[MealFrequencyContentView] ✅ Set mealFrequency to: \(value) from selection '\(display)'")
                        }) {
                            HStack(spacing: 16) {
                                // Radio button (left side)
                                ZStack {
                                    Circle()
                                        .stroke(selectedMealCount == display ? Color(hex: "C0FF73") : Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 24, height: 24)

                                    if selectedMealCount == display {
                                        Circle()
                                            .fill(Color(hex: "C0FF73"))
                                            .frame(width: 12, height: 12)
                                    }
                                }

                                // Content
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text(display)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)

                                        Image(systemName: icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(iconColor)
                                    }

                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                            }
                            .padding(20)
                            .background(selectedMealCount == display ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedMealCount == display ? Color(hex: "C0FF73").opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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
                    .padding(.top, 8)
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

// MARK: - Finish Section Content Views

struct YourPlanIsReadyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var loadingStep = 0
    @State private var autoAdvanced = false

    let loadingSteps = [
        ("chart.bar.fill", "Analyzing your metabolism..."),
        ("clock.fill", "Optimizing meal windows..."),
        ("fork.knife", "Calibrating macro distribution..."),
        ("sparkles", "Personalizing your program...")
    ]

    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                Text("Creating Your Plan")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Loading animation
                ZStack {
                    // Pulsing circle
                    Circle()
                        .stroke(Color.nutriSyncAccent.opacity(0.2), lineWidth: 3)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            Color.nutriSyncAccent,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(Double(loadingStep) * 90))
                        .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: loadingStep)

                    // Current step icon
                    if loadingStep < loadingSteps.count {
                        Image(systemName: loadingSteps[loadingStep].0)
                            .font(.system(size: 32))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
                .padding(.vertical, 20)

                // Loading steps with checkmarks
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<loadingSteps.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            if index < loadingStep {
                                // Completed
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.nutriSyncAccent)
                            } else if index == loadingStep {
                                // Current
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .nutriSyncAccent))
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                // Pending
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }

                            Text(loadingSteps[index].1)
                                .font(.system(size: 15))
                                .foregroundColor(index <= loadingStep ? .white : .white.opacity(0.5))

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear {
            // Auto-advance through steps
            let timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                if loadingStep < loadingSteps.count - 1 {
                    withAnimation {
                        loadingStep += 1
                    }
                } else if !autoAdvanced {
                    // Wait a bit on the last step, then auto-advance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        autoAdvanced = true
                        coordinator.nextScreen()
                    }
                    timer.invalidate()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}

// MARK: - Specific Goals Selection View

struct SpecificGoalsSelectionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("What are your specific nutrition goals?")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            // Subtitle
            Text("Select all that apply - we'll customize your plan")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            // Goal Cards Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SpecificGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: coordinator.selectedSpecificGoals.contains(goal)
                    ) {
                        toggleGoal(goal)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func toggleGoal(_ goal: SpecificGoal) {
        if coordinator.selectedSpecificGoals.contains(goal) {
            coordinator.selectedSpecificGoals.remove(goal)
        } else {
            coordinator.selectedSpecificGoals.insert(goal)
        }
    }
}

// MARK: - Goal Card Component

struct GoalCard: View {
    let goal: SpecificGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon (SF Symbol) - turns green when selected
                Image(systemName: goal.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white)
                    .frame(height: 44)

                // Goal Name - turns green when selected
                Text(goal.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 135, maxHeight: 135)  // Fixed height for consistency
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .overlay(
                // Checkmark overlay when selected
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.nutriSyncAccent)
                                    .font(.title3)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Ranking View

// MARK: - Option 1: Button-Based Reordering
struct GoalRankingWithButtonsView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Title
                Text("Rank Your Goals")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Tap arrows to reorder by priority")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Additional info
                Text("Your #1 goal will have the most influence on your meal windows")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Ranked Goals List
                VStack(spacing: 12) {
                    ForEach(Array(coordinator.rankedGoals.enumerated()), id: \.element.id) { index, rankedGoal in
                        RankedGoalRowWithButtons(
                            rankedGoal: rankedGoal,
                            rank: index,
                            canMoveUp: index > 0,
                            canMoveDown: index < coordinator.rankedGoals.count - 1,
                            onMoveUp: {
                                // Block Next button during reorder - AGGRESSIVE blocking
                                coordinator.isGoalDragging = true

                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    coordinator.rankedGoals.move(
                                        fromOffsets: IndexSet(integer: index),
                                        toOffset: index - 1
                                    )
                                }

                                // IMMEDIATELY update all ranks based on new positions
                                for (newIndex, _) in coordinator.rankedGoals.enumerated() {
                                    coordinator.rankedGoals[newIndex].rank = newIndex
                                }
                                print("[GoalRankingView] ⬆️ Moved up - Updated ranks:")
                                for (i, rg) in coordinator.rankedGoals.enumerated() {
                                    print("[GoalRankingView]   [\(i)] \(rg.goal.rawValue) - rank: \(rg.rank)")
                                }

                                // Re-enable Next button after LONG delay to prevent any navigation
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                                    await MainActor.run {
                                        coordinator.isGoalDragging = false
                                    }
                                }
                            },
                            onMoveDown: {
                                // Block Next button during reorder - AGGRESSIVE blocking
                                coordinator.isGoalDragging = true

                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    coordinator.rankedGoals.move(
                                        fromOffsets: IndexSet(integer: index),
                                        toOffset: index + 2
                                    )
                                }

                                // IMMEDIATELY update all ranks based on new positions
                                for (newIndex, _) in coordinator.rankedGoals.enumerated() {
                                    coordinator.rankedGoals[newIndex].rank = newIndex
                                }
                                print("[GoalRankingView] ⬇️ Moved down - Updated ranks:")
                                for (i, rg) in coordinator.rankedGoals.enumerated() {
                                    print("[GoalRankingView]   [\(i)] \(rg.goal.rawValue) - rank: \(rg.rank)")
                                }

                                // Re-enable Next button after LONG delay to prevent any navigation
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                                    await MainActor.run {
                                        coordinator.isGoalDragging = false
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .scrollDisabled(false)
        .onDisappear {
            print("[GoalRankingView] 🔄 onDisappear called - updating ranks")
            // Update ranks based on position in array when leaving screen
            for (index, _) in coordinator.rankedGoals.enumerated() {
                print("[GoalRankingView]   Setting rank \(index) for: \(coordinator.rankedGoals[index].goal.rawValue)")
                coordinator.rankedGoals[index].rank = index
            }
            print("[GoalRankingView] ✅ Ranks updated successfully")
        }
    }
}

// MARK: - Option 3: Native List with EditMode
struct GoalRankingWithListView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @Environment(\.editMode) private var editMode

    var body: some View {
        @Bindable var coordinator = coordinator
        VStack(spacing: 0) {
            // Title
            Text("Rank Your Goals")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.top, 20)

            // Subtitle
            Text("Drag handles to reorder by priority")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            // Additional info
            Text("Your #1 goal will have the most influence on your meal windows")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            // Native List with reordering
            List {
                ForEach(Array(coordinator.rankedGoals.enumerated()), id: \.element.id) { index, rankedGoal in
                    RankedGoalRowForList(
                        rankedGoal: rankedGoal,
                        rank: index
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
                .onMove { from, to in
                    coordinator.rankedGoals.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .onDisappear {
            // Update ranks based on position in array when leaving screen
            for (index, _) in coordinator.rankedGoals.enumerated() {
                coordinator.rankedGoals[index].rank = index
            }
        }
    }
}

// Default to button-based for now - can switch to test the other
typealias GoalRankingView = GoalRankingWithButtonsView

// MARK: - Ranked Goal Row

struct RankedGoalRow: View {
    let rankedGoal: RankedGoal
    let rank: Int

    private var rankLabel: String {
        switch rank {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        case 3: return "4th"
        case 4: return "5th"
        default: return "\(rank + 1)th"
        }
    }

    private var detailText: String {
        rank < 2 ? "We'll ask detailed questions" : "We'll use smart defaults"
    }

    private var accentColor: Color {
        rank < 2 ? Color.nutriSyncAccent : Color.white.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            Text(rankLabel)
                .font(.headline)
                .foregroundColor(rank < 2 ? .black : .white.opacity(0.7))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(accentColor)
                )

            // Goal Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // SF Symbol Icon (matches Specific Goals screen)
                    Image(systemName: rankedGoal.goal.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24)

                    Text(rankedGoal.goal.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(detailText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.white.opacity(0.4))
                .font(.title3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor, lineWidth: rank < 2 ? 2 : 1)
                )
        )
    }
}

// MARK: - Ranked Goal Row with Buttons

struct RankedGoalRowWithButtons: View {
    let rankedGoal: RankedGoal
    let rank: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private var rankLabel: String {
        switch rank {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        case 3: return "4th"
        case 4: return "5th"
        default: return "\(rank + 1)th"
        }
    }

    private var detailText: String {
        rank < 2 ? "We'll ask detailed questions" : "We'll use smart defaults"
    }

    private var accentColor: Color {
        rank < 2 ? Color.nutriSyncAccent : Color.white.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Goal Info with integrated ranking
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    // SF Symbol Icon (matches Specific Goals screen)
                    Image(systemName: rankedGoal.goal.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(rank < 2 ? .nutriSyncAccent : .white)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(rankedGoal.goal.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        // Subtle rank indicator
                        Text("#\(rank + 1) Priority")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(rank < 2 ? .nutriSyncAccent : .white.opacity(0.5))
                    }
                }

                Text(detailText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Up/Down Arrows
            VStack(spacing: 8) {
                Button {
                    onMoveUp()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canMoveUp ? .white : .white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        .background(
                            Circle()
                                .fill(canMoveUp ? Color.white.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canMoveUp)

                Button {
                    onMoveDown()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canMoveDown ? .white : .white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        .background(
                            Circle()
                                .fill(canMoveDown ? Color.white.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canMoveDown)
            }
            .allowsHitTesting(true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor, lineWidth: rank < 2 ? 2 : 1)
                )
        )
    }
}

// MARK: - Ranked Goal Row for List

struct RankedGoalRowForList: View {
    let rankedGoal: RankedGoal
    let rank: Int

    private var rankLabel: String {
        switch rank {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        case 3: return "4th"
        case 4: return "5th"
        default: return "\(rank + 1)th"
        }
    }

    private var detailText: String {
        rank < 2 ? "We'll ask detailed questions" : "We'll use smart defaults"
    }

    private var accentColor: Color {
        rank < 2 ? Color.nutriSyncAccent : Color.white.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Goal Info with integrated ranking
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    // SF Symbol Icon (matches Specific Goals screen)
                    Image(systemName: rankedGoal.goal.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(rank < 2 ? .nutriSyncAccent : .white)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(rankedGoal.goal.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        // Subtle rank indicator
                        Text("#\(rank + 1) Priority")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(rank < 2 ? .nutriSyncAccent : .white.opacity(0.5))
                    }
                }

                Text(detailText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor, lineWidth: rank < 2 ? 2 : 1)
                )
        )
    }
}


// MARK: - Sleep Preferences View

struct SleepPreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Sleep Optimization")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Help us time your meals for better rest")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Form content
                VStack(alignment: .leading, spacing: 24) {
                    // Bedtime picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What time do you typically go to bed?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        DatePicker("", selection: $coordinator.sleepBedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    // Hours before bed
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How many hours before bed should your last meal end?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.sleepHoursBeforeBed) {
                            Text("2 hours (flexible)").tag(2)
                            Text("3 hours (recommended)").tag(3)
                            Text("4 hours (strict)").tag(4)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Avoid late carbs toggle
                    Toggle("Avoid high-carb foods in evening", isOn: $coordinator.sleepAvoidLateCarbs)
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    // Sleep sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How sensitive is your sleep to food timing?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.sleepQualitySensitivity) {
                            Text("Low").tag("Low")
                            Text("Medium").tag("Medium")
                            Text("High").tag("High")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Energy, Muscle, Performance, Metabolic Preferences Views

struct EnergyPreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Energy Management")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Let's prevent those energy crashes")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Form content
                VStack(alignment: .leading, spacing: 32) {
                    // Energy Crash Times
                    VStack(alignment: .leading, spacing: 16) {
                        Text("When do you typically experience energy crashes?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            ForEach(EnergyManagementPreferences.CrashTime.allCases, id: \.self) { time in
                                EnergyCrashTimeButton(
                                    time: time,
                                    isSelected: coordinator.energyCrashTimes.contains(time),
                                    action: {
                                        if coordinator.energyCrashTimes.contains(time) {
                                            coordinator.energyCrashTimes.remove(time)
                                        } else {
                                            coordinator.energyCrashTimes.insert(time)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Snacking Preference
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How do you prefer to handle snacking?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            ForEach(EnergyManagementPreferences.SnackingPreference.allCases, id: \.self) { preference in
                                SnackingPreferenceButton(
                                    preference: preference,
                                    isSelected: coordinator.energySnackingPreference == preference,
                                    action: { coordinator.energySnackingPreference = preference }
                                )
                            }
                        }
                    }

                    // Caffeine Sensitivity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Caffeine sensitivity?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            ForEach(["Low", "Medium", "High"], id: \.self) { sensitivity in
                                CaffeineSensitivityButton(
                                    sensitivity: sensitivity,
                                    isSelected: coordinator.energyCaffeineSensitivity == sensitivity,
                                    action: { coordinator.energyCaffeineSensitivity = sensitivity }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Energy Preferences Components

struct EnergyCrashTimeButton: View {
    let time: EnergyManagementPreferences.CrashTime
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch time {
        case .midMorning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .none: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
                    .frame(width: 28)

                Text(time.rawValue)
                    .font(.system(size: 17))
                    .foregroundColor(.white)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct SnackingPreferenceButton: View {
    let preference: EnergyManagementPreferences.SnackingPreference
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch preference {
        case .noSnacks: return "xmark.circle.fill"
        case .lightSnacks: return "leaf.fill"
        case .frequentSnacks: return "chart.bar.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(preference.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct CaffeineSensitivityButton: View {
    let sensitivity: String
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch sensitivity {
        case "Low": return "cup.and.saucer.fill"
        case "Medium": return "mug.fill"
        case "High": return "bolt.fill"
        default: return "mug.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))

                Text(sensitivity)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.nutriSyncAccent.opacity(0.1) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
    }
}

struct MusclePreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Muscle Building & Recovery")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Optimize your protein timing")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Form content
                VStack(alignment: .leading, spacing: 32) {
                    // Training Days
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How many days per week do you train?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        TrainingDaysSelector(
                            days: coordinator.muscleTrainingDays,
                            onDecrement: {
                                if coordinator.muscleTrainingDays > 3 {
                                    coordinator.muscleTrainingDays -= 1
                                }
                            },
                            onIncrement: {
                                if coordinator.muscleTrainingDays < 7 {
                                    coordinator.muscleTrainingDays += 1
                                }
                            }
                        )
                    }

                    // Training Style
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's your primary training style?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            ForEach(MuscleGainPreferences.TrainingStyle.allCases, id: \.self) { style in
                                TrainingStyleButton(
                                    style: style,
                                    isSelected: coordinator.muscleTrainingStyle == style,
                                    action: { coordinator.muscleTrainingStyle = style }
                                )
                            }
                        }
                    }

                    // Protein Distribution
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Protein distribution preference?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            ProteinDistributionButton(
                                title: "Even throughout day",
                                subtitle: "Consistent protein every meal",
                                icon: "clock.fill",
                                isSelected: coordinator.muscleProteinDistribution == "Even",
                                action: { coordinator.muscleProteinDistribution = "Even" }
                            )

                            ProteinDistributionButton(
                                title: "Post-Workout Focus",
                                subtitle: "Higher protein after training",
                                icon: "figure.strengthtraining.traditional",
                                isSelected: coordinator.muscleProteinDistribution == "Post-Workout Focus",
                                action: { coordinator.muscleProteinDistribution = "Post-Workout Focus" }
                            )

                            ProteinDistributionButton(
                                title: "Maximum (6 meals)",
                                subtitle: "Frequent protein doses",
                                icon: "chart.line.uptrend.xyaxis",
                                isSelected: coordinator.muscleProteinDistribution == "Maximum",
                                action: { coordinator.muscleProteinDistribution = "Maximum" }
                            )
                        }
                    }

                    // Protein Supplements
                    Button(action: {
                        coordinator.muscleSupplementProtein.toggle()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 22))
                                .foregroundColor(coordinator.muscleSupplementProtein ? .nutriSyncAccent : .white.opacity(0.5))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("I use protein supplements")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)

                                Text("Powder, shakes, bars, etc.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(coordinator.muscleSupplementProtein ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                                    .frame(width: 51, height: 31)

                                Circle()
                                    .fill(.white)
                                    .frame(width: 27, height: 27)
                                    .offset(x: coordinator.muscleSupplementProtein ? 10 : -10)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(coordinator.muscleSupplementProtein ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: coordinator.muscleSupplementProtein ? 2 : 1)
                        )
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Muscle Preferences Components

struct TrainingDaysSelector: View {
    let days: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(days > 3 ? .white : .white.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .disabled(days <= 3)

            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.nutriSyncAccent)

                Text("days")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.nutriSyncAccent, lineWidth: 2)
            )
            .cornerRadius(16)

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(days < 7 ? .white : .white.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .disabled(days >= 7)
        }
    }
}

struct TrainingStyleButton: View {
    let style: MuscleGainPreferences.TrainingStyle
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch style {
        case .strength: return "dumbbell.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .powerlifting: return "figure.strengthtraining.functional"
        case .generalFitness: return "figure.mixed.cardio"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
                    .frame(width: 28)

                Text(style.rawValue)
                    .font(.system(size: 17))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.nutriSyncAccent)
                }
            }
            .padding(20)
            .background(isSelected ? Color.nutriSyncAccent.opacity(0.1) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct ProteinDistributionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.nutriSyncAccent)
                }
            }
            .padding(20)
            .background(isSelected ? Color.nutriSyncAccent.opacity(0.1) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct PerformancePreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Athletic Performance")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Fuel your workouts effectively")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Form content
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When do you typically work out?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        DatePicker("", selection: $coordinator.performanceWorkoutTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average workout duration?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.performanceWorkoutDuration) {
                            Text("30 min").tag(30)
                            Text("60 min").tag(60)
                            Text("90 min").tag(90)
                            Text("2 hrs").tag(120)
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle("Want a pre-workout meal?", isOn: $coordinator.performancePreworkoutMeal)
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    Toggle("Want a post-workout meal?", isOn: $coordinator.performancePostworkoutMeal)
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workout intensity?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.performanceWorkoutIntensity) {
                            Text("Light").tag("Light")
                            Text("Moderate").tag("Moderate")
                            Text("Intense").tag("Intense")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct MetabolicPreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Metabolic Health")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Subtitle
                Text("Support blood sugar and metabolism")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                // Form content
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred fasting window?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.metabolicFastingHours) {
                            Text("12 hours").tag(12)
                            Text("14 hours").tag(14)
                            Text("16 hours").tag(16)
                            Text("18 hours").tag(18)
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle("Blood sugar concerns?", isOn: $coordinator.metabolicBloodSugarConcern)
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    Toggle("Prefer lower-carb approach?", isOn: $coordinator.metabolicPreferLowerCarbs)
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal timing consistency preference?")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Picker("", selection: $coordinator.metabolicMealTimingConsistency) {
                            Text("Flexible").tag("Flexible")
                            Text("Consistent").tag("Consistent")
                            Text("Very Strict").tag("Very Strict")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Goal Impact Preview View

struct GoalImpactPreviewView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Personalized Plan Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Here's how your goals will shape your meal windows")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Mock Timeline
                VStack(alignment: .leading, spacing: 16) {
                    Text("📅 Tomorrow's Meal Windows")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(mockWindows, id: \.time) { window in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(window.time)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.nutriSyncAccent)

                                Text(window.title)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(window.purpose)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))

                                Text(window.description)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                        )
                    }
                }

                // Goal Impact Cards
                VStack(alignment: .leading, spacing: 16) {
                    Text("🎯 How Your Goals Shape Your Plan")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(Array(coordinator.rankedGoals.prefix(3).enumerated()), id: \.element.id) { index, rankedGoal in
                        GoalImpactCard(goal: rankedGoal.goal, rank: index)
                    }
                }

                Spacer(minLength: 20)

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Adjust") {
                        // Go back to ranking screen
                        coordinator.currentScreenIndex = max(0, coordinator.currentScreenIndex - (coordinator.rankedGoals.count > 1 ? 7 : 6))
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    Button("Looks Good!") {
                        coordinator.nextScreen()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.nutriSyncAccent)
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
    }

    private var mockWindows: [(time: String, title: String, purpose: String, description: String)] {
        guard let topGoal = coordinator.rankedGoals.first?.goal else {
            return [
                ("7:00 AM - 8:30 AM", "Breakfast Window", "Balanced Start", "Energizing first meal"),
                ("12:00 PM - 1:30 PM", "Lunch Window", "Sustained Energy", "Keep you going all afternoon"),
                ("6:00 PM - 7:30 PM", "Dinner Window", "Recovery & Rest", "Light evening meal")
            ]
        }

        switch topGoal {
        case .weightManagement:
            return [
                ("7:00 AM - 8:30 AM", "Breakfast", "Weight Management (#1)", "Balanced macros, portion controlled"),
                ("12:00 PM - 1:30 PM", "Lunch", "Sustained Energy", "Nutrient-dense, satisfying"),
                ("3:00 PM - 4:00 PM", "Snack", "Metabolism Boost", "Keep energy stable"),
                ("6:30 PM - 7:30 PM", "Dinner", "Light Evening", "Portion controlled, early timing"),
                ("10:00 PM", "Fasting Begins", "", "14-hour fasting window")
            ]
        case .muscleGain:
            return [
                ("7:00 AM - 8:30 AM", "Breakfast", "Muscle Recovery (#1)", "High protein, optimal timing"),
                ("12:00 PM - 1:30 PM", "Lunch", "Sustained Energy", "Balanced macros"),
                ("4:00 PM - 5:00 PM", "Pre-Workout", "Performance Fuel", "Light carbs for energy"),
                ("6:30 PM - 7:30 PM", "Post-Workout", "Muscle Recovery (#1)", "High protein + carbs"),
                ("9:00 PM", "Fasting Begins", "", "Recovery overnight")
            ]
        case .betterSleep:
            let _ = coordinator.sleepBedtime
            let hours = coordinator.sleepHoursBeforeBed
            return [
                ("7:00 AM - 8:30 AM", "Breakfast", "Morning Energy", "Balanced start"),
                ("12:00 PM - 1:30 PM", "Lunch", "Sustained Energy", "Keep you alert"),
                ("5:00 PM - 6:00 PM", "Dinner", "Sleep Optimization (#1)", "Ends \(hours) hrs before bed"),
                ("10:00 PM", "Bedtime", "Fasting Window", "Optimized for sleep quality")
            ]
        case .steadyEnergy:
            return [
                ("7:00 AM - 8:30 AM", "Breakfast", "Morning Energy", "Balanced start"),
                ("10:00 AM - 11:00 AM", "Mid-Morning Snack", "Energy Boost (#1)", "Prevent morning crash"),
                ("1:00 PM - 2:00 PM", "Lunch", "Sustained Energy (#1)", "Balanced macros"),
                ("3:30 PM - 4:30 PM", "Afternoon Snack", "Energy Boost (#1)", "Avoid afternoon crash"),
                ("7:00 PM - 8:00 PM", "Dinner", "Evening Meal", "Light and satisfying")
            ]
        case .athleticPerformance:
            return [
                ("7:00 AM - 8:30 AM", "Breakfast", "Morning Fuel", "Energizing start"),
                ("11:30 AM - 12:30 PM", "Pre-Workout", "Performance (#1)", "Carb-focused fuel"),
                ("2:00 PM - 3:00 PM", "Post-Workout", "Recovery (#1)", "High protein + carbs"),
                ("7:00 PM - 8:00 PM", "Dinner", "Recovery", "Complete nutrition")
            ]
        case .metabolicHealth:
            return [
                ("10:00 AM - 11:00 AM", "Breakfast", "Break Fast", "\(coordinator.metabolicFastingHours)hr fast complete"),
                ("2:00 PM - 3:00 PM", "Lunch", "Metabolic Boost (#1)", "Blood sugar stable"),
                ("6:00 PM - 7:00 PM", "Dinner", "Final Meal", "Prepare for fast"),
                ("8:00 PM", "Fasting Begins", "Metabolic Health (#1)", "\(coordinator.metabolicFastingHours) hour window")
            ]
        }
    }
}

struct GoalImpactCard: View {
    let goal: SpecificGoal
    let rank: Int

    private var rankLabel: String {
        switch rank {
        case 0: return "#1 Priority"
        case 1: return "#2 Priority"
        case 2: return "#3 Priority"
        default: return "#\(rank + 1)"
        }
    }

    private var impacts: [String] {
        switch goal {
        case .weightManagement:
            return [
                "✓ Portion-controlled meal windows",
                "✓ 14-hour fasting window for metabolism",
                "✓ Balanced macros to reach target weight"
            ]
        case .muscleGain:
            return [
                "✓ 5 eating windows for optimal protein intake",
                "✓ Post-workout window within 1 hour",
                "✓ Protein distributed for recovery"
            ]
        case .betterSleep:
            return [
                "✓ Last meal ends 3 hours before bed",
                "✓ Lower carbs in evening meals",
                "✓ Lighter portions for better rest"
            ]
        case .steadyEnergy:
            return [
                "✓ 4-5 balanced meals throughout day",
                "✓ Timed windows to prevent crashes",
                "✓ Steady macro distribution"
            ]
        case .athleticPerformance:
            return [
                "✓ Pre-workout meal for fuel",
                "✓ Post-workout for recovery",
                "✓ Timing optimized around training"
            ]
        case .metabolicHealth:
            return [
                "✓ 14-hour fasting window",
                "✓ Blood sugar stability focus",
                "✓ Consistent meal timing"
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.icon)
                    .font(.title3)

                Text(goal.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(rankLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(rank == 0 ? .black : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rank == 0 ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                    .cornerRadius(8)
            }

            ForEach(impacts, id: \.self) { impact in
                Text(impact)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rank == 0 ? Color.nutriSyncAccent : Color.white.opacity(0.1), lineWidth: rank == 0 ? 2 : 1)
                )
        )
    }
}

struct ReviewProgramContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    var body: some View {
        Text("Review Program Content")
            .foregroundColor(.white)
    }
}