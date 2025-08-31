//
//  WakeTimeSelectionViewV2.swift
//  NutriSync
//
//  Converted wake time selection using onboarding template pattern
//

import SwiftUI

struct WakeTimeSelectionViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    @State private var selectedWakeTime: Date = Date()
    
    var body: some View {
        CheckInScreenTemplate(
            title: "What time did you wake up?",
            subtitle: "We'll optimize your meal windows based on your wake time",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.wakeTime = selectedWakeTime
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            VStack(spacing: 20) {
                // Time scroll selector for past times - increased height
                TimeScrollSelector(
                    selectedTime: $selectedWakeTime,
                    hoursBack: 12,  // Show past 12 hours
                    interval: 15,   // 15-minute intervals
                    autoScrollTarget: getDefaultWakeTime()
                )
                .padding(.horizontal, 20)
                .padding(.top, 40)  // Add top padding to better position the selector
            }
        }
        .onAppear {
            // Initialize with default wake time if not already set
            if viewModel.wakeTime == Date.distantPast {
                selectedWakeTime = getDefaultWakeTime()
            } else {
                selectedWakeTime = viewModel.wakeTime
            }
        }
    }
    
    private func getDefaultWakeTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Default to 7 AM today
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 7
        components.minute = 0
        components.second = 0
        
        if let defaultTime = calendar.date(from: components) {
            // If default time is in the future, return current time
            if defaultTime > now {
                return now
            }
            return defaultTime
        }
        
        return now
    }
}