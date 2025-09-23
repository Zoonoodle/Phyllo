# Tasks: Post-Onboarding Immediate Window Generation

**Input**: Design documents from `post-onboarding-windows-spec.md` and `post-onboarding-windows-plan.md`
**Prerequisites**: Spec complete ✓, Plan complete ✓
**Branch**: `001-post-onboarding-windows`

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Context (Brownfield iOS Project)
- **Main Project**: `/Users/brennenprice/Documents/Phyllo/NutriSync/`
- **Views**: `NutriSync/Views/`
- **Services**: `NutriSync/Services/`
- **Models**: `NutriSync/Models/`

---

## Phase 3.1: Data Model Updates

- [ ] T001 Add firstDayCompleted and onboardingCompletedAt fields to UserProfile struct in `NutriSync/Models/UserProfile.swift`
- [ ] T002 Update FirebaseDataProvider to handle new UserProfile fields in `NutriSync/Services/DataProvider/FirebaseDataProvider.swift`
- [ ] T003 [P] Create FirstDayConfiguration struct in `NutriSync/Models/FirstDayConfiguration.swift`

## Phase 3.2: Service Implementation

- [ ] T004 Create FirstDayWindowService class in `NutriSync/Services/FirstDayWindowService.swift`
- [ ] T005 Implement shouldGenerateFirstDayWindows logic in FirstDayWindowService
- [ ] T006 Implement calculateProRatedCalories method with formula: (remaining_hours / waking_hours) × daily_calories
- [ ] T007 Add generatePartialDayWindows method to AIWindowGenerationService in `NutriSync/Services/AI/AIWindowGenerationService.swift`
- [ ] T008 Implement window count logic based on time (Before 12pm: 3, 12-4pm: 2-3, 4-8pm: 1-2, After 8pm: tomorrow)

## Phase 3.3: UI Components

- [ ] T009 [P] Create WelcomeBanner component in `NutriSync/Views/Components/WelcomeBanner.swift`
- [ ] T010 [P] Implement auto-dismiss after 5 seconds and manual dismiss in WelcomeBanner
- [ ] T011 [P] Create simple tooltip overlays for first-time features in `NutriSync/Views/Components/FirstTimeTooltips.swift`

## Phase 3.4: Flow Integration

- [ ] T012 Modify ContentView to detect first-time users (!firstDayCompleted) in `NutriSync/Views/ContentView.swift:99`
- [ ] T013 Add first-day window generation trigger in ContentView after profile check
- [ ] T014 Update OnboardingCompletionViewModel to set onboardingCompletedAt timestamp in `NutriSync/ViewModels/OnboardingCompletionViewModel.swift`
- [ ] T015 Prevent morning check-in nudge on first day by checking firstDayCompleted in NudgeManager

## Phase 3.5: Edge Case Handling

- [ ] T016 [P] Implement late evening logic (>8pm shows tomorrow) in FirstDayWindowService
- [ ] T017 [P] Add minimum time validation (<2 hours before bedtime) in FirstDayWindowService  
- [ ] T018 [P] Handle timezone considerations using device local time consistently

## Phase 3.6: State Management

- [ ] T019 Update MainTabViewModel to handle first-day state in `NutriSync/ViewModels/MainTabViewModel.swift`
- [ ] T020 Set firstDayCompleted flag after successful window generation
- [ ] T021 Ensure next-day transition to normal morning check-in flow

## Phase 3.7: Testing & Validation

- [ ] T022 Test onboarding completion at 9am (expect 3 windows)
- [ ] T023 Test onboarding completion at 2pm (expect 2-3 windows)
- [ ] T024 Test onboarding completion at 7pm (expect 1-2 windows)
- [ ] T025 Test onboarding completion at 9pm (expect tomorrow's plan)
- [ ] T026 Test pro-rated calorie calculations for various times
- [ ] T027 Test existing user flow remains unaffected
- [ ] T028 Compile all modified files with swiftc to verify no syntax errors

## Phase 3.8: Polish & Documentation

- [ ] T029 [P] Add logging for first-day window generation events
- [ ] T030 [P] Update CLAUDE.md with first-day window behavior documentation
- [ ] T031 Optimize window generation performance to <3 seconds
- [ ] T032 Add analytics tracking for first-day completion rates

---

## Dependencies Graph

```
Data Model (T001-T003)
    ↓
Service Layer (T004-T008)
    ↓
UI Components (T009-T011) [Parallel]
    ↓
Flow Integration (T012-T015)
    ↓
Edge Cases (T016-T018) [Parallel]
    ↓
State Management (T019-T021)
    ↓
Testing (T022-T028)
    ↓
Polish (T029-T032) [Parallel]
```

## Parallel Execution Examples

### Batch 1 - UI Components (while services are being built)
```bash
# Can run simultaneously:
Task T009: "Create WelcomeBanner component"
Task T010: "Implement banner auto-dismiss"
Task T011: "Create FirstTimeTooltips"
```

### Batch 2 - Edge Cases
```bash
# Can run simultaneously:
Task T016: "Implement late evening logic"
Task T017: "Add minimum time validation"
Task T018: "Handle timezone considerations"
```

### Batch 3 - Final Polish
```bash
# Can run simultaneously:
Task T029: "Add logging for events"
Task T030: "Update documentation"
```

---

## Implementation Notes

### Critical Path
1. **Must complete first**: T001-T002 (UserProfile changes)
2. **Core logic**: T004-T008 (FirstDayWindowService)
3. **Integration point**: T012-T013 (ContentView changes)
4. **Validation**: T022-T028 (Testing all scenarios)

### Risk Areas
- **T012-T013**: ContentView integration - test thoroughly to avoid breaking existing flow
- **T006**: Pro-rating calculation - ensure bounds checking (min 200 cal, max full day)
- **T020-T021**: State transitions - verify flag persistence and next-day behavior

### Success Metrics
- [ ] New user sees windows within 30 seconds of completing onboarding
- [ ] Pro-rated calories are accurate (±5% of formula)
- [ ] No regression in existing user flows
- [ ] All time-based scenarios handle correctly
- [ ] Welcome banner appears and dismisses appropriately

---

## Commit Strategy
- Commit after each task with message: `feat(first-day): T00X - [description]`
- Run `swiftc -parse` on modified files before each commit
- Push every 3-4 commits to track progress

## Next Steps
1. Create feature branch: `git checkout -b 001-post-onboarding-windows`
2. Start with T001 (UserProfile model changes)
3. Work through tasks sequentially except [P] marked items
4. Run full test suite after T028
5. Create PR after all tasks complete