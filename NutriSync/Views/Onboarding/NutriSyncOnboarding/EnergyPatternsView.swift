//
//  EnergyPatternsView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Energy Patterns (Split from CircadianOptimizationView)
//

import SwiftUI

struct EnergyPatternsView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var energyPeak = ""
    @State private var caffeineSensitivity = ""
    
    let energyOptions = ["Early morning", "Mid-morning", "Afternoon", "Evening", "Night owl"]
    let caffeineOptions = ["Very sensitive", "Moderate", "Low sensitivity", "No caffeine"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 27)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Energy Patterns")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // Subtitle
                Text("When do you feel most energized?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
                
                // Energy peaks
                VStack(alignment: .leading, spacing: 16) {
                    Text("Peak Energy Time")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(energyOptions, id: \.self) { option in
                            OptionButton(
                                title: option,
                                isSelected: energyPeak == option,
                                action: {
                                    energyPeak = option
                                }
                            )
                        }
                    }
                }
                
                // Caffeine sensitivity
                VStack(alignment: .leading, spacing: 16) {
                    Text("Caffeine Sensitivity")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(caffeineOptions, id: \.self) { option in
                            OptionButton(
                                title: option,
                                isSelected: caffeineSensitivity == option,
                                action: {
                                    caffeineSensitivity = option
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
                    // Save energy patterns to coordinator
                    coordinator.energyPeak = energyPeak
                    coordinator.caffeineSensitivity = caffeineSensitivity
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
        !energyPeak.isEmpty && !caffeineSensitivity.isEmpty
    }
}

struct EnergyPatternsView_Previews: PreviewProvider {
    static var previews: some View {
        EnergyPatternsView()
    }
}