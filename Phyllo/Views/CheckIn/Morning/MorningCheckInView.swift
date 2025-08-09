//
//  MorningCheckInView.swift
//  Phyllo
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
    @State private var selectedFocuses: Set<MorningCheckIn.DayFocus> = []
    
    // Animation states
    @State private var showContent = false
    @State private var isTransitioning = false
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with progress
                VStack(spacing: 16) {
                    HStack {
                        Button(action: handleBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.phylloTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    
                    // Progress bar
                    SegmentedProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
                // Content
                if showContent {
                    Group {
                        switch currentStep {
                        case 1:
                            WelcomeCheckInView(onContinue: handleNextStep)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case 2:
                            SleepQualityView(
                                selectedQuality: $sleepQuality,
                                onContinue: handleNextStep
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case 3:
                            DayFocusSelectionView(
                                selectedFocuses: $selectedFocuses,
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
            dayFocus: selectedFocuses,
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
            let planned = selectedFocuses.map { $0.rawValue }
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

// MARK: - Welcome View
struct WelcomeCheckInView: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Welcome text at top
            VStack(spacing: 16) {
                Text("Good morning!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateText ? 1.0 : 0)
                    .offset(y: animateText ? 0 : 20)
                
                Text("Let's start your day with a quick check-in to optimize your nutrition plan.")
                    .font(.system(size: 16))
                    .foregroundColor(.phylloTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateText ? 1.0 : 0)
                    .offset(y: animateText ? 0 : 20)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateText)
            
            Spacer()
            
            // Coffee steam animation in center
            CoffeeSteamAnimation()
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showContent)
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 40) {
                // Text under coffee
                Text("Takes less than 15 seconds")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextTertiary)
                    .opacity(animateText ? 1.0 : 0)
                
                // Continue button aligned to right
                HStack {
                    Spacer()
                    CheckInButton("", style: .minimal, action: onContinue)
                        .opacity(animateText ? 1.0 : 0)
                        .scaleEffect(animateText ? 1.0 : 0.8)
                }
            }
            .padding(.bottom, 60)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateText)
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
                animateText = true
            }
        }
    }
}

#Preview {
    MorningCheckInView()
        .preferredColorScheme(.dark)
}