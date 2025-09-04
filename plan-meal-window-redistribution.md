# Meal Window Redistribution System - Implementation Plan

## Executive Summary

This plan outlines the implementation of an intelligent meal window redistribution system that automatically adjusts upcoming meal windows based on user consumption patterns. The system uses a proximity-based algorithm with threshold triggers and preview/nudge UI following the onboarding theme.

**User Decisions:**
- Algorithm: Proximity-Based (1A)
- Triggers: Threshold-based at ±25% deviation (2B)
- Safety: 3-hour bedtime buffer (3)
- Control: Preview with accept/reject nudge (4B)
- Scope: Same-day redistribution only (5A)
- Priority: Real-time redistribution, preview mode, educational explanations

---

## Phase 1: Core Algorithm Implementation (Day 1)

### 1.1 Enhanced Redistribution Engine

**File**: `NutriSync/Services/WindowRedistributionEngine.swift` (NEW)

```swift
protocol RedistributionEngine {
    func calculateRedistribution(
        trigger: RedistributionTrigger,
        windows: [MealWindow],
        constraints: RedistributionConstraints,
        currentTime: Date
    ) -> RedistributionResult
}

struct ProximityBasedEngine: RedistributionEngine {
    // Proximity-weighted distribution
    // Closer windows get more adjustment
}

struct RedistributionConstraints {
    let minCaloriesPerWindow: Int = 200
    let maxCaloriesPerWindow: Int = 1000
    let minProteinPercentage: Double = 0.7  // Preserve 70% minimum
    let bedtimeBufferHours: Double = 3.0
    let deviationThreshold: Double = 0.25   // 25% triggers redistribution
}
```

### 1.2 Redistribution Trigger System

**File**: `NutriSync/Services/RedistributionTriggerManager.swift` (NEW)

```swift
class RedistributionTriggerManager: ObservableObject {
    func evaluateTrigger(meal: LoggedMeal, window: MealWindow) -> Bool {
        // Check if deviation exceeds 25% threshold
        let deviation = calculateDeviation(meal, window)
        return abs(deviation) > 0.25
    }
    
    func handleMealLogged(_ meal: LoggedMeal) async {
        if evaluateTrigger(meal, window) {
            await proposeRedistribution()
        }
    }
}
```

### 1.3 Update WindowRedistributionManager

**File**: `NutriSync/Views/CheckIn/WindowRedistributionManager.swift` (MODIFY)

**Changes:**
- Integrate ProximityBasedEngine
- Add threshold checking
- Implement bedtime buffer protection
- Add preview generation capability

**Key Algorithm Logic:**
```swift
// Proximity weighting formula
let timeToWindow = window.startTime.timeIntervalSince(triggerWindow.endTime)
let maxTimeSpan = dayEndTime.timeIntervalSince(currentTime)
let proximityWeight = 1.0 - (timeToWindow / maxTimeSpan)
let adjustmentAmount = totalAdjustmentNeeded * proximityWeight
```

---

## Phase 2: Real-Time Integration (Day 1-2)

### 2.1 Meal Logging Hook

**File**: `NutriSync/Services/DataProvider/FirebaseDataProvider.swift` (MODIFY)

**Add to `saveMeal()` method:**
```swift
// After successful meal save
if let redistribution = await redistributionTriggerManager.evaluateMeal(meal) {
    await presentRedistributionNudge(redistribution)
}
```

### 2.2 Redistribution Preview Service

**File**: `NutriSync/Services/RedistributionPreviewService.swift` (NEW)

```swift
class RedistributionPreviewService: ObservableObject {
    @Published var pendingRedistribution: RedistributionResult?
    @Published var showingPreview: Bool = false
    
    func generatePreview(for meal: AnalyzingMeal) async -> RedistributionPreview {
        // Calculate what would happen if meal is logged
        // Return preview without applying changes
    }
}
```

---

## Phase 3: UI Implementation - Onboarding-Style Nudge (Day 2)

### 3.1 Redistribution Nudge Component

**File**: `NutriSync/Views/Components/RedistributionNudge.swift` (NEW)

**Design Matching Onboarding Theme:**
```swift
struct RedistributionNudge: View {
    let redistribution: RedistributionResult
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient background matching onboarding
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 2)
            
            VStack(spacing: 20) {
                // Icon with gentle pulse animation
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(.phylloAccent)
                    .scaleEffect(showingDetails ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                
                // Clear, friendly explanation
                VStack(spacing: 8) {
                    Text("Adjusting Your Day")
                        .font(.headline)
                        .foregroundColor(.phylloText)
                    
                    Text(redistribution.explanation)
                        .font(.subheadline)
                        .foregroundColor(.phylloTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Visual preview of changes
                RedistributionVisualization(redistribution: redistribution)
                    .frame(height: 120)
                
                // Action buttons matching onboarding style
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Text("Keep Original")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.phylloTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onAccept) {
                        Text("Apply Changes")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.phylloAccent)
                            .cornerRadius(12)
                    }
                }
                
                // Educational snippet
                Button(action: { showingDetails.toggle() }) {
                    Label("Why this adjustment?", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.phylloTextTertiary)
                }
            }
            .padding(24)
            .background(Color.phylloCard)
            .cornerRadius(20)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
}
```

### 3.2 Redistribution Visualization

**File**: `NutriSync/Views/Components/RedistributionVisualization.swift` (NEW)

```swift
struct RedistributionVisualization: View {
    let redistribution: RedistributionResult
    
    var body: some View {
        // Bar chart showing before/after for each window
        // Use smooth animations and clear labels
        // Highlight the trigger window and affected windows
    }
}
```

### 3.3 Integration in ScheduleViewModel

**File**: `NutriSync/ViewModels/ScheduleViewModel.swift` (MODIFY)

**Add:**
```swift
@Published var pendingRedistribution: RedistributionResult?
@Published var showingRedistributionNudge = false

func handleRedistributionProposal(_ result: RedistributionResult) {
    pendingRedistribution = result
    showingRedistributionNudge = true
}

func applyRedistribution() async {
    guard let redistribution = pendingRedistribution else { return }
    await dataProvider.applyRedistribution(redistribution)
    showingRedistributionNudge = false
    pendingRedistribution = nil
}
```

---

## Phase 4: Educational Explanations (Day 2-3)

### 4.1 Explanation Generator

**File**: `NutriSync/Services/RedistributionExplanationService.swift` (NEW)

```swift
class RedistributionExplanationService {
    func generateExplanation(for redistribution: RedistributionResult) -> String {
        // Create user-friendly explanations
        switch redistribution.trigger {
        case .overconsumption(let percent):
            return "You ate \(percent)% more than planned. I've reduced your upcoming meals proportionally, with larger adjustments to your next window to help balance your day."
        case .underconsumption(let percent):
            return "You ate \(percent)% less than planned. I've increased your upcoming meals to help you reach your daily goals, with more calories added to your next window."
        default:
            return generateGenericExplanation(redistribution)
        }
    }
    
    func generateEducationalTip(for pattern: RedistributionPattern) -> String {
        // Provide learning opportunities
    }
}
```

### 4.2 Learning Tips Integration

**File**: `NutriSync/Views/Components/RedistributionLearningTip.swift` (NEW)

```swift
struct RedistributionLearningTip: View {
    let pattern: RedistributionPattern
    
    var body: some View {
        // Small educational cards that appear after redistribution
        // Tips like "Try having more protein at breakfast to stay fuller longer"
    }
}
```

---

## Phase 5: Testing & Refinement (Day 3)

### 5.1 Test Scenarios

**Create test cases for:**
1. Single window overconsumption (150% of target)
2. Single window underconsumption (50% of target)
3. Multiple consecutive overconsumptions
4. Missed window handling
5. Edge cases near bedtime
6. Minimum/maximum bound enforcement

### 5.2 Compilation Testing

```bash
# Test each new file
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Services/WindowRedistributionEngine.swift \
  NutriSync/Services/RedistributionTriggerManager.swift \
  NutriSync/Services/RedistributionPreviewService.swift \
  NutriSync/Services/RedistributionExplanationService.swift

# Test UI components
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Components/RedistributionNudge.swift \
  NutriSync/Views/Components/RedistributionVisualization.swift \
  NutriSync/Views/Components/RedistributionLearningTip.swift
```

---

## Implementation Order & Timeline

### Day 1: Core Algorithm
1. Create `WindowRedistributionEngine.swift` with proximity-based logic
2. Create `RedistributionTriggerManager.swift` with threshold detection
3. Update `WindowRedistributionManager.swift` with new engine
4. Test algorithm with unit tests

### Day 2: Integration & UI
1. Integrate triggers into `FirebaseDataProvider.saveMeal()`
2. Create `RedistributionNudge.swift` with onboarding theme
3. Create `RedistributionVisualization.swift` 
4. Update `ScheduleViewModel` with nudge handling

### Day 3: Polish & Testing
1. Create `RedistributionExplanationService.swift`
2. Add educational tips
3. Comprehensive testing
4. Fix edge cases
5. Performance optimization

---

## Success Criteria

1. **Functional Requirements:**
   - ✅ Redistribution triggers at ±25% deviation
   - ✅ Proximity-based weighting works correctly
   - ✅ 3-hour bedtime buffer enforced
   - ✅ Min/max bounds respected (200-1000 calories)
   - ✅ Preview nudge appears with accept/reject

2. **User Experience:**
   - ✅ Nudge matches onboarding visual theme
   - ✅ Clear explanations for adjustments
   - ✅ Smooth animations and transitions
   - ✅ Educational tips provide value

3. **Technical Requirements:**
   - ✅ All files compile without errors
   - ✅ No performance degradation
   - ✅ Firestore updates are atomic
   - ✅ Handles edge cases gracefully

---

## Risk Mitigation

1. **Data Integrity:** Always preserve original window values
2. **User Trust:** Clear explanations and preview before applying
3. **Performance:** Debounce rapid meal entries, cache calculations
4. **Edge Cases:** Comprehensive bounds checking and validation

---

## Next Steps After Implementation

1. A/B test different threshold values (20% vs 25% vs 30%)
2. Collect user feedback on nudge design
3. Add preference controls in settings
4. Implement learning from accept/reject patterns
5. Consider multi-day redistribution for Phase 2

---

*Plan created based on user preferences: Proximity-based algorithm, 25% threshold triggers, 3-hour bedtime buffer, preview nudge with onboarding theme, same-day only redistribution.*

**PHASE 2: PLANNING COMPLETE. Start NEW session for Phase 3 (Implementation).**