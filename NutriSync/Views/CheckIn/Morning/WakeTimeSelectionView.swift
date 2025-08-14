//
//  WakeTimeSelectionView.swift
//  NutriSync
//
//  Created on 8/10/25.
//

import SwiftUI

struct WakeTimeSelectionView: View {
    @Binding var wakeTime: Date
    let onContinue: () -> Void
    
    @State private var selectedHour = 7
    @State private var selectedMinute = 0
    @State private var showContent = false
    @State private var animateTitle = false
    @State private var animateGrid = false
    
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
        VStack(spacing: 0) {
            // Title section
            VStack(spacing: 16) {
                Text("What time did you wake up?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateTitle ? 1.0 : 0)
                    .offset(y: animateTitle ? 0 : 20)
                
                Text("We'll optimize your meal windows based on your wake time")
                    .font(.system(size: 16))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateTitle ? 1.0 : 0)
                    .offset(y: animateTitle ? 0 : 20)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateTitle)
            
            // Selected time display
            VStack(spacing: 8) {
                Text(selectedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1.0 : 0)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                
                Text("TAP TO SELECT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.nutriSyncTextTertiary)
                    .opacity(showContent ? 0.7 : 0)
            }
            .padding(.top, 40)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: showContent)
            
            Spacer()
            
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
                                    WakeTimeButton(
                                        hour: hour,
                                        minute: minute,
                                        isSelected: selectedHour == hour && selectedMinute == minute,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedHour = hour
                                                selectedMinute = minute
                                                updateWakeTime()
                                                
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
                        .opacity(animateGrid ? 1.0 : 0)
                        .offset(x: animateGrid ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(0.1 * Double(hour - hourRange.lowerBound)), value: animateGrid)
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
            .opacity(showContent ? 1.0 : 0)
            .offset(y: showContent ? 0 : 40)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
            
            Spacer()
            
            // Continue button
            HStack {
                Spacer()
                CheckInButton("", style: .minimal, action: onContinue)
                    .opacity(animateGrid ? 1.0 : 0)
                    .scaleEffect(animateGrid ? 1.0 : 0.8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: animateGrid)
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
            
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
                animateTitle = true
                animateGrid = true
            }
        }
    }
    
    private func updateWakeTime() {
        let calendar = Calendar.current
        wakeTime = calendar.date(bySettingHour: selectedHour, 
                               minute: selectedMinute, 
                               second: 0, 
                               of: Date()) ?? Date()
    }
}

// MARK: - Time Button Component
private struct WakeTimeButton: View {
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

#Preview {
    struct PreviewWrapper: View {
        @State private var wakeTime = Date()
        
        var body: some View {
            WakeTimeSelectionView(wakeTime: $wakeTime) {
                print("Continue tapped")
            }
            .preferredColorScheme(.dark)
            .background(Color.nutriSyncBackground)
        }
    }
    
    return PreviewWrapper()
}