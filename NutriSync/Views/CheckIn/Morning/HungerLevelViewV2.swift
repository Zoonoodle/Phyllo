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
                // Hunger display
                VStack(spacing: 12) {
                    Text(hungerEmoji)
                        .font(.system(size: 72))
                    
                    Text(hungerLabel)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Hunger Level")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                // Hunger slider
                VStack(spacing: 16) {
                    Slider(value: $hunger, in: 1...10, step: 1)
                        .accentColor(.nutriSyncAccent)
                        .padding(.horizontal, 20)
                    
                    // Labels
                    HStack {
                        Text("Not hungry")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("Starving")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
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
    
    private var hungerEmoji: String {
        switch Int(hunger) {
        case 1...2: return "😌"
        case 3...4: return "🙂"
        case 5...6: return "😐"
        case 7...8: return "😋"
        case 9...10: return "🤤"
        default: return "😐"
        }
    }
    
    private var hungerLabel: String {
        switch Int(hunger) {
        case 1...2: return "Not Hungry"
        case 3...4: return "Slightly Hungry"
        case 5...6: return "Moderately Hungry"
        case 7...8: return "Very Hungry"
        case 9...10: return "Starving"
        default: return "Moderately Hungry"
        }
    }
}