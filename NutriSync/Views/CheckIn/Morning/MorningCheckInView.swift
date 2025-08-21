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
    @State private var sleepQuality: MorningCheckIn.SleepQuality?
    
    // Animation states
    @State private var showContent = false
    @State private var isTransitioning = false
    
    private let totalSteps = 2
    
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
                            SleepQualityView(
                                selectedQuality: $sleepQuality,
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
    
    private func completeCheckIn() {
        guard let quality = sleepQuality else { return }
        
        let checkIn = MorningCheckIn(
            date: Date(),
            wakeTime: wakeTime,
            sleepQuality: quality,
            dayFocus: [],
            morningMood: nil
        )
        
        checkInManager.saveMorningCheckIn(checkIn)

        // Bridge to data layer so windows are regenerated based on check-in
        Task {
            let provider = DataSourceProvider.shared.provider
            let today = Date()
            // Map UI check-in to data model used by generation
            let sleepQuality10 = quality.rawValue * 2 // scale 1-5 → 2-10
            let estimatedSleepHours: Double = {
                switch quality {
                case .terrible: return 3
                case .poor: return 5
                case .fair: return 6.5
                case .good: return 8
                case .excellent: return 9
                }
            }()
            let planned: [String] = []
            let dataCheckIn = MorningCheckInData(
                date: today,
                wakeTime: wakeTime,
                sleepQuality: sleepQuality10,
                sleepDuration: estimatedSleepHours * 3600,
                energyLevel: max(1, min(5, quality.rawValue + 1)),
                plannedActivities: planned,
                hungerLevel: 3
            )
            do {
                try await provider.saveMorningCheckIn(dataCheckIn)
                let profile = try await provider.getUserProfile() ?? UserProfile.defaultProfile
                _ = try await provider.generateDailyWindows(for: today, profile: profile, checkIn: dataCheckIn)
            } catch {
                print("❌ Failed to persist morning check-in or generate windows: \(error)")
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
