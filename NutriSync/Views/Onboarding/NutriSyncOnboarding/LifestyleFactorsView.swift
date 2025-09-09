//
//  LifestyleFactorsView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Lifestyle Factors
//

import SwiftUI

struct LifestyleFactorsView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var workSchedule = ""
    @State private var socialMealsPerWeek: Double = 2
    @State private var travelFrequency = ""
    
    let workScheduleOptions = ["9-5 office", "Shift work", "Remote/flexible", "Student", "Not working"]
    let travelOptions = ["Rarely", "Monthly", "Weekly", "Constantly"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 24)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("Your Lifestyle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    // Subtitle
                    Text("Help us adapt your eating windows to your daily schedule and lifestyle.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 12)
                    
                    // Work schedule
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Work Schedule")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(workScheduleOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    isSelected: workSchedule == option,
                                    action: {
                                        workSchedule = option
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Social meals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly Social Meals")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(Int(socialMealsPerWeek)) \(Int(socialMealsPerWeek) == 1 ? "meal" : "meals") per week")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Slider(
                            value: $socialMealsPerWeek,
                            in: 0...7,
                            step: 1
                        )
                        .accentColor(.white)
                        .padding(.horizontal, 4)
                    }
                    .padding(.bottom, 8)
                    
                    // Travel frequency
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Travel Frequency")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(travelOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    isSelected: travelFrequency == option,
                                    action: {
                                        travelFrequency = option
                                    }
                                )
                            }
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
                    // Save lifestyle factors to coordinator
                    coordinator.workSchedule = workSchedule
                    coordinator.socialMealsPerWeek = socialMealsPerWeek
                    coordinator.travelFrequency = travelFrequency
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
    }
    
    private var canContinue: Bool {
        !workSchedule.isEmpty && !travelFrequency.isEmpty
    }
}

struct LifestyleFactorsView_Previews: PreviewProvider {
    static var previews: some View {
        LifestyleFactorsView()
    }
}