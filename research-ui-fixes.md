# UI Issues Research Document
## Date: 2025-09-11

### Executive Summary
Research completed for three critical UI issues in NutriSync app:
1. Performance header being obscured by iPhone Dynamic Island
2. Daily Summary showing as popup instead of full-screen
3. "I was fasting" state not visually updating

---

## Issue 1: Performance Header Padding Problem

### Current State
- **Location**: `/Views/Momentum/PerformanceHeaderView.swift` (lines 21-62)
- **Problem**: Insufficient top padding causes header to be obscured by Dynamic Island
- **Root Cause**: `NutritionDashboardView.swift` (line 47) doesn't apply safe area padding to header

### Working Example (Schedule Tab)
- **Location**: `/Views/Focus/DayNavigationHeader.swift` (lines 24-85)
- **Pattern**: Uses proper safe area handling with adequate vertical spacing

### Files Affected
1. `NutritionDashboardView.swift` - Main layout container
2. `PerformanceHeaderView.swift` - Header component
3. Need to examine safe area modifiers

### Solution Path
Add `.safeAreaPadding(.top)` or explicit top padding to header section in NutritionDashboardView

---

## Issue 2: Daily Summary Display Mode

### Current State
- **Trigger Location**: `DayNavigationHeader.swift` (lines 62-67)
- **Presentation**: Using `.sheet()` modifier in `AIScheduleView.swift` (lines 43-45)
- **Problem**: Shows as modal popup instead of full-screen navigation

### Target Pattern (WindowDetailView)
- **Location**: `/Views/Focus/WindowDetailView.swift`
- **Pattern**: Uses NavigationStack with full-screen layout

### Existing Infrastructure
- `DayDetailView.swift` (lines 34-101) already designed for full-screen
- Has proper navigation bar and safe area handling
- Just needs different presentation method

### Solution Path
Replace `.sheet(isPresented:)` with NavigationLink for full-screen push navigation

---

## Issue 3: Fasting State Not Saving Visually

### Backend Implementation (WORKING)
- **Model**: `MealWindow.swift` has `isMarkedAsFasted: Bool` (line 118)
- **ViewModel**: `ScheduleViewModel.swift` has `markWindowsAsFasted()` method
- **Database**: Firebase properly saves/loads fasted state
- **Logic**: Correctly filters missed vs fasted windows

### UI Components (NOT REFLECTING STATE)
- **MissedMealsRecoveryView.swift** (lines 317-325): Button triggers correct backend action
- **Problem Areas**:
  - `SimpleTimelineView.swift` - May not distinguish fasted state visually
  - `ExpandableWindowBanner.swift` - May not show fasted state differently
  - Window color/status indicators need examination

### Root Cause
UI layer doesn't read `isMarkedAsFasted` property to change visual appearance from "missed" (red) to "fasted" (neutral/gray) state

### Solution Path
1. Add visual state for fasted windows (gray color instead of red)
2. Update timeline view to show fasted state
3. Update window banners to display fasted indicator

---

## Technical Constraints

### Safe Area Considerations
- Must support Dynamic Island (iPhone 14 Pro+)
- Must support notch devices (iPhone X-13)
- Must support regular status bar (older devices)

### Navigation Patterns
- App uses NavigationStack (iOS 16+)
- Sheet presentations for modals
- NavigationLink for full-screen pushes

### State Management
- Using @Observable ViewModels
- Firebase for persistence
- Local state updates must sync with database

---

## Testing Requirements

### Device Testing Needed
1. iPhone 15 Pro (Dynamic Island)
2. iPhone 13 (Notch)
3. iPhone SE (Regular status bar)

### State Testing
1. Mark window as fasted → Check visual update
2. Reload app → Verify fasted state persists
3. Test with multiple missed windows

### Navigation Testing
1. Daily summary navigation flow
2. Back navigation behavior
3. State preservation during navigation

---

## Dependencies
- SwiftUI 6 (iOS 17+)
- Firebase Firestore
- @Observable pattern

---

## Risk Assessment
- **Low Risk**: Header padding fix (simple UI adjustment)
- **Medium Risk**: Navigation change (affects user flow)
- **Low Risk**: Fasting state visual (display only, backend works)

---

## Next Steps (Phase 2 - Planning)
1. Get user preference on fasted window color (gray vs other)
2. Confirm navigation preference (push vs modal)
3. Prioritize which issue to fix first
4. Create detailed implementation plan