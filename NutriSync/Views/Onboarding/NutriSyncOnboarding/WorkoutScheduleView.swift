//
//  WorkoutScheduleView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Workout Schedule
//

import SwiftUI

struct WorkoutScheduleView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedDays: Set<String> = []
    @State private var workoutTime = Date()
    
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 13)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Workout Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Subtitle
                Text("When do you typically exercise?")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                
                // Days selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout Days")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Day selection grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(weekDays, id: \.self) { day in
                            DaySelectionButton(
                                day: day,
                                isSelected: selectedDays.contains(day),
                                action: {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Time selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Typical Workout Time")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    DatePicker("", 
                        selection: $workoutTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(0.9)
                    .frame(height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    coordinator.previousScreen()
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
                    // Save workout schedule to coordinator
                    coordinator.workoutDays = selectedDays
                    coordinator.workoutTime = workoutTime
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(!selectedDays.isEmpty ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(!selectedDays.isEmpty ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(selectedDays.isEmpty)
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

struct DaySelectionButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color.nutriSyncBackground : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

struct WorkoutScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutScheduleView()
    }
}