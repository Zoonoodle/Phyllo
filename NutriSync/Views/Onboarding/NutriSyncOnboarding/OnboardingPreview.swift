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
        
        // Basics (6 screens)
        ("1. Basic Info", AnyView(BasicInfoView())),
        ("2. Weight", AnyView(WeightView())),
        ("3. Body Fat", AnyView(BodyFatLevelView())),
        ("4. Exercise", AnyView(ExerciseFrequencyView())),
        ("5. Activity", AnyView(ActivityLevelView())),
        ("6. Expenditure", AnyView(ExpenditureView())),
        
        // Notice (2 screens)
        ("7. Health Disclaimer", AnyView(HealthDisclaimerView())),
        ("8. Not to Worry", AnyView(NotToWorryView())),
        
        // Goal Setting (6 screens)
        ("9. Goal Intro", AnyView(GoalSettingIntroView())),
        ("10. Goal Selection", AnyView(GoalSelectionView())),
        ("11. Target Weight", AnyView(TargetWeightView())),
        ("12. Weight Loss Rate", AnyView(WeightLossRateView())),
        ("13. Workout Schedule", AnyView(WorkoutScheduleView())),
        ("14. Workout Nutrition", AnyView(WorkoutNutritionView())),
        
        // Program (16 screens)
        ("15. Almost There", AnyView(AlmostThereView())),
        ("16. Diet Preference", AnyView(DietPreferenceView())),
        ("17. Training Plan", AnyView(TrainingPlanView())),
        ("18. Calorie Floor", AnyView(CalorieFloorView())),
        ("19. Calorie Distribution", AnyView(CalorieDistributionView())),
        ("20. Sleep Schedule", AnyView(SleepScheduleView())),
        ("21. Meal Frequency", AnyView(MealFrequencyView())),
        ("22. Breakfast Habit", AnyView(BreakfastHabitView())),
        ("23. Eating Window", AnyView(EatingWindowView())),
        ("24. Lifestyle Factors", AnyView(LifestyleFactorsView())),
        ("25. Dietary Restrictions", AnyView(DietaryRestrictionsView())),
        ("26. Nutrition Preferences", AnyView(NutritionPreferencesView())),
        ("27. Energy Patterns", AnyView(EnergyPatternsView())),
        ("28. Meal Timing", AnyView(MealTimingPreferenceView())),
        ("29. Window Flexibility", AnyView(WindowFlexibilityView())),
        ("30. Notification Preferences", AnyView(NotificationPreferencesView())),
        
        // Finish (1 screen)
        ("31. Review Program", AnyView(ReviewProgramView()))
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
