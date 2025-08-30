//
//  DayFocusViewV2.swift
//  NutriSync
//
//  Converted day focus view using onboarding template pattern
//

import SwiftUI

struct DayFocusViewV2: View {
    @Bindable var viewModel: MorningCheckInViewModel
    
    private let maxSelections = 3
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        CheckInScreenTemplate(
            title: "What's your main focus for today?",
            subtitle: "Pick up to 3",
            currentStep: viewModel.currentStep,
            totalSteps: viewModel.totalSteps,
            onBack: viewModel.previousStep,
            onNext: {
                viewModel.nextStep()
            },
            canGoNext: !viewModel.dayFocus.isEmpty
        ) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(MorningCheckIn.DayFocus.allCases, id: \.self) { focus in
                    FocusButtonV2(
                        focus: focus,
                        isSelected: viewModel.dayFocus.contains(focus),
                        isDisabled: !viewModel.dayFocus.contains(focus) && viewModel.dayFocus.count >= maxSelections,
                        onToggle: {
                            toggleFocus(focus)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private func toggleFocus(_ focus: MorningCheckIn.DayFocus) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if viewModel.dayFocus.contains(focus) {
                viewModel.dayFocus.remove(focus)
            } else if viewModel.dayFocus.count < maxSelections {
                viewModel.dayFocus.insert(focus)
            }
        }
    }
}

// MARK: - Focus Button
struct FocusButtonV2: View {
    let focus: MorningCheckIn.DayFocus
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            onToggle()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
        }) {
            VStack(spacing: 8) {
                Image(systemName: focus.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .white.opacity(isDisabled ? 0.3 : 0.5))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(isDisabled ? 0.03 : 0.05))
                    )
                
                Text(focus.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .white.opacity(isDisabled ? 0.3 : 0.7))
            }
            .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}