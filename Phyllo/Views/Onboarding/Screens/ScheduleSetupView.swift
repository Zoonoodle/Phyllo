//
//  ScheduleSetupView.swift
//  Phyllo
//
//  Schedule setup for onboarding - wake/sleep times and work schedule
//

import SwiftUI

struct ScheduleSetupView: View {
    @Binding var data: OnboardingData
    @State private var showWakeTimePicker = false
    @State private var showSleepTimePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your daily schedule")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll optimize your meal windows around your routine")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // Wake Time
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Wake Time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "sunrise.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { showWakeTimePicker.toggle() }) {
                            HStack {
                                Text(data.wakeTime?.formatted(date: .omitted, time: .shortened) ?? "Select wake time")
                                    .font(.system(size: 17))
                                    .foregroundColor(data.wakeTime != nil ? .white : .white.opacity(0.5))
                                
                                Spacer()
                                
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if showWakeTimePicker {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { data.wakeTime ?? defaultWakeTime() },
                                    set: { data.wakeTime = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(height: 150)
                            .clipped()
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    
                    // Sleep Time
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Sleep Time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.indigo)
                        }
                        
                        Button(action: { showSleepTimePicker.toggle() }) {
                            HStack {
                                Text(data.sleepTime?.formatted(date: .omitted, time: .shortened) ?? "Select sleep time")
                                    .font(.system(size: 17))
                                    .foregroundColor(data.sleepTime != nil ? .white : .white.opacity(0.5))
                                
                                Spacer()
                                
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if showSleepTimePicker {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { data.sleepTime ?? defaultSleepTime() },
                                    set: { data.sleepTime = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(height: 150)
                            .clipped()
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    
                    // Sleep Duration Display
                    if let wake = data.wakeTime, let sleep = data.sleepTime {
                        SleepDurationCard(wakeTime: wake, sleepTime: sleep)
                    }
                    
                    // Work Schedule
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Work Schedule")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(WorkSchedule.allCases, id: \.self) { schedule in
                                WorkScheduleOption(
                                    schedule: schedule,
                                    isSelected: data.workSchedule == schedule
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        data.workSchedule = schedule
                                    }
                                }
                            }
                        }
                    }
                    
                    // Meal Preference
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Preferred Meal Frequency")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(2...6, id: \.self) { count in
                                MealCountButton(
                                    count: count,
                                    isSelected: data.preferredMealCount == count
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        data.preferredMealCount = count
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showWakeTimePicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSleepTimePicker)
    }
    
    private func defaultWakeTime() -> Date {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    private func defaultSleepTime() -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Sleep Duration Card

struct SleepDurationCard: View {
    let wakeTime: Date
    let sleepTime: Date
    
    var sleepDuration: (hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let wake = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let sleep = calendar.dateComponents([.hour, .minute], from: sleepTime)
        
        guard let wakeHour = wake.hour, let wakeMinute = wake.minute,
              let sleepHour = sleep.hour, let sleepMinute = sleep.minute else {
            return (0, 0)
        }
        
        var totalMinutes = 0
        
        if sleepHour < wakeHour || (sleepHour == wakeHour && sleepMinute < wakeMinute) {
            // Sleep time is next day
            totalMinutes = (24 - wakeHour) * 60 - wakeMinute + sleepHour * 60 + sleepMinute
        } else {
            totalMinutes = (sleepHour - wakeHour) * 60 + (sleepMinute - wakeMinute)
        }
        
        return (totalMinutes / 60, totalMinutes % 60)
    }
    
    var body: some View {
        HStack {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 20))
                .foregroundColor(.indigo)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Duration")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(sleepDuration.hours)h \(sleepDuration.minutes)m")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Quality indicator
            if sleepDuration.hours >= 7 && sleepDuration.hours <= 9 {
                Label("Optimal", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            } else if sleepDuration.hours < 7 {
                Label("Low", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.indigo.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Work Schedule Option

struct WorkScheduleOption: View {
    let schedule: WorkSchedule
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch schedule {
        case .traditional: return "building.2"
        case .shiftWork: return "clock.arrow.2.circlepath"
        case .remote: return "house.laptop"
        case .irregular: return "calendar.badge.clock"
        }
    }
    
    var description: String {
        switch schedule {
        case .traditional: return "Regular daytime hours"
        case .shiftWork: return "Rotating or night shifts"
        case .remote: return "Flexible work from home"
        case .irregular: return "Varies day to day"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Meal Count Button

struct MealCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                
                Text("meals")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .black.opacity(0.8) : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.phylloAccent : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ScheduleSetupView(data: $data)
            }
        }
    }
    
    return PreviewWrapper()
}