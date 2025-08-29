//
//  PlannedBedtimeView.swift
//  NutriSync
//
//  Created on 8/27/25.
//

import SwiftUI

struct PlannedBedtimeView: View {
    @Binding var plannedBedtime: Date
    let wakeTime: Date
    let onContinue: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.nutriSyncAccent)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showContent)
                
                // Title
                VStack(spacing: 8) {
                    Text("What time do you")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("plan to sleep tonight?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This helps optimize your meal timing")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            }
            
            // Time Picker
            VStack(spacing: 16) {
                DatePicker(
                    "",
                    selection: $plannedBedtime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .colorScheme(.dark)
                .scaleEffect(1.2)
                .padding(.horizontal)
                .onChange(of: plannedBedtime) { newValue in
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
                        if adjustedBedtime < wakeTime {
                            if let tomorrowBedtime = calendar.date(byAdding: .day, value: 1, to: adjustedBedtime) {
                                plannedBedtime = tomorrowBedtime
                            } else {
                                plannedBedtime = adjustedBedtime
                            }
                        } else {
                            plannedBedtime = adjustedBedtime
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
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: showContent)
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    Text("Complete Check-In")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.nutriSyncAccent)
                )
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: showContent)
        }
        .padding(.vertical, 32)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
    
    private var sleepDurationText: String {
        let calendar = Calendar.current
        
        // Calculate awake time
        let awakeInterval: TimeInterval
        if plannedBedtime > wakeTime {
            // Normal case: sleep tonight
            awakeInterval = plannedBedtime.timeIntervalSince(wakeTime)
        } else {
            // Bedtime is past midnight
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: wakeTime) ?? wakeTime
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: wakeTime)) ?? wakeTime
            let timeUntilMidnight = endOfDay.timeIntervalSince(wakeTime)
            let timeAfterMidnight = plannedBedtime.timeIntervalSince(startOfNextDay)
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

#Preview {
    ZStack {
        Color.nutriSyncBackground
            .ignoresSafeArea()
        
        PlannedBedtimeView(
            plannedBedtime: .constant(Date()),
            wakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            onContinue: {}
        )
    }
}