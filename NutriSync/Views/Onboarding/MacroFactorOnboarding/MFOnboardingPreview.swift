//
//  MFOnboardingPreview.swift
//  NutriSync
//
//  Preview container for all MacroFactor screens
//

import SwiftUI

struct MFOnboardingPreview: View {
    @State private var selectedScreen = 0
    
    let screens = [
        // Basics
        ("Weight", AnyView(MFWeightView())),
        ("Body Fat", AnyView(MFBodyFatLevelView())),
        ("Exercise", AnyView(MFExerciseFrequencyView())),
        ("Activity", AnyView(MFActivityLevelView())),
        ("Expenditure", AnyView(MFExpenditureView())),
        
        // Notice
        ("Health Disclaimer", AnyView(MFHealthDisclaimerView())),
        ("Not to Worry", AnyView(MFNotToWorryView())),
        
        // Goal Setting
        ("Goal Intro", AnyView(MFGoalSettingIntroView())),
        ("Goal Selection", AnyView(MFGoalSelectionView())),
        ("Target Weight", AnyView(MFTargetWeightView())),
        ("Weight Loss Rate", AnyView(MFWeightLossRateView())),
        
        // Program
        ("Almost There", AnyView(MFAlmostThereView())),
        ("Diet Preference", AnyView(MFDietPreferenceView())),
        ("Training Plan", AnyView(MFTrainingPlanView())),
        ("Calorie Floor", AnyView(MFCalorieFloorView())),
        ("Calorie Distribution", AnyView(MFCalorieDistributionView())),
        
        // Meal Timing (New)
        ("Sleep Schedule", AnyView(MFSleepScheduleView())),
        ("Meal Frequency", AnyView(MFMealFrequencyView())),
        ("Breakfast Habit", AnyView(MFBreakfastHabitView())),
        ("Eating Window", AnyView(MFEatingWindowView())),
        
        // Finish
        ("Review Program", AnyView(MFReviewProgramView())),
        
        // Section Intros
        ("Section Nav", AnyView(MFSectionIntroView(
            section: .basics,
            completedSections: [],
            onContinue: {}
        ))),
        
        // Full Flow
        ("Full Onboarding", AnyView(MFOnboardingCoordinator()))
    ]
    
    var body: some View {
        ZStack {
            // Background color that extends to all edges
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Screen selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<screens.count, id: \.self) { index in
                            Button {
                                withAnimation {
                                    selectedScreen = index
                                }
                            } label: {
                                Text(screens[index].0)
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedScreen == index ? 
                                        Color.white : 
                                        Color.white.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedScreen == index ? 
                                        Color.nutriSyncBackground : 
                                        .white
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(Color.nutriSyncBackground)
                
                // Screen content
                TabView(selection: $selectedScreen) {
                    ForEach(0..<screens.count, id: \.self) { index in
                        screens[index].1
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.nutriSyncBackground)
            }
        }
    }
}

struct MFOnboardingPreview_Previews: PreviewProvider {
    static var previews: some View {
        MFOnboardingPreview()
    }
}