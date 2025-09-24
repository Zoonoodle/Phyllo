//
//  ScheduleView.swift
//  NutriSync
//
//  Single screen for all schedule inputs
//

import SwiftUI

struct ScheduleView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var showWorkoutPicker = false
    @State private var hasWorkout = false
    
    // Quick presets based on common patterns
    let quickPresets = [
        ("9-5 Workday", Date.from(hour: 9), Date.from(hour: 17)),
        ("Early Shift", Date.from(hour: 6), Date.from(hour: 14)),
        ("Night Shift", Date.from(hour: 22), Date.from(hour: 6))
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= 1 ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("What's your schedule?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("I'll plan your meals around your commitments")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Work schedule toggle
                    VStack(spacing: 16) {
                        Toggle(isOn: $viewModel.hasWorkToday) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.nutriSyncAccent)
                                Text("Working today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .tint(.nutriSyncAccent)
                        
                        if viewModel.hasWorkToday {
                            // Quick presets
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickPresets, id: \.0) { preset in
                                        Button(action: {
                                            viewModel.workStart = preset.1
                                            viewModel.workEnd = preset.2
                                        }) {
                                            Text(preset.0)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(isPresetSelected(preset) ? .black : .white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    isPresetSelected(preset) ?
                                                    Color.nutriSyncAccent : Color.white.opacity(0.1)
                                                )
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            
                            // Time pickers
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Start")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    DatePicker("", selection: $viewModel.workStart, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .padding(8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("End")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    DatePicker("", selection: $viewModel.workEnd, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .padding(8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    
                    // Workout toggle
                    VStack(spacing: 16) {
                        Toggle(isOn: $hasWorkout) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .foregroundColor(.nutriSyncAccent)
                                Text("Planning to exercise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .tint(.nutriSyncAccent)
                        
                        if hasWorkout {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What time?")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                DatePicker("", selection: Binding(
                                    get: { viewModel.workoutTime ?? Date() },
                                    set: { viewModel.workoutTime = $0 }
                                ), displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    
                    // Quick options for common patterns
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or use yesterday's schedule")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button(action: loadYesterdaySchedule) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                Text("Same as yesterday")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.nutriSyncAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.nutriSyncAccent.opacity(0.15))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button(action: { viewModel.previousScreen() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                }
                
                Button(action: { 
                    if !hasWorkout {
                        viewModel.workoutTime = nil
                    }
                    viewModel.nextScreen() 
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncAccent)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasWorkToday)
        .animation(.easeInOut(duration: 0.2), value: hasWorkout)
    }
    
    private func isPresetSelected(_ preset: (String, Date, Date)) -> Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: viewModel.workStart)
        let endHour = calendar.component(.hour, from: viewModel.workEnd)
        let presetStartHour = calendar.component(.hour, from: preset.1)
        let presetEndHour = calendar.component(.hour, from: preset.2)
        
        return startHour == presetStartHour && endHour == presetEndHour
    }
    
    private func loadYesterdaySchedule() {
        // TODO: Load from previous day's sync
        // For now, use typical 9-5
        viewModel.workStart = Date.from(hour: 9)
        viewModel.workEnd = Date.from(hour: 17)
        viewModel.hasWorkToday = true
    }
}

// MARK: - Date Helper
extension Date {
    static func from(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(
            year: calendar.component(.year, from: Date()),
            month: calendar.component(.month, from: Date()),
            day: calendar.component(.day, from: Date()),
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components) ?? Date()
    }
}