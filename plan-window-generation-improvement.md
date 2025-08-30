# Plan: Window Generation System Improvement
## Unified Service with Night Schedule Support

**Created:** 2025-08-30  
**Based on:** research-window-naming-workout-issue.md  
**User Preferences:** Quick fix → Consolidation, Hybrid naming, Flexible workout windows, Night schedule priority

---

## 🎯 Objectives

1. Replace dual service architecture with single AIWindowGenerationService
2. Implement hybrid contextual window naming
3. Add comprehensive night shift/late schedule support
4. Create flexible workout window generation (4-6 windows)
5. Handle midnight crossover edge cases
6. Implement logging system for name quality review

---

## 📋 Implementation Steps

### Phase 1: Service Consolidation (Immediate Fix)

#### Step 1.1: Update MorningCheckInView Reference
**File:** `NutriSync/Views/CheckIn/MorningCheckInView.swift:185`
```swift
// Change from:
WindowGenerationService.shared.generateWindows(...)
// To:
AIWindowGenerationService.shared.generateWindows(...)
```

#### Step 1.2: Verify AIWindowGenerationService Has All Features
**File:** `NutriSync/Services/AIWindowGenerationService.swift`
- [ ] Confirm workout detection logic exists (lines 261-276)
- [ ] Verify name validation logic (lines 355-494)
- [ ] Check prompt quality (lines 214-244)

#### Step 1.3: Test Quick Fix
- [ ] Run morning check-in flow
- [ ] Verify meaningful window names
- [ ] Confirm workout windows generate (4-5 windows)

### Phase 2: Night Schedule Enhancement

#### Step 2.1: Add Schedule Type Detection
**File:** `NutriSync/Services/AIWindowGenerationService.swift`
```swift
enum ScheduleType {
    case earlyBird      // Wake: 4-7am
    case standard       // Wake: 7-10am  
    case nightOwl       // Wake: 10am-2pm
    case nightShift     // Wake: 2pm+ or sleep during day
    
    static func detect(wakeTime: Date, bedTime: Date) -> ScheduleType {
        let hour = Calendar.current.component(.hour, from: wakeTime)
        let sleepHour = Calendar.current.component(.hour, from: bedTime)
        
        if sleepHour >= 4 && sleepHour <= 10 { // Sleep during day
            return .nightShift
        } else if hour >= 14 { // Wake after 2pm
            return .nightShift
        } else if hour >= 10 {
            return .nightOwl
        } else if hour < 7 {
            return .earlyBird
        }
        return .standard
    }
}
```

#### Step 2.2: Schedule-Aware Window Generation
```swift
// Add to prompt based on schedule type
switch scheduleType {
case .nightShift:
    """
    CRITICAL: User works night shift or has nocturnal schedule.
    - First window should be their "breakfast" even if at 8pm
    - Respect their biological clock (their morning is evening time)
    - Pre-work window if they work nights
    - Avoid names like "dinner" for their first meal
    - Use functional names: "First Meal", "Pre-Shift Energy", "Mid-Shift Fuel"
    """
case .nightOwl:
    """
    User is a night owl (late riser).
    - Compress morning windows or skip if waking after 11am
    - Focus on afternoon/evening optimization
    - Later workout windows are normal for this user
    """
// ... other cases
}
```

### Phase 3: Hybrid Contextual Naming System

#### Step 3.1: Context-Aware Name Generator
```swift
struct WindowNameGenerator {
    struct Context {
        let windowIndex: Int
        let totalWindows: Int
        let scheduleType: ScheduleType
        let isPreWorkout: Bool
        let isPostWorkout: Bool
        let timeOfDay: TimeOfDay
        let userGoal: UserGoal
        let isFirstMeal: Bool
        let isLastMeal: Bool
    }
    
    static func generate(context: Context) -> String {
        // Priority order for naming
        if context.isPreWorkout {
            return preWorkoutName(context)
        } else if context.isPostWorkout {
            return postWorkoutName(context)
        } else if context.isFirstMeal {
            return firstMealName(context)
        } else if context.isLastMeal {
            return lastMealName(context)
        } else {
            return functionalName(context)
        }
    }
    
    private static func preWorkoutName(_ context: Context) -> String {
        switch context.userGoal {
        case .buildMuscle:
            return "Anabolic Primer"
        case .improvePerformance:
            return "Performance Fuel"
        case .loseWeight:
            return "Pre-Training Energy"
        default:
            return "Pre-Workout Power"
        }
    }
    
    private static func postWorkoutName(_ context: Context) -> String {
        let baseNames = [
            "Recovery Window",
            "Post-Training Recovery", 
            "Anabolic Window",
            "Muscle Recovery"
        ]
        // Add time context for late workouts
        if context.timeOfDay == .lateNight {
            return "Night Recovery"
        }
        return baseNames.randomElement()!
    }
    
    private static func firstMealName(_ context: Context) -> String {
        switch context.scheduleType {
        case .nightShift:
            return "First Meal" // Not "breakfast" at 8pm
        case .nightOwl:
            return "Late Morning Fuel"
        default:
            return "Morning Foundation"
        }
    }
}
```

#### Step 3.2: Fallback Name Validation
```swift
struct WindowNameValidator {
    static let genericPatterns = [
        "Window \\d+",
        "Meal \\d+",
        "Eating Window \\d+",
        "Period \\d+"
    ]
    
    static func isGeneric(_ name: String) -> Bool {
        for pattern in genericPatterns {
            if name.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
    
    static func logForReview(_ window: MealWindow, reason: String) {
        // Log to Firebase for manual review
        let log = [
            "windowName": window.name,
            "reason": reason,
            "timestamp": Date(),
            "userId": Auth.auth().currentUser?.uid ?? "unknown",
            "context": [
                "startTime": window.startTime,
                "windowType": window.windowType
            ]
        ]
        Firestore.firestore()
            .collection("windowNameReviews")
            .addDocument(data: log)
    }
}
```

### Phase 4: Flexible Workout Window Logic

#### Step 4.1: Enhanced Workout Detection
```swift
struct WorkoutParser {
    static func parseWorkouts(from activities: [String]) -> [WorkoutInfo] {
        var workouts: [WorkoutInfo] = []
        
        for activity in activities {
            // Enhanced regex for various formats
            let patterns = [
                "workout.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", // "workout 5:30pm"
                "gym.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",     // "gym 6am"
                "training.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?", // "training 7pm"
                "exercise.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?"  // "exercise 5:00am"
            ]
            
            for pattern in patterns {
                if let match = activity.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                    // Extract time and create WorkoutInfo
                    let workout = parseWorkoutTime(from: activity)
                    workouts.append(workout)
                    break
                }
            }
        }
        
        return workouts
    }
    
    struct WorkoutInfo {
        let time: Date
        let isLateNight: Bool  // After 8pm
        let isFasted: Bool      // Before 8am with no prior window
        let intensity: WorkoutIntensity
    }
}
```

#### Step 4.2: Dynamic Window Count
```swift
func determineWindowCount(workouts: [WorkoutInfo], scheduleType: ScheduleType) -> Int {
    let baseWindows = 3
    var additionalWindows = 0
    
    for workout in workouts {
        if workout.isLateNight {
            // Late workout needs recovery window that might cross midnight
            additionalWindows += 2 // Pre + extended post
        } else if workout.isFasted {
            // Fasted workout needs careful fueling
            additionalWindows += 2 // Light pre + substantial post
        } else {
            // Standard workout
            additionalWindows += 1 // Combined pre/post window
        }
    }
    
    // Cap at 6 windows max
    return min(baseWindows + additionalWindows, 6)
}
```

### Phase 5: Midnight Crossover Handling

#### Step 5.1: Timeline Correction
```swift
extension MealWindow {
    var crossesMidnight: Bool {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startTime)
        let endDay = calendar.startOfDay(for: endTime)
        return startDay != endDay
    }
    
    func splitAtMidnight() -> [MealWindow] {
        guard crossesMidnight else { return [self] }
        
        let midnight = Calendar.current.startOfDay(for: endTime)
        
        // Window before midnight
        let beforeMidnight = MealWindow(
            id: "\(id)_pre",
            name: "\(name) (Evening)",
            startTime: startTime,
            endTime: midnight,
            // ... copy other properties
        )
        
        // Window after midnight  
        let afterMidnight = MealWindow(
            id: "\(id)_post",
            name: "\(name) (Continued)",
            startTime: midnight,
            endTime: endTime,
            // ... copy other properties
        )
        
        return [beforeMidnight, afterMidnight]
    }
}
```

#### Step 5.2: Night Shift Timeline Display
```swift
// Special timeline for night workers
struct NightShiftTimelineView: View {
    let windows: [MealWindow]
    let currentDate: Date
    
    var body: some View {
        // Show 24-hour view starting from wake time
        // Don't reset at midnight for night shift workers
        TimelineView(.periodic(from: wakeTime, by: 3600)) { context in
            // Custom rendering that respects biological time
        }
    }
}
```

### Phase 6: Delete WindowGenerationService

#### Step 6.1: Remove Service File
```bash
rm NutriSync/Services/WindowGenerationService.swift
```

#### Step 6.2: Update All References
Search and replace all imports and usages:
- [ ] MorningCheckInView.swift
- [ ] Any other files importing WindowGenerationService

#### Step 6.3: Clean Up Tests
Remove or update any tests for WindowGenerationService

---

## 🧪 Testing Requirements

### Core Functionality Tests
1. **Standard Schedule**
   - Morning check-in → 3-4 meaningful windows
   - Names match time and purpose
   
2. **Workout Scenarios**
   - Early morning workout → Pre-workout + post-workout windows
   - Evening workout → Proper recovery window
   - Late night workout (10pm) → Recovery window crosses midnight correctly

3. **Night Shift Worker**
   - Wake at 6pm → First window named appropriately (not "dinner")
   - Sleep at 10am → Last window before sleep
   - Timeline displays correctly across midnight

4. **Night Owl**
   - Wake at noon → Compressed morning, focus on afternoon/evening
   - Late workout → Handled appropriately

### Edge Case Tests
1. **Multiple Workouts**
   - Two workouts → 5-6 windows total
   - Workouts close together → Merged recovery window

2. **Midnight Crossover**
   - Window 11pm-1am → Split or displayed correctly
   - Timeline visualization → No confusion at date boundary

3. **Name Quality**
   - No "Window 1", "Window 2" names
   - Context-appropriate hybrid names
   - Failed names logged for review

### Manual Verification Checklist
- [ ] Morning check-in generates quality names
- [ ] Workout detection works from planned activities
- [ ] Night shift schedule recognized and handled
- [ ] Timeline displays correctly for all schedule types
- [ ] Generic names trigger logging
- [ ] Old service completely removed

---

## 📊 Success Metrics

1. **Window Name Quality**
   - 0% generic names ("Window 1", etc.)
   - 90%+ contextually appropriate names
   - <10% names need manual review

2. **Schedule Support**
   - Night shift workers get appropriate windows
   - Night owls get compressed morning windows
   - All schedules see correct timeline

3. **Workout Handling**
   - 100% of workouts detected from activities
   - Appropriate pre/post windows generated
   - Late night workouts handled correctly

4. **Technical Metrics**
   - Single service (no duplication)
   - <5 second generation time
   - Proper error handling and logging

---

## 🚀 Rollback Plan

If issues arise:
1. Revert MorningCheckInView to use WindowGenerationService
2. Keep both services temporarily
3. Debug and fix AIWindowGenerationService
4. Retry migration

---

## 📝 Future Enhancements

1. **Machine Learning**
   - Learn from user's actual eating patterns
   - Adjust window names based on feedback
   
2. **Seasonal Adjustments**
   - Summer vs winter schedules
   - Holiday handling
   
3. **Social Integration**
   - Planned social meals
   - Date night windows

4. **Advanced Night Shift**
   - Rotating shift support
   - Jet lag recovery mode

---

## Next Steps

1. Begin with Phase 1 (Quick Fix) - immediate testing
2. Implement Phase 2-3 (Night schedules + Naming) 
3. Test thoroughly with edge cases
4. Delete old service (Phase 6)
5. Monitor logs for name quality issues
6. Iterate based on user feedback

**Estimated Time:** 2-3 hours for full implementation