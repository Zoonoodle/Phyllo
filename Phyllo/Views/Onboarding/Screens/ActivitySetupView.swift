//
//  ActivitySetupView.swift
//  Phyllo
//
//  Activity level and workout schedule setup
//

import SwiftUI

struct ActivitySetupView: View {
    @Binding var data: OnboardingData
    
    let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your activity level")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This helps us calculate your nutritional needs")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // Activity Level Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Label {
                            Text("Overall Activity Level")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                ActivityLevelCard(
                                    level: level,
                                    isSelected: data.activityLevel == level
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        data.activityLevel = level
                                    }
                                }
                            }
                        }
                    }
                    
                    // Workout Days
                    VStack(alignment: .leading, spacing: 16) {
                        Label {
                            Text("Workout Days")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Select the days you typically exercise")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { day in
                                DaySelector(
                                    day: weekDays[day],
                                    isSelected: data.workoutDays.contains(day)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if data.workoutDays.contains(day) {
                                            data.workoutDays.remove(day)
                                        } else {
                                            data.workoutDays.insert(day)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !data.workoutDays.isEmpty {
                            Text("\(data.workoutDays.count) days per week")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.phylloAccent)
                        }
                    }
                    
                    // Preferred Workout Time
                    if !data.workoutDays.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Label {
                                Text("Preferred Workout Time")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(WorkoutTime.allCases, id: \.self) { time in
                                    WorkoutTimeOption(
                                        time: time,
                                        isSelected: data.preferredWorkoutTime == time
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            data.preferredWorkoutTime = time
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    
                    // Fasting Protocol (Optional)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label {
                                Text("Intermittent Fasting")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Text("Optional")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ForEach([FastingProtocol.sixteen8, .eighteen6, .twenty4], id: \.self) { fastingOption in
                                    FastingProtocolButton(
                                        protocol: fastingOption,
                                        isSelected: data.fastingProtocol == fastingOption
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if data.fastingProtocol == fastingOption {
                                                data.fastingProtocol = nil
                                            } else {
                                                data.fastingProtocol = fastingOption
                                            }
                                        }
                                    }
                                }
                            }
                            
                            HStack(spacing: 8) {
                                ForEach([FastingProtocol.omad, .custom], id: \.self) { fastingOption in
                                    FastingProtocolButton(
                                        protocol: fastingOption,
                                        isSelected: data.fastingProtocol == fastingOption
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if data.fastingProtocol == fastingOption {
                                                data.fastingProtocol = nil
                                            } else {
                                                data.fastingProtocol = fastingOption
                                            }
                                        }
                                    }
                                }
                                
                                // None button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        data.fastingProtocol = nil
                                    }
                                }) {
                                    Text("None")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(data.fastingProtocol == nil ? .black : .white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(data.fastingProtocol == nil ? Color.white.opacity(0.8) : Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
    }
}

// MARK: - Activity Level Card

struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch level {
        case .sedentary: return "figure.seated"
        case .lightlyActive: return "figure.walk"
        case .moderate: return "figure.walk.motion"
        case .veryActive: return "figure.run"
        case .extremelyActive: return "figure.climbing"
        }
    }
    
    var description: String {
        switch level {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Exercise 1-3 days/week"
        case .moderate: return "Exercise 3-5 days/week"
        case .veryActive: return "Exercise 6-7 days/week"
        case .extremelyActive: return "Athlete or very physical job"
        }
    }
    
    var color: Color {
        switch level {
        case .sedentary: return .gray
        case .lightlyActive: return .blue
        case .moderate: return .green
        case .veryActive: return .orange
        case .extremelyActive: return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? color : .white.opacity(0.5))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
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
                        .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(color)
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
                            .stroke(isSelected ? color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day Selector

struct DaySelector: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.phylloAccent : Color.white.opacity(0.05))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Time Option

struct WorkoutTimeOption: View {
    let time: WorkoutTime
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(time.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.purple : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fasting Protocol Button

struct FastingProtocolButton: View {
    let `protocol`: FastingProtocol
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(`protocol`.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.phylloAccent : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                ActivitySetupView(data: $data)
            }
        }
    }
    
    return PreviewWrapper()
}