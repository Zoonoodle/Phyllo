# Research: Weight Goal Screen Unification
## For Gain Weight Goal Implementation

## Executive Summary
This research analyzes the current two-screen approach (Target Weight + Weight Loss Rate) to create a unified screen matching the provided mockup design for weight gain goals.

## Current Implementation

### Screen Structure
- **TargetWeightContentView** (OnboardingContentViews.swift:1044-1172)
  - Uses +/- buttons for weight selection
  - Shows current weight reference
  - Displays weight difference with arrows
  
- **WeightLossRateContentView** (OnboardingContentViews.swift:1174-1296)
  - 4 predefined rate cards (0.5-2.0 lbs/week)
  - Color-coded by aggressiveness
  - Timeline calculation display

### Data Flow
```swift
// Coordinator properties
var weight: Double = 70 // Current weight in kg
var goal: String = "" // "Gain Weight" for our case
var targetWeight: Double? = nil 
var weightLossRate: Double? = nil // Also used for gain rate
```

## Mockup Analysis (Image #1)

### Key UI Elements
1. **Top Section**: Two info cards
   - Left: Initial daily budget (kcal)
   - Right: Projected end date

2. **Target Weight Section**
   - Title: "What is your target weight?"
   - Value display: Large number with "lbs" unit
   - Ruler slider with tick marks (200-220 range visible)
   - Green highlight for valid range (current to max)

3. **Goal Rate Section**  
   - Title: "What is your target goal rate?"
   - Slider with "Standard (Recommended)" label
   - Weekly/Monthly gain displays (+0.6 lbs/week, +2.4 lbs/month)
   - Percentage body weight calculations

## Critical Behaviors for Gain Weight

### Slider Constraints (Images #4-6)
1. **Minimum**: Current weight (no selection below)
2. **Maximum**: Current + reasonable gain limit
3. **Visual feedback**: Green highlight shows valid range
4. **Drag behavior**: Value updates only within valid range
5. **Real-time updates**: Budget & date recalculate on drag

### Calculations Required
```swift
// Daily calorie surplus for gain
let weeklyGainLbs = selectedRate // 0.5-1.0 for gain
let dailySurplus = (weeklyGainLbs * 3500) / 7

// Timeline calculation
let totalGainLbs = targetWeight - currentWeight  
let weeksToGoal = totalGainLbs / weeklyGainLbs
let projectedDate = Date().addingTimeInterval(weeksToGoal * 7 * 86400)

// Calorie budget
let tdee = calculateTDEE() // Existing method
let dailyBudget = tdee + dailySurplus
```

## New Components Needed

### 1. Custom Ruler Slider
- Tick marks at 1 lb intervals
- Green highlight for valid range
- Smooth drag gesture handling
- Value snapping to nearest lb

### 2. Info Cards
- Rounded corners with subtle background
- Dynamic value updates
- Proper number formatting

### 3. Rate Slider
- Continuous range (0.5-1.0 lbs/week for gain)
- "Standard" marker at 0.75 lbs/week
- Dual display (weekly + monthly)

## Implementation Strategy

### View Structure
```swift
struct UnifiedWeightGoalView: View {
    // State
    @State private var targetWeight: Double
    @State private var goalRate: Double = 0.75
    
    // Computed
    var dailyBudget: Int { /* calculation */ }
    var projectedDate: Date { /* calculation */ }
    
    var body: some View {
        VStack {
            // Info cards row
            // Target weight section with ruler
            // Goal rate section with slider
        }
    }
}
```

### Gesture Handling
- Use DragGesture for ruler interaction
- Clamp values to valid range
- Update coordinator on gesture end
- Provide haptic feedback at boundaries

## Files to Modify

1. **OnboardingContentViews.swift**
   - Replace both existing screens
   - Add new UnifiedWeightGoalView

2. **OnboardingSectionData.swift**
   - Remove "Weight Loss Rate" screen
   - Rename "Target Weight" to "Weight Goal"

3. **OnboardingCoordinator.swift**
   - Update navigation logic
   - Adjust screen indices

## Edge Cases to Handle

1. **Boundary conditions**
   - Current weight = max weight
   - Very small gain targets (<5 lbs)
   - Very large gain targets (>50 lbs)

2. **User interactions**
   - Rapid dragging
   - Releasing outside valid range
   - Switching between weight/rate sliders

3. **Data consistency**
   - Ensure rate limits for gain (max 1 lb/week)
   - Validate timeline calculations
   - Handle unit conversions properly

## Dependencies
- GoalCalculationService for TDEE
- TDEECalculator for calorie math
- Firebase for data persistence
- Existing color system for theming

## Next Steps (Planning Phase)
1. Design exact slider components
2. Define animation behaviors
3. Create state management approach
4. Plan testing strategy
5. Consider migration path

---
*Research completed. Ready for Planning Phase with user input on design preferences.*