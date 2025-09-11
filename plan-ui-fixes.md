# UI Fixes Implementation Plan
## Date: 2025-09-11
## Based on: research-ui-fixes.md

### User Preferences Confirmed
- **Priority Order**: Header padding → Daily Summary → Fasting state
- **Fasted Color**: Gray/neutral 
- **Daily Summary**: .fullScreenCover() instead of .sheet()
- **Testing**: Real iPhone with Dynamic Island available
- **Fasted Indicator**: Show in ALL places where windows appear

---

## Implementation Steps

### Step 1: Fix Performance Header Padding (Dynamic Island)
**Files to modify:**
- `Views/Momentum/NutritionDashboardView.swift`

**Actions:**
1. Locate line 47 where PerformanceHeaderView is placed
2. Add `.safeAreaPadding(.top)` modifier to the header
3. Test on iPhone with Dynamic Island
4. Verify header is fully visible below Dynamic Island
5. Test on regular notch iPhone for compatibility

**Success Criteria:**
- Header fully visible on Dynamic Island devices
- No excessive padding on notch/regular devices
- Matches padding pattern from DayNavigationHeader.swift

---

### Step 2: Change Daily Summary to Full-Screen Cover
**Files to modify:**
- `Views/Focus/AIScheduleView.swift`

**Actions:**
1. Locate lines 43-45 with `.sheet(isPresented:)` modifier
2. Replace `.sheet()` with `.fullScreenCover()`
3. Ensure DayDetailView maintains proper navigation bar
4. Test dismissal gesture/button functionality
5. Verify state preservation during presentation

**Success Criteria:**
- Daily Summary opens as full-screen cover
- Proper dismissal mechanism works
- No navigation issues or state loss

---

### Step 3: Implement Fasted State Visual Indicators
**Files to modify (in order):**
1. `Views/Focus/SimpleTimelineView.swift`
2. `Views/Focus/ExpandableWindowBanner.swift`
3. `Views/Focus/DayDetailView.swift`
4. Any other files displaying MealWindow status

**Actions:**

#### 3.1: Define Fasted Color
```swift
// Add to color extensions or inline
static let phylloFasted = Color.gray.opacity(0.6)  // Neutral gray
static let phylloMissed = Color.red.opacity(0.8)   // Keep existing
```

#### 3.2: Update SimpleTimelineView.swift
1. Find window status color logic
2. Add condition: `if window.isMarkedAsFasted { return .phylloFasted }`
3. Update status text to show "Fasted" instead of "Missed"
4. Test with multiple fasted windows

#### 3.3: Update ExpandableWindowBanner.swift
1. Locate banner background color logic
2. Add fasted state check before missed state
3. Update icon/text to indicate fasted (e.g., "✓ Fasted" in gray)
4. Ensure proper data binding with isMarkedAsFasted

#### 3.4: Update DayDetailView.swift
1. Find where window status is displayed
2. Add fasted state visual differentiation
3. Ensure consistency with other views

#### 3.5: Search for Other Window Display Locations
1. Use grep to find all files referencing MealWindow display
2. Update each to handle fasted state
3. Maintain visual consistency across app

**Success Criteria:**
- Fasted windows show gray color (not red)
- "Fasted" label appears instead of "Missed"
- Visual update occurs immediately after marking as fasted
- State persists after app reload
- Consistent appearance in ALL window displays

---

## Testing Protocol

### After Each Step:
1. Compile modified files with `swiftc -parse`
2. Build and run in Xcode
3. Test on real iPhone with Dynamic Island
4. Test on simulator with regular notch
5. Capture screenshots for verification

### Integration Testing (After All Steps):
1. **Header Test:**
   - Launch app on Dynamic Island iPhone
   - Navigate to Momentum tab
   - Verify header visibility

2. **Daily Summary Test:**
   - Tap Daily Summary from Schedule tab
   - Verify full-screen presentation
   - Test dismissal
   - Check state preservation

3. **Fasting State Test:**
   - Create missed windows
   - Mark as "I was fasting"
   - Verify immediate visual update to gray
   - Force quit and relaunch app
   - Confirm fasted state persists
   - Check all views show consistent gray color

---

## Rollback Plan

If any step causes issues:
1. Git revert to last working commit
2. Isolate problematic change
3. Re-implement with alternative approach
4. Document issue in progress file

---

## Time Estimates

- **Step 1 (Header)**: 15 minutes
- **Step 2 (Daily Summary)**: 20 minutes  
- **Step 3 (Fasted State)**: 45 minutes
- **Testing**: 30 minutes
- **Total**: ~2 hours

---

## Dependencies to Verify

- SwiftUI 6 safe area modifiers
- .fullScreenCover() availability (iOS 14+)
- MealWindow.isMarkedAsFasted property exists
- Color definitions accessible across views

---

## Next Actions

1. Start new session for Phase 3 (Implementation)
2. Provide this plan + research to new agent
3. Execute steps in order
4. Monitor context usage (stop at 60%)
5. Create progress document if needed