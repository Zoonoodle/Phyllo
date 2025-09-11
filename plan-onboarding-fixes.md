# NutriSync/Phyllo Onboarding Fixes - Implementation Plan

## Overview
This plan addresses 19 identified issues in the onboarding flow, incorporating user preferences from the planning phase discussion.

## User-Approved Design Decisions

1. **Progress Header**: Section-based with dashes and icons: `[basics icon] - - - - - [next section icon]`
2. **Body Fat Visuals**: Remove body fat screen entirely from the app
3. **TDEE Calculation**: Mifflin-St Jeor equation with activity multiplier + manual adjustment
4. **Weight Goal Icons**: Enhanced SF Symbols with backgrounds
5. **Workout Nutrition**: Split into Pre-workout screen → Post-workout screen
6. **Navigation Pattern**: Bottom navigation with back/next buttons
7. **Screens to Remove**: 9 total (including Workout Schedule and Body Fat Level)

## Implementation Phases

### PHASE A: Screen Removal & Flow Simplification (Priority 1)
**Goal**: Reduce onboarding from 31 to ~19 screens

#### A1. Remove 9 Screens
- [ ] Remove CalorieDistributionView.swift
- [ ] Remove BreakfastHabitView.swift  
- [ ] Remove LifestyleFactorsView.swift
- [ ] Remove NutritionPreferencesView.swift
- [ ] Remove EnergyPatternsView.swift
- [ ] Remove NotificationPreferencesView.swift (Window Reminders)
- [ ] Remove WorkoutScheduleView.swift (NEW - added to removal list)
- [ ] Remove BodyFatLevelView.swift (NEW - remove entirely)
- [ ] Remove MissedWindowNudge.swift and related popup system

#### A2. Update Navigation Flow
- [ ] Update OnboardingSectionData.swift to remove deleted screens
- [ ] Recalculate step counts (from 31 → ~19 steps)
- [ ] Update section definitions in NutriSyncOnboardingSection enum
- [ ] Fix navigation indices for remaining screens

#### A3. Clean Up Data Model
- [ ] Remove unused coordinator properties for deleted screens
- [ ] Update Firebase OnboardingProgress model
- [ ] Remove unnecessary data collection fields

### PHASE B: Fix Broken Functionality (Priority 2)
**Goal**: Make all interactive elements actually work

#### B1. Implement TDEE Calculation
```swift
// Mifflin-St Jeor Implementation
struct TDEECalculator {
    static func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        switch gender {
        case .male:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }
    
    static func applyActivityMultiplier(bmr: Double, activityLevel: ActivityLevel) -> Double {
        let multipliers: [ActivityLevel: Double] = [
            .sedentary: 1.2,
            .lightlyActive: 1.375,
            .moderatelyActive: 1.55,
            .veryActive: 1.725,
            .extremelyActive: 1.9
        ]
        return bmr * (multipliers[activityLevel] ?? 1.2)
    }
}
```

- [ ] Create TDEECalculator utility
- [ ] Add activity level selection in ExpenditureView
- [ ] Implement +/- manual adjustment buttons when user selects "No"
- [ ] Display calculated value instead of hardcoded 1805

#### B2. Fix Weight Loss Rate Slider
- [ ] Make slider interactive with real drag gesture
- [ ] Calculate actual weight loss projections based on position
- [ ] Update display values dynamically (lbs/week and lbs/month)
- [ ] Add haptic feedback on value changes

#### B3. Fix Target Weight Slider
- [ ] Simplify drag gesture (remove damping factor)
- [ ] Add sub-header text: "Drag to select your goal weight"
- [ ] Improve ruler sensitivity
- [ ] Add unit switching (lbs/kg)
- [ ] Fix snapping to whole numbers

#### B4. Split Workout Nutrition Screen
- [ ] Create PreWorkoutNutritionView.swift
- [ ] Create PostWorkoutNutritionView.swift
- [ ] Update navigation flow to include both screens
- [ ] Move relevant options to each screen

### PHASE C: Visual & UX Improvements (Priority 3)
**Goal**: Consistent, polished user experience

#### C1. Implement New Progress Header
```swift
struct SectionProgressHeader: View {
    let currentSection: NutriSyncOnboardingSection
    let nextSection: NutriSyncOnboardingSection?
    let progress: Double // 0.0 to 1.0 within section
    
    var body: some View {
        HStack(spacing: 8) {
            // Current section icon
            Image(systemName: currentSection.icon)
                .foregroundColor(.white)
            
            // Progress dashes
            ProgressDashes(progress: progress)
                .frame(height: 2)
            
            // Next section icon (grayed if exists)
            if let next = nextSection {
                Image(systemName: next.icon)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal)
    }
}
```

- [ ] Create new SectionProgressHeader component
- [ ] Replace all NavigationHeader instances
- [ ] Add section icons to NutriSyncOnboardingSection enum
- [ ] Implement dash-based progress indicator

#### C2. Enhance Weight Goal Icons
- [ ] Create icon backgrounds with gradients
- [ ] Use better SF Symbols:
  - Lose: "arrow.down.circle.fill" with red gradient
  - Maintain: "equal.circle.fill" with blue gradient  
  - Gain: "arrow.up.circle.fill" with green gradient
- [ ] Add subtle animations on selection

#### C3. Standardize Bottom Navigation
```swift
struct OnboardingBottomNav: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let canGoNext: Bool
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button(action: onNext) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(canGoNext ? .nutriSyncAccent : .white.opacity(0.3))
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
```

- [ ] Create standardized OnboardingBottomNav component
- [ ] Replace all custom navigation implementations
- [ ] Ensure consistent positioning and styling
- [ ] Add validation for "Next" button state

#### C4. Fix Layout Issues
- [ ] Fix "How many meals" horizontal skewing - center align
- [ ] Fix "When do you prefer to eat" vertical spacing
- [ ] Standardize padding across all screens
- [ ] Fix Start Journey screen theme consistency

#### C5. Apply Consistent Theme
- [ ] Use nutriSyncBackground consistently
- [ ] Replace all .white.opacity() with theme colors
- [ ] Standardize button styles with PrimaryButton component
- [ ] Apply consistent corner radius (16px)

## Testing Requirements

### After Each Phase
1. **Compilation Test**: `swiftc -parse` all modified files
2. **Navigation Test**: Complete flow start to finish
3. **Data Persistence**: Verify Firebase saves correctly
4. **Visual Review**: Screenshot each screen for comparison

### Edge Cases to Test
- [ ] Skip/back navigation through removed screens
- [ ] TDEE calculation with extreme values
- [ ] Weight slider at min/max bounds
- [ ] Screen rotation handling
- [ ] Dark mode consistency

## Success Criteria

### Metrics
- Onboarding completion time: < 5 minutes
- Screen count: 19-22 (down from 31)
- All sliders/inputs functional
- Zero navigation dead-ends
- Consistent visual theme throughout

### Validation Checkpoints
1. ✅ All 8 screens successfully removed
2. ✅ TDEE calculates correctly with manual adjustment
3. ✅ Weight loss rate slider fully interactive
4. ✅ Target weight drag works smoothly
5. ✅ Progress header shows section icons with dashes
6. ✅ Bottom navigation consistent across all screens
7. ✅ No Firebase errors on completion

## File Modification List

### Files to Delete (9)
1. CalorieDistributionView.swift
2. BreakfastHabitView.swift
3. LifestyleFactorsView.swift
4. NutritionPreferencesView.swift
5. EnergyPatternsView.swift
6. NotificationPreferencesView.swift
7. WorkoutScheduleView.swift
8. BodyFatLevelView.swift
9. MissedWindowNudge.swift

### Files to Create (4)
1. SectionProgressHeader.swift
2. OnboardingBottomNav.swift
3. PreWorkoutNutritionView.swift
4. PostWorkoutNutritionView.swift

### Files to Modify (14+)
1. OnboardingSectionData.swift - Remove deleted screens
2. OnboardingCoordinator.swift - Update navigation logic
3. ExpenditureView.swift - Add TDEE calculation
4. WeightLossRateView.swift - Make slider functional
5. TargetWeightView.swift - Fix drag and add sub-header
6. GoalSelectionView.swift - Enhanced icons
7. WorkoutNutritionView.swift - Split into two files
8. MealFrequencyView.swift - Fix horizontal layout
9. MealTimingPreferenceView.swift - Fix vertical spacing
10. AlmostThereView.swift - Theme consistency
11. SleepScheduleView.swift - Fix navigation pattern
12. SharedComponents.swift - Add new components
13. NudgeManager.swift - Remove missed window logic
14. All remaining screens - Apply new nav components

## Estimated Timeline

### Phase A: 2-3 hours
- Screen removal: 1 hour
- Flow updates: 1 hour  
- Testing: 30 min

### Phase B: 3-4 hours
- TDEE calculator: 1 hour
- Fix sliders: 1.5 hours
- Split workout screen: 1 hour
- Testing: 30 min

### Phase C: 3-4 hours
- New header component: 1 hour
- Navigation standardization: 1 hour
- Visual fixes: 1.5 hours
- Testing: 30 min

**Total: 8-11 hours of implementation**

## Next Steps

1. Start NEW Claude session for Phase 3: Implementation
2. Attach this plan + research document
3. Begin with Phase A (screen removal)
4. Test after each phase completion
5. Document any issues encountered

---

**Ready for Implementation Phase** - Please start a new session with:
- `@plan-onboarding-fixes.md` (this file)
- `@research-onboarding-issues.md` (research document)
- Begin executing Phase A