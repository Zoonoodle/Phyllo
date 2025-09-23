# Implementation Plan: Post-Onboarding Immediate Window Generation

**Branch**: `001-post-onboarding-windows` | **Date**: 2025-09-22 | **Spec**: [post-onboarding-windows-spec.md](./post-onboarding-windows-spec.md)
**Input**: Feature specification for first-day window generation

## Summary
Enable immediate app usage after onboarding by generating contextually appropriate meal windows for the remainder of the first day, with pro-rated calories and smart timing, eliminating the friction of forced morning check-in at inappropriate times.

## Technical Context
**Language/Version**: Swift 5.9 / SwiftUI 6  
**Primary Dependencies**: Firebase (Auth, Firestore), Vertex AI (Gemini)  
**Storage**: Firebase Firestore  
**Testing**: XCTest + Manual in Xcode Simulator  
**Target Platform**: iOS 17+  
**Project Type**: Mobile (iOS SwiftUI)  
**Performance Goals**: Window generation < 3 seconds  
**Constraints**: Must not break existing user flows, maintain Firebase data structure  
**Scale/Scope**: ~5 files modified, 2 new components, 300-400 LOC

## Constitution Check
*Based on NutriSync development principles from CLAUDE.md*

- [x] **Minimal Complexity**: Simple state detection and calculation logic
- [x] **User-First**: Removes friction for new users
- [x] **Data Integrity**: Preserves existing Firebase structure
- [x] **Testable**: Clear success criteria and edge cases
- [x] **Backwards Compatible**: Doesn't affect existing users
- [x] **Performance**: No additional API calls, uses existing data

## Project Structure (Brownfield - Existing Paths)

### Files to Modify
```
NutriSync/
├── Views/
│   ├── ContentView.swift                    # Entry point - detect first-time user
│   └── Onboarding/
│       └── OnboardingCompletionViewModel.swift  # Trigger window generation
├── Services/
│   ├── AI/
│   │   └── AIWindowGenerationService.swift  # Add first-day generation method
│   └── DataProvider/
│       └── FirebaseDataProvider.swift       # Add first-day flag storage
├── Models/
│   └── UserProfile.swift                    # Add firstDayCompleted flag
└── Views/Components/
    └── WelcomeBanner.swift                  # NEW - Welcome message component
```

### New Components
```
NutriSync/
└── Services/
    └── FirstDayWindowService.swift         # NEW - Handles partial day logic
```

---

## Phase 0: Research & Analysis

### Current State Analysis
1. **Entry Point**: `ContentView.swift:76` - User lands at MainTabView after onboarding
2. **Problem**: `MorningCheckInNudge` appears immediately regardless of time
3. **Data Flow**: 
   - Onboarding → Save profile → Navigate to MainTabView
   - No window generation happens automatically
   - Windows only created via morning check-in

### Technical Discoveries
- `AIWindowGenerationService` has window generation logic but no first-day handling
- `OnboardingCompletionViewModel.saveToFirebase()` is the completion point
- `UserProfile` struct needs `firstDayCompleted: Bool` field
- `ContentView` already checks `hasProfile` - can extend for first-day detection

### Edge Cases Identified
1. **Timezone changes**: Use device local time consistently
2. **Late night completion** (>8pm): Show tomorrow's plan
3. **Very late completion** (past bedtime): Show welcome + tomorrow
4. **Minimal time remaining** (<2 hours): Show tomorrow's plan

---

## Phase 1: Design & Contracts

### Data Model Changes
```swift
// UserProfile.swift - Add field
struct UserProfile {
    // ... existing fields ...
    var firstDayCompleted: Bool = false  // NEW
    var onboardingCompletedAt: Date?     // NEW - timestamp for first-day detection
}
```

### Service Contracts
```swift
// FirstDayWindowService.swift - NEW
protocol FirstDayWindowGenerating {
    func shouldGenerateFirstDayWindows(profile: UserProfile) -> Bool
    func generateFirstDayWindows(
        for profile: UserProfile,
        completionTime: Date
    ) async throws -> [MealWindow]
    func calculateProRatedCalories(
        dailyCalories: Int,
        remainingHours: Double,
        totalWakingHours: Double
    ) -> Int
}

// AIWindowGenerationService.swift - Extend
extension AIWindowGenerationService {
    func generatePartialDayWindows(
        profile: UserProfile,
        startTime: Date,
        endTime: Date,
        targetCalories: Int
    ) async throws -> [MealWindow]
}
```

### UI Components
```swift
// WelcomeBanner.swift - NEW
struct WelcomeBanner: View {
    @State private var isShowing = true
    let onDismiss: () -> Void
    
    var body: some View {
        if isShowing {
            // Banner with "Welcome! Here's your personalized first day"
            // Dismiss button
            // Auto-dismiss after 5 seconds
        }
    }
}
```

### State Management Flow
```
1. Onboarding Complete
   ↓
2. Save profile with onboardingCompletedAt timestamp
   ↓
3. Navigate to ContentView
   ↓
4. ContentView detects first-time user (firstDayCompleted == false)
   ↓
5. Trigger FirstDayWindowService
   ↓
6. Generate windows with 30-min start delay
   ↓
7. Show MainTabView with WelcomeBanner
   ↓
8. Set firstDayCompleted = true
   ↓
9. Next day: Normal morning check-in flow
```

---

## Phase 2: Task Planning (for /tasks command)

### Task Categories
1. **Data Model Updates** (1 task)
   - Modify UserProfile struct
   - Update Firebase schema

2. **Service Implementation** (2 tasks)
   - Create FirstDayWindowService
   - Extend AIWindowGenerationService

3. **UI Flow Changes** (3 tasks)
   - Modify ContentView detection logic
   - Update OnboardingCompletionViewModel
   - Create WelcomeBanner component

4. **Integration & Testing** (2 tasks)
   - Wire up components
   - Test all time scenarios

### Critical Path
```
UserProfile changes → FirstDayWindowService → ContentView integration → Testing
```

### Risk Mitigation
- **Risk**: Breaking existing users
  - **Mitigation**: Check for nil onboardingCompletedAt (existing users)
- **Risk**: Incorrect calorie calculations  
  - **Mitigation**: Add validation and min/max bounds
- **Risk**: Poor window timing
  - **Mitigation**: Comprehensive time-based testing

---

## Implementation Checkpoints

### Phase 1 Complete ✓
- [x] Research existing codebase
- [x] Identify integration points  
- [x] Design data model changes
- [x] Define service contracts
- [x] Plan UI components

### Ready for Phase 2 (/tasks)
- Data models designed
- Service interfaces defined
- UI flow documented
- Edge cases identified
- Testing strategy ready

### Success Criteria
1. New user at 2pm gets 2-3 windows within 30 seconds
2. New user at 9pm sees tomorrow's plan
3. Existing users unaffected
4. No morning check-in on day 1
5. Normal flow resumes day 2

---

## Notes & Decisions

### Why Pro-Rating?
- Scientifically accurate - maintains daily deficit/surplus goals
- Builds trust - user sees system adapts intelligently
- Prevents overeating - doesn't dump full calories in partial day

### Why 30-Minute Delay?
- Gives user time to explore app
- Prevents immediate pressure to eat
- Allows for meal prep time
- Feels more natural than instant

### Why Max 3 Windows?
- Not overwhelming for new users
- Maintains reasonable meal spacing
- Fits typical partial day scenarios
- Simplifies mental model

---

## Next Command
Run `/tasks` to generate detailed development tasks from this plan.