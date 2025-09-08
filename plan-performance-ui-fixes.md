# Implementation Plan: Performance UI Fixes
Date: 2025-09-08
Approach: Option B - Comprehensive Redesign
Priority: URGENT
User Preferences: Maintain minimal/subtle theme with higher contrast

## Overview
Fix three critical UI issues in Performance tab:
1. Text truncation in mini cards
2. Duplicate macro bar in header
3. Low visibility/contrast of cards

## Implementation Steps

### Step 1: Remove MacroSummaryBar from Performance Header
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformanceHeaderView.swift`
**Action:** 
- Remove line 56 (MacroSummaryBar)
- Adjust spacing/layout as needed
**Test:** Compile and verify header displays correctly without macro bar

### Step 2: Fix Text Truncation in Mini Cards
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformancePillarMiniCard.swift`
**Actions:**
1. Remove ellipsis button (lines 29-35)
2. Implement dynamic width calculation
3. Add tap gesture to entire card
4. Adjust font sizing to be responsive
5. Modify HStack spacing for better text layout

**Key Changes:**
```swift
// Remove ellipsis button entirely
// Add .onTapGesture to entire card
// Use GeometryReader for dynamic width
// Calculate font size based on available space
```

### Step 3: Enhance Card Visibility
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformanceDesignSystem.swift`
**Actions:**
1. Update cardBorder opacity from 0.08 to 0.18
2. Keep minimal theme but increase contrast

**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/Components/PerformanceCard.swift`
**Actions:**
1. Add subtle shadow modifier
2. Enhance border styling while maintaining minimal aesthetic

### Step 4: Create Responsive Font System
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformancePillarMiniCard.swift`
**Actions:**
1. Implement dynamic font sizing based on screen width
2. Remove lineLimit(1) restriction
3. Use .minimumScaleFactor(0.8) for graceful scaling
4. Test on iPhone SE to ensure no truncation

### Step 5: Test Card Tap Functionality
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformancePillarMiniCard.swift`
**Actions:**
1. Add onTapGesture to replace ellipsis functionality
2. Trigger showInfoPopup on card tap
3. Ensure 44x44pt minimum tap target

### Step 6: Final Visual Polish
**Files:** All modified files
**Actions:**
1. Verify consistent spacing across all cards
2. Ensure proper contrast ratios
3. Test dark mode appearance
4. Validate on multiple device sizes

## Testing Checklist
- [ ] Compile all modified files with swiftc -parse
- [ ] No text truncation on iPhone SE
- [ ] MacroSummaryBar removed from Performance view
- [ ] Cards have improved visibility (higher contrast)
- [ ] Tap gestures work on entire card
- [ ] Maintains minimal/subtle design aesthetic
- [ ] All three mini cards display full text
- [ ] Performance header looks clean without macro bar

## Success Criteria
1. "Timing", "Nutrients", "Adherence" text fully visible
2. No duplicate macro information in Performance view
3. Cards visually distinct from background
4. Tap anywhere on card triggers info popup
5. Responsive design works on all iPhone sizes
6. Maintains app's minimal aesthetic with better usability

## Rollback Plan
If issues arise:
1. Git revert to commit before changes
2. Restore original PerformancePillarMiniCard.swift
3. Restore original PerformanceHeaderView.swift
4. Restore original PerformanceDesignSystem.swift

## Notes
- Priority: URGENT - Complete all steps in single session
- Maintain minimal/subtle theme throughout
- Focus on usability without sacrificing aesthetics
- Test thoroughly on smallest screen (iPhone SE)