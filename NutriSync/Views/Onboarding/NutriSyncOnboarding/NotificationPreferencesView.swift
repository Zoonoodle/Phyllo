//
//  NotificationPreferencesView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Notification Preferences
//

import SwiftUI

struct NotificationPreferencesView: View {
    @State private var windowStartNotifications = true
    @State private var windowEndNotifications = true
    @State private var checkInReminders = true
    @State private var notificationMinutesBefore = 15
    
    let timingOptions = [5, 10, 15, 30, 60]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 30)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Window Reminders")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("How should we notify you about your eating windows?")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Notification toggles
                    VStack(spacing: 16) {
                        ToggleRow(
                            title: "Window opening reminders",
                            subtitle: "Get notified when it's time to eat",
                            isOn: $windowStartNotifications
                        )
                        
                        ToggleRow(
                            title: "Window closing warnings",
                            subtitle: "Reminder before your eating window closes",
                            isOn: $windowEndNotifications
                        )
                        
                        ToggleRow(
                            title: "Daily check-in reminders",
                            subtitle: "Track your progress and energy levels",
                            isOn: $checkInReminders
                        )
                    }
                    .padding(.bottom, 8)
                    
                    // Notification timing
                    if windowStartNotifications || windowEndNotifications {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notification Timing")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Notify me \(notificationMinutesBefore) minutes before")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(timingOptions, id: \.self) { minutes in
                                        TimingButton(
                                            minutes: minutes,
                                            isSelected: notificationMinutesBefore == minutes,
                                            action: {
                                                notificationMinutesBefore = minutes
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Privacy note
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("You can change notification settings anytime in the app")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    // Back action
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    // Next action
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.nutriSyncBackground)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

struct TimingButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(minutes) min")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color.nutriSyncBackground : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }
}

struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreferencesView()
    }
}