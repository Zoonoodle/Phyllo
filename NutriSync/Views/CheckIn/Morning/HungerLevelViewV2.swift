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
                
                // Hunger slider with visual progress bar
                PhylloSlider(
                    value: $hunger,
                    range: 1...10,
                    step: 1,
                    label: "Current Hunger Level",
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
}