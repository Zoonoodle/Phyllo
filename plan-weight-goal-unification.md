# Implementation Plan: Unified Weight Goal Screen
## For Gain Weight Goal

## Overview
Create a single unified "Weight Goal" screen that combines target weight selection and goal rate into one intuitive interface, specifically for the gain weight goal initially.

## Design Decisions (Based on User Input)

### Visual & Interaction
- **Lime Green Accent**: `Color(hex: "C0FF73")` - matching Save button
- **Animation Speed**: 0.2s (quick)
- **Haptic Feedback**: Light tap on each pound change
- **Ruler Behavior**: Auto-centers on selected value, continuous scrolling

### Weight Limits
- **Maximum Gain**: 75 lbs above current weight
- **Goal Rate Range**: 0.5-1.0 lbs/week for gain
- **Standard Rate**: 0.75 lbs/week (research-backed safe muscle gain)

### Architecture
- **Component Strategy**: Create reusable `RulerSlider` component
- **Display Format**: Show lbs/week only (not % body weight)
- **Edge Cases**: Show warning but allow extreme values
- **Timeline Display**: Keep in weeks format

## Implementation Steps

### Step 1: Create RulerSlider Component
**File**: `NutriSync/Components/RulerSlider.swift` (NEW)

```swift
struct RulerSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let validRange: ClosedRange<Double> // For green highlighting
    let step: Double = 1.0
    let onChanged: ((Double) -> Void)?
    
    // Visual properties
    let accentColor = Color(hex: "C0FF73")
    let tickHeight: CGFloat = 20
    let majorTickHeight: CGFloat = 30
}
```

**Features**:
- Horizontal scrollable ruler with tick marks
- Green highlight for valid range (current to max for gain)
- Auto-centering on release
- Smooth drag gesture with value snapping
- Haptic feedback per pound change

### Step 2: Create Info Card Component
**File**: `NutriSync/Components/InfoCard.swift` (NEW)

```swift
struct InfoCard: View {
    let title: String
    let value: String
    let isHighlighted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color(hex: "C0FF73") : Color.clear, lineWidth: 1)
        )
    }
}
```

### Step 3: Create Unified Weight Goal View
**File**: Update `OnboardingContentViews.swift`

Replace both `TargetWeightContentView` and `WeightLossRateContentView` with:

```swift
struct WeightGoalContentView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    // State
    @State private var targetWeight: Double = 0
    @State private var goalRate: Double = 0.75
    @State private var isInitialized = false
    
    // Computed properties
    var currentWeightLbs: Int {
        Int(coordinator.weight * 2.20462)
    }
    
    var targetWeightLbs: Int {
        Int(targetWeight * 2.20462)
    }
    
    var dailyCalorieBudget: Int {
        let tdee = calculateTDEE()
        let weeklyGainLbs = goalRate
        let dailySurplus = (weeklyGainLbs * 3500) / 7
        return Int(tdee + dailySurplus)
    }
    
    var projectedEndDate: Date {
        let totalGainLbs = Double(targetWeightLbs - currentWeightLbs)
        let weeksToGoal = totalGainLbs / goalRate
        return Date().addingTimeInterval(weeksToGoal * 7 * 86400)
    }
}
```

### Step 4: Update Navigation Structure
**File**: `OnboardingSectionData.swift`

```swift
// Change from:
"Target Weight",
"Weight Loss Rate",

// To:
"Weight Goal", // Combined screen
```

**File**: `OnboardingCoordinator.swift`

Update navigation indices:
- Remove special handling for separate screens
- Adjust index offsets for screens after "Weight Goal"

### Step 5: Implement Weight Range Logic

```swift
extension WeightGoalContentView {
    var weightRange: ClosedRange<Double> {
        let minWeight = 66.0 // 30 kg in lbs
        let maxWeight = 440.0 // 200 kg in lbs
        return minWeight...maxWeight
    }
    
    var validWeightRange: ClosedRange<Double> {
        if coordinator.goal == "Gain Weight" {
            let maxGain = Double(currentWeightLbs + 75)
            return Double(currentWeightLbs)...maxGain
        } else if coordinator.goal == "Lose Weight" {
            let maxLoss = Double(currentWeightLbs - 100)
            return max(66.0, maxLoss)...Double(currentWeightLbs)
        }
        return weightRange // Maintain weight
    }
    
    var rateRange: ClosedRange<Double> {
        coordinator.goal == "Gain Weight" ? 0.5...1.0 : 0.5...2.0
    }
}
```

### Step 6: Add TDEE Calculation Integration

```swift
private func calculateTDEE() -> Double {
    // Use existing TDEECalculator
    let calculator = TDEECalculator()
    let bmr = calculator.calculateBMR(
        weight: coordinator.weight,
        height: coordinator.height,
        age: coordinator.age,
        biologicalSex: coordinator.biologicalSex
    )
    
    let activityMultiplier = coordinator.getActivityMultiplier()
    return bmr * activityMultiplier
}
```

### Step 7: Add Warning System

```swift
struct WeightWarningBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
```

Show when:
- Gain > 50 lbs: "This is an ambitious goal. Consider consulting a nutritionist."
- Rate = 1.0 lbs/week: "Maximum safe gain rate selected"

### Step 8: Layout Structure

```swift
var body: some View {
    VStack(spacing: 24) {
        // Info cards
        HStack(spacing: 12) {
            InfoCard(title: "initial daily budget", 
                    value: "\(dailyCalorieBudget) kcal")
            InfoCard(title: "projected end date", 
                    value: formatDate(projectedEndDate))
        }
        .padding(.horizontal)
        
        // Target weight section
        VStack(alignment: .leading, spacing: 16) {
            Text("What is your target weight?")
                .font(.system(size: 20, weight: .semibold))
            
            Text("\(targetWeightLbs) lbs")
                .font(.system(size: 48, weight: .bold))
                .frame(maxWidth: .infinity)
            
            RulerSlider(
                value: $targetWeight,
                range: weightRange,
                validRange: validWeightRange
            )
            .frame(height: 60)
        }
        .padding(.horizontal)
        
        // Goal rate section
        VStack(alignment: .leading, spacing: 16) {
            Text("What is your target goal rate?")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Standard (Recommended)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
            
            Slider(value: $goalRate, in: rateRange, step: 0.25)
                .accentColor(Color(hex: "C0FF73"))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("+\(String(format: "%.1f", goalRate)) lbs")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Per Week")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("+\(String(format: "%.1f", goalRate * 4.33)) lbs")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Per Month")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal)
        
        Spacer()
    }
}
```

## Testing Strategy

### Unit Tests
1. Weight range calculations for gain goal
2. Calorie budget calculations
3. Timeline projections
4. Unit conversions (kg ↔ lbs)

### Manual Testing
1. **Ruler Slider**:
   - Drag below current weight → Should not update
   - Drag above max (current + 75) → Should clamp
   - Release → Should auto-center
   - Each pound change → Haptic feedback

2. **Real-time Updates**:
   - Change target weight → Budget & date update
   - Change goal rate → Budget & date update
   - Animations complete in 0.2s

3. **Edge Cases**:
   - Current weight = 440 lbs (max)
   - Target = current + 1 lb
   - Target = current + 75 lbs
   - Rate at boundaries (0.5, 1.0)

## Success Criteria
- [ ] Single unified screen replaces two separate screens
- [ ] Ruler slider prevents selection below current weight
- [ ] Green highlighting shows valid gain range
- [ ] Real-time calorie and date calculations
- [ ] Smooth animations (0.2s)
- [ ] Haptic feedback on weight changes
- [ ] Data persists to coordinator
- [ ] Warning shown for extreme values
- [ ] Compiles without errors
- [ ] Manual testing passes all scenarios

## Files to Modify
1. `OnboardingContentViews.swift` - Add new view, remove old ones
2. `OnboardingSectionData.swift` - Update screen name
3. `OnboardingCoordinator.swift` - Fix navigation indices
4. `Components/RulerSlider.swift` - NEW file
5. `Components/InfoCard.swift` - NEW file

## Migration Notes
- No existing users to migrate
- Direct replacement of both screens
- Coordinator properties remain compatible
- Firebase schema unchanged

## Next Phase
After implementation, extend to support:
- Lose Weight goal (inverse ranges)
- Maintain Weight goal (no target weight)
- Different visual feedback per goal type

---
*Plan complete. Ready for Implementation Phase.*