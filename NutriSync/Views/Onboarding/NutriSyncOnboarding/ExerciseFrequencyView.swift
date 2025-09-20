//
//  ExerciseFrequencyView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 3 - Dark Theme
//

import SwiftUI

struct ExerciseGridIcon: View {
    let filledSquares: Int
    
    // Define scattered patterns for each frequency level
    private var filledPositions: Set<Int> {
        switch filledSquares {
        case 0:
            return []
        case 3:
            // Pattern for 1-3 sessions: [(x,x,0), (x,0,0), (0,0,0)]
            return [0, 1, 3]
        case 5:
            // Pattern for 4-6 sessions: [(x,x,x), (x,x,0), (x,0,0)]
            return [0, 1, 2, 3, 4]
        case 9:
            // All filled for 7+ sessions
            return Set(0...8)
        default:
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3) { col in
                        let index = row * 3 + col
                        Rectangle()
                            .fill(filledPositions.contains(index) ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .cornerRadius(1)
                    }
                }
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct ExerciseFrequencyOption: View {
    let text: String
    let filledSquares: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ExerciseGridIcon(filledSquares: filledSquares)
                
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
        ("0 sessions / week", 0),
        ("1-3 sessions / week", 3),
        ("4-6 sessions / week", 5),
        ("7+ sessions / week", 9)
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
                    ForEach(frequencies, id: \.0) { frequency, filledSquares in
                        ExerciseFrequencyOption(
                            text: frequency,
                            filledSquares: filledSquares,
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