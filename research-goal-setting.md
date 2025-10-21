# NutriSync Goal Setting Implementation Research

**Date**: October 21, 2025  
**Thoroughness**: Very Thorough  
**Status**: Complete Analysis

---

## EXECUTIVE SUMMARY

The NutriSync goal setting system is partially implemented but has critical gaps:

1. **UI/UX**: Pre-workout and post-workout nutrition screens exist and collect data
2. **Data Collection**: Coordinator captures `preworkoutTiming` and `postworkoutTiming`
3. **Data Persistence**: ⚠️ **CRITICAL GAP**: Workout timing data is collected but **NEVER PERSISTED** to Firebase
4. **Window Generation**: Partial support exists but pre/post-workout nutrition not integrated into window generation
5. **Goal Integration**: Goal-based macro distribution exists but doesn't consider workout timing

---

## 1. ONBOARDING GOAL SETTING SCREENS

### A. UI Flow Structure

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`

```swift
// Lines 61-89: Goal Setting Section screens
.goalSetting: [
    "Your Transformation",
    "Goal Selection",
    "Trend Weight",          // Dynamically hidden for maintenance
    "Weight Goal",           // Dynamically hidden for maintenance
    "Goal Summary",
    "Pre-Workout Nutrition",  // ← WORKOUT NUTRITION SCREENS
    "Post-Workout Nutrition"  // ← WORKOUT NUTRITION SCREENS
],
```

**Order in flow**:
1. Story Section (4 screens) - App introduction
2. Basics Section (7 screens) - Height, weight, exercise, activity
3. Notice Section (2 screens) - Health disclaimer
4. **Goal Setting Section (7 screens)** ← Pre/post-workout here
5. Program Section (5 screens) - Diet, training, meals
6. Finish Section (2 screens) - Review

### B. Pre-Workout Nutrition Screen

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`  
**Lines**: 3157-3245

**Options presented**:
```swift
let timings = [
    ("30 minutes before", "Quick energy boost"),
    ("1 hour before", "Optimal for most workouts"),
    ("2 hours before", "For larger meals"),
    ("No pre-workout meal", "I prefer fasted training")
]
```

**Data flow**:
- Stores in: `coordinator.preworkoutTiming` (String)
- Default: "1 hour before"
- Component: `PreWorkoutNutritionContentView`

### C. Post-Workout Nutrition Screen

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`  
**Lines**: 3247-3310+ (partial)

**Options presented**:
```swift
let timings = [
    ("Within 30 minutes", "Maximize recovery window"),
    ("Within 1 hour", "Good for muscle recovery"),
    ("Within 2 hours", "Flexible timing"),
    ("No specific timing", "I eat when convenient")
]
```

**Data flow**:
- Stores in: `coordinator.postworkoutTiming` (String)
- Component: `PostWorkoutNutritionContentView`

### D. Navigation & Coordinator Logic

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`  
**Lines**: 830-833

```swift
case "Pre-Workout Nutrition":
    PreWorkoutNutritionContentView()
case "Post-Workout Nutrition":
    PostWorkoutNutritionContentView()
```

---

## 2. DATA MODELS - CURRENT STATE

### A. Primary User Goals Model

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserGoals.swift`

```swift
struct UserGoals: Codable {
    var primaryGoal: Goal
    var activityLevel: ActivityLevel
    var dailyCalories: Int?
    var dailyProtein: Int?
    var dailyCarbs: Int?
    var dailyFat: Int?
    var targetWeight: Double?
    var timeline: Int? // weeks
    
    enum Goal: String, CaseIterable, Codable {
        case loseWeight = "Weight Loss"
        case buildMuscle = "Build Muscle"
        case maintainWeight = "Maintain Weight"
        case improvePerformance = "Performance"
        case betterSleep = "Better Sleep"
        case overallHealth = "Overall Health"
    }
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case athlete = "Athlete"
    }
}
```

**❌ MISSING**: No `preworkoutTiming` or `postworkoutTiming` fields

### B. User Profile Model

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserProfile.swift`  
**Lines**: 93-125

```swift
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var gender: Gender
    var height: Double // in inches
    var weight: Double // in pounds
    var activityLevel: ActivityLevel
    var primaryGoal: NutritionGoal
    var dietaryPreferences: [String]
    var dietaryRestrictions: [String]
    var dailyCalorieTarget: Int
    var dailyProteinTarget: Int
    var dailyCarbTarget: Int
    var dailyFatTarget: Int
    var preferredMealTimes: [String]
    var micronutrientPriorities: [String]
    
    // Schedule preferences
    var earliestMealHour: Int?
    var latestMealHour: Int?
    var mealsPerDay: Int?
    var workSchedule: WorkSchedule = .standard
    var typicalWakeTime: Date?
    var typicalSleepTime: Date?
    var fastingProtocol: FastingProtocol = .none
    var macroProfile: MacroProfile?
    
    // Tracking
    var firstDayCompleted: Bool = false
    var onboardingCompletedAt: Date?
}
```

**❌ MISSING**: No `preworkoutTiming` or `postworkoutTiming` fields

### C. Onboarding Progress Model (Temporary Storage)

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/OnboardingProgress.swift`  
**Lines**: 22-62

```swift
struct OnboardingProgress: Codable {
    let userId: String
    var currentSection: Int
    var currentStep: Int
    var completedSections: Set<Int>
    
    // Section 1-5 fields...
    var trainingType: String?  // "Lifting", "Cardio", etc.
    
    // ❌ MISSING:
    // var preworkoutTiming: String?
    // var postworkoutTiming: String?
}
```

### D. Onboarding Coordinator Temporary Storage

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`  
**Lines**: 120-122

```swift
// Workout data
var preworkoutTiming: String = ""
var postworkoutTiming: String = ""
```

**🔴 CRITICAL**: These are `@Observable` properties in the coordinator but:
- Are NOT saved to `OnboardingProgress`
- Are NOT saved to `UserProfile`
- Are NOT saved to `UserGoals`
- Are LOST when onboarding completes

---

## 3. WINDOW GENERATION & MACRO DISTRIBUTION

### A. Window Purpose Enum

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/MealWindow.swift`  
**Lines**: 138-146

```swift
enum WindowPurpose: String, CaseIterable, Codable {
    case preWorkout = "pre-workout"
    case postWorkout = "post-workout"
    case sustainedEnergy = "sustained-energy"
    case recovery = "recovery"
    case metabolicBoost = "metabolic-boost"
    case sleepOptimization = "sleep-optimization"
    case focusBoost = "focus-boost"
}
```

### B. Macro Distribution by Window Purpose

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/MacroCalculationService.swift`  
**Lines**: 154-175

```swift
static let windowDistributions: [WindowPurpose: (protein: Double, carbs: Double, fat: Double)] = [
    // Pre-Workout: High carbs for fuel, low fat to avoid digestion issues
    .preWorkout: (protein: 0.20, carbs: 0.60, fat: 0.20),
    
    // Post-Workout: High protein for recovery, high carbs for glycogen replenishment
    .postWorkout: (protein: 0.40, carbs: 0.45, fat: 0.15),
    
    // Other purposes...
    .sustainedEnergy: (protein: 0.25, carbs: 0.45, fat: 0.30),
    .recovery: (protein: 0.35, carbs: 0.40, fat: 0.25),
    .metabolicBoost: (protein: 0.30, carbs: 0.40, fat: 0.30),
    .sleepOptimization: (protein: 0.30, carbs: 0.25, fat: 0.45),
    .focusBoost: (protein: 0.30, carbs: 0.40, fat: 0.30)
]
```

### C. First Day Window Configuration

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/FirstDayConfiguration.swift`  
**Lines**: 206-241

```swift
enum WindowPurpose: String, Codable {
    case preWorkout = "preWorkout"
    case postWorkout = "postWorkout"
    case sustainedEnergy = "sustainedEnergy"
    case recovery = "recovery"
    case metabolicBoost = "metabolicBoost"
    case sleepOptimized = "sleepOptimized"
    
    var macroDistribution: (proteinRatio: Double, carbRatio: Double, fatRatio: Double) {
        switch self {
        case .preWorkout:
            return (0.20, 0.60, 0.20)
        case .postWorkout:
            return (0.40, 0.45, 0.15)
        case .sustainedEnergy:
            return (0.25, 0.45, 0.30)
        case .recovery:
            return (0.35, 0.40, 0.25)
        case .metabolicBoost:
            return (0.30, 0.40, 0.30)
        case .sleepOptimized:
            return (0.30, 0.25, 0.45)
        }
    }
}
```

### D. Window Name Generator for Pre/Post-Workout

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift`  
**Lines**: 70-127

```swift
static func generate(context: Context) -> String {
    // Priority order for naming
    let name: String
    if context.isPreWorkout {
        name = preWorkoutName(context)
    } else if context.isPostWorkout {
        name = postWorkoutName(context)
    } else if context.isFirstMeal {
        name = firstMealName(context)
    }
    // ...
}

private static func preWorkoutName(_ context: Context) -> String {
    switch context.userGoal {
    case .buildMuscle: return "Power Prime"
    case .improvePerformance: return "Performance"
    case .loseWeight: return "Pre-Workout"
    case .betterSleep: return "Active Fuel"
    case .maintainWeight, .overallHealth: return "Pre-Active"
    }
}

private static func postWorkoutName(_ context: Context) -> String {
    let baseNames = ["Recovery", "Post-Workout", "Anabolic", "Recovery"]
    if context.timeOfDay == .lateNight {
        return "Night Recovery"
    }
    return baseNames.randomElement() ?? "Recovery"
}
```

---

## 4. FIREBASE DATA STRUCTURE

### A. Current Schema for Goals

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/DataProvider/FirebaseDataProvider.swift`  
**Lines**: 1543-1570

```
users/{userId}/
  └── goals/
      └── current
          ├── primaryGoal: "Weight Loss" | "Build Muscle" | etc.
          ├── activityLevel: "Sedentary" | "Lightly Active" | etc.
          ├── dailyCalories: number
          ├── dailyProtein: number
          ├── dailyCarbs: number
          ├── dailyFat: number
          ├── targetWeight: number (optional)
          └── timeline: number (weeks, optional)
```

### B. Current Schema for User Profile

```
users/{userId}/
  └── profile/
      └── current
          ├── id: uuid
          ├── name: string
          ├── age: number
          ├── gender: "male" | "female" | etc.
          ├── height: number (inches)
          ├── weight: number (pounds)
          ├── activityLevel: string
          ├── primaryGoal: object (NutritionGoal)
          ├── dietaryPreferences: [string]
          ├── dailyCalorieTarget: number
          ├── dailyProteinTarget: number
          ├── dailyCarbTarget: number
          ├── dailyFatTarget: number
          ├── earliestMealHour: number (optional)
          ├── latestMealHour: number (optional)
          ├── mealsPerDay: number (optional)
          ├── workSchedule: string
          ├── typicalWakeTime: timestamp
          ├── typicalSleepTime: timestamp
          ├── fastingProtocol: string
          ├── macroProfile: object (optional)
          ├── firstDayCompleted: boolean
          └── onboardingCompletedAt: timestamp
```

### C. Meal Windows Structure

```
users/{userId}/
  └── windows/
      └── {date}/
          ├── id: uuid
          ├── name: string
          ├── startTime: timestamp
          ├── endTime: timestamp
          ├── targetCalories: number
          ├── targetProtein: number
          ├── targetCarbs: number
          ├── targetFat: number
          ├── purpose: "pre-workout" | "post-workout" | "recovery" | etc.
          ├── flexibility: "strict" | "moderate" | "flexible"
          ├── type: "regular" | "snack" | "shake" | "light"
          ├── rationale: string (optional)
          ├── foodSuggestions: [string]
          ├── micronutrientFocus: [string]
          ├── tips: [string]
          └── consumed: object
```

---

## 5. DATA FLOW & PERSISTENCE GAPS

### Current Flow (with gaps marked):

```
1. User enters Pre-Workout Nutrition screen
   ↓
2. PreWorkoutNutritionContentView stores selection in coordinator.preworkoutTiming
   ↓
3. User enters Post-Workout Nutrition screen
   ↓
4. PostWorkoutNutritionContentView stores selection in coordinator.postworkoutTiming
   ↓
5. User reaches Finish section
   ↓
6. OnboardingCoordinator.completeOnboarding() is called
   ↓
7. Calls buildUserProfile() → creates UserProfile (BUT DOESN'T INCLUDE WORKOUT DATA)
   ↓
8. Calls buildUserGoals() → creates UserGoals (BUT DOESN'T INCLUDE WORKOUT DATA)
   ↓
9. FirebaseDataProvider.createUserProfile() saves both
   ↓
10. ❌ CRITICAL: preworkoutTiming and postworkoutTiming are NEVER saved anywhere
    ❌ Data is LOST when onboarding completes
```

### The Missing Link - buildUserProfile() Method

**File**: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`  
**Lines**: 375-484

```swift
private func buildUserProfile() -> UserProfile {
    // ... lots of code for parsing and calculating ...
    
    // ❌ THIS IS THE GAP:
    // No code saves coordinator.preworkoutTiming or coordinator.postworkoutTiming
    // They simply vanish when this function returns
    
    var profile = UserProfile(
        id: UUID(),
        name: "User",
        age: 30,
        gender: .male,
        height: heightInInches,
        weight: weightInPounds,
        activityLevel: ActivityLevel(rawValue: activityLevel) ?? .moderatelyActive,
        primaryGoal: nutritionGoal,
        dietaryPreferences: Array(dietaryRestrictions),
        dietaryRestrictions: Array(dietaryRestrictions),
        // ... other fields ...
        // ❌ NO preworkoutTiming field
        // ❌ NO postworkoutTiming field
    )
    
    return profile
}
```

---

## 6. ALL FILES THAT REFERENCE WORKOUT NUTRITION

### Currently Implemented:

1. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/WorkoutNutritionView.swift`**
   - Legacy workout nutrition view (may be deprecated)
   - Lines: 1-185
   - Alternative UI with different options

2. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift`**
   - PreWorkoutNutritionContentView: Lines 3157-3245
   - PostWorkoutNutritionContentView: Lines 3247-3310+

3. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`**
   - Temporary storage: Lines 121-122
   - Navigation cases: Lines 830-833
   - Saves temporary data but doesn't persist: ❌

4. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`**
   - Screen definitions: Lines 87-88
   - Flow structure definition

### Infrastructure (doesn't use workout data):

5. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Models/MealWindow.swift`**
   - Has WindowPurpose enum with pre/post-workout
   - But doesn't track user's preference for WHEN they eat pre/post-workout

6. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Services/FirstDayWindowService.swift`**
   - Has pre/post-workout window generation logic
   - But doesn't know user's preferred timing

7. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift`**
   - Has window naming for pre/post-workout
   - But doesn't know user's preferred timing

8. **`/Users/brennenprice/Documents/Phyllo/NutriSync/Services/MacroCalculationService.swift`**
   - Has macro distributions for pre/post-workout windows
   - But doesn't know user's preferred timing

---

## 7. EDGE CASES & DEPENDENCIES DISCOVERED

### A. Timing Option Inconsistency

**Pre-Workout Options**:
- "30 minutes before"
- "1 hour before"
- "2 hours before"
- "No pre-workout meal"

**Post-Workout Options**:
- "Within 30 minutes"
- "Within 1 hour"
- "Within 2 hours"
- "No specific timing"

**Problem**: These are human-readable strings. No enum or validation exists.

### B. Goal-Dependent Behavior Not Implemented

Pre-workout/post-workout preferences should influence:
- Window timing based on goal (muscle gain needs post-workout faster)
- Macro distribution (already exists, but not triggered by user preference)
- Food suggestions (could be optimized)

**Current**: Window purposes are ASSIGNED BY AI but don't consider user preferences.

### C. Training Plan Mismatch

**File**: `TrainingPlanView.swift` collects:
- "None or Relaxed Activity"
- "Lifting"
- "Cardio"
- "Cardio & Lifting"

**But doesn't connect to**:
- Workout nutrition preferences
- Window generation for workouts

**Gap**: `trainingType` and `preworkoutTiming`/`postworkoutTiming` are separate silos.

### D. No Workout Timing in Windows

When a window is marked as `purpose: .preWorkout`, there's no data about:
- What time the user prefers to work out
- When they prefer to eat relative to that time
- Whether this should be factored into window scheduling

---

## 8. CURRENT FIREBASE SCHEMA DEFICIENCIES

### A. UserGoals Missing Fields

Should add:
```swift
struct UserGoals: Codable {
    // ... existing fields ...
    var preworkoutTiming: String?         // "30 minutes before", etc.
    var postworkoutTiming: String?        // "Within 30 minutes", etc.
    var trainingType: String?             // "Lifting", "Cardio", "Cardio & Lifting"
    var trainingFrequency: String?        // "3x per week", "5x per week", etc.
}
```

### B. UserProfile Missing Fields

Could optionally add:
```swift
struct UserProfile: Codable {
    // ... existing fields ...
    var preworkoutTiming: String?
    var postworkoutTiming: String?
}
```

### C. Firestore Collection Path

Proposed structure:
```
users/{userId}/
  └── goals/
      └── current/
          ├── primaryGoal: string
          ├── activityLevel: string
          ├── preworkoutTiming: string        // NEW
          ├── postworkoutTiming: string       // NEW
          ├── trainingType: string            // NEW (or move from profile)
          └── ... other fields ...
```

---

## 9. DEPENDENCIES & INTEGRATION POINTS

### Services that would use workout data:

1. **FirstDayWindowService.swift**
   - Would need to know user's workout preferences
   - Could schedule pre/post-workout windows appropriately
   - Currently hardcodes purposes based on time of day

2. **AIWindowGenerationService.swift**
   - Window naming already supports pre/post-workout
   - Could prioritize these if user has preferences
   - Would need access to user's training type and preferences

3. **MacroCalculationService.swift**
   - Already has macro profiles for pre/post-workout
   - Would need to know when to apply them
   - Currently applied based on window purpose (which is AI-determined)

4. **WindowRedistributionEngine.swift**
   - Might need to be workout-aware
   - If user misses pre-workout, should redistribute differently
   - Needs to consider workout timing when redistributing

5. **FirebaseDataProvider.swift**
   - Needs to load/save workout preferences
   - Currently saves profile but doesn't persist workout data

---

## 10. CURRENT FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────┐
│ Onboarding Started                                      │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │ NutriSyncOnboardingViewModel
        │ @Observable state
        ├─ preworkoutTiming: ""       ← Stores here
        ├─ postworkoutTiming: ""      ← Stores here
        ├─ trainingPlan: ""
        └─ ... other fields ...
        
        │
        ├─→ Pre-Workout Nutrition Screen
        │    └─→ User selects option
        │         └─→ coordinator.preworkoutTiming = selection
        │
        ├─→ Post-Workout Nutrition Screen
        │    └─→ User selects option
        │         └─→ coordinator.postworkoutTiming = selection
        │
        ├─→ Training Plan Screen
        │    └─→ User selects training type
        │         └─→ coordinator.trainingPlan = selection
        │
        └─→ Onboarding Complete
             │
             └─→ completeOnboarding()
                  │
                  ├─→ buildUserProfile()
                  │    │
                  │    ├─ Uses: coordinator.trainingPlan ✓
                  │    ├─ Uses: coordinator.preworkoutTiming ❌ LOST
                  │    ├─ Uses: coordinator.postworkoutTiming ❌ LOST
                  │    │
                  │    └─→ Returns: UserProfile (without workout data)
                  │
                  ├─→ buildUserGoals()
                  │    └─→ Returns: UserGoals (without workout data)
                  │
                  └─→ FirebaseDataProvider.createUserProfile(profile, goals)
                       │
                       ├─→ Save profile to: users/{uid}/profile/current
                       │    └─ ❌ No workout timing data
                       │
                       └─→ Save goals to: users/{uid}/goals/current
                            └─ ❌ No workout timing data
```

---

## KEY FINDINGS

### Critical Issues:

1. **Data is Collected but Not Persisted**
   - Pre-workout timing: Collected but never saved to Firebase
   - Post-workout timing: Collected but never saved to Firebase
   - These selections are completely lost after onboarding

2. **Missing Model Fields**
   - UserGoals struct has no fields for workout preferences
   - UserProfile struct has no fields for workout preferences
   - OnboardingProgress struct has no fields for workout preferences

3. **No Integration with Window Generation**
   - Window purposes (pre-workout, post-workout) are assigned by AI
   - User preferences don't influence this assignment
   - Macros are calculated but user timing preferences are unknown

4. **Incomplete Training Integration**
   - TrainingPlanView collects training type
   - Pre/Post-Workout screens collect timing preferences
   - But these are not connected in the data model

### Positive Elements:

1. **UI/UX is complete** - Screens exist and collect data properly
2. **Window purposes are defined** - pre-workout and post-workout have special handling
3. **Macro distributions exist** - pre/post-workout macros are science-backed
4. **Window naming logic** - Pre/post-workout windows have appropriate names
5. **Coordinator structure** - Temporary storage in @Observable coordinator works well

---

## RECOMMENDATIONS FOR IMPLEMENTATION

When implementing goal-based window generation with workout nutrition:

1. Add fields to UserGoals model (or create new WorkoutPreferences struct)
2. Update OnboardingProgress to track workout data
3. Modify buildUserProfile() to save workout data
4. Add fields to Firebase schema
5. Update FirstDayWindowService to consider user preferences
6. Connect TrainingPlanView data with workout nutrition screens
7. Use macro distributions based on user's stated preferences

