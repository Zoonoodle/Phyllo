//
//  ExerciseFrequencyView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 3 - Dark Theme
//

import SwiftUI

struct ExerciseFrequencyView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedFrequency = "0 sessions / week"
    
    let frequencies = [
        ("0 sessions / week", "calendar"),
        ("1-3 sessions / week", "calendar"),
        ("4-6 sessions / week", "calendar"),
        ("7+ sessions / week", "calendar")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(totalSteps: 24, currentStep: 3)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text("How often do you exercise?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Subtitle
                    Text("Choose the number of recreational sports, cardio, or resistance training sessions you do per week.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    
                    // Exercise frequency options
                    VStack(spacing: 16) {
                        ForEach(frequencies, id: \.0) { frequency, icon in
                            ExerciseFrequencyOption(
                                text: frequency,
                                icon: icon,
                                isSelected: selectedFrequency == frequency
                            ) {
                                selectedFrequency = frequency
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
                        }
                        
                        Spacer()
                        
                        Button {
                            // Save exercise frequency to coordinator
                            coordinator.exerciseFrequency = selectedFrequency
                            coordinator.nextScreen()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(22)
                        }
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
}

struct ExerciseFrequencyOption: View {
    let text: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct ExerciseFrequencyView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseFrequencyView()
    }
}