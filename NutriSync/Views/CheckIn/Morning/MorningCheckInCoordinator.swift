//
//  MorningCheckInCoordinator.swift
//  NutriSync
//
//  Main coordinator for morning check-in flow using onboarding patterns
//

import SwiftUI

struct MorningCheckInCoordinator: View {
    @State private var viewModel = MorningCheckInViewModel()
    @Environment(\.dismiss) private var dismiss
    let isMandatory: Bool
    
    init(isMandatory: Bool = false) {
        self.isMandatory = isMandatory
        // Update total steps to include all screens
        viewModel.totalSteps = 7
    }
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button at top right - only show if not mandatory
                if !isMandatory {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                } else {
                    // Spacer for mandatory check-in to maintain layout
                    Color.clear
                        .frame(height: 56)
                }
                
                // Current screen based on step
                currentScreenView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .onAppear {
            // Set the correct total steps
            viewModel.totalSteps = 7
        }
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            // If we've moved past the last step, dismiss
            if newValue > 6 {
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private func currentScreenView() -> some View {
        switch viewModel.currentStep {
        case 0: 
            WakeTimeSelectionViewV2(viewModel: viewModel)
        case 1: 
            SleepQualityViewV2(viewModel: viewModel)
        case 2: 
            EnergyLevelViewV2(viewModel: viewModel)
        case 3: 
            HungerLevelViewV2(viewModel: viewModel)
        case 4:
            DayFocusViewV2(viewModel: viewModel)
        case 5:
            ActivitiesViewV2(viewModel: viewModel)
        case 6: 
            PlannedBedtimeViewV2(viewModel: viewModel)
        default: 
            EmptyView()
        }
    }
}

#Preview {
    MorningCheckInCoordinator()
        .preferredColorScheme(.dark)
}