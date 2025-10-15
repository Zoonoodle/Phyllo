# Implementation Plan: Goal-Specific Macro Calculation System
## Phase 2: Planning

**Created**: 2025-10-15
**Priority**: FIRST PRIORITY
**Estimated Complexity**: HIGH (Multiple systems affected)

---

## 📊 Executive Summary

### Problem Statement
- **3 different locations** calculating macros with inconsistent logic
- Protein targets differ between onboarding (0.8g/lb weight loss) vs service (1.0g/lb)
- Fat percentages are one-size-fits-all (28% for everything)
- Carbs are just "remainder" with no goal-specific optimization
- No window-specific macro distribution guidance
- `MacroConfiguration` presets exist but are completely unused

### Solution Overview
1. **Create `MacroCalculationService`** as single source of truth
2. **Implement goal-specific macro profiles** (percentage-based)
3. **Add NEW onboarding screen** for macro ratio customization
4. **Enhance AI prompt** with window-specific distribution guidance
5. **Refactor all existing code** to use centralized service
6. **Audit and integrate/delete** unused `MacroConfiguration` presets

### User Experience Enhancement
- User sees **recommended macro ratio** based on goal
- User can **customize ratio** if they prefer (e.g., low-carb preference)
- System validates ratios add up to 100%
- Windows distribute macros intelligently based on purpose

---

## 🎯 Design Decisions (Confirmed)

✅ **1A**: Create `MacroCalculationService` as single source of truth
✅ **2A**: AI-driven window distribution with detailed prompt guidance
✅ **3**: Weight loss protein = 1.0-1.2g/lb (research-backed)
✅ **4**: Percentage-based with user customization screen in onboarding
✅ **5**: First priority implementation
✅ **6**: Audit and fix all unused `MacroConfiguration` presets

---

## 📁 Files to Create

### New Files
1. `NutriSync/Services/MacroCalculationService.swift` (NEW)
   - Single source of truth for all macro calculations
   - Goal-specific profiles
   - Validation logic
   - Window distribution recommendations

2. `NutriSync/Views/Onboarding/NutriSyncOnboarding/MacroCustomizationView.swift` (NEW)
   - Interactive macro ratio customization
   - Real-time preview of grams based on calories
   - Validation UI (must add to 100%)
   - Preset buttons for common ratios

3. `NutriSync/Models/MacroProfile.swift` (NEW)
   - Data models for macro profiles
   - Codable for persistence
   - Validation methods

---

## 📝 Files to Modify

### High Impact (Core Logic)
1. `NutriSync/Services/GoalCalculationService.swift`
   - Remove `calculateMacros()` method (lines 279-318)
   - Delegate to `MacroCalculationService` instead
   - Keep TDEE/BMR calculation logic (still needed)

2. `NutriSync/ViewModels/OnboardingCompletionViewModel.swift`
   - Remove `calculateMacros()` method (lines 295-325)
   - Use `MacroCalculationService` instead
   - Update to use user's customized macro profile

3. `NutriSync/Services/AI/AIWindowGenerationService.swift`
   - Enhance prompt with window-specific macro distribution (line ~786+)
   - Add structured guidance for each window purpose
   - Pass macro profile to prompt builder

4. `NutriSync/Models/UserGoals.swift`
   - **AUDIT**: Decide fate of `MacroConfiguration` (lines 239-266)
   - Either integrate with new service OR delete if redundant
   - Add `customMacroProfile` to `UserGoals` struct

5. `NutriSync/Models/UserProfile.swift` (likely exists)
   - Add `macroProfile: MacroProfile?` property
   - Store user's customized macro preferences

6. `NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`
   - Add new macro customization step
   - Insert after goal/activity selection, before summary
   - Pass data to completion flow

### Medium Impact (UI Integration)
7. `NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`
   - Add macro customization section definition

8. `NutriSync/Views/Onboarding/NutriSyncOnboarding/ReviewProgramView.swift`
   - Display user's chosen macro ratios in review
   - Show both percentages and estimated grams

### Low Impact (Cleanup)
9. `NutriSync/Services/FirstDayWindowService.swift`
   - Update to use `MacroCalculationService` if needed
   - Check lines that reference macro calculation

---

## 🔧 Implementation Steps (Detailed)

### **STEP 1: Create MacroCalculationService (Foundation)**
**Estimated Time**: 1 hour
**Files**: Create `MacroCalculationService.swift`

**Actions**:
1. Create new file in `Services/` directory
2. Define `MacroProfile` struct with:
   ```swift
   struct MacroProfile {
       let proteinPercentage: Double  // 0.0 - 1.0
       let carbPercentage: Double
       let fatPercentage: Double
       let goal: UserGoals.Goal
       let isCustomized: Bool

       func calculateGrams(calories: Int) -> (protein: Int, carbs: Int, fat: Int)
       func validate() -> Bool  // Ensures adds to 100%
   }
   ```

3. Define goal-specific presets:
   ```swift
   static let profiles: [UserGoals.Goal: MacroProfile] = [
       .loseWeight: MacroProfile(protein: 0.35, carbs: 0.30, fat: 0.35),
       .buildMuscle: MacroProfile(protein: 0.30, carbs: 0.45, fat: 0.25),
       .improvePerformance: MacroProfile(protein: 0.25, carbs: 0.50, fat: 0.25),
       .betterSleep: MacroProfile(protein: 0.30, carbs: 0.35, fat: 0.35),
       .overallHealth: MacroProfile(protein: 0.30, carbs: 0.40, fat: 0.30),
       .maintainWeight: MacroProfile(protein: 0.30, carbs: 0.40, fat: 0.30)
   ]
   ```

4. Add window-specific distribution recommendations:
   ```swift
   static let windowDistributions: [WindowPurpose: (protein: Double, carbs: Double, fat: Double)] = [
       .preWorkout: (0.20, 0.60, 0.20),
       .postWorkout: (0.40, 0.45, 0.15),
       .metabolicBoost: (0.30, 0.40, 0.30),
       .sustainedEnergy: (0.25, 0.45, 0.30),
       .sleepOptimization: (0.30, 0.25, 0.45),
       .focusBoost: (0.30, 0.40, 0.30),
       .recovery: (0.35, 0.40, 0.25)
   ]
   ```

5. Add validation methods:
   ```swift
   static func validate(profile: MacroProfile) -> Result<Void, MacroValidationError>
   ```

**Test**:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Services/MacroCalculationService.swift
```

**Commit**: `feat: add MacroCalculationService as single source of truth`

---

### **STEP 2: Create MacroCustomizationView (UI)**
**Estimated Time**: 2 hours
**Files**: Create `MacroCustomizationView.swift`

**Actions**:
1. Create SwiftUI view with three sliders:
   - Protein slider (15% - 50%)
   - Carbs slider (15% - 60%)
   - Fat slider (15% - 50%)

2. Real-time validation:
   - Display warning if doesn't add to 100%
   - Auto-adjust third slider if user changes two

3. Show recommended preset:
   ```swift
   let recommended = MacroCalculationService.profiles[coordinator.selectedGoal]
   ```

4. Display gram calculations:
   ```swift
   // Based on their calculated calorie target
   "Protein: \(Int(calories * proteinPercent / 4))g per day"
   ```

5. Add preset buttons:
   - "Recommended" (goal-based)
   - "High Protein" (40/30/30)
   - "Low Carb" (35/25/40)
   - "Balanced" (30/40/30)

6. Visual design:
   - Match existing onboarding aesthetic
   - Use `.nutriSyncAccent` for active selections
   - Add educational tooltips

**Design Reference**:
```
┌─────────────────────────────────────┐
│  Customize Your Macro Split         │
│                                     │
│  Recommended for Weight Loss:       │
│  🟢 35% Protein  30% Carbs  35% Fat │
│                                     │
│  ━━━━━━●━━━━━ Protein: 35%         │
│  Daily: 175g                        │
│                                     │
│  ━━●━━━━━━━━━ Carbs: 30%           │
│  Daily: 150g                        │
│                                     │
│  ━━━━━━●━━━━━ Fat: 35%             │
│  Daily: 78g                         │
│                                     │
│  Total: 100% ✓                      │
│                                     │
│  [Recommended] [High Protein]       │
│  [Low Carb]    [Balanced]           │
│                                     │
│  💡 Tip: Higher protein helps...    │
└─────────────────────────────────────┘
```

**Test**: Xcode simulator manual testing

**Commit**: `feat: add macro customization screen to onboarding`

---

### **STEP 3: Integrate Macro Customization into Onboarding Flow**
**Estimated Time**: 1 hour
**Files**:
- `OnboardingCoordinator.swift`
- `OnboardingSectionData.swift`
- `NutriSyncOnboardingViewModel.swift`

**Actions**:
1. Add `macroProfile: MacroProfile?` to coordinator state
2. Add new section in `OnboardingSectionData`:
   ```swift
   Section(
       title: "Macro Split",
       emoji: "🎯",
       screens: [.macroCustomization],
       isRequired: true
   )
   ```

3. Insert AFTER "Goals & Activity" section, BEFORE "Sleep Schedule"
4. Pass data through coordinator:
   ```swift
   func saveMacroProfile(_ profile: MacroProfile) {
       self.macroProfile = profile
   }
   ```

5. Update `ReviewProgramView` to display chosen macros:
   ```swift
   HStack {
       Text("Your Macro Split")
       Spacer()
       Text("\(profile.proteinPercentage)P / \(profile.carbPercentage)C / \(profile.fatPercentage)F")
   }
   ```

**Test**:
- Navigate through onboarding
- Verify macro screen appears in correct order
- Confirm data persists to review screen

**Commit**: `feat: integrate macro customization into onboarding flow`

---

### **STEP 4: Update UserProfile and UserGoals Models**
**Estimated Time**: 30 minutes
**Files**:
- `UserProfile.swift`
- `UserGoals.swift`

**Actions**:
1. Add to `UserProfile`:
   ```swift
   var macroProfile: MacroProfile?
   ```

2. Add Firestore serialization:
   ```swift
   func toFirestore() -> [String: Any] {
       // ... existing fields
       if let profile = macroProfile {
           data["macroProfile"] = [
               "proteinPercentage": profile.proteinPercentage,
               "carbPercentage": profile.carbPercentage,
               "fatPercentage": profile.fatPercentage,
               "isCustomized": profile.isCustomized
           ]
       }
   }
   ```

3. **AUDIT `MacroConfiguration`** (lines 239-266):
   ```swift
   // DECISION: Delete or integrate?
   // Current unused presets:
   // - balanced, highProtein, lowCarb, athleteTraining

   // Option A: Delete (redundant with MacroCalculationService)
   // Option B: Migrate to MacroCalculationService presets
   ```

   **My Recommendation**: **DELETE** `MacroConfiguration` struct
   - Completely redundant with new `MacroProfile`
   - Never used in codebase
   - Will confuse future developers
   - New system is more comprehensive

4. Update `UserGoals` struct (remove unused code):
   ```swift
   // REMOVE: Lines 239-266 (MacroConfiguration)
   // REASON: Replaced by MacroCalculationService
   ```

**Test**:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Models/UserProfile.swift \
  NutriSync/Models/UserGoals.swift
```

**Commit**: `refactor: add macroProfile to UserProfile, remove unused MacroConfiguration`

---

### **STEP 5: Refactor GoalCalculationService**
**Estimated Time**: 45 minutes
**Files**: `GoalCalculationService.swift`

**Actions**:
1. Remove `calculateMacros()` method (lines 279-318)
2. Keep TDEE/BMR calculation (still needed)
3. Update `NutritionTargets` struct:
   ```swift
   struct NutritionTargets {
       let dailyCalories: Int
       let macroProfile: MacroProfile  // NEW: Use this instead
       let deficit: Int?
       let surplus: Int?
       let weeklyWeightChange: Double

       // Computed properties for backward compatibility
       var protein: Int {
           macroProfile.calculateGrams(calories: dailyCalories).protein
       }
       var carbs: Int {
           macroProfile.calculateGrams(calories: dailyCalories).carbs
       }
       var fat: Int {
           macroProfile.calculateGrams(calories: dailyCalories).fat
       }
   }
   ```

4. Update methods to use `MacroCalculationService`:
   ```swift
   private func calculateWeightGoalTargets(...) -> NutritionTargets {
       let tdee = calculateTDEE(...)
       let dailyCalories = Int(tdee) + dailyCalorieAdjustment

       // NEW: Get macro profile from service
       let macroProfile = MacroCalculationService.profiles[goalType] ?? .balanced

       return NutritionTargets(
           dailyCalories: dailyCalories,
           macroProfile: macroProfile,  // Use profile instead of individual values
           deficit: ...,
           surplus: ...,
           weeklyWeightChange: ...
       )
   }
   ```

5. Remove all standalone macro calculation logic

**Test**:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Services/GoalCalculationService.swift
```

**Commit**: `refactor: delegate macro calculations to MacroCalculationService`

---

### **STEP 6: Refactor OnboardingCompletionViewModel**
**Estimated Time**: 30 minutes
**Files**: `OnboardingCompletionViewModel.swift`

**Actions**:
1. Remove `calculateMacros()` method (lines 295-325)
2. Update to use coordinator's `macroProfile`:
   ```swift
   private func generateMacroTargets(_ coordinator: NutriSyncOnboardingViewModel) async -> OnboardingMacroTargets {
       let calories = calculateDailyCalories(coordinator)

       // Use user's chosen macro profile
       let profile = coordinator.macroProfile ?? MacroCalculationService.profiles[coordinator.selectedGoal]!
       let macros = profile.calculateGrams(calories: calories)

       return OnboardingMacroTargets(
           calories: calories,
           protein: macros.protein,
           carbs: macros.carbs,
           fat: macros.fat
       )
   }
   ```

3. Update window creation to use profile:
   ```swift
   // Use profile to calculate per-window macros
   let dailyMacros = coordinator.macroProfile.calculateGrams(calories: totalCalories)
   let perWindowProtein = dailyMacros.protein / mealCount
   // etc.
   ```

**Test**:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/ViewModels/OnboardingCompletionViewModel.swift
```

**Commit**: `refactor: use MacroCalculationService in onboarding completion`

---

### **STEP 7: Enhance AI Window Generation Prompt**
**Estimated Time**: 1 hour
**Files**: `AIWindowGenerationService.swift`

**Actions**:
1. Add window-specific macro guidance to prompt (around line 786):
   ```swift
   prompt += """

   ## CRITICAL: Window-Specific Macro Distribution
   Each window's macros should align with its purpose. Use these distributions:

   ### Pre-Workout Windows
   - Protein: 20% of window calories
   - Carbs: 60% of window calories (HIGH for fuel)
   - Fat: 20% of window calories (LOW to avoid digestion issues)
   - Example: 400 cal window = 20g protein, 60g carbs, 9g fat

   ### Post-Workout Windows
   - Protein: 40% of window calories (HIGH for recovery)
   - Carbs: 45% of window calories (replenish glycogen)
   - Fat: 15% of window calories
   - Example: 600 cal window = 60g protein, 68g carbs, 10g fat

   ### Metabolic Boost Windows (Morning)
   - Protein: 30% of window calories
   - Carbs: 40% of window calories
   - Fat: 30% of window calories (balanced)
   - Example: 500 cal window = 38g protein, 50g carbs, 17g fat

   ### Sustained Energy Windows (Midday)
   - Protein: 25% of window calories
   - Carbs: 45% of window calories
   - Fat: 30% of window calories
   - Example: 600 cal window = 38g protein, 68g carbs, 20g fat

   ### Sleep Optimization Windows (Evening)
   - Protein: 30% of window calories
   - Carbs: 25% of window calories (LOW to avoid insulin spikes)
   - Fat: 45% of window calories (HIGH for satiety)
   - Example: 400 cal window = 30g protein, 25g carbs, 20g fat

   ### Focus Boost Windows
   - Protein: 30% of window calories
   - Carbs: 40% of window calories
   - Fat: 30% of window calories
   - Example: 400 cal window = 30g protein, 40g carbs, 13g fat

   ### Recovery Windows
   - Protein: 35% of window calories (HIGH)
   - Carbs: 40% of window calories
   - Fat: 25% of window calories
   - Example: 500 cal window = 44g protein, 50g carbs, 14g fat

   IMPORTANT: These window distributions may differ from daily targets.
   The DAILY TOTAL across all windows must match:
   - Daily Protein Target: \(profile.dailyProteinTarget)g
   - Daily Carb Target: \(profile.dailyCarbTarget)g
   - Daily Fat Target: \(profile.dailyFatTarget)g

   Balance window-specific needs with daily totals.
   """
   ```

2. Pass user's macro profile to prompt builder:
   ```swift
   func generateWindows(...) async throws -> ... {
       // Get user's macro profile
       let macroProfile = profile.macroProfile ?? MacroCalculationService.profiles[profile.primaryGoal]!

       let prompt = buildPrompt(
           profile: profile,
           macroProfile: macroProfile,  // NEW parameter
           checkIn: checkIn,
           ...
       )
   }
   ```

3. Include profile in prompt:
   ```swift
   prompt += """
   ## User's Chosen Macro Profile
   - Protein: \(Int(macroProfile.proteinPercentage * 100))%
   - Carbs: \(Int(macroProfile.carbPercentage * 100))%
   - Fat: \(Int(macroProfile.fatPercentage * 100))%
   \(macroProfile.isCustomized ? "- ⚠️ USER CUSTOMIZED - Must respect their preferences" : "- System recommended")
   """
   ```

**Test**:
- Generate windows manually in Xcode
- Verify AI respects window-specific distributions
- Check daily totals match user's profile

**Commit**: `feat: add window-specific macro distribution to AI prompt`

---

### **STEP 8: Update FirstDayWindowService (if needed)**
**Estimated Time**: 20 minutes
**Files**: `FirstDayWindowService.swift`

**Actions**:
1. Audit file for macro calculations
2. Update to use `MacroCalculationService` if needed
3. Ensure consistency with main window generation

**Test**:
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Services/FirstDayWindowService.swift
```

**Commit**: `refactor: ensure FirstDayWindowService uses MacroCalculationService`

---

### **STEP 9: Testing & Validation**
**Estimated Time**: 2 hours
**Files**: Manual testing in Xcode

**Test Cases**:

#### Test Case 1: Weight Loss Goal
1. Complete onboarding, select "Weight Loss"
2. Verify recommended macro ratio: 35% protein, 30% carbs, 35% fat
3. Accept recommended ratios
4. Generate windows
5. Verify:
   - Daily totals match profile
   - Morning windows have balanced macros
   - Evening windows have lower carbs, higher fat
   - Total protein ≥ 1.0g/lb body weight

#### Test Case 2: Muscle Gain Goal
1. Complete onboarding, select "Build Muscle"
2. Verify recommended: 30% protein, 45% carbs, 25% fat
3. Accept recommended
4. Generate windows
5. Verify:
   - High carb windows for energy
   - Pre-workout window has 60% carbs
   - Post-workout has 40% protein
   - Daily carbs are 45% of total

#### Test Case 3: Custom Macro Ratios
1. Complete onboarding, select "Weight Loss"
2. **Customize** to 40% protein, 30% carbs, 30% fat
3. Verify validation (adds to 100%)
4. Save custom profile
5. Generate windows
6. Verify:
   - Windows respect 40% protein preference
   - Daily totals match custom profile
   - System acknowledges customization

#### Test Case 4: Performance Goal
1. Select "Improve Performance"
2. Verify: 25% protein, 50% carbs, 25% fat
3. Generate windows
4. Verify very high carb distribution

#### Test Case 5: Edge Cases
1. Try invalid ratios (doesn't add to 100%) → Should show error
2. Try extreme ratios (10% protein) → Should warn user
3. Change goal mid-onboarding → Should update recommended ratios
4. Skip macro customization → Should use recommended

#### Test Case 6: Existing Users (Migration)
1. User has existing profile without `macroProfile`
2. System should generate profile from goal
3. User should see recommended ratios
4. No data loss or crashes

**Success Criteria**:
- ✅ All test cases pass
- ✅ No compilation errors
- ✅ No runtime crashes
- ✅ UI matches design
- ✅ Macros always add to 100%
- ✅ Window distributions make nutritional sense

---

### **STEP 10: Code Review & Cleanup**
**Estimated Time**: 30 minutes

**Actions**:
1. Search for any remaining hardcoded macro calculations:
   ```bash
   rg "protein \* 4|carbs \* 4|fat \* 9" --type swift
   ```

2. Verify all files use `MacroCalculationService`:
   ```bash
   rg "MacroCalculationService" --type swift
   ```

3. Confirm `MacroConfiguration` deleted:
   ```bash
   rg "MacroConfiguration" --type swift
   ```

4. Run final compilation:
   ```bash
   swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
     -target arm64-apple-ios17.0 \
     NutriSync/Services/MacroCalculationService.swift \
     NutriSync/Services/GoalCalculationService.swift \
     NutriSync/ViewModels/OnboardingCompletionViewModel.swift \
     NutriSync/Views/Onboarding/NutriSyncOnboarding/MacroCustomizationView.swift
   ```

5. Commit and push:
   ```bash
   git add -A
   git commit -m "feat: implement goal-specific macro calculation system with user customization"
   git push origin main
   ```

**Commit**: `feat: complete goal-specific macro system implementation`

---

## 🎯 Success Criteria Checklist

### Functionality
- [ ] `MacroCalculationService` created with goal-specific profiles
- [ ] Macro customization screen integrated into onboarding
- [ ] User can customize macro ratios (percentages)
- [ ] System validates ratios add to 100%
- [ ] `GoalCalculationService` refactored to use service
- [ ] `OnboardingCompletionViewModel` refactored to use service
- [ ] AI prompt enhanced with window-specific distributions
- [ ] `MacroConfiguration` struct audited and removed
- [ ] All macro calculations centralized

### Testing
- [ ] Weight loss goal test passes (35/30/35 default)
- [ ] Muscle gain goal test passes (30/45/25 default)
- [ ] Performance goal test passes (25/50/25 default)
- [ ] Custom ratio test passes (user can modify)
- [ ] Validation test passes (rejects invalid ratios)
- [ ] Window distribution test passes (purpose-specific macros)
- [ ] Existing user migration test passes (no data loss)

### Code Quality
- [ ] No compilation errors
- [ ] No duplicate macro calculation logic
- [ ] All files follow Swift conventions
- [ ] Inline comments explain complex logic
- [ ] No unused code remains

### Documentation
- [ ] CLAUDE.md updated with new macro system
- [ ] Inline code comments added
- [ ] Complex calculations explained

---

## 🚨 Rollback Procedures

If implementation fails:

### Rollback Step 1: Identify Last Good Commit
```bash
git log --oneline | grep "feat: add MacroCalculationService"
```

### Rollback Step 2: Create Backup Branch
```bash
git branch backup-macro-implementation
git checkout backup-macro-implementation
```

### Rollback Step 3: Revert Changes
```bash
git revert <commit-hash>
```

### Rollback Step 4: Restore Original Files
```bash
git checkout HEAD~10 -- NutriSync/Services/GoalCalculationService.swift
git checkout HEAD~10 -- NutriSync/ViewModels/OnboardingCompletionViewModel.swift
```

### Rollback Step 5: Delete New Files
```bash
rm NutriSync/Services/MacroCalculationService.swift
rm NutriSync/Views/Onboarding/NutriSyncOnboarding/MacroCustomizationView.swift
```

### Rollback Step 6: Test Original System
```bash
swiftc -parse NutriSync/Services/GoalCalculationService.swift
```

---

## 📊 Estimated Timeline

| Step | Description | Time | Cumulative |
|------|-------------|------|------------|
| 1 | Create MacroCalculationService | 1h | 1h |
| 2 | Create MacroCustomizationView | 2h | 3h |
| 3 | Integrate into onboarding flow | 1h | 4h |
| 4 | Update models | 30m | 4.5h |
| 5 | Refactor GoalCalculationService | 45m | 5.25h |
| 6 | Refactor OnboardingCompletionViewModel | 30m | 5.75h |
| 7 | Enhance AI prompt | 1h | 6.75h |
| 8 | Update FirstDayWindowService | 20m | 7h |
| 9 | Testing & validation | 2h | 9h |
| 10 | Code review & cleanup | 30m | 9.5h |

**Total Estimated Time**: ~9.5 hours
**Recommended Sessions**: 2-3 sessions with context monitoring

---

## 🎬 Next Steps

1. **User approval of this plan**
2. **Start NEW session for Phase 3: Implementation**
3. **Attach this plan**: `@plan-goal-specific-macros.md`
4. **Implementation agent will**:
   - Create `TodoWrite` list from steps
   - Execute steps 1-10 systematically
   - Test after each major change
   - Monitor context usage (stop at 60%)
   - Create `progress-goal-specific-macros.md` if needed

---

## 📝 Notes for Implementation Agent

- **Priority**: FIRST PRIORITY - block other work if needed
- **Complexity**: HIGH - affects multiple systems
- **Testing**: Manual testing in Xcode required for UI
- **Context Risk**: HIGH - may need 2-3 sessions
- **Dependencies**: None - can start immediately

### Key Decisions Already Made
✅ Single source of truth (MacroCalculationService)
✅ Percentage-based ratios
✅ User customization screen in onboarding
✅ AI-driven window distribution
✅ Delete `MacroConfiguration` struct
✅ Weight loss protein = 1.0-1.2g/lb

### Critical Implementation Notes
- Always validate macros add to 100%
- Maintain backward compatibility for existing users
- Test each goal type individually
- Window distributions override daily ratios for purpose
- Daily totals must still match user's profile

---

**END OF PLAN - READY FOR PHASE 3 IMPLEMENTATION**
