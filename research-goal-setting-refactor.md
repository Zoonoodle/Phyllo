# Goal Setting Refactor Research Document
**Date**: October 21, 2025
**Phase**: PHASE 1 - RESEARCH
**Task**: Replace Pre/Post-Workout Nutrition Screens with Goal-Oriented Screens
**Status**: Research Complete

---

## EXECUTIVE SUMMARY

### User Request
Replace the current pre-workout and post-workout nutrition timing screens with **goal-oriented screens** that collect specific user objectives:
- Gaining muscle
- Reducing energy crashes
- Improving sleep (not eating too close to bed)
- Other nutrition-related goals

### Critical Discovery
**The current pre/post-workout screens collect data but NEVER persist it to Firebase.** This makes replacement straightforward - we're not losing any functional data, only UI screens.

### Research Findings
1. ✅ Current pre/post workout screens: Lines 3157-3310+ in OnboardingContentViews.swift
2. ✅ Data is stored temporarily in coordinator but NEVER saved
3. ✅ Window generation already supports goal-based purposes (recovery, metabolic boost, sleep optimization)
4. ✅ UserGoals model has primaryGoal but no sub-goals or specific preferences
5. ✅ Firebase schema needs extension for specific goal preferences

---

## 1. CURRENT STATE ANALYSIS

### A. Existing Pre/Post-Workout Screens (TO BE REMOVED)

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Pre-Workout Nutrition Screen** (Lines 3157-3245):
```swift
PreWorkoutNutritionContentView
- Options: "30 minutes before", "1 hour before", "2 hours before", "No pre-workout meal"
- Stores in: coordinator.preworkoutTiming
- Default: "1 hour before"
```

**Post-Workout Nutrition Screen** (Lines 3247-3310+):
```swift
PostWorkoutNutritionContentView
- Options: "Within 30 minutes", "Within 1 hour", "Within 2 hours", "No specific timing"
- Stores in: coordinator.postworkoutTiming
```

**Coordinator Properties** (Lines 121-122):
```swift
var preworkoutTiming: String = ""
var postworkoutTiming: String = ""
```

**Section Structure** (OnboardingSectionData.swift, Lines 87-88):
```swift
.goalSetting: [
    "Your Transformation",
    "Goal Selection",
    "Trend Weight",
    "Weight Goal",
    "Goal Summary",
    "Pre-Workout Nutrition",    // ← REMOVE THIS
    "Post-Workout Nutrition"    // ← REMOVE THIS
]
```

**Navigation** (OnboardingCoordinator.swift, Lines 830-833):
```swift
case "Pre-Workout Nutrition":
    PreWorkoutNutritionContentView()
case "Post-Workout Nutrition":
    PostWorkoutNutritionContentView()
```

### B. Current Goal System

**Primary Goal Enum** (UserGoals.swift):
```swift
enum Goal: String, CaseIterable, Codable {
    case loseWeight = "Weight Loss"
    case buildMuscle = "Build Muscle"
    case maintainWeight = "Maintain Weight"
    case improvePerformance = "Performance"
    case betterSleep = "Better Sleep"
    case overallHealth = "Overall Health"
}
```

**Current UserGoals Model**:
```swift
struct UserGoals: Codable {
    var primaryGoal: Goal            // Single goal only
    var activityLevel: ActivityLevel
    var dailyCalories: Int?
    var dailyProtein: Int?
    var dailyCarbs: Int?
    var dailyFat: Int?
    var targetWeight: Double?
    var timeline: Int?

    // ❌ NO specific goal preferences
    // ❌ NO sub-goals
    // ❌ NO workout preferences
}
```

### C. Window Generation System

**Window Purposes Already Defined** (MealWindow.swift, Lines 138-146):
```swift
enum WindowPurpose: String, CaseIterable, Codable {
    case preWorkout = "pre-workout"
    case postWorkout = "post-workout"
    case sustainedEnergy = "sustained-energy"      // ← Energy crashes
    case recovery = "recovery"                      // ← Muscle gain
    case metabolicBoost = "metabolic-boost"
    case sleepOptimization = "sleep-optimization"  // ← Sleep goals
    case focusBoost = "focus-boost"
}
```

**Macro Distributions** (MacroCalculationService.swift, Lines 154-175):
```swift
static let windowDistributions: [WindowPurpose: (protein: Double, carbs: Double, fat: Double)] = [
    .preWorkout: (protein: 0.20, carbs: 0.60, fat: 0.20),
    .postWorkout: (protein: 0.40, carbs: 0.45, fat: 0.15),
    .sustainedEnergy: (protein: 0.25, carbs: 0.45, fat: 0.30),    // Balanced for energy
    .recovery: (protein: 0.35, carbs: 0.40, fat: 0.25),           // High protein for muscle
    .sleepOptimization: (protein: 0.30, carbs: 0.25, fat: 0.45),  // Lower carbs, early timing
]
```

---

## 2. PROPOSED GOAL-ORIENTED SCREENS

### A. Specific Goal Categories

Based on user request and existing window purposes:

1. **Muscle Gain & Recovery**
   - Focus: High protein timing
   - Window purposes: recovery, postWorkout
   - Macro profile: High protein (35-40%)

2. **Energy Management**
   - Focus: Steady energy, avoid crashes
   - Window purposes: sustainedEnergy, focusBoost
   - Macro profile: Balanced with emphasis on slow-digesting carbs

3. **Sleep Optimization**
   - Focus: Meal timing relative to bedtime
   - Window purposes: sleepOptimization
   - Constraints: No eating X hours before bed
   - Macro profile: Lower carbs, higher fat in evening

4. **Performance & Athletic Goals**
   - Focus: Workout fueling
   - Window purposes: preWorkout, postWorkout
   - Timing: Meal windows around training

5. **Metabolic Health**
   - Focus: Blood sugar stability, intermittent fasting
   - Window purposes: metabolicBoost
   - Pattern: Longer fasting windows

### B. Multi-Goal Selection Model

**Key Design Decision: Can users select MULTIPLE specific goals?**

**Option A: Single Specific Goal (Simpler)**
```swift
enum SpecificGoal: String, CaseIterable, Codable {
    case muscleGain = "Build Muscle & Recover Faster"
    case steadyEnergy = "Avoid Energy Crashes"
    case betterSleep = "Improve Sleep Quality"
    case athleticPerformance = "Optimize Workout Performance"
    case metabolicHealth = "Improve Metabolic Health"
}
```

**Option B: Multiple Goals (More Flexible, RECOMMENDED)**
```swift
struct SpecificGoals: Codable {
    var selectedGoals: Set<SpecificGoal>

    enum SpecificGoal: String, CaseIterable, Codable {
        case muscleGain = "Build Muscle & Recover Faster"
        case steadyEnergy = "Avoid Energy Crashes"
        case betterSleep = "Improve Sleep Quality"
        case athleticPerformance = "Optimize Workout Performance"
        case metabolicHealth = "Improve Metabolic Health"
    }

    // Helper computed properties
    var prioritizesMuscle: Bool { selectedGoals.contains(.muscleGain) }
    var needsSleepOptimization: Bool { selectedGoals.contains(.betterSleep) }
    var focusesOnEnergy: Bool { selectedGoals.contains(.steadyEnergy) }
}
```

**RECOMMENDATION**: Use Option B (multi-select) because:
- Users often have multiple goals (e.g., muscle gain AND better sleep)
- More data = better AI window generation
- Can prioritize based on goal combinations

### C. Goal-Specific Data Collection

For each goal type, we may need additional context:

**Sleep Optimization Goal**:
```swift
struct SleepOptimizationPreferences: Codable {
    var hoursBeforeBed: Int  // 2, 3, or 4 hours
    var typicalBedtime: Date
    var avoidLateCarbs: Bool
}
```

**Energy Management Goal**:
```swift
struct EnergyManagementPreferences: Codable {
    var crashTimes: [String]  // "Mid-morning", "Afternoon", "Evening"
    var preferredMealFrequency: Int  // 3, 4, 5, or 6 meals
}
```

**Muscle Gain Goal**:
```swift
struct MuscleGainPreferences: Codable {
    var proteinPriority: String  // "High", "Very High", "Maximum"
    var trainingDays: Int  // Days per week
    var trainingType: String  // "Strength", "Hypertrophy", "Powerlifting"
}
```

**Athletic Performance Goal**:
```swift
struct PerformancePreferences: Codable {
    var workoutTime: Date?  // When they typically train
    var workoutDuration: Int  // Minutes
    var preworkoutMeal: Bool
    var postworkoutMeal: Bool
}
```

---

## 3. DATA MODEL DESIGN

### A. Extended UserGoals Structure

**RECOMMENDED APPROACH**:
```swift
struct UserGoals: Codable {
    // Existing fields
    var primaryGoal: Goal
    var activityLevel: ActivityLevel
    var dailyCalories: Int?
    var dailyProteinTarget: Int?
    var dailyCarbTarget: Int?
    var dailyFatTarget: Int?
    var targetWeight: Double?
    var timeline: Int?

    // NEW: Specific goal preferences
    var specificGoals: Set<SpecificGoal>
    var sleepPreferences: SleepOptimizationPreferences?
    var energyPreferences: EnergyManagementPreferences?
    var musclePreferences: MuscleGainPreferences?
    var performancePreferences: PerformancePreferences?

    enum SpecificGoal: String, CaseIterable, Codable {
        case muscleGain = "Build Muscle & Recover"
        case steadyEnergy = "Steady Energy Levels"
        case betterSleep = "Better Sleep Quality"
        case athleticPerformance = "Athletic Performance"
        case metabolicHealth = "Metabolic Health"
    }
}
```

### B. Alternative: Separate Preferences Model

**Alternative Approach** (if UserGoals gets too large):
```swift
// Separate model for specific preferences
struct NutritionPreferences: Codable, Identifiable {
    let id: UUID
    var userId: String
    var selectedGoals: Set<SpecificGoal>
    var sleepOptimization: SleepPreferences?
    var energyManagement: EnergyPreferences?
    var muscleGain: MusclePreferences?
    var performance: PerformancePreferences?

    enum SpecificGoal: String, CaseIterable, Codable {
        case muscleGain = "muscleGain"
        case steadyEnergy = "steadyEnergy"
        case betterSleep = "betterSleep"
        case athleticPerformance = "athleticPerformance"
        case metabolicHealth = "metabolicHealth"
    }
}
```

### C. Coordinator Changes

**OnboardingCoordinator Updates**:
```swift
@Observable
class OnboardingCoordinator {
    // REMOVE these
    // var preworkoutTiming: String = ""
    // var postworkoutTiming: String = ""

    // ADD these
    var selectedSpecificGoals: Set<SpecificGoal> = []
    var sleepHoursBeforeBed: Int = 3
    var energyCrashTimes: [String] = []
    var muscleProteinPriority: String = "High"
    var workoutTime: Date?
}
```

---

## 4. FIREBASE SCHEMA DESIGN

### A. Extended Goals Collection

**Firestore Path**: `users/{userId}/goals/current`

```javascript
{
  // Existing fields
  primaryGoal: "Build Muscle",
  activityLevel: "Moderately Active",
  dailyCalories: 2400,
  dailyProtein: 180,
  dailyCarbs: 240,
  dailyFat: 80,
  targetWeight: 185,
  timeline: 12,

  // NEW: Specific goal preferences
  specificGoals: ["muscleGain", "betterSleep"],  // Array of selected goals

  // NEW: Goal-specific data (conditional based on selectedGoals)
  sleepPreferences: {
    hoursBeforeBed: 3,
    typicalBedtime: "2025-10-21T22:00:00Z",
    avoidLateCarbs: true
  },

  musclePreferences: {
    proteinPriority: "High",
    trainingDaysPerWeek: 5,
    trainingType: "Hypertrophy"
  },

  energyPreferences: {
    crashTimes: ["Afternoon"],
    preferredMealFrequency: 4
  },

  performancePreferences: {
    workoutTime: "2025-10-21T17:00:00Z",
    workoutDuration: 60,
    preworkoutMeal: true,
    postworkoutMeal: true
  }
}
```

### B. Alternative: Separate Collection

**If preferences grow complex**:

**Path**: `users/{userId}/nutritionPreferences/current`
```javascript
{
  id: "uuid",
  userId: "firebaseAuthId",
  selectedGoals: ["muscleGain", "betterSleep"],
  sleepOptimization: { ... },
  muscleGain: { ... },
  energyManagement: { ... },
  performance: { ... },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## 5. WINDOW GENERATION INTEGRATION

### A. How Specific Goals Influence Windows

**Goal → Window Purpose Mapping**:
```swift
extension SpecificGoal {
    var primaryWindowPurposes: [WindowPurpose] {
        switch self {
        case .muscleGain:
            return [.recovery, .postWorkout]
        case .steadyEnergy:
            return [.sustainedEnergy, .focusBoost]
        case .betterSleep:
            return [.sleepOptimization]
        case .athleticPerformance:
            return [.preWorkout, .postWorkout]
        case .metabolicHealth:
            return [.metabolicBoost]
        }
    }
}
```

### B. Window Timing Constraints

**Sleep Goal Example**:
```swift
// If user selected "betterSleep" with "3 hours before bed" preference
// Last meal window must end at: bedtime - 3 hours

if userGoals.specificGoals.contains(.betterSleep),
   let sleepPrefs = userGoals.sleepPreferences {
    let bedtime = sleepPrefs.typicalBedtime
    let latestMealEnd = bedtime.addingTimeInterval(-Double(sleepPrefs.hoursBeforeBed) * 3600)

    // Constrain window generation
    windowConstraints.latestEndTime = latestMealEnd
}
```

**Energy Goal Example**:
```swift
// If user selected "steadyEnergy" and crashes at "Afternoon"
// Schedule a sustained-energy window at 2-3 PM

if userGoals.specificGoals.contains(.steadyEnergy),
   let energyPrefs = userGoals.energyPreferences,
   energyPrefs.crashTimes.contains("Afternoon") {

    // Create window at crash time with sustained-energy purpose
    let afternoonWindow = MealWindow(
        startTime: 14:00,
        endTime: 15:00,
        purpose: .sustainedEnergy,
        macroDistribution: .balanced
    )
}
```

### C. AI Prompt Enhancement

**Current AI Window Generation** uses user goals but not specific preferences.

**Enhanced Prompt Structure**:
```swift
let enhancedPrompt = """
Generate daily meal windows for user with:

PRIMARY GOAL: \(userGoals.primaryGoal.rawValue)

SPECIFIC GOALS:
\(userGoals.specificGoals.map { $0.rawValue }.joined(separator: ", "))

CONSTRAINTS:
\(generateConstraintsText(from: userGoals))

PREFERENCES:
- Sleep: \(sleepPreferencesText())
- Energy: \(energyPreferencesText())
- Muscle: \(musclePreferencesText())

Generate \(mealsPerDay) windows optimized for these goals.
"""
```

---

## 6. UI/UX FLOW DESIGN

### A. Proposed Screen Flow

**Current Goal Setting Section** (7 screens):
1. Your Transformation
2. Goal Selection
3. Trend Weight
4. Weight Goal
5. Goal Summary
6. ~~Pre-Workout Nutrition~~ ← REMOVE
7. ~~Post-Workout Nutrition~~ ← REMOVE

**NEW Goal Setting Section** (5-8 screens depending on selections):
1. Your Transformation
2. Goal Selection (primary goal - keep as is)
3. Trend Weight
4. Weight Goal
5. Goal Summary
6. **Specific Goals Selection** ← NEW (multi-select)
7. **Sleep Preferences** ← NEW (conditional - if betterSleep selected)
8. **Energy Preferences** ← NEW (conditional - if steadyEnergy selected)
9. **Muscle Preferences** ← NEW (conditional - if muscleGain selected)
10. **Performance Preferences** ← NEW (conditional - if athleticPerformance selected)

### B. Specific Goals Selection Screen

**UI Pattern**: Multi-select card grid

```swift
SpecificGoalsSelectionView
├─ Header: "What are your specific nutrition goals?"
├─ Subtitle: "Select all that apply - we'll customize your plan"
└─ Goal Cards (multi-select):
    ├─ 🏋️ Build Muscle & Recover Faster
    │   └─ "Optimize protein timing and recovery windows"
    ├─ ⚡️ Maintain Steady Energy
    │   └─ "Avoid crashes and stay energized all day"
    ├─ 😴 Improve Sleep Quality
    │   └─ "Optimize meal timing for better rest"
    ├─ 🏃 Athletic Performance
    │   └─ "Fuel your workouts effectively"
    └─ 🧬 Metabolic Health
        └─ "Support blood sugar and metabolic function"
```

**Selection State**:
- Checkmark overlay when selected
- Use signature color (#C0FF73) for selection border/background
- Minimum 0 selections (can skip)
- Maximum all selections allowed

### C. Conditional Detail Screens

**Sleep Preferences Screen** (shown if "Better Sleep" selected):
```swift
SleepPreferencesView
├─ Header: "Sleep Optimization Preferences"
├─ Question: "How many hours before bed do you want your last meal?"
└─ Options:
    ├─ 2 hours (flexible)
    ├─ 3 hours (recommended)
    └─ 4 hours (strict)
```

**Energy Preferences Screen** (shown if "Steady Energy" selected):
```swift
EnergyPreferencesView
├─ Header: "Energy Management"
├─ Question: "When do you typically experience energy crashes?"
└─ Options (multi-select):
    ├─ Mid-morning (9-11 AM)
    ├─ Afternoon (2-4 PM)
    ├─ Evening (6-8 PM)
    └─ No specific pattern
```

**Muscle Preferences Screen** (shown if "Build Muscle" selected):
```swift
MusclePreferencesView
├─ Header: "Muscle Building Preferences"
├─ Question 1: "How many days per week do you train?"
│   └─ Options: 3, 4, 5, 6, 7 days
└─ Question 2: "Training style?"
    └─ Options: Strength, Hypertrophy, Powerlifting, General Fitness
```

**Performance Preferences Screen** (shown if "Athletic Performance" selected):
```swift
PerformancePreferencesView
├─ Header: "Workout Fueling Preferences"
├─ Question 1: "When do you typically work out?"
│   └─ Time picker
├─ Question 2: "Do you want a pre-workout meal?"
│   └─ Toggle: Yes/No
└─ Question 3: "Do you want a post-workout meal?"
    └─ Toggle: Yes/No
```

---

## 7. IMPLEMENTATION IMPACT ANALYSIS

### A. Files to Modify

**1. Data Models** (3 files):
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserGoals.swift`
  - Add `specificGoals` property
  - Add preference structs
  - Add enums for specific goals

- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/OnboardingProgress.swift`
  - Add fields to track specific goal selections during onboarding

- Create `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/NutritionPreferences.swift` (optional)
  - If using separate preferences model

**2. Onboarding Views** (2-3 files):
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`
  - REMOVE: PreWorkoutNutritionContentView (Lines 3157-3245)
  - REMOVE: PostWorkoutNutritionContentView (Lines 3247-3310+)
  - ADD: SpecificGoalsSelectionView
  - ADD: SleepPreferencesView (conditional)
  - ADD: EnergyPreferencesView (conditional)
  - ADD: MusclePreferencesView (conditional)
  - ADD: PerformancePreferencesView (conditional)

- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`
  - Update goalSetting screen list
  - Remove pre/post workout screens
  - Add new screen titles

- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`
  - REMOVE: preworkoutTiming and postworkoutTiming properties (Lines 121-122)
  - ADD: selectedSpecificGoals property
  - ADD: preference properties for each goal type
  - UPDATE: buildUserGoals() to include specific goals
  - UPDATE: Navigation switch cases (Lines 830-833)

**3. Firebase Integration** (1 file):
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/DataProvider/FirebaseDataProvider.swift`
  - Update saveUserGoals() to save specific goals
  - Update loadUserGoals() to load specific goals
  - Add migration logic if needed

**4. Window Generation** (3 files):
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/FirstDayWindowService.swift`
  - Use specific goals to influence first-day windows
  - Apply constraints from preferences (sleep timing, etc.)

- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift`
  - Enhance prompt with specific goal data
  - Use preferences to constrain window timing

- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/WindowGenerationService.swift`
  - Update window purpose assignment based on specific goals

**5. Optional: Legacy Cleanup** (1 file):
- Consider removing `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/WorkoutNutritionView.swift`
  - May be deprecated alternative implementation

### B. Data Migration Requirements

**Question**: Are there any existing users with data?

**If YES**:
```swift
// Migration strategy for existing users
func migrateToSpecificGoals(currentGoals: UserGoals) -> UserGoals {
    var updated = currentGoals

    // Infer specific goals from primary goal
    switch currentGoals.primaryGoal {
    case .buildMuscle:
        updated.specificGoals = [.muscleGain]
    case .loseWeight:
        updated.specificGoals = [.metabolicHealth, .steadyEnergy]
    case .betterSleep:
        updated.specificGoals = [.betterSleep]
    case .improvePerformance:
        updated.specificGoals = [.athleticPerformance]
    default:
        updated.specificGoals = []
    }

    return updated
}
```

**If NO** (development/testing only):
- No migration needed
- Clean implementation

---

## 8. EDGE CASES & VALIDATION

### A. Goal Conflicts

**Scenario**: User selects conflicting goals
- Example: "Better Sleep" (no late meals) + "Athletic Performance" (late evening workout)

**Solution**:
- Show warning/info message when conflicts detected
- Allow user to proceed but note that AI will balance preferences
- Prioritize based on primary goal

### B. No Specific Goals Selected

**Scenario**: User skips specific goals selection

**Solution**:
- Treat as valid (not everyone has specific preferences)
- Fall back to primary goal only
- Window generation uses standard patterns

### C. Too Many Goals Selected

**Scenario**: User selects all 5 specific goals

**Solution**:
- Allow it (more data is good)
- AI will balance all preferences
- Some goals may overlap beneficially (muscle + performance)

### D. Invalid Preference Combinations

**Scenario**: User wants sleep optimization but has very late bedtime AND early wake time

**Solution**:
- Validate during onboarding
- Show feedback: "With this schedule, you may have limited eating windows"
- Allow user to adjust or proceed

---

## 9. TESTING STRATEGY

### A. Unit Tests Needed

1. **UserGoals Model Tests**:
   - Codable encoding/decoding with specific goals
   - Computed properties for goal priorities
   - Validation logic

2. **Preference Model Tests**:
   - Each preference struct encodes/decodes correctly
   - Optional fields handled properly

3. **Window Generation Tests**:
   - Specific goals correctly influence window purposes
   - Sleep constraints applied correctly
   - Energy crash windows scheduled at right times
   - Muscle gain includes recovery windows

### B. Integration Tests

1. **Onboarding Flow**:
   - Can complete onboarding with 0 specific goals
   - Can complete with 1 specific goal
   - Can complete with multiple specific goals
   - Conditional screens appear only when relevant
   - Data persists to Firebase correctly

2. **Window Generation**:
   - First-day windows respect sleep constraints
   - AI windows include appropriate purposes
   - Macros distributed correctly per goal type

### C. UI Testing

1. **Multi-Select Behavior**:
   - Cards show selected state with signature color
   - Can select/deselect goals
   - Can skip screen entirely

2. **Conditional Screens**:
   - Sleep screen appears only if betterSleep selected
   - Energy screen appears only if steadyEnergy selected
   - Other conditional screens work correctly
   - Can navigate back and change selections

---

## 10. ALTERNATIVES CONSIDERED

### Alternative 1: Keep Pre/Post Workout + Add Specific Goals
**Pros**: More data collected
**Cons**: Longer onboarding, redundant with performance goal
**Decision**: REJECTED - User wants to replace, not extend

### Alternative 2: Single Specific Goal Instead of Multi-Select
**Pros**: Simpler UI, faster onboarding
**Cons**: Less flexible, users have multiple goals in reality
**Decision**: REJECTED - Multi-select provides better customization

### Alternative 3: Ask About All Preferences Upfront
**Pros**: Collect everything at once
**Cons**: Overwhelming user experience, many irrelevant questions
**Decision**: REJECTED - Use conditional screens based on goal selections

### Alternative 4: No Specific Goals, Just Primary Goal
**Pros**: Simplest implementation
**Cons**: Loses valuable customization data
**Decision**: REJECTED - Defeats purpose of refactor

---

## 11. RECOMMENDATIONS & NEXT STEPS

### A. Recommended Approach

1. **Use Multi-Select Specific Goals**
   - Allows users to select multiple relevant goals
   - Provides rich data for AI window generation
   - Better user experience than single selection

2. **Implement Conditional Preference Screens**
   - Only show detail screens for selected goals
   - Keeps onboarding concise
   - Collects necessary context without overwhelming

3. **Extend UserGoals Model**
   - Add specific goals directly to UserGoals
   - Keeps related data together
   - Avoid proliferation of models

4. **Enhance Window Generation**
   - Use specific goals to assign window purposes
   - Apply timing constraints from preferences
   - Improve AI prompts with preference data

### B. Questions for Planning Phase

**For User/Designer:**
1. Should specific goals be required or optional?
2. Should we limit maximum number of specific goals?
3. How many questions per preference screen? (Keep it 1-3 max?)
4. Should we provide a "Skip" option for detail screens?
5. UI design: Cards in grid or vertical list?
6. Should we show a preview/summary of goal impacts before finishing?

**For Implementation:**
1. Extend UserGoals or create separate NutritionPreferences model?
2. Where to store preferences in Firebase? (goals collection or separate?)
3. Should we support goal priorities? (primary, secondary, tertiary)
4. How to handle updates to goals after onboarding?
5. Do we need analytics tracking for goal selections?

### C. Estimated Scope

**Files to Create**: 5-6 new view files (specific goal screens)
**Files to Modify**: 8-10 existing files
**Lines of Code**: ~800-1200 new lines
**Complexity**: Medium-High (data model changes + UI + integration)
**Risk**: Medium (touches onboarding, data models, window generation)

---

## 12. CRITICAL SUCCESS FACTORS

✅ **Must Have**:
1. Remove pre/post-workout screens completely
2. Add specific goals selection (multi-select)
3. Persist specific goals to Firebase
4. Use specific goals in window generation
5. Maintain onboarding flow smoothness

⚠️ **Should Have**:
1. Conditional preference screens
2. Goal-specific constraints (sleep timing, etc.)
3. Enhanced AI prompts with preferences
4. Validation for conflicting goals

💡 **Nice to Have**:
1. Goal impact preview
2. Analytics tracking
3. Post-onboarding goal editing
4. Goal priority ranking
5. Smart defaults based on primary goal

---

## PHASE 1 COMPLETE ✅

**Research Findings**:
1. ✅ Current pre/post workout screens identified and analyzed
2. ✅ Data models documented (UserGoals, UserProfile)
3. ✅ Window generation integration understood
4. ✅ Firebase schema analyzed and extension designed
5. ✅ UI/UX flow proposed with multi-select approach
6. ✅ Implementation impact mapped (8-10 files)
7. ✅ Edge cases and testing strategy documented

**Next Phase**: PLANNING
- User must provide design preferences
- Clarify data model approach
- Create step-by-step implementation plan
- Define success criteria

**Start NEW session for Phase 2 with:**
- This research document
- User answers to design questions
- Ready to create detailed implementation plan

---

*Research completed: October 21, 2025*
*Next: Phase 2 - Planning (new session required)*
