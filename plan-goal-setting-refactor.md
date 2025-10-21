# Goal Setting Refactor Implementation Plan
**Date**: October 21, 2025
**Phase**: PHASE 2 - PLANNING
**Task**: Replace Pre/Post-Workout Screens with Ranked Goal-Oriented System
**Status**: Plan Complete - Ready for Implementation

---

## EXECUTIVE SUMMARY

### Confirmed Design Decisions (from User Input)

✅ **Goal Selection**: Required (minimum 1 specific goal)
✅ **Maximum Goals**: No limit (users can select all 5)
✅ **Ranking System**: Drag-and-drop priority ranking (if 2+ goals selected)
✅ **Question Depth**: Top 2 Focus
  - Rank 1-2: Full detail (3-4 questions per goal)
  - Rank 3+: Smart defaults (no detailed questions)
✅ **Preview Screen**: Combined timeline + goal impact cards
✅ **Data Storage**: Extend UserGoals model
✅ **UI Patterns**:
  - Card grid for goal selection
  - Vertical list with drag handles for ranking
  - Skip buttons on all preference screens
✅ **Single Goal**: Skip ranking screen, ask full detail

### What We're Building

A sophisticated goal-oriented onboarding system that:
1. Collects multiple specific nutrition goals (muscle, energy, sleep, performance, metabolic)
2. Ranks goals by priority using drag-and-drop
3. Asks detailed questions ONLY for top 2 priorities
4. Shows preview of how goals will shape their meal plan
5. Uses ranking to intelligently generate meal windows

### Key Innovation
**Adaptive Question Depth**: Users see 3-4 detailed questions for their #1-2 priorities, but lower-ranked goals use smart defaults. This balances personalization with onboarding speed.

---

## 1. DATA MODEL SPECIFICATIONS

### A. Extended UserGoals Model

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserGoals.swift`

```swift
struct UserGoals: Codable {
    // EXISTING FIELDS (keep as-is)
    var primaryGoal: Goal
    var activityLevel: ActivityLevel
    var dailyCalories: Int?
    var dailyProteinTarget: Int?
    var dailyCarbTarget: Int?
    var dailyFatTarget: Int?
    var targetWeight: Double?
    var timeline: Int?

    // NEW: Specific goals with priority ranking
    var rankedSpecificGoals: [RankedGoal]  // Ordered by priority (index 0 = highest)

    // NEW: Goal-specific preferences (only for rank 1-2)
    var sleepPreferences: SleepOptimizationPreferences?
    var energyPreferences: EnergyManagementPreferences?
    var musclePreferences: MuscleGainPreferences?
    var performancePreferences: PerformancePreferences?
    var metabolicPreferences: MetabolicHealthPreferences?

    // COMPUTED PROPERTIES
    var topPriorityGoal: SpecificGoal? {
        rankedSpecificGoals.first?.goal
    }

    var hasMultipleGoals: Bool {
        rankedSpecificGoals.count > 1
    }

    func priorityRank(for goal: SpecificGoal) -> Int? {
        rankedSpecificGoals.firstIndex(where: { $0.goal == goal })
    }
}

// NEW: Ranked goal wrapper
struct RankedGoal: Codable, Identifiable {
    let id: UUID
    let goal: SpecificGoal
    var rank: Int  // 0 = highest priority

    init(goal: SpecificGoal, rank: Int) {
        self.id = UUID()
        self.goal = goal
        self.rank = rank
    }
}

// NEW: Specific goal enum
enum SpecificGoal: String, CaseIterable, Codable, Identifiable {
    case muscleGain = "Build Muscle & Recover"
    case steadyEnergy = "Steady Energy Levels"
    case betterSleep = "Better Sleep Quality"
    case athleticPerformance = "Athletic Performance"
    case metabolicHealth = "Metabolic Health"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .muscleGain: return "💪"
        case .steadyEnergy: return "⚡️"
        case .betterSleep: return "😴"
        case .athleticPerformance: return "🏃"
        case .metabolicHealth: return "🧬"
        }
    }

    var subtitle: String {
        switch self {
        case .muscleGain: return "Optimize protein timing and recovery windows"
        case .steadyEnergy: return "Avoid crashes and stay energized all day"
        case .betterSleep: return "Optimize meal timing for better rest"
        case .athleticPerformance: return "Fuel your workouts effectively"
        case .metabolicHealth: return "Support blood sugar and metabolic function"
        }
    }

    var primaryWindowPurposes: [WindowPurpose] {
        switch self {
        case .muscleGain: return [.recovery, .postWorkout]
        case .steadyEnergy: return [.sustainedEnergy, .focusBoost]
        case .betterSleep: return [.sleepOptimization]
        case .athleticPerformance: return [.preWorkout, .postWorkout]
        case .metabolicHealth: return [.metabolicBoost]
        }
    }
}

// NEW: Sleep preferences (for Rank 1-2 only)
struct SleepOptimizationPreferences: Codable {
    var typicalBedtime: Date  // Time component only
    var hoursBeforeBed: Int  // 2, 3, or 4 hours
    var avoidLateCarbs: Bool
    var sleepQualitySensitivity: String  // "Low", "Medium", "High"

    static let defaultForRank3Plus = SleepOptimizationPreferences(
        typicalBedtime: Date.from(hour: 22, minute: 0),  // 10 PM default
        hoursBeforeBed: 3,
        avoidLateCarbs: true,
        sleepQualitySensitivity: "Medium"
    )
}

// NEW: Energy preferences (for Rank 1-2 only)
struct EnergyManagementPreferences: Codable {
    var crashTimes: [CrashTime]  // When user experiences crashes
    var preferredMealFrequency: Int  // 3, 4, 5, or 6 meals
    var caffeineSensitivity: String  // "Low", "Medium", "High"

    enum CrashTime: String, CaseIterable, Codable {
        case midMorning = "Mid-Morning (9-11 AM)"
        case afternoon = "Afternoon (2-4 PM)"
        case evening = "Evening (6-8 PM)"
        case none = "No specific pattern"
    }

    static let defaultForRank3Plus = EnergyManagementPreferences(
        crashTimes: [.afternoon],
        preferredMealFrequency: 4,
        caffeineSensitivity: "Medium"
    )
}

// NEW: Muscle gain preferences (for Rank 1-2 only)
struct MuscleGainPreferences: Codable {
    var trainingDaysPerWeek: Int  // 3-7
    var trainingStyle: TrainingStyle
    var proteinDistribution: String  // "Even", "Post-Workout Focus", "Maximum"
    var supplementProtein: Bool  // Do they use protein powder?

    enum TrainingStyle: String, CaseIterable, Codable {
        case strength = "Strength Training"
        case hypertrophy = "Hypertrophy/Bodybuilding"
        case powerlifting = "Powerlifting"
        case generalFitness = "General Fitness"
    }

    static let defaultForRank3Plus = MuscleGainPreferences(
        trainingDaysPerWeek: 4,
        trainingStyle: .generalFitness,
        proteinDistribution: "Even",
        supplementProtein: false
    )
}

// NEW: Performance preferences (for Rank 1-2 only)
struct PerformancePreferences: Codable {
    var typicalWorkoutTime: Date  // Time component only
    var workoutDuration: Int  // Minutes (30, 45, 60, 90, 120)
    var preworkoutMealDesired: Bool
    var postworkoutMealDesired: Bool
    var workoutIntensity: String  // "Light", "Moderate", "Intense"

    static let defaultForRank3Plus = PerformancePreferences(
        typicalWorkoutTime: Date.from(hour: 17, minute: 0),  // 5 PM default
        workoutDuration: 60,
        preworkoutMealDesired: true,
        postworkoutMealDesired: true,
        workoutIntensity: "Moderate"
    )
}

// NEW: Metabolic health preferences (for Rank 1-2 only)
struct MetabolicHealthPreferences: Codable {
    var fastingWindowHours: Int  // 12, 14, 16, 18
    var bloodSugarConcern: Bool
    var preferLowerCarbs: Bool
    var mealTimingConsistency: String  // "Flexible", "Consistent", "Very Strict"

    static let defaultForRank3Plus = MetabolicHealthPreferences(
        fastingWindowHours: 14,
        bloodSugarConcern: false,
        preferLowerCarbs: false,
        mealTimingConsistency: "Consistent"
    )
}

// HELPER: Date extension for time-only dates
extension Date {
    static func from(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
```

### B. OnboardingCoordinator Updates

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`

```swift
@Observable
class OnboardingCoordinator {
    // REMOVE THESE (Lines 121-122):
    // var preworkoutTiming: String = ""
    // var postworkoutTiming: String = ""

    // ADD THESE:
    var selectedSpecificGoals: Set<SpecificGoal> = []
    var rankedGoals: [RankedGoal] = []

    // Goal-specific preference storage
    var sleepBedtime: Date = Date.from(hour: 22, minute: 0)
    var sleepHoursBeforeBed: Int = 3
    var sleepAvoidLateCarbs: Bool = true
    var sleepQualitySensitivity: String = "Medium"

    var energyCrashTimes: Set<EnergyManagementPreferences.CrashTime> = []
    var energyMealFrequency: Int = 4
    var energyCaffeineSensitivity: String = "Medium"

    var muscleTrainingDays: Int = 4
    var muscleTrainingStyle: MuscleGainPreferences.TrainingStyle = .generalFitness
    var muscleProteinDistribution: String = "Even"
    var muscleSupplementProtein: Bool = false

    var performanceWorkoutTime: Date = Date.from(hour: 17, minute: 0)
    var performanceWorkoutDuration: Int = 60
    var performancePreworkoutMeal: Bool = true
    var performancePostworkoutMeal: Bool = true
    var performanceWorkoutIntensity: String = "Moderate"

    var metabolicFastingHours: Int = 14
    var metabolicBloodSugarConcern: Bool = false
    var metabolicPreferLowerCarbs: Bool = false
    var metabolicMealTimingConsistency: String = "Consistent"

    // HELPER: Build UserGoals from coordinator state
    func buildUserGoals() -> UserGoals {
        var goals = UserGoals(
            primaryGoal: selectedPrimaryGoal,
            activityLevel: selectedActivityLevel,
            dailyCalories: calculatedCalories,
            // ... other existing fields
            rankedSpecificGoals: rankedGoals,
            sleepPreferences: buildSleepPreferences(),
            energyPreferences: buildEnergyPreferences(),
            musclePreferences: buildMusclePreferences(),
            performancePreferences: buildPerformancePreferences(),
            metabolicPreferences: buildMetabolicPreferences()
        )
        return goals
    }

    private func buildSleepPreferences() -> SleepOptimizationPreferences? {
        guard rankedGoals.contains(where: { $0.goal == .betterSleep }) else { return nil }

        let rank = rankedGoals.firstIndex(where: { $0.goal == .betterSleep }) ?? 99
        if rank >= 2 {
            // Rank 3+: Use defaults
            return SleepOptimizationPreferences.defaultForRank3Plus
        }

        // Rank 1-2: Use collected data
        return SleepOptimizationPreferences(
            typicalBedtime: sleepBedtime,
            hoursBeforeBed: sleepHoursBeforeBed,
            avoidLateCarbs: sleepAvoidLateCarbs,
            sleepQualitySensitivity: sleepQualitySensitivity
        )
    }

    // Similar methods for other preferences...
}
```

### C. Firebase Schema

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

  // NEW: Ranked specific goals
  rankedSpecificGoals: [
    {
      id: "uuid-1",
      goal: "muscleGain",
      rank: 0  // Highest priority
    },
    {
      id: "uuid-2",
      goal: "betterSleep",
      rank: 1  // Second priority
    },
    {
      id: "uuid-3",
      goal: "steadyEnergy",
      rank: 2  // Third priority (will use defaults)
    }
  ],

  // NEW: Goal-specific preferences (only for rank 0-1)
  sleepPreferences: {
    typicalBedtime: "2025-10-21T22:00:00Z",
    hoursBeforeBed: 3,
    avoidLateCarbs: true,
    sleepQualitySensitivity: "High"
  },

  musclePreferences: {
    trainingDaysPerWeek: 5,
    trainingStyle: "Hypertrophy",
    proteinDistribution: "Post-Workout Focus",
    supplementProtein: true
  },

  energyPreferences: {
    crashTimes: ["Afternoon"],
    preferredMealFrequency: 4,
    caffeineSensitivity: "Medium"
  }
  // Note: No detailed preferences for rank 2+ goals
}
```

---

## 2. SCREEN-BY-SCREEN FLOW

### Current Goal Setting Section (7 screens)
1. Your Transformation
2. Goal Selection
3. Trend Weight
4. Weight Goal
5. Goal Summary
6. ~~Pre-Workout Nutrition~~ ← **REMOVE**
7. ~~Post-Workout Nutrition~~ ← **REMOVE**

### NEW Goal Setting Section (7-10 screens, conditional)

#### **Screen 6: Specific Goals Selection** ✨ NEW
**Type**: Multi-select card grid
**Requirement**: Minimum 1 selection required

**UI Layout**:
```
┌─────────────────────────────────────────┐
│  What are your specific nutrition      │
│  goals?                                 │
│  Select all that apply                  │
├─────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐          │
│  │ 💪        │  │ ⚡️       │          │
│  │ Build     │  │ Steady    │          │
│  │ Muscle    │  │ Energy    │          │
│  │ [✓]       │  │           │          │
│  └───────────┘  └───────────┘          │
│  ┌───────────┐  ┌───────────┐          │
│  │ 😴        │  │ 🏃        │          │
│  │ Better    │  │ Athletic  │          │
│  │ Sleep     │  │ Perform.  │          │
│  │ [✓]       │  │           │          │
│  └───────────┘  └───────────┘          │
│  ┌───────────┐                         │
│  │ 🧬        │                         │
│  │ Metabolic │                         │
│  │ Health    │                         │
│  └───────────┘                         │
└─────────────────────────────────────────┘
```

**Behavior**:
- Use signature color (#C0FF73) for selected state
- Checkmark overlay when selected
- Must select at least 1 to proceed
- Continue button disabled until 1+ selected

**Component**: `SpecificGoalsSelectionView`

---

#### **Screen 7: Goal Ranking** ✨ NEW (Conditional)
**Condition**: Only shown if 2+ goals selected
**Type**: Vertical drag-and-drop list

**UI Layout**:
```
┌─────────────────────────────────────────┐
│  Rank Your Goals                        │
│  Drag to reorder by priority            │
│                                         │
│  Your #1 goal will have the most        │
│  influence on your meal windows         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ 1st  💪 Build Muscle & Recover  │   │
│  │      ⋮⋮ [drag handle]           │   │
│  │      We'll ask detailed questions│  │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 2nd  😴 Better Sleep Quality    │   │
│  │      ⋮⋮                          │   │
│  │      We'll ask detailed questions│  │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 3rd  ⚡️ Steady Energy Levels   │   │
│  │      ⋮⋮                          │   │
│  │      We'll use smart defaults    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Behavior**:
- Rank badges: "1st", "2nd", "3rd", "4th", "5th"
- Different colors for rank 1-2 (accent) vs 3+ (muted)
- Explanatory text under rank 1-2: "We'll ask detailed questions"
- Explanatory text under rank 3+: "We'll use smart defaults"
- Can reorder freely before continuing

**Component**: `GoalRankingView`

---

#### **Screens 8-12: Preference Screens** ✨ NEW (Conditional)
**Condition**: Only shown for goals ranked 1-2

##### **Sleep Preferences** (if betterSleep in rank 1-2)
```
┌─────────────────────────────────────────┐
│  Sleep Optimization                     │
│  Help us time your meals for better     │
│  rest                                   │
├─────────────────────────────────────────┤
│  What time do you typically go to bed?  │
│  [Time Picker: 10:00 PM]                │
│                                         │
│  How many hours before bed should your  │
│  last meal end?                         │
│  ○ 2 hours (flexible)                   │
│  ● 3 hours (recommended)                │
│  ○ 4 hours (strict)                     │
│                                         │
│  Avoid high-carb foods in evening?      │
│  [Toggle: ON]                           │
│                                         │
│  How sensitive is your sleep to food    │
│  timing?                                │
│  ○ Low  ● Medium  ○ High                │
└─────────────────────────────────────────┘
               [Skip] [Continue]
```
**Questions**: 4 (full detail for rank 1-2)

---

##### **Energy Preferences** (if steadyEnergy in rank 1-2)
```
┌─────────────────────────────────────────┐
│  Energy Management                      │
│  Let's prevent those energy crashes     │
├─────────────────────────────────────────┤
│  When do you typically experience       │
│  energy crashes? (Select all)           │
│  [✓] Mid-Morning (9-11 AM)              │
│  [✓] Afternoon (2-4 PM)                 │
│  [ ] Evening (6-8 PM)                   │
│  [ ] No specific pattern                │
│                                         │
│  How many meals per day do you prefer?  │
│  ○ 3  ● 4  ○ 5  ○ 6                     │
│                                         │
│  Caffeine sensitivity?                  │
│  ○ Low  ● Medium  ○ High                │
└─────────────────────────────────────────┘
               [Skip] [Continue]
```
**Questions**: 3

---

##### **Muscle Preferences** (if muscleGain in rank 1-2)
```
┌─────────────────────────────────────────┐
│  Muscle Building & Recovery             │
│  Optimize your protein timing           │
├─────────────────────────────────────────┤
│  How many days per week do you train?   │
│  [Stepper: 4 days]                      │
│                                         │
│  What's your primary training style?    │
│  ○ Strength Training                    │
│  ● Hypertrophy/Bodybuilding             │
│  ○ Powerlifting                         │
│  ○ General Fitness                      │
│                                         │
│  Protein distribution preference?       │
│  ○ Even throughout day                  │
│  ● Post-Workout Focus                   │
│  ○ Maximum (6 meals)                    │
│                                         │
│  Do you use protein supplements?        │
│  [Toggle: ON]                           │
└─────────────────────────────────────────┘
               [Skip] [Continue]
```
**Questions**: 4

---

##### **Performance Preferences** (if athleticPerformance in rank 1-2)
```
┌─────────────────────────────────────────┐
│  Athletic Performance                   │
│  Fuel your workouts effectively         │
├─────────────────────────────────────────┤
│  When do you typically work out?        │
│  [Time Picker: 5:00 PM]                 │
│                                         │
│  Average workout duration?              │
│  ○ 30 min  ● 60 min  ○ 90 min  ○ 2 hrs  │
│                                         │
│  Want a pre-workout meal?               │
│  [Toggle: ON]                           │
│                                         │
│  Want a post-workout meal?              │
│  [Toggle: ON]                           │
│                                         │
│  Workout intensity?                     │
│  ○ Light  ● Moderate  ○ Intense         │
└─────────────────────────────────────────┘
               [Skip] [Continue]
```
**Questions**: 5

---

##### **Metabolic Preferences** (if metabolicHealth in rank 1-2)
```
┌─────────────────────────────────────────┐
│  Metabolic Health                       │
│  Support blood sugar and metabolism     │
├─────────────────────────────────────────┤
│  Preferred fasting window?              │
│  ○ 12 hours  ● 14 hours                 │
│  ○ 16 hours  ○ 18 hours                 │
│                                         │
│  Blood sugar concerns?                  │
│  [Toggle: OFF]                          │
│                                         │
│  Prefer lower-carb approach?            │
│  [Toggle: OFF]                          │
│                                         │
│  Meal timing consistency preference?    │
│  ○ Flexible  ● Consistent  ○ Very Strict│
└─────────────────────────────────────────┘
               [Skip] [Continue]
```
**Questions**: 4

---

#### **Screen 13: Goal Impact Preview** ✨ NEW
**Type**: Combined timeline + impact cards
**Purpose**: Show user how their ranked goals will shape their plan

**UI Layout**:
```
┌─────────────────────────────────────────┐
│  Your Personalized Plan Preview         │
├─────────────────────────────────────────┤
│  📅 Tomorrow's Meal Windows:            │
│                                         │
│  ├─ 7:00 AM - 8:30 AM                   │
│  │  Breakfast Window                    │
│  │  Purpose: Steady Energy (#3)         │
│  │  Balanced macros, sustained fuel     │
│  │                                      │
│  ├─ 12:00 PM - 1:30 PM                  │
│  │  Lunch Window                        │
│  │  Purpose: Muscle Recovery (#1)       │
│  │  High protein, optimal timing        │
│  │                                      │
│  ├─ 4:00 PM - 5:00 PM                   │
│  │  Pre-Workout Snack (#1)              │
│  │  Light carbs for energy              │
│  │                                      │
│  ├─ 6:30 PM - 7:30 PM                   │
│  │  Dinner Window                       │
│  │  Purpose: Sleep Optimization (#2)    │
│  │  Ends 3 hrs before bed (10pm)        │
│  │  Lower carbs, lighter portions       │
│  │                                      │
│  └─ 10:00 PM - Bedtime                  │
│     Fasting begins                      │
│                                         │
├─────────────────────────────────────────┤
│  🎯 How Your Goals Shape Your Plan:     │
│                                         │
│  💪 Build Muscle (#1 Priority)          │
│  ✓ 5 eating windows for protein intake  │
│  ✓ Post-workout window within 1 hour    │
│  ✓ 180g protein distributed evenly      │
│                                         │
│  😴 Better Sleep (#2 Priority)          │
│  ✓ Last meal ends at 7:00 PM (3 hrs)    │
│  ✓ Lower carbs after 6 PM               │
│  ✓ Lighter evening portions             │
│                                         │
│  ⚡️ Steady Energy (#3 Priority)        │
│  ✓ 4 balanced meals throughout day      │
│  ✓ Smart defaults applied               │
└─────────────────────────────────────────┘
           [Looks Good!] [Adjust]
```

**Behavior**:
- Shows mock timeline using current data
- Impact cards show top 3 goals (or all if <3)
- Visual hierarchy: Rank 1 larger/bolder than rank 2-3
- "Adjust" button goes back to ranking screen
- "Looks Good!" completes onboarding

**Component**: `GoalImpactPreviewView`

---

## 3. IMPLEMENTATION STEPS

### STEP 1: Data Model Updates
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserGoals.swift`

**Tasks**:
1. ✅ Add `SpecificGoal` enum with all 5 goals
2. ✅ Create `RankedGoal` struct with id, goal, rank
3. ✅ Add preference structs for each goal type:
   - `SleepOptimizationPreferences` (with static defaults)
   - `EnergyManagementPreferences` (with static defaults)
   - `MuscleGainPreferences` (with static defaults)
   - `PerformancePreferences` (with static defaults)
   - `MetabolicHealthPreferences` (with static defaults)
4. ✅ Update `UserGoals` struct with new properties:
   - `rankedSpecificGoals: [RankedGoal]`
   - Optional preference properties
5. ✅ Add computed properties (`topPriorityGoal`, `hasMultipleGoals`, `priorityRank(for:)`)
6. ✅ Add `Date.from(hour:minute:)` extension helper
7. ✅ Test compilation with `swiftc -parse`

**Success Criteria**:
- All structs compile without errors
- Codable conformance works
- Default values compile correctly

---

### STEP 2: OnboardingCoordinator Updates
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`

**Tasks**:
1. ✅ REMOVE old properties (lines 121-122):
   - `preworkoutTiming`
   - `postworkoutTiming`
2. ✅ ADD new properties:
   - `selectedSpecificGoals: Set<SpecificGoal>`
   - `rankedGoals: [RankedGoal]`
   - All preference-specific properties (sleep, energy, muscle, performance, metabolic)
3. ✅ Create builder methods:
   - `buildSleepPreferences() -> SleepOptimizationPreferences?`
   - `buildEnergyPreferences() -> EnergyManagementPreferences?`
   - `buildMusclePreferences() -> MuscleGainPreferences?`
   - `buildPerformancePreferences() -> PerformancePreferences?`
   - `buildMetabolicPreferences() -> MetabolicHealthPreferences?`
4. ✅ Update `buildUserGoals()` to include ranked goals and preferences
5. ✅ Test compilation

**Success Criteria**:
- No compilation errors
- Builder methods correctly check rank (0-1 = detailed, 2+ = defaults)
- UserGoals object builds correctly

---

### STEP 3: Update OnboardingSectionData
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`

**Tasks**:
1. ✅ REMOVE from goalSetting section (lines 87-88):
   - "Pre-Workout Nutrition"
   - "Post-Workout Nutrition"
2. ✅ ADD to goalSetting section:
   - "Specific Goals" (always shown)
   - "Goal Ranking" (conditional - handled in coordinator)
   - "Sleep Preferences" (conditional)
   - "Energy Preferences" (conditional)
   - "Muscle Preferences" (conditional)
   - "Performance Preferences" (conditional)
   - "Metabolic Preferences" (conditional)
   - "Goal Impact Preview" (always shown)
3. ✅ Test compilation

**Success Criteria**:
- Section data compiles
- Screen titles are correct

---

### STEP 4: Create SpecificGoalsSelectionView
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Tasks**:
1. ✅ Create new view struct `SpecificGoalsSelectionView`
2. ✅ Implement card grid layout (LazyVGrid with 2 columns)
3. ✅ Create selectable goal cards with:
   - Icon (emoji)
   - Goal name
   - Subtitle description
   - Checkmark overlay when selected
   - Signature color (#C0FF73) for selected state
4. ✅ Bind to `coordinator.selectedSpecificGoals`
5. ✅ Disable continue button until 1+ selected
6. ✅ Add validation logic
7. ✅ Test compilation
8. ✅ Test in simulator (select/deselect goals)

**Success Criteria**:
- UI matches design
- Can select/deselect goals
- Continue button validation works
- Signature color applied correctly

---

### STEP 5: Create GoalRankingView
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Tasks**:
1. ✅ Create new view struct `GoalRankingView`
2. ✅ Implement drag-and-drop vertical list
3. ✅ Show rank badges (1st, 2nd, 3rd, etc.)
4. ✅ Show explanatory text:
   - Rank 1-2: "We'll ask detailed questions"
   - Rank 3+: "We'll use smart defaults"
5. ✅ Add drag handle icon (⋮⋮)
6. ✅ Implement reordering logic
7. ✅ Update `coordinator.rankedGoals` on reorder
8. ✅ Test compilation
9. ✅ Test in simulator (drag to reorder)

**Success Criteria**:
- Drag-and-drop works smoothly
- Rank updates correctly
- Visual hierarchy clear (rank 1-2 emphasized)
- Explanatory text shows correctly

---

### STEP 6: Create Preference Detail Views
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Tasks**:
1. ✅ Create `SleepPreferencesView` (4 questions)
   - Bedtime time picker
   - Hours before bed (2/3/4)
   - Avoid late carbs toggle
   - Sleep sensitivity (Low/Medium/High)
   - Skip button
2. ✅ Create `EnergyPreferencesView` (3 questions)
   - Crash times (multi-select)
   - Meal frequency (3/4/5/6)
   - Caffeine sensitivity
   - Skip button
3. ✅ Create `MusclePreferencesView` (4 questions)
   - Training days stepper
   - Training style picker
   - Protein distribution
   - Supplement toggle
   - Skip button
4. ✅ Create `PerformancePreferencesView` (5 questions)
   - Workout time picker
   - Duration picker
   - Pre-workout meal toggle
   - Post-workout meal toggle
   - Intensity picker
   - Skip button
5. ✅ Create `MetabolicPreferencesView` (4 questions)
   - Fasting hours picker
   - Blood sugar toggle
   - Lower carbs toggle
   - Consistency picker
   - Skip button
6. ✅ Bind all fields to coordinator properties
7. ✅ Implement skip button (sets to defaults)
8. ✅ Test compilation
9. ✅ Test each screen in simulator

**Success Criteria**:
- All UI elements render correctly
- Data binds to coordinator
- Skip button sets smart defaults
- Consistent visual style across all screens

---

### STEP 7: Create GoalImpactPreviewView
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Tasks**:
1. ✅ Create new view struct `GoalImpactPreviewView`
2. ✅ Generate mock timeline based on current data:
   - Use ranked goals to assign window purposes
   - Calculate meal times based on preferences
   - Apply sleep constraints (bedtime - hours)
   - Apply workout timing if performance goal
3. ✅ Create timeline visualization:
   - List of windows with times
   - Purpose label (linked to ranked goal)
   - Brief description
4. ✅ Create goal impact cards:
   - Top 3 ranked goals (or all if < 3)
   - Bullet points of specific impacts
   - Visual hierarchy by rank
5. ✅ Add "Looks Good!" and "Adjust" buttons
6. ✅ "Adjust" navigates back to ranking screen
7. ✅ "Looks Good!" proceeds to complete onboarding
8. ✅ Test compilation
9. ✅ Test in simulator

**Success Criteria**:
- Timeline shows realistic meal windows
- Goal impacts are accurate and specific
- Navigation buttons work
- Visual hierarchy emphasizes rank 1-2

---

### STEP 8: Update Navigation Logic
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`

**Tasks**:
1. ✅ REMOVE navigation cases (lines 830-833):
   - "Pre-Workout Nutrition"
   - "Post-Workout Nutrition"
2. ✅ ADD navigation cases:
   - "Specific Goals" → `SpecificGoalsSelectionView()`
   - "Goal Ranking" → `GoalRankingView()` (conditional)
   - "Sleep Preferences" → `SleepPreferencesView()` (conditional)
   - "Energy Preferences" → `EnergyPreferencesView()` (conditional)
   - "Muscle Preferences" → `MusclePreferencesView()` (conditional)
   - "Performance Preferences" → `PerformancePreferencesView()` (conditional)
   - "Metabolic Preferences" → `MetabolicPreferencesView()` (conditional)
   - "Goal Impact Preview" → `GoalImpactPreviewView()`
3. ✅ Implement conditional screen logic:
   - Skip ranking if only 1 goal selected
   - Only show preference screens for rank 1-2 goals
4. ✅ Update screen advancement logic
5. ✅ Test compilation
6. ✅ Test full flow in simulator

**Success Criteria**:
- Navigation flows correctly
- Conditional screens appear only when appropriate
- Can complete onboarding with 1 goal (skips ranking)
- Can complete with 5 goals (shows ranking, only asks details for top 2)

---

### STEP 9: REMOVE Old Pre/Post Workout Views
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`

**Tasks**:
1. ✅ DELETE `PreWorkoutNutritionContentView` (lines 3157-3245)
2. ✅ DELETE `PostWorkoutNutritionContentView` (lines 3247-3310+)
3. ✅ Search codebase for any references:
   ```bash
   rg "PreWorkoutNutrition" --type swift
   rg "PostWorkoutNutrition" --type swift
   ```
4. ✅ Remove any remaining references
5. ✅ Test compilation
6. ✅ Test full onboarding flow

**Success Criteria**:
- No compilation errors
- No references to old views remain
- Onboarding completes without old screens

---

### STEP 10: Firebase Integration
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/DataProvider/FirebaseDataProvider.swift`

**Tasks**:
1. ✅ Update `saveUserGoals()` to save:
   - `rankedSpecificGoals` array
   - Preference objects (only non-nil ones)
2. ✅ Update `loadUserGoals()` to load:
   - `rankedSpecificGoals` array
   - Preference objects
3. ✅ Handle missing data gracefully (backward compatibility)
4. ✅ Test save/load cycle:
   ```swift
   // Save goals
   try await firebaseDataProvider.saveUserGoals(goals)
   // Load goals
   let loaded = try await firebaseDataProvider.loadUserGoals()
   // Verify equality
   ```
5. ✅ Test compilation

**Success Criteria**:
- Data saves to Firestore correctly
- Data loads from Firestore correctly
- Backward compatible with existing users (if any)
- No data loss

---

### STEP 11: Window Generation Integration
**Files**:
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/FirstDayWindowService.swift`
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift`
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/WindowGenerationService.swift`

**Tasks**:
1. ✅ Update `FirstDayWindowService`:
   - Use `rankedSpecificGoals` to assign window purposes
   - Apply constraints from preferences (sleep timing, workout timing)
   - Prioritize rank 1 goal in window assignment
2. ✅ Update `AIWindowGenerationService`:
   - Enhance prompt with ranked goals and preferences
   - Include constraints in prompt (bedtime, workout time, etc.)
   - Mention goal priorities in prompt
3. ✅ Update `WindowGenerationService`:
   - Use ranked goals for purpose assignment
   - Apply timing constraints
4. ✅ Test window generation:
   - Create test UserGoals with ranked goals
   - Generate windows
   - Verify purposes align with goals
   - Verify constraints are applied
5. ✅ Test compilation

**Success Criteria**:
- Windows have appropriate purposes based on ranked goals
- Sleep constraints applied (last meal ends X hours before bed)
- Workout windows scheduled if performance goal ranked high
- Energy windows scheduled at crash times if energy goal ranked high
- Muscle recovery windows included if muscle goal ranked high

---

### STEP 12: Testing & Edge Cases
**Tasks**:
1. ✅ Test edge case: User selects 1 goal
   - Skips ranking screen
   - Asks 3-4 detailed questions
   - Completes onboarding
2. ✅ Test edge case: User selects 2 goals
   - Shows ranking screen
   - Asks detailed questions for both
   - Generates windows correctly
3. ✅ Test edge case: User selects 5 goals
   - Shows ranking screen
   - Asks detailed questions for rank 1-2 only
   - Uses defaults for rank 3-5
   - Generates balanced windows
4. ✅ Test skip button on all preference screens
   - Verify smart defaults are applied
   - Verify can complete onboarding after skipping
5. ✅ Test goal impact preview
   - Verify timeline is realistic
   - Verify goal impacts are accurate
   - Test "Adjust" button navigation
6. ✅ Test conflicting goals (e.g., late workout + early sleep)
   - Verify AI balances conflicting constraints
   - Verify preview shows realistic compromise
7. ✅ Test data persistence
   - Complete onboarding
   - Verify data saved to Firebase
   - Reload app
   - Verify data loaded correctly
8. ✅ Test backward compatibility
   - Load user without rankedSpecificGoals
   - Verify app doesn't crash
   - Verify defaults applied

**Success Criteria**:
- All edge cases handled gracefully
- No crashes or errors
- Data persists correctly
- Window generation works for all goal combinations

---

### STEP 13: Compilation Testing
**Tasks**:
1. ✅ Compile ALL edited files:
   ```bash
   swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
     -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
     NutriSync/Models/UserGoals.swift \
     NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift \
     NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift \
     NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift \
     NutriSync/Services/DataProvider/FirebaseDataProvider.swift \
     NutriSync/Services/FirstDayWindowService.swift \
     NutriSync/Services/AI/AIWindowGenerationService.swift \
     NutriSync/Services/AI/WindowGenerationService.swift
   ```
2. ✅ Fix any compilation errors
3. ✅ Type-check for semantic validation
4. ✅ Build in Xcode
5. ✅ Run in simulator

**Success Criteria**:
- All files compile without errors
- No type errors
- Full build succeeds
- App runs in simulator

---

### STEP 14: User Testing & Feedback
**Tasks**:
1. ✅ Complete full onboarding flow with different goal combinations
2. ✅ Take screenshots of each new screen
3. ✅ User reviews and provides feedback
4. ✅ Make UI/UX adjustments based on feedback
5. ✅ Re-test after adjustments
6. ✅ Final compilation test

**Success Criteria**:
- User approves all screens
- UI matches design expectations
- Flow feels smooth and intuitive
- No friction points

---

### STEP 15: Commit & Push
**Tasks**:
1. ✅ Final compilation test (MANDATORY)
2. ✅ Stage all changes:
   ```bash
   git add -A
   ```
3. ✅ Commit with clear message:
   ```bash
   git commit -m "feat: replace pre/post-workout screens with ranked goal-oriented system

   - Add SpecificGoal enum with 5 goal types
   - Implement goal ranking with drag-and-drop UI
   - Add adaptive question depth (detailed for rank 1-2, defaults for 3+)
   - Create preference screens for sleep, energy, muscle, performance, metabolic goals
   - Add goal impact preview screen with timeline + impact cards
   - Remove old pre/post-workout nutrition screens
   - Integrate ranked goals with window generation
   - Update Firebase schema to persist ranked goals and preferences"
   ```
4. ✅ Push to remote:
   ```bash
   git push origin main
   ```

**Success Criteria**:
- All changes committed
- Pushed successfully
- No conflicts

---

## 4. TESTING STRATEGY

### Unit Tests (if implementing)
1. **UserGoals Model**:
   - Test Codable encoding/decoding with ranked goals
   - Test computed properties (topPriorityGoal, priorityRank)
   - Test default preference values

2. **Preference Builder Methods**:
   - Test rank 1-2 returns detailed preferences
   - Test rank 3+ returns defaults
   - Test nil when goal not selected

3. **Window Generation**:
   - Test window purposes align with ranked goals
   - Test sleep constraints applied
   - Test workout timing constraints applied

### Integration Tests
1. **Onboarding Flow**:
   - Complete with 1 goal (skips ranking)
   - Complete with 2 goals (shows ranking, both detailed)
   - Complete with 5 goals (shows ranking, top 2 detailed)
   - Skip all preference screens
   - Test navigation back/forward

2. **Data Persistence**:
   - Save goals to Firebase
   - Load goals from Firebase
   - Verify data integrity

3. **Window Generation**:
   - Generate windows with different goal combinations
   - Verify purposes are appropriate
   - Verify constraints are respected

### Manual Testing Checklist
- [ ] Complete onboarding with 1 specific goal
- [ ] Complete onboarding with 2 specific goals
- [ ] Complete onboarding with 5 specific goals
- [ ] Drag to reorder goals in ranking screen
- [ ] Skip each preference screen individually
- [ ] Test "Adjust" button on preview screen
- [ ] Verify goal impact preview shows correct timeline
- [ ] Verify data persists after app restart
- [ ] Test conflicting goals (late workout + early sleep)
- [ ] Test all UI states (selected/unselected cards, etc.)

---

## 5. SUCCESS CRITERIA

### Feature Complete When:
- [ ] All 5 specific goals can be selected
- [ ] Ranking screen works with drag-and-drop
- [ ] Rank 1-2 goals show detailed preference screens
- [ ] Rank 3+ goals use smart defaults (no questions asked)
- [ ] Single goal selection skips ranking
- [ ] Skip buttons work on all preference screens
- [ ] Goal impact preview shows realistic timeline
- [ ] Goal impact preview shows specific impacts per goal
- [ ] Data persists to Firebase correctly
- [ ] Window generation uses ranked goals
- [ ] Sleep constraints applied to window timing
- [ ] Workout timing constraints applied
- [ ] Old pre/post-workout screens removed
- [ ] No compilation errors
- [ ] User approves UI/UX
- [ ] Full onboarding flow completes successfully

### Quality Metrics:
- **Onboarding Completion Rate**: Should remain high (not drop due to complexity)
- **Question Count**:
  - 1 goal: 3-4 questions
  - 2 goals: 6-8 questions total
  - 5 goals: 6-8 questions (only top 2 detailed)
- **Window Generation Quality**: Windows should clearly reflect top 2 goals
- **Performance**: Ranking interaction should be smooth (60fps)

---

## 6. ROLLBACK PROCEDURES

### If Implementation Fails:
1. **Revert git commit**:
   ```bash
   git revert HEAD
   git push origin main
   ```

2. **Restore old screens**:
   - Restore PreWorkoutNutritionContentView
   - Restore PostWorkoutNutritionContentView
   - Restore old navigation cases
   - Restore old coordinator properties

3. **Test restored version**:
   - Compile and test in simulator
   - Verify onboarding completes

### Partial Rollback (if only part fails):
- Can disable ranking screen temporarily (always show detailed questions)
- Can disable preview screen temporarily (skip directly to completion)
- Can fall back to single goal selection only

---

## 7. POTENTIAL CHALLENGES & SOLUTIONS

### Challenge 1: Drag-and-Drop Performance
**Problem**: Dragging might feel laggy with animations
**Solution**: Use `.animation(.default, value: rankedGoals)` for smooth reordering

### Challenge 2: Conditional Navigation Logic
**Problem**: Complex conditional screen flow might have bugs
**Solution**: Create helper method `nextScreenAfter(current:)` that encapsulates all logic

### Challenge 3: Preview Timeline Accuracy
**Problem**: Generating realistic preview without full window generation might be inaccurate
**Solution**: Use simplified heuristics for preview (e.g., "muscle goal = 5 windows", "sleep goal = end 3 hrs before bed")

### Challenge 4: Skip Button Behavior
**Problem**: Users might not understand what "skip" means
**Solution**: Change button text to "Use Defaults" or show brief toast after skip

### Challenge 5: Too Many Questions
**Problem**: Even with top 2 focus, 8 questions might feel long
**Solution**: Add progress indicator, keep questions on single screen where possible

---

## 8. FUTURE ENHANCEMENTS (Not in This Phase)

- [ ] Allow re-ranking goals after onboarding (in settings)
- [ ] Add goal impact preview to settings (show current plan)
- [ ] Track goal progress over time (analytics)
- [ ] Smart suggestions: "Based on your patterns, consider prioritizing Sleep"
- [ ] A/B test: Single goal vs multi-goal onboarding conversion
- [ ] Add more specific goals (e.g., "Reduce Bloating", "Improve Digestion")
- [ ] Allow users to add custom goals
- [ ] Goal conflict warnings during ranking ("These goals may conflict")

---

## PHASE 2 COMPLETE ✅

**Plan Created**: October 21, 2025

**Next Phase**: IMPLEMENTATION (Phase 3)
- Start NEW session for Phase 3
- Provide: @plan-goal-setting-refactor.md @research-goal-setting-refactor.md
- Execute steps 1-15 systematically
- Monitor context usage (stop at 60%)
- Test after EVERY step

**Estimated Implementation Time**: 3-5 agent sessions (depending on context usage)

**Files to Create**: 5-6 new view components
**Files to Modify**: 8-10 existing files
**Lines of Code**: ~1000-1500 new lines

---

*Planning completed: October 21, 2025*
*Ready for Phase 3 - Implementation (requires new session)*
