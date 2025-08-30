//
//  WakeTimeSelectionViewV2.swift
//  NutriSync
//
//  Converted wake time selection using onboarding template pattern
//

import SwiftUI

struct WakeTimeSelectionViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    
    @State private var selectedHour = 7
    @State private var selectedMinute = 0
    
    // Define reasonable wake time range (4 AM to 12 PM)
    private let hourRange = 4...12
    private let minutes = [0, 15, 30, 45]
    
    private var selectedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: selectedHour == 12 ? 12 : selectedHour,
                                minute: selectedMinute,
                                second: 0,
                                of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    var body: some View {
        CheckInScreenTemplate(
            title: "What time did you wake up?",
            subtitle: "We'll optimize your meal windows based on your wake time",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                updateWakeTime()
                viewModel.nextStep()
            },
            canGoNext: true
        ) {
            VStack(spacing: 24) {
                // Selected time display
                VStack(spacing: 8) {
                    Text(selectedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("TAP TO SELECT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.nutriSyncTextTertiary)
                        .opacity(0.7)
                }
                .padding(.top, 20)
                
                // Time selection grid
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(hourRange, id: \.self) { hour in
                            VStack(spacing: 12) {
                                // Hour label
                                HStack {
                                    Text("\(hour == 12 ? 12 : hour % 12) \(hour < 12 ? "AM" : "PM")")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.nutriSyncTextTertiary)
                                    Spacer()
                                }
                                
                                // Minute buttons for this hour
                                HStack(spacing: 12) {
                                    ForEach(minutes, id: \.self) { minute in
                                        WakeTimeButtonV2(
                                            hour: hour,
                                            minute: minute,
                                            isSelected: selectedHour == hour && selectedMinute == minute,
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    selectedHour = hour
                                                    selectedMinute = minute
                                                    
                                                    // Haptic feedback
                                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                                    impact.prepare()
                                                    impact.impactOccurred()
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .frame(maxHeight: 350)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.03))
                )
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // Set initial time based on current time or reasonable default
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.hour, .minute], from: now)
            
            // If it's early morning, use current time; otherwise default to 7 AM
            if let hour = components.hour, hour >= 4 && hour <= 12 {
                selectedHour = hour
                // Round to nearest 15 minutes
                if let minute = components.minute {
                    selectedMinute = minutes.min(by: { abs($0 - minute) < abs($1 - minute) }) ?? 0
                }
            } else {
                selectedHour = 7
                selectedMinute = 0
            }
            
            updateWakeTime()
        }
    }
    
    private func updateWakeTime() {
        let calendar = Calendar.current
        viewModel.wakeTime = calendar.date(bySettingHour: selectedHour,
                                          minute: selectedMinute,
                                          second: 0,
                                          of: Date()) ?? Date()
    }
}

// MARK: - Time Button Component
private struct WakeTimeButtonV2: View {
    let hour: Int
    let minute: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var timeString: String {
        String(format: "%d:%02d", hour == 12 ? 12 : hour % 12, minute)
    }
    
    var body: some View {
        Button(action: action) {
            Text(timeString)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.nutriSyncGreen : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}