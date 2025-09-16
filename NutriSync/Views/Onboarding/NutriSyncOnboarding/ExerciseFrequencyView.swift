//
//  ExerciseFrequencyView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 3 - Dark Theme
//

import SwiftUI

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

// Content-only version for carousel
struct ExerciseFrequencyContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedFrequency = "0 sessions / week"
    @State private var isInitialized = false
    
    let frequencies = [
        ("0 sessions / week", "calendar"),
        ("1-3 sessions / week", "calendar"),
        ("4-6 sessions / week", "calendar"),
        ("7+ sessions / week", "calendar")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
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
                            coordinator.exerciseFrequency = selectedFrequency
                            print("[ExerciseFrequency] Selected: \(selectedFrequency)")
                            print("[ExerciseFrequency] Saved to coordinator: \(coordinator.exerciseFrequency)")
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
        .onChange(of: selectedFrequency) { _ in 
            coordinator.exerciseFrequency = selectedFrequency
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Load existing value from coordinator if it exists
        if !coordinator.exerciseFrequency.isEmpty {
            selectedFrequency = coordinator.exerciseFrequency
        }
    }
}

struct ExerciseFrequencyView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseFrequencyContentView()
    }
}