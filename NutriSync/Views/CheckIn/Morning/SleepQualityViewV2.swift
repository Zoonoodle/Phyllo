//
//  SleepQualityViewV2.swift
//  NutriSync
//
//  Converted sleep quality view using onboarding template pattern
//

import SwiftUI

struct SleepQualityViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    @State private var sleepHours: Double = 7.0
    
    var body: some View {
        CheckInScreenTemplate(
            title: "How many hours did you sleep?",
            subtitle: "Track your sleep to optimize your energy and meal timing",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                // Convert hours to quality rating (1-10 scale)
                viewModel.sleepQuality = Int(min(max(sleepHours / 1.2, 1), 10))
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            VStack(spacing: 40) {
                // Sleep hours display
                VStack(spacing: 12) {
                    Text("\(sleepHours, specifier: "%.1f")")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("hours of sleep")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Quality indicator
                    HStack(spacing: 4) {
                        Image(systemName: qualityIcon)
                            .font(.system(size: 16))
                            .foregroundColor(.nutriSyncAccent)
                        
                        Text(qualityText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.nutriSyncAccent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 40)
                
                // Simple slider
                VStack(spacing: 16) {
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                        .accentColor(.nutriSyncAccent)
                        .padding(.horizontal, 20)
                    
                    // Min and max labels
                    HStack {
                        Text("0h")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("12h")
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
            if viewModel.sleepQuality > 0 {
                sleepHours = Double(viewModel.sleepQuality) * 1.2
            }
        }
    }
    
    private var qualityText: String {
        switch sleepHours {
        case 0..<3: return "Very Poor"
        case 3..<5: return "Poor"
        case 5..<7: return "Fair"
        case 7..<9: return "Good"
        default: return "Excellent"
        }
    }
    
    private var qualityIcon: String {
        switch sleepHours {
        case 0..<3: return "moon.zzz"
        case 3..<5: return "moon"
        case 5..<7: return "moon.fill"
        case 7..<9: return "moon.stars"
        default: return "moon.stars.fill"
        }
    }
}