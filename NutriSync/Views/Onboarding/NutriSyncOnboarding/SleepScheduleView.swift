//
//  SleepScheduleView.swift
//  NutriSync
//
//  Sleep schedule input for circadian rhythm alignment
//

import SwiftUI

struct SleepScheduleView: View {
    @State private var wakeTime: Date = {
        let components = DateComponents(hour: 7, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    @State private var bedTime: Date = {
        let components = DateComponents(hour: 23, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationHeader(
                    currentStep: 1,
                    totalSteps: 4,
                    onBack: {},
                    onClose: {}
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("What's your typical sleep schedule?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Explanation
                        Text("Your meal timing will be optimized around your circadian rhythm. Research shows that eating in sync with your biological clock improves metabolism and energy levels.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                        
                        // Wake time picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wake Time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 24)
                            
                            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .colorInvert()
                                .colorMultiply(.white)
                                .padding(.horizontal, 24)
                                .frame(height: 120)
                        }
                        .padding(.top, 16)
                        
                        // Bed time picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bed Time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 24)
                            
                            DatePicker("", selection: $bedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .colorInvert()
                                .colorMultiply(.white)
                                .padding(.horizontal, 24)
                                .frame(height: 120)
                        }
                        
                        // Info card
                        HStack(spacing: 16) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.nutriSyncAccent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Circadian Optimization")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("We'll schedule your last meal 3 hours before bedtime to optimize sleep quality and metabolic health.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineSpacing(2)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Continue button
                PrimaryButton(title: "Continue") {
                    // Handle continue
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