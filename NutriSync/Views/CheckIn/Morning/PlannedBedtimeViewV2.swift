//
//  PlannedBedtimeViewV2.swift
//  NutriSync
//
//  Converted planned bedtime selection using onboarding template pattern
//

import SwiftUI

struct PlannedBedtimeViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    
    var body: some View {
        CheckInScreenTemplate(
            title: "What time do you plan to sleep tonight?",
            subtitle: "This helps optimize your meal timing",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.completeCheckIn()
            },
            canGoNext: true
        ) {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.nutriSyncAccent)
                    .padding(.top, 20)
                
                // Time Picker
                VStack(spacing: 16) {
                    DatePicker(
                        "",
                        selection: $viewModel.plannedBedtime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1.2)
                    .padding(.horizontal)
                    .onChange(of: viewModel.plannedBedtime) { newValue in
                        // Ensure bedtime is set to today's date with the selected time
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: newValue)
                        
                        // Create bedtime on today's date
                        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
                        todayComponents.hour = components.hour
                        todayComponents.minute = components.minute
                        todayComponents.second = 0
                        
                        if let adjustedBedtime = calendar.date(from: todayComponents) {
                            // If bedtime is before wake time, assume it's for tomorrow
                            if adjustedBedtime < viewModel.wakeTime {
                                if let tomorrowBedtime = calendar.date(byAdding: .day, value: 1, to: adjustedBedtime) {
                                    viewModel.plannedBedtime = tomorrowBedtime
                                } else {
                                    viewModel.plannedBedtime = adjustedBedtime
                                }
                            } else {
                                viewModel.plannedBedtime = adjustedBedtime
                            }
                        }
                    }
                    
                    // Sleep duration estimate
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.nutriSyncAccent.opacity(0.8))
                        
                        Text(sleepDurationText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
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
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var sleepDurationText: String {
        let calendar = Calendar.current
        
        // Calculate awake time
        let awakeInterval: TimeInterval
        if viewModel.plannedBedtime > viewModel.wakeTime {
            // Normal case: sleep tonight
            awakeInterval = viewModel.plannedBedtime.timeIntervalSince(viewModel.wakeTime)
        } else {
            // Bedtime is past midnight
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: viewModel.wakeTime) ?? viewModel.wakeTime
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: viewModel.wakeTime)) ?? viewModel.wakeTime
            let timeUntilMidnight = endOfDay.timeIntervalSince(viewModel.wakeTime)
            let timeAfterMidnight = viewModel.plannedBedtime.timeIntervalSince(startOfNextDay)
            awakeInterval = timeUntilMidnight + timeAfterMidnight + 1 // +1 for the second at midnight
        }
        
        let hours = Int(awakeInterval) / 3600
        let minutes = (Int(awakeInterval) % 3600) / 60
        
        if minutes > 0 {
            return "You'll be awake for \(hours)h \(minutes)m"
        } else {
            return "You'll be awake for \(hours) hours"
        }
    }
}