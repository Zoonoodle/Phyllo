# Research: Window Naming & Workout Scheduling Issues

## Executive Summary
The app has two competing window generation services, with the problematic one (`WindowGenerationService`) being used by the Morning Check-In flow, causing generic window names and missing workout-related windows.

## Critical Findings

### 1. Duplicate Services Causing Confusion
**Two separate window generation services exist:**
- `WindowGenerationService.swift` - PROBLEMATIC (used by MorningCheckInView)
- `AIWindowGenerationService.swift` - BETTER (used by FirebaseDataProvider)

### 2. Root Cause of Generic Names
**Location:** `/NutriSync/Services/WindowGenerationService.swift:217`
```json
// PROBLEM: Example JSON in prompt uses "Window 1" as name
{
  "name": "Window 1",  // AI copies this literally!
  "startTime": "ISO8601 timestamp",
  ...
}
```

**Why it happens:**
- The prompt shows "Window 1" as the example name in JSON format
- AI interprets this as the expected output format
- No explicit instruction to avoid generic names

### 3. Better Implementation in AIWindowGenerationService
**Location:** `/NutriSync/Services/AIWindowGenerationService.swift`
- Line 214: Explicitly forbids generic names
- Lines 234-244: Provides extensive meaningful name examples
- Lines 355-494: Fallback logic to fix generic names if returned

### 4. Service Usage Pattern
```
MorningCheckInView.swift:185 → WindowGenerationService.shared (BAD)
FirebaseDataProvider.swift:346 → AIWindowGenerationService.shared (GOOD)
```

### 5. Workout Window Generation Issues

#### WindowGenerationService (Missing Logic)
- No special handling for workouts
- Treats workout as regular activity
- No pre/post workout window creation

#### AIWindowGenerationService (Has Logic)
- Lines 261-263: Pre-workout window timing
- Lines 274-276: Post-workout recovery window
- But logic may not be triggered properly

#### Planned Activities Format
```swift
plannedActivities: ["Workout 5:30pm-6:30pm"]
```
- Time embedded in string
- Needs parsing to detect workout times
- Should trigger 4-5 windows (pre/post workout)

## Technical Analysis

### MealWindow Model
- Property: `name: String` (line 14)
- CodingKeys: Maps to "name" (line 88)
- No transformation applied to names from AI

### Window Processing Flow
1. User completes morning check-in
2. MorningCheckInView calls `WindowGenerationService.generateWindows()`
3. AI returns JSON with "Window 1", "Window 2" names
4. Windows saved directly to Firebase without name transformation
5. UI displays generic names

### Missing Workout Detection
```swift
// WindowGenerationService lacks this logic:
if plannedActivities.contains(where: { $0.lowercased().contains("workout") }) {
    // Should generate pre-workout window 30-60 min before
    // Should generate post-workout window immediately after
    // Total should be 4-5 windows, not 3
}
```

## Verification Points

### Console Log Evidence
```
🤖 AI Response: {"windows": [{"name": "Window 1", ...
✅ Successfully parsed 3 windows  // Should be 4-5 with workout
```

### Expected vs Actual
- **Expected:** "Morning Fuel", "Pre-Workout Power", "Post-Training Recovery", "Evening Balance"
- **Actual:** "Window 1", "Window 2", "Window 3"

## Solution Options

### Option A: Quick Fix (Recommended for immediate resolution)
1. Replace `WindowGenerationService` usage with `AIWindowGenerationService` in MorningCheckInView
2. Test to verify meaningful names and workout windows

### Option B: Fix WindowGenerationService
1. Update prompt to use meaningful example names
2. Add explicit instruction against generic names
3. Implement workout detection logic
4. Add name validation/fallback

### Option C: Consolidate Services
1. Merge both services into single implementation
2. Use best practices from AIWindowGenerationService
3. Remove duplicate code
4. Update all references

## File Locations for Fixes

1. **MorningCheckInView.swift:185** - Change service reference
2. **WindowGenerationService.swift:217** - Fix prompt example
3. **WindowGenerationService.swift:150-250** - Add workout logic
4. **FirebaseDataProvider.swift:346** - Already using correct service

## Testing Checklist
- [ ] Generate windows with workout in planned activities
- [ ] Verify 4-5 windows created (not 3)
- [ ] Check for meaningful window names
- [ ] Confirm pre-workout window 30-60 min before workout
- [ ] Confirm post-workout window immediately after
- [ ] Test without workout (should be 3 windows)

## Related Issues
- Duplicate service maintenance burden
- Inconsistent behavior across app
- Potential for future confusion
- Code duplication

## Recommended Next Steps
1. Implement Option A for immediate fix
2. Test thoroughly
3. Consider Option C for long-term maintenance
4. Update documentation to clarify service usage