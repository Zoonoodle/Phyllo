//
//  OnboardingPreview.swift
//  NutriSync
//
//  Preview container for NutriSync onboarding screens
//

import SwiftUI

struct OnboardingPreview: View {
    @State private var selectedScreen = 0
    
    let screens = [
        // Section Intros & Full Flow (at the beginning for easy access)
        ("Full Onboarding", AnyView(NutriSyncOnboardingCoordinator())),
        ("Section Nav", AnyView(SectionIntroView(
            section: NutriSyncOnboardingSection.basics,
            completedSections: [],
            onContinue: {}
        ))),
        
        // Basics (5 screens)
        ("1. Basic Info", AnyView(BasicInfoView())),
        ("2. Weight", AnyView(WeightView())),
        ("3. Exercise", AnyView(ExerciseFrequencyView())),
        ("4. Activity", AnyView(ActivityLevelView())),
        ("5. Expenditure", AnyView(ExpenditureView())),
        
        // Notice (2 screens)
        ("6. Health Disclaimer", AnyView(HealthDisclaimerView())),
        ("7. Not to Worry", AnyView(NotToWorryView())),
        
        // Goal Setting (5 screens)
        ("8. Goal Intro", AnyView(GoalSettingIntroView())),
        ("9. Goal Selection", AnyView(GoalSelectionView())),
        ("10. Target Weight", AnyView(TargetWeightView())),
        ("11. Weight Loss Rate", AnyView(WeightLossRateView())),
        ("12. Workout Nutrition", AnyView(WorkoutNutritionView())),
        
        // Program (10 screens)
        ("13. Almost There", AnyView(AlmostThereView())),
        ("14. Diet Preference", AnyView(DietPreferenceView())),
        ("15. Training Plan", AnyView(TrainingPlanView())),
        ("16. Calorie Floor", AnyView(CalorieFloorView())),
        ("17. Sleep Schedule", AnyView(SleepScheduleView())),
        ("18. Meal Frequency", AnyView(MealFrequencyView())),
        ("19. Eating Window", AnyView(EatingWindowView())),
        ("20. Dietary Restrictions", AnyView(DietaryRestrictionsView())),
        ("21. Meal Timing", AnyView(MealTimingPreferenceView())),
        ("22. Window Flexibility", AnyView(WindowFlexibilityView())),
        
        // Finish (1 screen)
        ("23. Review Program", AnyView(ReviewProgramView()))
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

struct OnboardingPreview_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPreview()
    }
}
