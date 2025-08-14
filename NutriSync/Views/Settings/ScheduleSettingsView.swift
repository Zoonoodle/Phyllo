//
//  ScheduleSettingsView.swift
//  NutriSync
//
//  Created on 8/12/25.
//

import SwiftUI

struct ScheduleSettingsView: View {
    @StateObject private var viewModel = ScheduleSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Work Schedule Section
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Work Schedule", systemImage: "briefcase.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(WorkSchedule.allCases, id: \.self) { schedule in
                                ScheduleOptionRow(
                                    title: schedule.displayName,
                                    isSelected: viewModel.workSchedule == schedule,
                                    action: { viewModel.workSchedule = schedule }
                                )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(16)
                        
                        // Meal Hours Section
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Typical Meal Hours", systemImage: "clock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("First Meal")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Picker("", selection: $viewModel.earliestMealHour) {
                                    ForEach(0...23, id: \.self) { hour in
                                        Text(formatHour(hour))
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.nutriSyncAccent)
                            }
                            
                            HStack {
                                Text("Last Meal")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Picker("", selection: $viewModel.latestMealHour) {
                                    ForEach(viewModel.earliestMealHour...23, id: \.self) { hour in
                                        Text(formatHour(hour))
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.nutriSyncAccent)
                            }
                            
                            if viewModel.hasDetectedPattern {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                    Text("Based on your meal history")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.nutriSyncAccent.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(16)
                        
                        // Fasting Protocol Section
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Fasting Protocol", systemImage: "timer")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(FastingProtocol.allCases, id: \.self) { fastingType in
                                ScheduleOptionRow(
                                    title: fastingType.displayName,
                                    isSelected: viewModel.fastingProtocol == fastingType,
                                    action: { viewModel.fastingProtocol = fastingType }
                                )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(16)
                        
                        // Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.nutriSyncAccent)
                            
                            Text("Your schedule settings help us show the right hours on your timeline and avoid unnecessary nudges during your fasting or sleeping hours.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.nutriSyncAccent.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveSettings()
                            dismiss()
                        }
                    }
                    .foregroundColor(.nutriSyncAccent)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUserProfile()
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

struct ScheduleOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.nutriSyncAccent)
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model

@MainActor
class ScheduleSettingsViewModel: ObservableObject {
    @Published var workSchedule: WorkSchedule = .standard
    @Published var earliestMealHour: Int = 7
    @Published var latestMealHour: Int = 22
    @Published var fastingProtocol: FastingProtocol = .none
    @Published var hasDetectedPattern = false
    
    private let dataProvider = DataSourceProvider.shared.provider
    private var userProfile: UserProfile?
    
    func loadUserProfile() async {
        do {
            if let profile = try await dataProvider.getUserProfile() {
                self.userProfile = profile
                
                // Load current settings
                self.workSchedule = profile.workSchedule
                self.fastingProtocol = profile.fastingProtocol
                
                if let earliest = profile.earliestMealHour,
                   let latest = profile.latestMealHour {
                    self.earliestMealHour = earliest
                    self.latestMealHour = latest
                    self.hasDetectedPattern = true
                } else {
                    // Try to detect pattern from meal history
                    if let patterns = try await MealPatternAnalyzer.shared.analyzeMealPatterns(for: profile.id.uuidString) {
                        self.earliestMealHour = patterns.earliest
                        self.latestMealHour = patterns.latest
                        self.hasDetectedPattern = true
                    }
                }
            }
        } catch {
            DebugLogger.shared.error("Failed to load user profile: \(error)")
        }
    }
    
    func saveSettings() async {
        guard var profile = userProfile else { return }
        
        // Update profile with new settings
        profile.workSchedule = workSchedule
        profile.earliestMealHour = earliestMealHour
        profile.latestMealHour = latestMealHour
        profile.fastingProtocol = fastingProtocol
        
        do {
            try await dataProvider.saveUserProfile(profile)
            DebugLogger.shared.success("Schedule settings saved")
        } catch {
            DebugLogger.shared.error("Failed to save schedule settings: \(error)")
        }
    }
}

#Preview {
    ScheduleSettingsView()
}