SwiftCompile normal arm64 /Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/SleepScheduleView.swift (in target 'NutriSync' from project 'NutriSync')
    cd /Users/brennenprice/Documents/Phyllo
    

/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/SleepScheduleView.swift:27:17: error: cannot find 'MFNavigationHeader' in scope
                MFNavigationHeader(
                ^~~~~~~~~~~~~~~~~~
/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/SleepScheduleView.swift:114:17: error: cannot find 'MFPrimaryButton' in scope
                MFPrimaryButton(title: "Continue") {
                ^~~~~~~~~~~~~~~
# NutriSync Onboarding Conversion Plan
## MacroFactor → NutriSync Implementation Guide

Last Updated: 2025-08-29

---

## 📋 Executive Summary

Convert existing MacroFactor onboarding screens to NutriSync-specific flow while:
- **Preserving 100% of UI/design code** (1:1 aesthetic match)
- **Renaming all MF references** to NutriSync/generic names
- **Adding 7 new screens** for window generation data
- **Maintaining disconnected architecture** until user auth implementation

---

## 🎯 Implementation Goals

1. **Preserve Aesthetic**: Keep ALL UI components, styles, animations unchanged
2. **Update Branding**: Replace MacroFactor with NutriSync throughout
3. **Collect Window Data**: Add screens for missing window generation requirements
4. **Maintain Architecture**: Keep coordinator pattern and section organization
5. **Stay Disconnected**: No backend integration in this phase

---

## 📂 Phase 1: File Structure Renaming

### Folder Rename
```bash
NutriSync/Views/Onboarding/MacroFactorOnboarding/ 
→ 
NutriSync/Views/Onboarding/Onboarding/
```

### File Renames (27 files total)
```
# Coordinator & Data
MFOnboardingCoordinator.swift → OnboardingCoordinator.swift
MFOnboardingViewModel.swift → OnboardingViewModel.swift
MFOnboardingSectionData.swift → OnboardingSectionData.swift

# Section Views
MFSectionNavigationView.swift → SectionNavigationView.swift
MFSharedComponents.swift → SharedComponents.swift
MFOnboardingPreview.swift → OnboardingPreview.swift

# Basics Section (6 files)
MFBasicInfoView.swift → BasicInfoView.swift
MFWeightView.swift → WeightView.swift
MFBodyFatLevelView.swift → BodyFatLevelView.swift
MFExerciseFrequencyView.swift → ExerciseFrequencyView.swift
MFActivityLevelView.swift → ActivityLevelView.swift
MFExpenditureView.swift → ExpenditureView.swift

# Notice Section (2 files)
MFHealthDisclaimerView.swift → HealthDisclaimerView.swift
MFNotToWorryView.swift → NotToWorryView.swift

# Goal Setting Section (4 files)
MFGoalSettingIntroView.swift → GoalSettingIntroView.swift
MFGoalSelectionView.swift → GoalSelectionView.swift
MFTargetWeightView.swift → TargetWeightView.swift
MFWeightLossRateView.swift → WeightLossRateView.swift

# Program Section (9 files)
MFAlmostThereView.swift → AlmostThereView.swift
MFDietPreferenceView.swift → DietPreferenceView.swift
MFTrainingPlanView.swift → TrainingPlanView.swift
MFCalorieFloorView.swift → CalorieFloorView.swift
MFCalorieDistributionView.swift → CalorieDistributionView.swift
MFSleepScheduleView.swift → SleepScheduleView.swift
MFMealFrequencyView.swift → MealFrequencyView.swift
MFBreakfastHabitView.swift → BreakfastHabitView.swift
MFEatingWindowView.swift → EatingWindowView.swift

# Finish Section (1 file)
MFReviewProgramView.swift → ReviewProgramView.swift
```

---

## 📝 Phase 2: Text Content Updates

### Global Find & Replace
```
"MacroFactor" → "NutriSync"
"macro tracking" → "window timing optimization"
"calorie targets" → "optimal eating windows"
"macro coach" → "nutrition timing coach"
"adherence neutral" → "adaptively flexible"
```

### Screen-Specific Text Updates

#### HealthDisclaimerView
```swift
// OLD
"MacroFactor can help you reach your physique and performance goals"

// NEW
"NutriSync optimizes your meal timing to align with your body's natural rhythms and goals"
```

#### GoalSettingIntroView
```swift
// OLD
"MacroFactor's targets are designed to help you reach your goals"

// NEW
"NutriSync's personalized windows are designed to optimize your nutrition timing"
```

#### NotToWorryView
```swift
// OLD
"MacroFactor adjusts your program based on your progress"

// NEW
"NutriSync adapts your eating windows based on your lifestyle and progress"
```

#### AlmostThereView
```swift
// OLD
"Let's set up your nutrition program"

// NEW
"Let's optimize your meal timing windows"
```

#### ReviewProgramView
```swift
// OLD
"Your MacroFactor program is ready"

// NEW
"Your personalized eating schedule is ready"
```

---

## 🆕 Phase 3: New Screen Additions

### Section 3: Goal Setting (Add 2 screens)

#### 1. WorkoutScheduleView (New)
```swift
struct WorkoutScheduleView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Header (same style as other screens)
            OnboardingHeader(
                title: "Workout Schedule",
                subtitle: "When do you typically exercise?"
            )
            
            // Day selection grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(DayOfWeek.allCases) { day in
                    DayToggleButton(
                        day: day,
                        isSelected: viewModel.workoutDays.contains(day)
                    )
                }
            }
            
            // Time selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Typical workout time")
                    .font(.headline)
                
                DatePicker("", 
                    selection: $viewModel.workoutTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
            }
            
            Spacer()
            
            // Navigation (same as other screens)
            OnboardingNavigation(
                canProceed: !viewModel.workoutDays.isEmpty,
                onNext: { /* navigate */ },
                onBack: { /* navigate */ }
            )
        }
    }
}
```

#### 2. WorkoutNutritionView (New)
```swift
struct WorkoutNutritionView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Workout Nutrition",
                subtitle: "How do you fuel your training?"
            )
            
            // Pre-workout preference
            OptionCard(
                title: "Pre-workout meal",
                options: ["2-3 hours before", "1 hour before", "Fasted training"],
                selection: $viewModel.preworkoutTiming
            )
            
            // Post-workout preference
            OptionCard(
                title: "Post-workout priority",
                options: ["Immediate refuel", "Within 2 hours", "No preference"],
                selection: $viewModel.postworkoutTiming
            )
            
            Spacer()
            
            OnboardingNavigation(...)
        }
    }
}
```

### Section 4: Program (Add 5 screens)

#### 3. LifestyleFactorsView (New)
```swift
struct LifestyleFactorsView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Your Lifestyle",
                subtitle: "Help us adapt to your schedule"
            )
            
            // Work schedule
            OptionCard(
                title: "Work schedule",
                options: ["9-5 office", "Shift work", "Remote/flexible", "Student"],
                selection: $viewModel.workSchedule
            )
            
            // Social meals
            Slider(
                title: "Weekly social meals",
                value: $viewModel.socialMealsPerWeek,
                range: 0...7
            )
            
            // Travel frequency
            OptionCard(
                title: "Travel frequency",
                options: ["Rarely", "Monthly", "Weekly", "Constantly"],
                selection: $viewModel.travelFrequency
            )
            
            Spacer()
            OnboardingNavigation(...)
        }
    }
}
```

#### 4. NutritionPreferencesView (New)
```swift
struct NutritionPreferencesView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Nutrition Preferences",
                subtitle: "Any dietary considerations?"
            )
            
            // Dietary restrictions
            MultiSelectList(
                title: "Dietary restrictions",
                options: ["Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Keto", "None"],
                selections: $viewModel.dietaryRestrictions
            )
            
            // Food sensitivities
            TextField("Food sensitivities (optional)", 
                text: $viewModel.foodSensitivities
            )
            .textFieldStyle(OnboardingTextFieldStyle())
            
            // Macro preference
            OptionCard(
                title: "Macro focus",
                options: ["Balanced", "Higher protein", "Higher carbs", "Higher fats"],
                selection: $viewModel.macroPreference
            )
            
            Spacer()
            OnboardingNavigation(...)
        }
    }
}
```

#### 5. CircadianOptimizationView (New)
```swift
struct CircadianOptimizationView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Energy Patterns",
                subtitle: "When do you feel most energized?"
            )
            
            // Energy peaks
            OptionCard(
                title: "Peak energy time",
                options: ["Early morning", "Mid-morning", "Afternoon", "Evening"],
                selection: $viewModel.energyPeak
            )
            
            // Caffeine sensitivity
            OptionCard(
                title: "Caffeine sensitivity",
                options: ["Very sensitive", "Moderate", "Low sensitivity", "No caffeine"],
                selection: $viewModel.caffeineSensitivity
            )
            
            // Digestion preference
            OptionCard(
                title: "Prefer larger meals",
                options: ["Morning", "Midday", "Evening", "No preference"],
                selection: $viewModel.largerMealPreference
            )
            
            Spacer()
            OnboardingNavigation(...)
        }
    }
}
```

#### 6. WindowFlexibilityView (New)
```swift
struct WindowFlexibilityView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Schedule Flexibility",
                subtitle: "How adaptive should your windows be?"
            )
            
            // Flexibility level
            SegmentedControl(
                title: "Window flexibility",
                options: ["Strict timing", "Moderate flex", "Very flexible"],
                selection: $viewModel.flexibilityLevel
            )
            
            // Auto-adjustment
            Toggle("Auto-adjust for missed windows", 
                isOn: $viewModel.autoAdjustWindows
            )
            .toggleStyle(OnboardingToggleStyle())
            
            // Weekend differences
            Toggle("Different schedule on weekends", 
                isOn: $viewModel.weekendDifferent
            )
            .toggleStyle(OnboardingToggleStyle())
            
            Spacer()
            OnboardingNavigation(...)
        }
    }
}
```

#### 7. NotificationPreferencesView (New)
```swift
struct NotificationPreferencesView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "Window Reminders",
                subtitle: "How should we notify you?"
            )
            
            // Window start notifications
            Toggle("Window opening reminders", 
                isOn: $viewModel.windowStartNotifications
            )
            
            // Window closing warnings
            Toggle("Window closing warnings", 
                isOn: $viewModel.windowEndNotifications
            )
            
            // Check-in reminders
            Toggle("Daily check-in reminders", 
                isOn: $viewModel.checkInReminders
            )
            
            // Notification timing
            if viewModel.windowStartNotifications {
                Stepper("Notify \(viewModel.notificationMinutesBefore) min before",
                    value: $viewModel.notificationMinutesBefore,
                    in: 5...60,
                    step: 5
                )
            }
            
            Spacer()
            OnboardingNavigation(...)
        }
    }
}
```

---

## 🔄 Phase 4: Update Navigation Flow

### OnboardingCoordinator Updates
```swift
// Add new screens to section data
enum OnboardingScreen: CaseIterable {
    // Existing screens...
    
    // New screens (insert in appropriate sections)
    case workoutSchedule      // After targetWeight
    case workoutNutrition     // After workoutSchedule
    case lifestyleFactors     // After eatingWindow
    case nutritionPreferences // After lifestyleFactors
    case circadianOptimization // After nutritionPreferences
    case windowFlexibility    // After circadianOptimization
    case notificationPreferences // After windowFlexibility
}

// Update total step count
let totalSteps = 31 // Was 24, now 31 with 7 new screens

// Update progress calculation
var currentProgress: Double {
    Double(currentStepIndex) / Double(31)
}
```

### ViewModel Data Updates
```swift
// Add new properties to OnboardingViewModel
@Observable class OnboardingViewModel {
    // Existing properties...
    
    // Workout data
    var workoutDays: Set<DayOfWeek> = []
    var workoutTime: Date = Date()
    var preworkoutTiming: String = ""
    var postworkoutTiming: String = ""
    
    // Lifestyle data
    var workSchedule: String = ""
    var socialMealsPerWeek: Double = 2
    var travelFrequency: String = ""
    
    // Nutrition preferences
    var dietaryRestrictions: Set<String> = []
    var foodSensitivities: String = ""
    var macroPreference: String = ""
    
    // Circadian data
    var energyPeak: String = ""
    var caffeineSensitivity: String = ""
    var largerMealPreference: String = ""
    
    // Window preferences
    var flexibilityLevel: String = ""
    var autoAdjustWindows: Bool = true
    var weekendDifferent: Bool = false
    
    // Notifications
    var windowStartNotifications: Bool = true
    var windowEndNotifications: Bool = true
    var checkInReminders: Bool = true
    var notificationMinutesBefore: Int = 15
}
```

---

## 🎨 Phase 5: Component Updates

### Shared Components (Keep Same Style)
```swift
// Components to reuse for new screens:
// - OnboardingHeader (title + subtitle)
// - OnboardingNavigation (back/next buttons)
// - OptionCard (single selection)
// - MultiSelectList (multiple selection)
// - OnboardingSlider (value selection)
// - OnboardingToggle (boolean options)
// - OnboardingTextFieldStyle (text input)
// - ProgressBar (step indicator)
```

### Color Updates (Already Done)
```swift
// Already using NutriSync colors:
.nutriSyncBackground
.nutriSyncAccent
.nutriSyncCard
// No changes needed
```

---

## ✅ Phase 6: Testing & Validation

### Compilation Test
```bash
# Test each renamed file
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Onboarding/Onboarding/*.swift
```

### Manual Testing Checklist
- [ ] All 31 screens navigate correctly
- [ ] Back navigation works from any screen
- [ ] Progress bar updates accurately
- [ ] Data persists during session
- [ ] All text references updated
- [ ] New screens match aesthetic
- [ ] No MF references remain

### Search & Verify
```bash
# Ensure no MacroFactor references remain
rg "MacroFactor" NutriSync/Views/Onboarding/ --type swift
rg "MF" NutriSync/Views/Onboarding/ --type swift  # Should only find in old comments
```

---

## 📊 Implementation Time Estimate

### Phase Breakdown
1. **File Renaming**: 30 minutes
2. **Text Updates**: 45 minutes  
3. **New Screen Creation**: 2-3 hours
4. **Navigation Updates**: 30 minutes
5. **Testing & Debugging**: 1 hour
6. **Final Review**: 30 minutes

**Total Estimate**: 5-6 hours

---

## 🚦 Success Criteria

1. ✅ All MF references removed
2. ✅ All files renamed (no MF prefix)
3. ✅ 7 new screens added with same aesthetic
4. ✅ Collects all data for window generation
5. ✅ Maintains exact UI/design quality
6. ✅ No backend integration (stays disconnected)
7. ✅ Compiles without errors
8. ✅ Manual testing passes

---

## 🔮 Future Considerations (Not This Phase)

1. **User Auth Integration**: Connect after auth implementation
2. **Firebase Persistence**: Save onboarding data
3. **Window Generation**: Call service after completion
4. **Progress Restoration**: Resume incomplete onboarding
5. **Skip Options**: Allow partial completion
6. **A/B Testing**: Track completion rates

---

## 📝 Notes for Implementation

- **DO NOT DELETE** any UI code - only modify text
- **PRESERVE** all animations and transitions
- **MAINTAIN** component consistency across new screens
- **USE** existing shared components for new screens
- **TEST** after each major change
- **COMMIT** frequently with clear messages

---

**Ready for Implementation Phase 3**
Start new session with: `@plan-onboarding-conversion.md @research-onboarding-conversion.md`
