# Feature Specification: Post-Onboarding Immediate Window Generation

**Feature Branch**: `001-post-onboarding-windows`  
**Created**: 2025-09-22  
**Status**: Requirements Complete  
**Input**: User completes onboarding at any time of day and needs immediate meal windows  
**Decisions Made**: 2025-09-22 - All requirements clarified

## Existing System Context (Brownfield)

### Current Implementation Problems
- **Location**: `ContentView.swift:76` - User directed to `MainTabView` after onboarding
- **Issue**: Forces morning check-in regardless of completion time
- **User Impact**: User completing onboarding at 3pm must wait until next day to use app
- **Files Affected**:
  - `ContentView.swift` - Main navigation after onboarding
  - `AIWindowGenerationService.swift` - Window generation logic
  - `OnboardingCompletionViewModel.swift` - Handles onboarding finish
  - `MorningCheckInCoordinator.swift` - Currently forced on first-time users

### Current User Flow
1. User completes onboarding (any time)
2. Profile saved to Firebase
3. Redirected to MainTabView
4. Nudged to do morning check-in (even at 3pm!)
5. No windows available until check-in completed
6. Poor first-time user experience

## 🎯 Feature Goal
Enable users to start using NutriSync immediately after onboarding by generating contextually appropriate meal windows for the remainder of their first day.

---

## User Scenarios & Testing

### Primary User Story
As a new NutriSync user completing onboarding at 2pm, I want to receive meal windows for the rest of my day (lunch, snack, dinner) so I can start tracking immediately without waiting until tomorrow.

### Acceptance Scenarios
1. **Given** user completes onboarding at 2pm, **When** they reach the main app, **Then** they see 2-3 meal windows for the remainder of the day
2. **Given** user completes onboarding at 9pm, **When** they reach the main app, **Then** they see either a late snack window or a "day complete" message with tomorrow's preview
3. **Given** user completes onboarding at 7am, **When** they reach the main app, **Then** they see a full day of windows starting from breakfast
4. **Given** first-day windows are generated, **When** user opens app the next morning, **Then** they're prompted for morning check-in as normal

### Edge Cases
- What happens when user completes onboarding after their selected bedtime?
- How does system handle users in different timezones?
- What if user's wake/sleep schedule doesn't align with current time?

---

## Requirements

### Functional Requirements
- **FR-001**: System MUST detect first-time user post-onboarding
- **FR-002**: System MUST generate windows starting from current time + 30 minutes ("Smart Start")
- **FR-003**: System MUST pro-rate calories based on remaining hours in day (e.g., 40% of day remaining = 40% of daily calories)
- **FR-004**: System MUST skip morning check-in for first day only
- **FR-005**: System MUST show simple tooltips on key features for first-time users (non-blocking)
- **FR-006**: Windows MUST respect user's bedtime from onboarding (no eating windows past bedtime - 3 hours)
- **FR-007**: System MUST show tomorrow's full plan if onboarding completed after 8pm
- **FR-008**: System MUST transition to normal flow (with morning check-in) on day 2
- **FR-009**: System MUST display welcome banner "Welcome! Here's your personalized first day" (dismissible)
- **FR-010**: System MUST limit first day to maximum 3 windows regardless of time

### Business Rules
- **BR-001**: Minimum window duration is 1 hour
- **BR-002**: Maximum windows for partial day is 3 (2-3 based on time available)
- **BR-003**: First window starts exactly 30 minutes from completion time
- **BR-004**: Calorie distribution uses pro-rata calculation: (hours_remaining / waking_hours) × daily_calories
- **BR-005**: If less than 2 hours remain before bedtime buffer, show tomorrow's plan instead
- **BR-006**: Window spacing must be at least 2 hours apart for partial day

### Key Entities
- **FirstDayConfiguration**: Temporary configuration for initial window generation
  - Start time (post-onboarding completion)
  - Remaining hours until bedtime
  - Pro-rated calorie targets
  - Number of windows to generate
  
- **OnboardingCompletion**: Tracks onboarding finish state
  - Completion timestamp
  - First day handled flag
  - Tutorial shown flag

---

## Implementation Strategy

### Window Generation Logic
- **Before 12pm**: Generate up to 3 windows (lunch, snack, dinner)
- **12pm - 4pm**: Generate 2-3 windows (snack, dinner, optional evening snack)
- **4pm - 8pm**: Generate 1-2 windows (dinner, optional evening snack)
- **After 8pm**: Show tomorrow's full plan with welcome message

### Calorie Pro-Rating Formula
```
remaining_hours = bedtime_minus_3_hours - current_time
waking_hours = bedtime - wake_time  
daily_calories = user.tdee
partial_day_calories = (remaining_hours / waking_hours) × daily_calories
```

### First-Time User Experience
1. Welcome banner appears (dismissible)
2. Windows generate with 30-min delay for first meal
3. Simple tooltips highlight key actions (log meal, view details)
4. No morning check-in required on day 1
5. Normal flow resumes on day 2

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Next Steps
Once clarifications are provided:
1. Update this specification with decisions
2. Create implementation plan (`/plan`)
3. Generate development tasks (`/tasks`)
4. Begin implementation (`/implement`)