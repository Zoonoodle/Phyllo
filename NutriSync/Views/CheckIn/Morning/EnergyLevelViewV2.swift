//
//  EnergyLevelViewV2.swift
//  NutriSync
//
//  Converted energy level view using onboarding template pattern
//

import SwiftUI

struct EnergyLevelViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    @State private var energy: Double = 5.0
    
    var body: some View {
        CheckInScreenTemplate(
            title: "How's your energy?",
            subtitle: "This helps us optimize your meal timing",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.energyLevel = Int(energy)
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            VStack(spacing: 40) {
                // Energy display
                VStack(spacing: 12) {
                    Image(systemName: energyIcon)
                        .font(.system(size: 72))
                        .foregroundColor(.nutriSyncAccent)
                    
                    Text(energyLabel)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Energy Level")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 40)
                
                // Energy slider
                VStack(spacing: 16) {
                    Slider(value: $energy, in: 1...10, step: 1)
                        .accentColor(.nutriSyncAccent)
                        .padding(.horizontal, 20)
                    
                    // Labels
                    HStack {
                        Text("Exhausted")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("Excellent")
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
            if viewModel.energyLevel > 0 {
                energy = Double(viewModel.energyLevel)
            } else {
                energy = 5.0
            }
        }
    }
    
    private var energyIcon: String {
        switch Int(energy) {
        case 1...2: return "battery.0"
        case 3...4: return "battery.25"
        case 5...6: return "battery.50"
        case 7...8: return "battery.75"
        case 9...10: return "battery.100"
        default: return "battery.50"
        }
    }
    
    private var energyLabel: String {
        switch Int(energy) {
        case 1...2: return "Exhausted"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Moderate"
        }
    }
}