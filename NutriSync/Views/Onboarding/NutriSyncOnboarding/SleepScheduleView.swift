//
//  SleepScheduleView.swift
//  NutriSync
//
//  Sleep schedule input for circadian rhythm alignment
//

import SwiftUI

struct SleepScheduleView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var wakeTime: Date = {
        let components = DateComponents(hour: 7, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    @State private var bedTime: Date = {
        let components = DateComponents(hour: 23, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var hasInteracted = false
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationHeader(
                    currentStep: 1,
                    totalSteps: 4,
                    onBack: { coordinator.previousScreen() },
                    onClose: {}
                )
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("What's your typical sleep schedule?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                    // Wake time picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wake Time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                        
                        DatePicker("", selection: Binding(
                            get: { wakeTime },
                            set: { 
                                wakeTime = $0
                                hasInteracted = true
                            }
                        ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .environment(\.colorScheme, .dark)
                            .padding(.horizontal, 24)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    .padding(.top, 32)
                        
                    // Bed time picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bed Time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                        
                        DatePicker("", selection: Binding(
                            get: { bedTime },
                            set: { 
                                bedTime = $0
                                hasInteracted = true
                            }
                        ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .environment(\.colorScheme, .dark)
                            .padding(.horizontal, 24)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                }
                
                Spacer()
                
                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isEnabled: hasInteracted
                ) {
                    coordinator.wakeTime = wakeTime
                    coordinator.bedTime = bedTime
                    coordinator.nextScreen()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var sleepDuration: String {
        let duration = bedTime.timeIntervalSince(wakeTime)
        let hours = Int(duration) / 3600
        let adjustedHours = hours < 0 ? hours + 24 : hours
        return "\(adjustedHours) hours"
    }
}