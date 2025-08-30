//
//  MorningCheckInView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct MorningCheckInView: View {
    @StateObject private var checkInManager = CheckInManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Check-in state
    @State private var currentStep = 1
    @State private var wakeTime = Date()
    @State private var plannedBedtime: Date = {
        // Default to 10:30 PM today
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 30
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }()
    @State private var sleepQuality: Int = 5  // 0-10 scale
    @State private var energyLevel: Int = 5  // 0-10 scale
    @State private var hungerLevel: Int = 5  // 0-10 scale
    @State private var plannedActivities: [String] = []
    @State private var windowPreference: MorningCheckIn.WindowPreference = .auto
    @State private var hasRestrictions: Bool = false
    @State private var restrictions: [String] = []
    
    // Animation states
    @State private var showContent = false
    @State private var isTransitioning = false
    
    private let totalSteps = 6  // Includes planned bedtime step
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                Spacer()
                    .frame(height: 0)
                
                if showContent {
                    Group {
                        switch currentStep {
                        case 1:
                            WakeTimeSelectionView(
                                wakeTime: $wakeTime,
                                onContinue: handleNextStep,
                                onBack: handleBack
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 2:
                            SleepQualitySliderView(
                                sleepQuality: $sleepQuality,
                                onContinue: handleNextStep
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 3:
                            EnergyLevelSliderView(
                                energyLevel: $energyLevel,
                                onContinue: handleNextStep
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 4:
                            HungerLevelSliderView(
                                hungerLevel: $hungerLevel,
                                onContinue: handleNextStep
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 5:
                            EnhancedActivitiesView(
                                plannedActivities: $plannedActivities,
                                onContinue: { activities, preference, hasRest, rest in
                                    plannedActivities = activities
                                    windowPreference = preference
                                    hasRestrictions = hasRest
                                    restrictions = rest
                                    handleNextStep()
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 6:
                            PlannedBedtimeView(
                                plannedBedtime: $plannedBedtime,
                                wakeTime: wakeTime,
                                onContinue: completeCheckIn
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        default:
                            EmptyView()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                showContent = true
            }
        }
    }
    
    private func handleBack() {
        guard currentStep > 1 else {
            dismiss()
            return
        }
        
        withAnimation {
            currentStep -= 1
        }
    }
    
    private func handleNextStep() {
        guard currentStep < totalSteps else { return }
        
        withAnimation {
            currentStep += 1
        }
    }
    
    // Function no longer needed - using MorningCheckIn directly
    
    private func completeCheckIn() {
        
        let checkIn = MorningCheckIn(
            date: Date(),
            wakeTime: wakeTime,
            plannedBedtime: plannedBedtime,
            sleepQuality: sleepQuality,
            energyLevel: energyLevel,
            hungerLevel: hungerLevel,
            dayFocus: [],
            morningMood: nil,
            plannedActivities: plannedActivities,
            windowPreference: windowPreference,
            hasRestrictions: hasRestrictions,
            restrictions: restrictions
        )
        
        checkInManager.saveMorningCheckIn(checkIn)

        // Bridge to data layer so windows are regenerated based on check-in
        Task {
            let provider = DataSourceProvider.shared.provider
            let today = Date()
            
            // Use WindowGenerationService for enhanced generation
            do {
                // Save check-in to Firebase first
                try await provider.saveMorningCheckIn(checkIn)
                
                // Get user profile and goals
                let profile = try await provider.getUserProfile() ?? UserProfile.defaultProfile
                let goals = try await provider.getUserGoals() ?? UserGoals.defaultGoals
                
                // Generate windows using AI-enhanced service
                let windowService = AIWindowGenerationService.shared
                let windows = try await windowService.generateWindows(
                    for: profile,
                    checkIn: checkIn,
                    date: Date()
                )
                
                // Save generated windows to Firebase
                for window in windows {
                    try await provider.saveWindow(window)
                }
                
                print("✅ Successfully generated \(windows.count) meal windows with activities: \(plannedActivities)")
            } catch {
                print("❌ Failed to generate windows: \(error)")
            }
        }
        
        // Haptic feedback for completion
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
        
        // Dismiss with celebration
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dismiss()
        }
    }
}

#Preview {
    MorningCheckInView()
        .preferredColorScheme(.dark)
}
