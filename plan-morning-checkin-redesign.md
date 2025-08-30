# Plan: Morning Check-In Redesign - Gradual Migration Approach
*Phase 2: Implementation Plan*
*Created: 2025-08-30*

## User-Approved Design Decisions
- **Approach:** Gradual migration (Option B) - Screen-by-screen conversion
- **Components:** Fully replace with onboarding equivalents
- **Navigation:** Bottom right "Next", bottom left back arrow (matching onboarding exactly)
- **Visual Priority:** Consistent navigation > Progress bar > Headers > Section organization
- **Animations:** Simplify to match onboarding (remove custom animations)
- **Data Migration:** Immediate switch to Observable pattern for consistency
- **Testing:** Standard (compilation + manual UI testing)
- **Timeline:** Standard (3-4 days)
- **Cleanup:** Delete all unused components after replacement

---

## Implementation Strategy: Gradual Migration

### Overview
Convert the morning check-in flow screen-by-screen while maintaining a working app at each step. Each screen conversion will be atomic - fully replacing old with new, then deleting unused code.

### Migration Order (Based on Complexity)
1. **Step 1:** Create shared components and ViewModel
2. **Step 2:** Convert simple screens (WakeTime, PlannedBedtime)
3. **Step 3:** Convert slider screens (Sleep, Energy, Hunger)
4. **Step 4:** Convert complex screens (EnhancedActivities, DayFocus)
5. **Step 5:** Replace coordinator and cleanup

---

## Step-by-Step Implementation Plan

### Step 1: Foundation Components (Session 1 Start)
**Files to Create:**
```
/NutriSync/Views/CheckIn/Components/
├── OnboardingHeader.swift          # Standardized header from onboarding
├── OnboardingNavigation.swift      # Bottom nav with back/next
├── CheckInScreenTemplate.swift     # Template wrapper for all screens
└── MorningCheckInViewModel.swift   # Observable ViewModel
```

**Components to Import/Adapt from Onboarding:**
```swift
// From /NutriSync/Views/Onboarding/Components/
- ProgressBar.swift → Copy and adapt for check-in
```

**ViewModel Structure:**
```swift
@Observable
class MorningCheckInViewModel {
    // Navigation
    var currentStep: Int = 0
    var totalSteps: Int = 6
    
    // Data (replacing @State variables)
    var wakeTime: Date = Date()
    var plannedBedtime: Date = Date()
    var sleepQuality: Int = 5
    var energyLevel: Int = 5
    var hungerLevel: Int = 5
    var plannedActivities: [String] = []
    var windowPreference: MorningCheckIn.WindowPreference = .auto
    var hasRestrictions: Bool = false
    var restrictions: [String] = []
    
    // Navigation methods
    func nextStep() { currentStep += 1 }
    func previousStep() { currentStep -= 1 }
    func canGoNext() -> Bool { /* validation logic */ }
    func saveCheckIn() { /* CheckInManager integration */ }
}
```

**Test After Step 1:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  OnboardingHeader.swift OnboardingNavigation.swift \
  CheckInScreenTemplate.swift MorningCheckInViewModel.swift
```

---

### Step 2: Simple Screen Conversions (Session 1 Continue)

#### 2.1 WakeTimeSelectionView
**Current File:** `/NutriSync/Views/CheckIn/Morning/WakeTimeSelectionView.swift`

**Conversion Tasks:**
1. Create new `WakeTimeSelectionViewV2.swift` using template
2. Remove custom header/navigation
3. Use CheckInScreenTemplate wrapper
4. Connect to viewModel.wakeTime
5. Preserve time grid selection UI
6. Test compilation
7. Update MorningCheckInView to use V2
8. Delete original WakeTimeSelectionView.swift

**Components to Delete After:**
- Original WakeTimeSelectionView.swift
- Any wake-time specific animations

#### 2.2 PlannedBedtimeView
**Current File:** `/NutriSync/Views/CheckIn/Morning/PlannedBedtimeView.swift`

**Conversion Tasks:**
1. Create `PlannedBedtimeViewV2.swift`
2. Apply same template pattern
3. Connect to viewModel.plannedBedtime
4. Test and verify
5. Delete original file

**Test After Step 2:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  WakeTimeSelectionViewV2.swift PlannedBedtimeViewV2.swift \
  MorningCheckInViewModel.swift
```

---

### Step 3: Slider Screen Conversions (Session 2 Start)

#### 3.1 SleepQualityView
**Current File:** `/NutriSync/Views/CheckIn/Morning/SleepQualityView.swift`

**Conversion Tasks:**
1. Create `SleepQualityViewV2.swift`
2. Remove complex animation states
3. Use standard template transitions
4. Preserve slider functionality
5. **DELETE:** Moon phase visualizations (simplify per user request)
6. Connect to viewModel.sleepQuality

**Components to Delete:**
- SleepVisualizations.swift (moon phases)
- CoffeeSteamAnimation.swift (if only used here)
- Original SleepQualityView.swift

#### 3.2 EnergyLevelSelectionView
**Current File:** `/NutriSync/Views/CheckIn/Morning/EnergyLevelSelectionView.swift`

**Conversion Tasks:**
1. Create `EnergyLevelViewV2.swift`
2. Standardize with template
3. Simplify animations
4. Delete original

#### 3.3 HungerLevelSelectionView
**Current File:** `/NutriSync/Views/CheckIn/Morning/HungerLevelSelectionView.swift`

**Conversion Tasks:**
1. Create `HungerLevelViewV2.swift`
2. Apply template pattern
3. Delete original

**Components to Delete After Step 3:**
- CheckInSliderViews.swift (replace with simpler version)
- SleepHoursSlider.swift (if not used elsewhere)
- All three original slider views

**Test After Step 3:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  SleepQualityViewV2.swift EnergyLevelViewV2.swift \
  HungerLevelViewV2.swift MorningCheckInViewModel.swift
```

---

### Step 4: Complex Screen Conversions (Session 2/3)

#### 4.1 EnhancedActivitiesView
**Current File:** `/NutriSync/Views/CheckIn/Morning/EnhancedActivitiesView.swift`

**Major Refactoring Required:**
1. Create `ActivitiesViewV2.swift`
2. Split into manageable sections
3. Connect multiple data points to viewModel:
   - plannedActivities
   - windowPreference
   - hasRestrictions
   - restrictions
4. Simplify callback structure
5. Remove complex animations
6. Apply template wrapper

#### 4.2 DayFocusSelectionView
**Current File:** `/NutriSync/Views/CheckIn/Morning/DayFocusSelectionView.swift`

**Conversion Tasks:**
1. Create `DayFocusViewV2.swift`
2. Standardize selection UI
3. Apply template
4. Delete original

**Components to Delete After Step 4:**
- PlannedActivitiesView.swift (legacy version)
- Original EnhancedActivitiesView.swift
- Original DayFocusSelectionView.swift

---

### Step 5: Coordinator Replacement & Final Cleanup (Session 3/4)

#### 5.1 Create New Coordinator
**File:** `/NutriSync/Views/CheckIn/Morning/MorningCheckInCoordinator.swift`

```swift
struct MorningCheckInCoordinator: View {
    @State private var viewModel = MorningCheckInViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button at top right
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
                
                // Current screen based on step
                currentScreenView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
    
    @ViewBuilder
    private func currentScreenView() -> some View {
        switch viewModel.currentStep {
        case 0: WakeTimeSelectionViewV2(viewModel: viewModel)
        case 1: SleepQualityViewV2(viewModel: viewModel)
        case 2: EnergyLevelViewV2(viewModel: viewModel)
        case 3: HungerLevelViewV2(viewModel: viewModel)
        case 4: ActivitiesViewV2(viewModel: viewModel)
        case 5: PlannedBedtimeViewV2(viewModel: viewModel)
        default: EmptyView()
        }
    }
}
```

#### 5.2 Update Entry Points
1. Replace MorningCheckInView references with MorningCheckInCoordinator
2. Update FocusView.swift to use new coordinator
3. Test full flow end-to-end

#### 5.3 Final Cleanup
**Delete These Files:**
```
/NutriSync/Views/CheckIn/Morning/
├── MorningCheckInView.swift         # Old coordinator
├── CheckInButton.swift              # Replaced by OnboardingNavigation
├── CheckInProgressBar.swift         # Replaced by ProgressBar
├── All original screen files        # Already replaced with V2
└── Any unused animation files       # Simplified per requirement
```

---

## Test Cases & Success Criteria

### Compilation Tests (After Each Step)
```bash
# Step 1: Foundation
swiftc -parse [all new component files]

# Step 2-4: Each screen conversion
swiftc -parse [converted screen files + viewModel]

# Step 5: Full coordinator
swiftc -parse MorningCheckInCoordinator.swift [all V2 screens]
```

### Manual UI Testing Checklist
- [ ] Progress bar visible and updates correctly
- [ ] Back navigation works on all screens except first
- [ ] Next navigation validates input before proceeding
- [ ] Data persists when navigating back/forward
- [ ] CheckInManager receives correct data on completion
- [ ] Window generation triggers after check-in
- [ ] Visual consistency matches onboarding exactly

### Edge Cases to Verify
- [ ] First screen has no back button
- [ ] Last screen shows "Complete" instead of "Next"
- [ ] Validation prevents empty required fields
- [ ] Time selections handle midnight crossover
- [ ] Data saves to CheckInManager correctly

---

## Rollback Procedures

### If Issues Occur at Any Step:
1. **Immediate:** Revert the specific V2 file changes
2. **Keep original files** until V2 is verified working
3. **Test original flow** still functions
4. **Document issue** in progress file
5. **Adjust approach** if needed

### Git Strategy:
```bash
# Create checkpoint before each major step
git add -A && git commit -m "checkpoint: before [step name]"

# If rollback needed
git reset --hard HEAD~1  # Return to checkpoint
```

---

## Component Deletion Schedule

### After Step 1 Verification:
- None (foundation only)

### After Step 2 Verification:
- WakeTimeSelectionView.swift
- PlannedBedtimeView.swift

### After Step 3 Verification:
- SleepQualityView.swift
- EnergyLevelSelectionView.swift
- HungerLevelSelectionView.swift
- CheckInSliderViews.swift
- SleepHoursSlider.swift
- SleepVisualizations.swift
- CoffeeSteamAnimation.swift

### After Step 4 Verification:
- EnhancedActivitiesView.swift
- DayFocusSelectionView.swift
- PlannedActivitiesView.swift

### After Step 5 Verification:
- MorningCheckInView.swift
- CheckInButton.swift
- CheckInProgressBar.swift
- Any remaining unused check-in components

---

## Expected Timeline

### Day 1 (Session 1)
- **Morning:** Step 1 - Create foundation components
- **Afternoon:** Step 2 - Convert simple screens

### Day 2 (Session 2)
- **Morning:** Step 3 - Convert slider screens
- **Afternoon:** Step 4 (partial) - Begin complex screens

### Day 3 (Session 3)
- **Morning:** Step 4 (complete) - Finish complex screens
- **Afternoon:** Step 5 - Replace coordinator

### Day 4 (Session 4)
- **Morning:** Final testing and verification
- **Afternoon:** Cleanup and component deletion

---

## Context Management Notes

### Session Boundaries:
- **Session 1:** Steps 1-2 (foundation + simple screens)
- **Session 2:** Steps 3-4 (sliders + complex screens start)
- **Session 3:** Steps 4-5 (complex screens finish + coordinator)
- **Session 4:** Testing, cleanup, and deletion

### Progress Tracking:
- Create `progress-morning-checkin-redesign.md` when reaching 60% context
- Document exact file and line being worked on
- List completed conversions
- Note any issues or decisions made

---

## Final Notes

This gradual migration approach ensures:
1. **Working app at each step** - No breaking changes
2. **Clean codebase** - Delete unused code immediately after verification
3. **Visual consistency** - Exact match with onboarding patterns
4. **Maintainable architecture** - Observable pattern throughout
5. **Testable increments** - Verify each screen independently

The key is maintaining discipline about:
- Testing after EVERY change
- Deleting old code once new is verified
- Following the template pattern exactly
- Not adding unnecessary complexity

---

**PHASE 2: PLANNING COMPLETE**

Start a NEW session for Phase 3: Implementation. Provide this plan document along with the research document to begin the systematic conversion.