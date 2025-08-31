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
                Spacer()
                
                // Sleep hours display
                VStack(spacing: 12) {
                    Text("\(sleepHours, specifier: "%.1f")")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("hours of sleep")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Sleep quality slider with visual progress bar
                PhylloSlider(
                    value: $sleepHours,
                    range: 0...12,
                    step: 0.5,
                    label: "Sleep Duration",
                    gradient: LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lowLabel: "0 hours",
                    highLabel: "12 hours"
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Initialize from viewModel if already set
            if viewModel.sleepQuality > 0 {
                sleepHours = Double(viewModel.sleepQuality) * 1.2
            }
        }
    }
}