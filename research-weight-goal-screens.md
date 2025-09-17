# Research: Weight Goal Screens in NutriSync Onboarding

## Overview
This document analyzes the current implementation of weight goal screens in the NutriSync onboarding flow to understand how to unify the Target Weight and Weight Loss Rate screens.

## Current Implementation Analysis

### 1. Screen Structure & Navigation Flow

#### Onboarding Section: Goal Setting
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingSectionData.swift`

Current Goal Setting section screens:
```swift
.goalSetting: [
    "Goal Intro",
    "Goal Selection",        // Index 1 
    "Maintenance Strategy",  // Index 2 (only for "Maintain Weight")
    "Target Weight",         // Index 3 (skip for "Maintain Weight")
    "Weight Loss Rate",      // Index 4 (skip for "Maintain Weight")
    "Pre-Workout Nutrition", // Index 5
    "Post-Workout Nutrition" // Index 6
]
```

#### Navigation Logic
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`

Key navigation patterns:
- After Goal Selection, if "maintain weight" → jump to Maintenance Strategy (index 2)
- After Goal Selection, if "lose/gain weight" → skip to Target Weight (index 3)
- After Maintenance Strategy → jump to Pre-Workout Nutrition (index 5)
- This means Target Weight and Weight Loss Rate are skipped for maintenance goals

### 2. Current Weight Goal Screens

#### A. Target Weight Screen
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift` (lines 1044-1172)

**Key Features:**
- Displays current weight in lbs (converted from kg storage)
- Uses +/- buttons for target weight selection (1 kg increments)
- Range: 30-200 kg (66-440 lbs)
- Shows weight difference (loss/gain) with colored arrows
- Automatically sets default target based on goal type
- State managed via: `@State private var targetWeight: Double = 70`
- Saves to coordinator: `coordinator.targetWeight = newValue`

**UI Components:**
- Current weight display (read-only)
- Target weight picker with +/- buttons
- Weight difference indicator with red/green arrows
- Standard onboarding layout with title/subtitle

#### B. Weight Loss Rate Screen  
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingContentViews.swift` (lines 1174-1296)

**Key Features:**
- 4 predefined rate options: 0.5, 1.0, 1.5, 2.0 lbs per week
- Each option has title, subtitle, and description
- Color-coded based on aggressiveness (green→red)
- Calculates timeline estimate automatically
- State managed via: `@State private var selectedRate: Double = 1.0`
- Saves to coordinator: `coordinator.weightLossRate = rate`

**Rate Options:**
```swift
let rates = [
    (0.5, "Gradual", "0.5 lbs per week", "Easier to maintain, minimal muscle loss"),
    (1.0, "Moderate", "1 lb per week", "Good balance of speed and sustainability"),
    (1.5, "Aggressive", "1.5 lbs per week", "Faster results, requires more discipline"),
    (2.0, "Very Aggressive", "2 lbs per week", "Maximum safe rate, very challenging")
]
```

### 3. Data Models & Storage

#### Coordinator Properties
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`

```swift
// Weight-related properties
var weight: Double = 70 // Current weight in kg
var goal: String = "" // "Lose Weight", "Maintain Weight", "Gain Weight" 
var targetWeight: Double? = nil // Target weight in kg
var weightLossRate: Double? = nil // Rate in lbs per week
var maintenanceStrategy: String = "" // For maintain weight goal
```

#### UserGoals Model
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserGoals.swift`

```swift
struct UserGoals: Codable {
    var targetWeight: Double? // Target weight storage
    var timeline: Int? // Timeline in weeks
    // ... other properties
}
```

#### Legacy NutritionGoal Model
The codebase also has a legacy enum with associated values:
```swift
enum NutritionGoal: Identifiable, Codable {
    case weightLoss(targetPounds: Double, timeline: Int)
    case muscleGain(targetPounds: Double, timeline: Int)
    // ... other cases
}
```

### 4. Calculation Services

#### GoalCalculationService
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/GoalCalculationService.swift`

**Key Methods:**
- `calculateTDEE()` - Total Daily Energy Expenditure calculation
- `calculateTargets(for goal: GoalType)` - Nutrition targets based on goals
- `calculateWeightGoalTargets()` - Specific weight target calculations

**Weight Goal Types:**
```swift
enum GoalType {
    case specificWeightTarget(currentWeight: Double, targetWeight: Double, weeks: Int)
    case bodyComposition(currentWeight: Double, currentBF: Double?, targetBF: Double?, focus: CompositionFocus)
    case performanceOptimization(currentWeight: Double, activityLevel: ActivityLevel)
}
```

**Calculation Logic:**
- Uses 3500 calories = 1 pound rule
- Safe weight change limits: 0.5-2 lbs/week loss, 0.5-1 lb/week gain
- TDEE-based calorie adjustments
- Macro distribution based on goal type

#### TDEE Calculator
Location: `/Users/brennenprice/Documents/Phyllo/NutriSync/Utilities/TDEECalculator.swift`

**Features:**
- Mifflin-St Jeor equation for BMR
- Activity level multipliers
- Unit conversion helpers
- Used by ExpenditureView for calorie calculation

### 5. Existing Slider/Picker Implementations

#### Weight Input Pattern
Both WeightView and TargetWeightView use +/- button approach rather than sliders:
```swift
HStack(spacing: 20) {
    Button { targetWeight -= 1 } label: { 
        Image(systemName: "minus.circle.fill")
    }
    Text("\(Int(targetWeight * 2.20462))")
        .font(.system(size: 48, weight: .bold))
    Button { targetWeight += 1 } label: {
        Image(systemName: "plus.circle.fill") 
    }
}
```

#### Selection Pattern Examples
Most selection screens use button-based selection:
- Goal Selection: Radio buttons with circular selection indicators
- Rate Selection: Cards with checkmark indicators
- Activity Level: Cards with stroke highlighting

### 6. Shared Components Available

#### From SharedComponents.swift
- `OnboardingOptionButton` - For single selection with radio buttons
- `MultiSelectButton` - For multiple selections with checkboxes  
- `PrimaryButton` - Standard CTA button
- `OnboardingSectionProgressBar` - Section progress indicator

#### Design Patterns
- Consistent dark theme with white text
- Card-based selection with stroke borders
- Color coding for different intensity levels
- Standard padding and spacing (16-20px)
- Rounded corners (12-16px radius)

### 7. Data Flow Dependencies

#### Current Weight → Target Weight
- Current weight displayed as reference
- Default target set based on goal (+/- 10 lbs)
- Weight difference calculated and displayed

#### Target Weight + Rate → Timeline Calculation
```swift
if let targetWeight = coordinator.targetWeight {
    let weightDiff = abs(coordinator.weight - targetWeight) * 2.20462
    let weeks = Int(weightDiff / selectedRate)
    // Display timeline
}
```

#### Integration with Calorie Calculation
The GoalCalculationService uses these values:
```swift
case .specificWeightTarget(currentWeight: current, targetWeight: target, weeks: weeks):
    return calculateWeightGoalTargets(/*...*/)
```

### 8. Edge Cases & Validation

#### Current Validations
- Target weight range: 30-200 kg (enforced in UI)
- Rate options: Fixed to safe ranges (0.5-2.0 lbs/week)
- Timeline calculation: Automatic based on math

#### Missing Validations
- No validation for unrealistic targets (e.g., target < current for gain goal)
- No validation for timeline constraints
- No handling of zero weight difference

### 9. UI/UX Patterns

#### Visual Hierarchy
1. Title (28pt, bold, white)
2. Subtitle (17pt, 60% opacity)
3. Main content area with cards/controls
4. Secondary info (calculations, differences)
5. Navigation buttons (bottom)

#### Interaction Patterns
- Immediate feedback on selection
- Auto-save to coordinator on change
- Color coding for different states/types
- Animations for state transitions

#### Color Semantics
- Green: Conservative/safe options
- Blue: Moderate/balanced options  
- Orange: Aggressive options
- Red: Very aggressive/maximum options
- White: Selected/active state

### 10. Technical Architecture

#### State Management
- Local `@State` for UI interactions
- Coordinator binding for persistence
- `loadDataFromCoordinator()` pattern for initialization
- `isInitialized` flag to prevent multiple loads

#### View Lifecycle
- `onAppear`: Load existing data
- `onChange`: Save data immediately  
- `onDisappear`: Final save (in some cases)

#### Error Handling
- Graceful fallbacks for missing data
- Default value assignments
- Safe unwrapping of optional values

## Recommendations for Unification

### 1. Combined Screen Structure
Create a single "Weight Goal" screen that combines:
- Current weight reference (read-only)
- Target weight selection 
- Rate/timeline selection
- Real-time timeline calculation
- Progress visualization

### 2. Interaction Model
- Use existing +/- buttons for target weight (familiar pattern)
- Keep card-based selection for rate options
- Add slider as alternative for fine-tuning
- Show live timeline updates

### 3. Data Dependencies
- Maintain current coordinator properties
- Keep existing calculation logic
- Preserve navigation flow logic
- Ensure backward compatibility

### 4. Reusable Components
- Extend existing `OnboardingOptionButton` for rate selection
- Reuse target weight picker pattern from current screen
- Leverage shared color coding system
- Apply consistent layout patterns

This analysis provides the foundation for creating a unified weight goal screen that maintains the current functionality while improving the user experience through better organization and flow.