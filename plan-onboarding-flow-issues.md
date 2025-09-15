# Onboarding Flow Issues - Implementation Plan

## User-Approved Design Decisions

1. **Goal Mapping**: Keep "Gain Weight" in UI, update mapping logic
2. **Maintain Weight Flow**: Show simplified "maintenance strategy" screen
3. **Rate Screen**: Make existing screen goal-aware with dynamic text/calculations
4. **Weight Slider**: Use combination approach (slider + text input)
5. **Priority**: Fix critical bugs first
6. **Testing**: Full manual testing of each flow path

## Implementation Steps (Priority Order)

### Phase 1: Critical Bug Fixes (High Priority)

#### Step 1: Fix Goal Selection Mapping
**File**: `OnboardingCoordinator.swift`
**Lines**: 302-315, 345-352

**Actions**:
1. Update switch statement in `buildUserProfile()` to handle "Gain Weight":
   ```swift
   case "gain weight": .buildMuscle(...)
   ```
2. Update `buildUserGoals()` method similarly
3. Add validation logging to confirm goal is correctly mapped
4. Test with swiftc -parse after changes

**Verification**:
- [ ] "Gain Weight" selection maps to `.buildMuscle`
- [ ] Goal persists correctly to OnboardingProgress
- [ ] UserProfile receives correct NutritionGoal

#### Step 2: Implement Conditional Navigation for Maintain Weight
**Files**: 
- `OnboardingCoordinator.swift` (lines 110-119)
- `OnboardingSectionData.swift` (lines 68-75)

**Actions**:
1. Modify `nextScreen()` method to check current goal:
   ```swift
   if currentScreen == "Goal Selection" && goal.lowercased() == "maintain weight" {
       // Skip to Maintenance Strategy screen
       currentScreenIndex = screenNames.firstIndex(of: "Maintenance Strategy") ?? currentScreenIndex + 1
   }
   ```
2. Add "Maintenance Strategy" to screen flow after "Goal Selection"
3. Skip "Target Weight" and "Weight Loss Rate" for maintain weight users
4. Test navigation flow with all three goals

**Verification**:
- [ ] Maintain weight users see Maintenance Strategy screen
- [ ] Lose/Gain weight users see Target Weight screen
- [ ] Navigation flows correctly for all paths

### Phase 2: New Screen Implementation

#### Step 3: Create Maintenance Strategy Screen
**New File**: `MaintenanceStrategyView.swift`
**Location**: `/NutriSync/Views/Onboarding/NutriSyncOnboarding/`

**Actions**:
1. Create new SwiftUI view with:
   - Title: "Maintenance Strategy"
   - Subtitle: "Let's optimize your eating schedule to maintain your current weight"
   - Options for maintenance focus:
     - Energy stability
     - Performance optimization
     - Better sleep quality
     - Overall health
2. Store selection in coordinator
3. Add to screen registry in `OnboardingCoordinator.swift`
4. Test compilation and UI rendering

**Verification**:
- [ ] Screen renders correctly
- [ ] Selection saves to coordinator
- [ ] Navigation continues properly

### Phase 3: UI Enhancements

#### Step 4: Fix Target Weight Screen with Combo Input
**File**: `TargetWeightView.swift`
**Lines**: 141-266 (WeightRulerSlider), add new text input

**Actions**:
1. Add `@State private var textInput: String = ""` 
2. Create TextField below slider:
   ```swift
   TextField("Enter weight", text: $textInput)
       .keyboardType(.decimalPad)
       .onChange(of: textInput) { updateSliderFromText() }
   ```
3. Sync slider and text input bidirectionally
4. Use coordinator.weight instead of hardcoded reference (lines 207-208)
5. Add visual indicator showing difference from current weight
6. Test input synchronization

**Verification**:
- [ ] Slider updates when typing
- [ ] Text updates when sliding
- [ ] Shows weight difference clearly
- [ ] Uses actual current weight

#### Step 5: Make Rate Selection Screen Goal-Aware
**File**: `WeightLossRateView.swift`
**All dynamic text and calculations**

**Actions**:
1. Rename file to `WeightChangeRateView.swift`
2. Update screen title based on goal:
   ```swift
   var title: String {
       switch coordinator.goal.lowercased() {
       case "lose weight": return "Weight Loss Rate"
       case "gain weight": return "Weight Gain Rate"
       default: return "Rate Selection"
       }
   }
   ```
3. Update subtitle dynamically (line 99)
4. Adjust calculations for weight gain (surplus instead of deficit)
5. Update display text to show positive values for gain
6. Adjust color scheme (green for healthy gain rate)
7. Update button text based on context

**Verification**:
- [ ] Correct title for each goal
- [ ] Proper calculations (deficit vs surplus)
- [ ] Visual indicators match goal type
- [ ] Text makes sense for context

### Phase 4: Data Flow Improvements

#### Step 6: Update OnboardingSectionData
**File**: `OnboardingSectionData.swift`
**Lines**: 68-75

**Actions**:
1. Create dynamic screen flow method:
   ```swift
   static func getGoalSettingScreens(for goal: String) -> [String] {
       var screens = ["Goal Intro", "Goal Selection"]
       
       switch goal.lowercased() {
       case "maintain weight":
           screens.append("Maintenance Strategy")
       case "lose weight", "gain weight":
           screens.append(contentsOf: ["Target Weight", "Weight Change Rate"])
       default:
           break
       }
       
       screens.append(contentsOf: ["Pre-Workout Nutrition", "Post-Workout Nutrition"])
       return screens
   }
   ```
2. Update coordinator to use dynamic flow
3. Test all navigation paths

**Verification**:
- [ ] Each goal shows correct screens
- [ ] No screens are skipped incorrectly
- [ ] Flow feels natural

### Phase 5: Testing & Validation

#### Step 7: Comprehensive Manual Testing
**Testing Checklist**:

1. **Goal Selection Path Testing**:
   - [ ] Select "Lose Weight" → Verify all screens shown
   - [ ] Select "Maintain Weight" → Verify maintenance strategy shown, no target/rate
   - [ ] Select "Gain Weight" → Verify all screens with gain-specific text

2. **Data Persistence Testing**:
   - [ ] Complete onboarding with each goal
   - [ ] Verify data saved to OnboardingProgress
   - [ ] Check UserProfile has correct values

3. **UI Component Testing**:
   - [ ] Target weight slider responds smoothly
   - [ ] Text input syncs with slider
   - [ ] Rate selection shows correct calculations
   - [ ] All text is contextually appropriate

4. **Edge Case Testing**:
   - [ ] Navigate backwards and forwards
   - [ ] Change goal mid-flow
   - [ ] Enter extreme weight values
   - [ ] Test with different units (kg/lbs)

5. **Compilation Testing**:
   ```bash
   swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
     -target arm64-apple-ios17.0 \
     GoalSelectionView.swift \
     TargetWeightView.swift \
     WeightChangeRateView.swift \
     MaintenanceStrategyView.swift \
     OnboardingCoordinator.swift \
     OnboardingSectionData.swift
   ```

## Success Criteria

### Functional Requirements
- ✅ All three goals ("Lose Weight", "Maintain Weight", "Gain Weight") work correctly
- ✅ Navigation flow adapts based on selected goal
- ✅ Target weight input works via both slider and text
- ✅ Rate selection adapts language and calculations for goal
- ✅ Data persists correctly to Firebase

### User Experience
- ✅ Clear, contextual language throughout
- ✅ Smooth transitions between screens
- ✅ No confusing or irrelevant screens shown
- ✅ Input methods are responsive and intuitive

### Technical Quality
- ✅ All files compile without errors
- ✅ No hardcoded values where dynamic data should be used
- ✅ Consistent code style with existing codebase
- ✅ No regression in other features

## Rollback Procedures

### If Issues Occur:
1. **Immediate Rollback**:
   ```bash
   git stash                    # Save current changes
   git checkout HEAD~1          # Revert to previous commit
   ```

2. **Partial Rollback** (if only one component fails):
   - Revert specific file changes
   - Keep working components
   - Document issue for next session

3. **Recovery Steps**:
   - Review error logs/compilation errors
   - Identify exact failure point
   - Create `recovery-onboarding-issues.md` with details
   - Start new session with recovery plan

## Estimated Time & Context Usage

### Per Step Estimates:
1. Goal mapping fix: 10-15% context
2. Conditional navigation: 15-20% context
3. Maintenance screen: 10-15% context
4. Target weight combo: 15-20% context
5. Goal-aware rate screen: 15-20% context
6. Data flow updates: 10% context
7. Testing: 10% context

**Total**: May require 2 implementation sessions if context exceeds 60%

## Next Actions

After this plan is approved:
1. Start new session for Phase 3: Implementation
2. Begin with Step 1 (critical goal mapping fix)
3. Test after each step with swiftc -parse
4. Create progress document if context reaches 60%
5. Continue until all steps complete

---

**PHASE 2: PLANNING COMPLETE**
Ready for implementation. Start NEW session for Phase 3.