//
//  HungerLevelViewV2.swift
//  NutriSync
//
//  Converted hunger level view using onboarding template pattern
//

import SwiftUI

struct HungerLevelViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    @State private var hunger: Double = 5.0
    
    var body: some View {
        CheckInScreenTemplate(
            title: "How hungry are you?",
            subtitle: "We'll adjust your first meal window accordingly",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.hungerLevel = Int(hunger)
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            VStack(spacing: 40) {
                Spacer()
                
                // Hunger display - positioned like sleep hours and energy battery
                VStack(spacing: 12) {
                    Image(systemName: hungerIcon)
                        .font(.system(size: 72))
                        .foregroundColor(.nutriSyncAccent)
                    
                    Text(hungerLabel)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Hunger Level")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Hunger slider using PhylloSlider with red to green gradient
                PhylloSlider(
                    value: $hunger,
                    range: 1...10,
                    step: 1,
                    label: "Hunger Level",
                    gradient: LinearGradient(
                        colors: [Color.red.opacity(0.6), Color.green.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lowLabel: "Not Hungry",
                    highLabel: "Very Hungry"
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Initialize from viewModel if already set
            if viewModel.hungerLevel > 0 {
                hunger = Double(viewModel.hungerLevel)
            } else {
                hunger = 5.0
            }
        }
    }
    
    private var hungerIcon: String {
        switch Int(hunger) {
        case 1...2: return "circle"              // Not hungry - empty circle
        case 3...4: return "circle.lefthalf.filled"  // Slightly hungry
        case 5...6: return "fork.knife"          // Moderate hunger
        case 7...8: return "fork.knife.circle"   // Hungry
        case 9...10: return "fork.knife.circle.fill" // Very hungry
        default: return "fork.knife"
        }
    }
    
    private var hungerLabel: String {
        switch Int(hunger) {
        case 1...2: return "Satisfied"
        case 3...4: return "Content"
        case 5...6: return "Moderate"
        case 7...8: return "Hungry"
        case 9...10: return "Very Hungry"
        default: return "Moderate"
        }
    }
}