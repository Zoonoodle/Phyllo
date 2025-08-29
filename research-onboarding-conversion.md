# NutriSync Research Documentation
## Onboarding Screens Conversion (MacroFactor → NutriSync)

Last Updated: 2025-08-29

---

## 🔍 Investigation Topic
Converting existing MacroFactorOnboarding screens to NutriSync-specific onboarding flow while maintaining aesthetic quality and ensuring all necessary data collection for window generation service.

### Key Questions
1. What MacroFactor-specific content needs to be replaced?
2. What additional data do we need for NutriSync's window generation?
3. How can we maintain the existing aesthetic while making it uniquely NutriSync?
4. What is the current implementation architecture and flow?
5. Are there any technical constraints or dependencies?

---

## 📊 Findings

### Pattern Analysis

#### Current Architecture
```
MFOnboardingCoordinator (Main Controller)
├── MFOnboardingViewModel (@Observable)
├── 5 Main Sections (Basics, Notice, Goal Setting, Program, Finish)
├── 25+ Individual Screen Views
├── Shared Components (Progress bars, buttons, headers)
└── Section Navigation System
```

#### File Structure
```
MacroFactorOnboarding/
├── Coordinator & Data Models (3 files)
├── Individual Screen Views (22 files)
├── Shared Components (1 file)
└── Preview Helper (1 file)
```

#### Screen Flow (14 Steps Total)
1. **Basics** → Basic Info → Weight → Body Fat → Exercise → Activity → Expenditure
2. **Notice** → Health Disclaimer → Not To Worry
3. **Goal Setting** → Intro → Goal Selection → Target Weight → Loss Rate
4. **Program** → Almost There → Diet → Training → Calories → Distribution → Sleep → Meals → Breakfast → Window
5. **Finish** → Review Program

### Technical Constraints
- **No Backend Integration**: Currently stores data only in memory during session
- **Hardcoded Progress**: 14-step progress bar hardcoded across all screens
- **No Data Persistence**: Data lost on app restart
- **Component Duplication**: MFProgressBar duplicated in multiple files
- **Missing NutriSync Features**: No window generation data collection

### Implementation Options

#### Option A: Minimal Conversion (Quick TestFlight)
**Pros:**
- Fast implementation (1-2 sessions)
- Low risk of breaking existing flow
- Ready for TestFlight quickly

**Cons:**
- Doesn't collect window generation data
- Still feels like MacroFactor
- Requires second pass later

**Files Affected:**
- 3 text update files (disclaimer, intro, review)
- Component consolidation files
- No architectural changes

#### Option B: Full NutriSync Integration (Recommended)
**Pros:**
- Collects all data for window generation
- Unique NutriSync identity
- Firebase integration ready
- One-time implementation

**Cons:**
- More complex (3-4 sessions)
- Requires careful planning
- Needs user design input

**Files Affected:**
- All 22 screen views (text/branding updates)
- Add 3-5 new screens for window preferences
- Firebase integration in coordinator
- Update shared components

#### Option C: Hybrid Approach
**Pros:**
- Quick branding updates first
- Gradual feature addition
- Lower risk

**Cons:**
- Multiple passes needed
- Inconsistent experience
- Technical debt

**Files Affected:**
- Phase 1: Text updates only
- Phase 2: New screens
- Phase 3: Backend integration

---

## 🧪 Experiments Run

### Test 1: Component Inventory
```bash
rg "MacroFactor" --type swift NutriSync/Views/Onboarding/
# Result: 3 direct references found
# - MFGoalSettingIntroView.swift: Line 74
# - MFHealthDisclaimerView.swift: Line 69
# - All file headers contain "MacroFactor Replica"
```

### Test 2: Color Theme Usage
```bash
rg "nutriSync" --type swift NutriSync/Views/Onboarding/
# Result: Already using NutriSync colors
# - nutriSyncBackground
# - nutriSyncAccent
# Theme partially converted
```

### Test 3: Data Collection Analysis
```swift
// Current data collected:
struct CollectedData {
    // Physical: weight, bodyFat, activity
    // Goals: targetWeight, lossRate
    // Preferences: diet, training, meals
    // Schedule: wake, sleep, eating window
    
    // MISSING for NutriSync:
    // - Workout schedule/timing
    // - Specific meal preferences
    // - Circadian rhythm data
    // - Social eating patterns
    // - Stress/recovery needs
}
```

---

## 📚 Data Requirements for NutriSync Window Generation

### Currently Collected (Keep)
- Weight, body fat, activity level ✓
- Goals (lose/maintain/gain) ✓
- Sleep schedule ✓
- Meal frequency ✓
- Eating window preferences ✓

### Need to Add for Window Generation
1. **Workout Schedule**
   - Days of week
   - Typical workout times
   - Pre/post workout nutrition needs

2. **Lifestyle Factors**
   - Work schedule (9-5, shifts, etc.)
   - Social meal commitments
   - Travel frequency

3. **Nutrition Preferences**
   - Specific dietary restrictions
   - Macro preferences
   - Food sensitivities

4. **Circadian Optimization**
   - Natural energy peaks
   - Caffeine sensitivity
   - Digestion preferences

5. **Window Generation Preferences**
   - Flexibility level (strict vs adaptive)
   - Auto-adjustment preferences
   - Notification settings

---

## 📐 Required Text/Branding Changes

### High Priority (MacroFactor → NutriSync)
1. **MFHealthDisclaimerView**: Complete disclaimer rewrite
2. **MFGoalSettingIntroView**: Update "MacroFactor's targets" text
3. **File Headers**: Remove "MacroFactor Replica" comments
4. **App Name References**: Any remaining "MacroFactor" → "NutriSync"

### Medium Priority (Enhancement)
1. **Section Descriptions**: Emphasize window timing benefits
2. **Progress Messages**: Add NutriSync-specific encouragement
3. **Review Screen**: Show personalized window preview

### Low Priority (Polish)
1. **Animations**: Add NutriSync personality
2. **Icons**: Consider custom icons
3. **Transitions**: Smoother section changes

---

## ✅ Validation Checklist

- [x] Patterns consistent across codebase? Yes - coordinator pattern well implemented
- [x] Performance implications understood? Minimal - UI only changes
- [x] Edge cases identified? Missing data persistence, no error handling
- [x] Dependencies available? All SwiftUI native, no external deps
- [x] Backwards compatibility maintained? N/A - new feature

---

## 🎯 Recommendation

**Recommended Approach:** Option B - Full NutriSync Integration

**Rationale:**
1. TestFlight needs complete experience for meaningful feedback
2. Window generation is core differentiator - needs proper data
3. One-time implementation avoids technical debt
4. Current architecture supports extension well

**Implementation Strategy:**
1. **Phase 1**: Update all text/branding (quick wins)
2. **Phase 2**: Add 3-5 new screens for window-specific data
3. **Phase 3**: Integrate with Firebase for persistence
4. **Phase 4**: Add preview of generated windows

**Next Step:** 
→ Create `plan-onboarding-conversion.md` with detailed implementation steps

---

## 🔄 Additional Research Findings

### Component Reusability
- `MFProgressBar` can be extracted to shared component
- Button styles already consistent via `MFPrimaryButton`
- Navigation header pattern reusable across app

### Firebase Integration Points
```swift
// Suggested integration in MFOnboardingCoordinator
func completeOnboarding() {
    // Save to Firebase
    FirebaseDataProvider.shared.saveOnboardingData(viewModel.userData)
    // Generate initial windows
    WindowGenerationService.shared.generateInitialWindows(userData)
    // Navigate to main app
}
```

### Missing Error Handling
- No validation on numeric inputs
- No network error handling
- No recovery from failed saves
- Should add before TestFlight

### Accessibility Gaps
- Missing VoiceOver labels
- No dynamic type support
- Color contrast needs verification
- Important for App Store approval

---

## 🚨 Risk Assessment

### Technical Risks
1. **Data Loss**: No persistence means users lose progress
   - Mitigation: Add Firebase immediately
   
2. **Navigation Bugs**: Complex state management
   - Mitigation: Thorough testing of back/forward

3. **Performance**: 25+ screens in memory
   - Mitigation: Lazy loading, proper cleanup

### User Experience Risks
1. **Too Long**: 25+ screens might cause drop-off
   - Mitigation: Consider condensing to 15-20

2. **Confusing Flow**: Section transitions unclear
   - Mitigation: Better progress indicators

3. **No Skip Option**: Forces full completion
   - Mitigation: Add "Complete Later" option

---

*Research completed. Ready for planning phase with user input on design decisions.*