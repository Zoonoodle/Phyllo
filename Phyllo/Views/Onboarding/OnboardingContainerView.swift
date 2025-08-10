//
//  OnboardingContainerView.swift
//  Phyllo
//
//  Main container for the onboarding flow
//

import SwiftUI

struct OnboardingContainerView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressBar(progress: coordinator.currentStep.progress)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Content
                Group {
                    switch coordinator.currentStep {
                    case .welcome:
                        WelcomeView()
                    case .goals:
                        GoalsSelectionView(
                            primaryGoal: $coordinator.onboardingData.primaryGoal,
                            secondaryGoals: $coordinator.onboardingData.secondaryGoals
                        )
                    case .age:
                        AgeStepView(age: $coordinator.onboardingData.age)
                    case .height:
                        HeightOnlyStepView(heightInInches: $coordinator.onboardingData.height)
                    case .weight:
                        WeightStepView(weight: $coordinator.onboardingData.currentWeight)
                    case .gender:
                        GenderStepView(gender: $coordinator.onboardingData.gender)
                    case .activity:
                        ActivitySetupView(data: $coordinator.onboardingData)
                    case .schedule:
                        ScheduleSetupView(data: $coordinator.onboardingData)
                    case .dietary:
                        DietaryPreferencesView(data: $coordinator.onboardingData)
                    case .challenges:
                        ChallengesView(challenges: $coordinator.onboardingData.currentChallenges)
                    case .habits:
                        HabitsBaselineView(data: $coordinator.onboardingData)
                    case .nudges:
                        NudgesDevicesView(data: $coordinator.onboardingData)
                    case .preview:
                        PlanPreviewView(data: coordinator.onboardingData)
                    case .permissions:
                        PermissionsView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coordinator.currentStep)
                
                Spacer()
                
                // Navigation Buttons
                OnboardingNavigationButtons(
                    canGoBack: coordinator.currentStep != .welcome,
                    canSkip: coordinator.currentStep.canSkip,
                    canProceed: coordinator.canProceedFromCurrentStep(),
                    onBack: { coordinator.previous() },
                    onSkip: { coordinator.skip() },
                    onNext: { coordinator.next() }
                )
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .environment(coordinator)
        .onChange(of: coordinator.isCompleted) { _, completed in
            if completed {
                dismiss()
            }
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.phylloAccent)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons

struct OnboardingNavigationButtons: View {
    let canGoBack: Bool
    let canSkip: Bool
    let canProceed: Bool
    let onBack: () -> Void
    let onSkip: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            // Back Button
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .opacity(canGoBack ? 1 : 0)
            .disabled(!canGoBack)
            
            Spacer()
            
            // Skip Button
            if canSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Next Button
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(canProceed ? Color.phylloAccent : Color.white.opacity(0.2))
                    )
            }
            .disabled(!canProceed)
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingContainerView()
}

// MARK: - Standalone Preview

struct OnboardingPreviewView: View {
    @State private var showOnboarding = true
    
    var body: some View {
        ZStack {
            // Main app content
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Main App")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Button("Show Onboarding") {
                    showOnboarding = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainerView()
        }
    }
}

#Preview("Standalone") {
    OnboardingPreviewView()
}

// MARK: - New Atomic Step Views

struct AgeStepView: View {
    @Binding var age: Int?
    @State private var selectedAge: Int = 25
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What's your age?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Your age helps us calculate accurate nutritional needs")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal)
            
            RingNumberPicker(value: $selectedAge, range: 13...90, step: 1, unitLabel: "years old")
                .padding(.top, 20)
            
            NumberCarousel(selected: $selectedAge, range: (selectedAge-3)...(selectedAge+3))
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            Spacer()
        }
        .onAppear { if let age = age { selectedAge = min(90, max(13, age)) } }
        .onChange(of: selectedAge) { age = selectedAge }
    }
}

struct HeightOnlyStepView: View {
    @Binding var heightInInches: Double?
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("How tall are you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("We'll use this to personalize your plan")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 24)
            .padding(.horizontal)
            
            HeightPicker(height: $heightInInches)
                .padding(.top, 12)
            
            if let inches = heightInInches {
                let cm = inches * 2.54
                Text("≈ \(Int(cm)) cm")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

struct WeightStepView: View {
    @Binding var weight: Double?
    @State private var current: Double = 170
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What do you weigh?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("We recommend targets based on your current weight")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 24)
            .padding(.horizontal)
            
            BigNumberStepper(value: $current, range: 70...400, step: 0.5, unit: "lbs")
                .padding(.top, 20)
            
            Text("≈ \(String(format: "%.0f", current * 0.453592)) kg")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
        .onAppear { if let w = weight { current = min(400, max(70, w)) } }
        .onChange(of: current) { weight = current }
    }
}

struct GenderStepView: View {
    @Binding var gender: Gender?
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("How do you identify?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Used only to tailor energy estimates and macros")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 24)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { item in
                    RadioCardRow(title: item.displayName, selected: gender == item) {
                        gender = item
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct HabitsBaselineView: View {
    @Binding var data: OnboardingData
    @State private var showFirstPicker = false
    @State private var showLastPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your habits baseline")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Helps us personalize windows and coaching")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // First / last meal times
                    TimePickerRow(title: "Typical first meal", time: Binding(get: { data.firstMealTime ?? defaultTime(hour: 10) }, set: { data.firstMealTime = $0 }), showPicker: $showFirstPicker)
                    TimePickerRow(title: "Typical last meal", time: Binding(get: { data.lastMealTime ?? defaultTime(hour: 20) }, set: { data.lastMealTime = $0 }), showPicker: $showLastPicker)
                    
                    // Water/Caffeine/Alcohol
                    SegmentedChipsSection(title: "Water intake", items: WaterIntake.allCases.map{ $0.rawValue }, selected: data.waterIntake.rawValue) { label in
                        data.waterIntake = WaterIntake(rawValue: label) ?? .moderate
                    }
                    
                    SegmentedChipsSection(title: "Caffeine", items: CaffeineLevel.allCases.map{ $0.rawValue }, selected: data.caffeineLevel.rawValue) { label in
                        data.caffeineLevel = CaffeineLevel(rawValue: label) ?? .none
                    }
                    
                    SegmentedChipsSection(title: "Alcohol", items: AlcoholFrequency.allCases.map{ $0.rawValue }, selected: data.alcoholFrequency.rawValue) { label in
                        data.alcoholFrequency = AlcoholFrequency(rawValue: label) ?? .never
                    }
                    
                    // Energy / Stress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current energy today")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        HStack {
                            Slider(value: Binding(get: { Double(data.energyBaseline) }, set: { data.energyBaseline = Int($0) }), in: 1...10, step: 1)
                                .tint(.phylloAccent)
                            Text("\(data.energyBaseline)")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    SegmentedChipsSection(title: "Stress level", items: StressLevel.allCases.map{ $0.rawValue }, selected: data.stressLevel.rawValue) { label in
                        data.stressLevel = StressLevel(rawValue: label) ?? .moderate
                    }
                }
                .padding(.horizontal)
                
                Color.clear.frame(height: 100)
            }
        }
    }
    
    private func defaultTime(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

struct NudgesDevicesView: View {
    @Binding var data: OnboardingData
    @State private var localPreference: NotificationPreference = .important
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nudges & devices")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("We’ll time reminders smartly and respect quiet hours")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Notification preset
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification preset")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        ForEach(NotificationPreference.allCases, id: \.self) { pref in
                            RadioCardRow(title: pref.rawValue, selected: localPreference == pref) {
                                localPreference = pref
                                data.notificationPreference = pref
                            }
                        }
                    }
                    
                    // Quiet hours
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quiet hours")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $data.quietHoursEnabled).labelsHidden().tint(.phylloAccent)
                        }
                        if data.quietHoursEnabled {
                            HStack(spacing: 12) {
                                QuietHourField(label: "From", hour: $data.quietHoursStart)
                                QuietHourField(label: "To", hour: $data.quietHoursEnd)
                            }
                        }
                    }
                    
                    // Wearables
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wearables")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        FlowLayout(spacing: 8) {
                            ForEach(Wearable.allCases, id: \.self) { w in
                                SelectChip(title: w.rawValue, selected: data.wearables.contains(w)) {
                                    if data.wearables.contains(w) { data.wearables.remove(w) } else { data.wearables.insert(w) }
                                }
                            }
                        }
                    }
                    
                    // Privacy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        ForEach(PrivacyPreference.allCases, id: \.self) { pref in
                            RadioCardRow(title: pref.rawValue, selected: data.privacyPreference == pref) {
                                data.privacyPreference = pref
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Color.clear.frame(height: 100)
            }
        }
        .onAppear { localPreference = data.notificationPreference }
    }
}

// MARK: - Shared Components

struct RingNumberPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    var unitLabel: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 220, height: 220)
                Text("\(value)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.phylloAccent)
                VStack { Spacer().frame(height: 180); Text(unitLabel).foregroundColor(.white.opacity(0.6)).font(.system(size: 16)) }
            }
            
            HStack(spacing: 16) {
                CircleButton(symbol: "minus") { value = max(range.lowerBound, value - step) }
                CircleButton(symbol: "plus") { value = min(range.upperBound, value + step) }
            }
        }
    }
}

struct BigNumberStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 220, height: 220)
                VStack(spacing: 6) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.phylloAccent)
                    Text(unit)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            HStack(spacing: 16) {
                CircleButton(symbol: "minus") { value = max(range.lowerBound, (value - step).rounded(toNearest: step)) }
                CircleButton(symbol: "plus") { value = min(range.upperBound, (value + step).rounded(toNearest: step)) }
            }
        }
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        let inv = 1.0 / step
        return (self * inv).rounded() / inv
    }
}

struct CircleButton: View {
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.phylloAccent))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NumberCarousel: View {
    @Binding var selected: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        let values = Array(range).filter { $0 >= 0 }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(values, id: \.self) { v in
                    Text("\(v)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(v == selected ? .black : .white.opacity(0.6))
                        .frame(width: 56, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(v == selected ? Color.phylloAccent : Color.white.opacity(0.06))
                        )
                        .onTapGesture { selected = v }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RadioCardRow: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selected ? .white : .white.opacity(0.85))
                Spacer()
                ZStack {
                    Circle().stroke(selected ? Color.phylloAccent : Color.white.opacity(0.2), lineWidth: 2).frame(width: 22, height: 22)
                    if selected { Circle().fill(Color.phylloAccent).frame(width: 14, height: 14) }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(selected ? 0.06 : 0.03))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? Color.phylloAccent.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Color.phylloAccent : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimePickerRow: View {
    let title: String
    @Binding var time: Date
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showPicker.toggle() } } label: {
                HStack {
                    Text(title).foregroundColor(.white).font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.white.opacity(0.8))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(showPicker ? 180 : 0))
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1)))
            }
            .buttonStyle(PlainButtonStyle())
            if showPicker {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(height: 150)
                    .clipped()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct SegmentedChipsSection: View {
    let title: String
    let items: [String]
    var selected: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.white)
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { label in
                    SelectChip(title: label, selected: label == selected) { onSelect(label) }
                }
            }
        }
    }
}

struct QuietHourField: View {
    let label: String
    @Binding var hour: Int
    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))
            Stepper(value: $hour, in: 0...23) {
                Text("\(hour):00")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .tint(.phylloAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}