//
//  DayFocusViewV2.swift
//  NutriSync
//
//  Converted day focus view using onboarding template pattern
//

import SwiftUI

struct DayFocusViewV2: View {
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Bindable var viewModel: MorningCheckInViewModel
    
    private let maxSelections = 3
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        CheckInScreenTemplate(
            title: "What activities do you have planned?",
            subtitle: "Pick up to 3 (we'll adjust meal timing)",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.nextStep()
            },
            canGoNext: !viewModel.selectedActivities.isEmpty
        ) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(MorningActivity.allCases, id: \.self) { activity in
                        ActivityButtonV2(
                            activity: activity,
                            isSelected: viewModel.selectedActivities.contains(activity),
                            isDisabled: !viewModel.selectedActivities.contains(activity) && viewModel.selectedActivities.count >= maxSelections,
                            onToggle: {
                                toggleActivity(activity)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
    }
    
    private func toggleActivity(_ activity: MorningActivity) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if viewModel.selectedActivities.contains(activity) {
                viewModel.selectedActivities.removeAll { $0 == activity }
                viewModel.activityDurations.removeValue(forKey: activity)
            } else if viewModel.selectedActivities.count < maxSelections {
                viewModel.selectedActivities.append(activity)
                viewModel.activityDurations[activity] = activity.defaultDuration
            }
        }
        hapticGenerator.impactOccurred()
    }
}

// MARK: - Activity Button
struct ActivityButtonV2: View {
    let activity: MorningActivity
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            onToggle()
        }) {
            VStack(spacing: 8) {
                // Icon circle - larger and cleaner like DayFocusSelectionView
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.1))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: activity.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? Color.black : Color.white.opacity(0.7))
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.nutriSyncAccent, lineWidth: 3)
                            .frame(width: 76, height: 76)
                    }
                }
                
                // Label
                Text(activity.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color.white : Color.nutriSyncTextSecondary)
            }
            .opacity(isDisabled && !isSelected ? 0.4 : 1.0)
        }
        .disabled(isDisabled)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}