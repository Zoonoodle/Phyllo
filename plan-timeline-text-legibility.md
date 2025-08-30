# Plan: Timeline Text Legibility Enhancement
## Date: 2025-08-30

## User-Approved Design Decisions

1. **Text Scaling Factor**: 1.25x (Option B)
2. **Contrast/Opacity**: +0.25 boost (Option B)
3. **Layout Adjustments**: Flexible - Minor adjustments OK (Option B)
4. **Implementation Strategy**: Centralized Typography System (Option A)
5. **Minimum Font Size**: 12px (Option B)

## Implementation Plan

### Step 1: Create Typography System File
**File**: `NutriSync/Views/Focus/TimelineTypography.swift`

Create centralized typography constants with the 1.25x scaling applied:

```swift
struct TimelineTypography {
    // Hour markers (was 12px → 15px)
    static let hourLabel = Font.system(size: 15, weight: .medium)
    static let hourLabelCurrent = Font.system(size: 15, weight: .semibold)
    
    // Window headers (was 13-14px → 16-17px)
    static let windowTitle = Font.system(size: 17, weight: .semibold)
    static let windowTitleInactive = Font.system(size: 16, weight: .semibold)
    
    // Time ranges (was 11px → 14px)
    static let timeRange = Font.system(size: 14, weight: .medium)
    
    // Duration (was 10px → 12px minimum)
    static let duration = Font.system(size: 12, weight: .regular)
    
    // Calories (was 12-15px → 15-18px)
    static let caloriesLarge = Font.system(size: 18, weight: .bold)
    static let caloriesMedium = Font.system(size: 16, weight: .semibold)
    static let caloriesSmall = Font.system(size: 15, weight: .semibold)
    
    // Units (was 10-11px → 12-14px)
    static let calorieUnit = Font.system(size: 14, weight: .regular)
    static let calorieUnitSmall = Font.system(size: 12, weight: .regular)
    
    // Macros (was 9-10px → 12-14px)
    static let macroValue = Font.system(size: 14, weight: .medium)
    static let macroLabel = Font.system(size: 12, weight: .regular)
    
    // Food items (was 13px → 16px)
    static let foodName = Font.system(size: 16, weight: .medium)
    static let foodCalories = Font.system(size: 14, weight: .medium)
    
    // Timestamps (was 11px → 14px)
    static let timestamp = Font.system(size: 14, weight: .regular)
    
    // Status text (was 10-12px → 12-15px)
    static let statusLabel = Font.system(size: 14, weight: .medium)
    static let statusValue = Font.system(size: 15, weight: .semibold)
    
    // Progress (was 12px → 15px)
    static let progressPercentage = Font.system(size: 15, weight: .bold)
    static let progressLabel = Font.system(size: 12, weight: .medium)
}

struct TimelineOpacity {
    // Boosted by +0.25 from original values
    static let primary: Double = 1.0      // was 1.0
    static let secondary: Double = 0.95   // was 0.7
    static let tertiary: Double = 0.75    // was 0.5
    static let quaternary: Double = 0.55  // was 0.3
    
    // Special states
    static let inactive: Double = 0.75    // was 0.5
    static let disabled: Double = 0.55    // was 0.3
    static let currentHour: Double = 1.0  // was 0.8
    static let otherHour: Double = 0.75   // was 0.5
}
```

### Step 2: Update SimpleTimelineView.swift
**Priority**: Hour markers on left side

Changes needed:
1. Import TimelineTypography
2. Update HourRowView:
   - Replace `.system(size: 12)` with `TimelineTypography.hourLabel`
   - Update opacity from 0.5/0.8 to `TimelineOpacity.otherHour/currentHour`
3. Test hour height still works with larger text

### Step 3: Update ExpandableWindowBanner.swift
**Priority**: Window headers and main content

Changes needed:
1. Import TimelineTypography
2. Update window title fonts:
   - Active: `TimelineTypography.windowTitle`
   - Inactive: `TimelineTypography.windowTitleInactive`
3. Update time range: `TimelineTypography.timeRange`
4. Update duration: `TimelineTypography.duration`
5. Update calorie display logic:
   - Large numbers: `TimelineTypography.caloriesLarge`
   - Medium: `TimelineTypography.caloriesMedium`
   - Units: `TimelineTypography.calorieUnit`
6. Update macro displays:
   - Values: `TimelineTypography.macroValue`
   - Labels: `TimelineTypography.macroLabel`
7. Update all opacity values using TimelineOpacity constants
8. Adjust internal padding if text clips

### Step 4: Update WindowFoodsList.swift
**Priority**: Meal item display

Changes needed:
1. Import TimelineTypography
2. Update MealRowCompact:
   - Food name: `TimelineTypography.foodName`
   - Calories: `TimelineTypography.foodCalories`
   - Timestamp: `TimelineTypography.timestamp`
3. Update opacity values
4. Test text truncation with larger sizes

### Step 5: Update MealRow.swift
**Priority**: Compact meal display component

Changes needed:
1. Import TimelineTypography if not already
2. Apply consistent font sizes
3. Update opacity values
4. Verify minimum scale factor still works

### Step 6: Layout Adjustments (if needed)
**File**: `TimelineLayoutManager.swift`

Monitor during testing:
1. If text clips, increase:
   - `hourHeight` from 80 to 85-90
   - `mealCardHeight` from 50 to 55
2. Adjust `minimumHourHeight` if needed
3. Test overlapping windows still display correctly

### Step 7: Testing Protocol

1. **Compilation Test**:
   ```bash
   swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
     -target arm64-apple-ios17.0 \
     NutriSync/Views/Focus/TimelineTypography.swift \
     NutriSync/Views/Focus/SimpleTimelineView.swift \
     NutriSync/Views/Focus/ExpandableWindowBanner.swift \
     NutriSync/Views/Focus/WindowFoodsList.swift
   ```

2. **Visual Testing Checklist**:
   - [ ] Hour markers readable and aligned
   - [ ] Window headers clear and not truncated
   - [ ] Time ranges visible
   - [ ] Calorie counts prominent
   - [ ] Macro values/labels distinguishable
   - [ ] Food names not cut off
   - [ ] Timestamps visible
   - [ ] Animations still smooth
   - [ ] No layout breaking on scroll
   - [ ] Overlapping windows still work

3. **Edge Cases**:
   - [ ] Empty windows
   - [ ] Single meal windows
   - [ ] Multiple meal windows
   - [ ] Completed windows
   - [ ] Active windows
   - [ ] Future windows
   - [ ] Midnight crossover
   - [ ] Very long food names

### Step 8: Final Verification

1. Take screenshot of updated timeline
2. Compare with original for design preservation
3. Verify all text is readable
4. Check contrast improvements
5. Test on iPhone SE (smallest screen)

### Step 9: Cleanup

1. Remove old hardcoded font sizes
2. Delete research and plan documents
3. Update codebase-todolist.md
4. Commit with message: "feat: improve timeline text legibility with 1.25x scaling and contrast boost"

## Implementation Order

1. **Create TimelineTypography.swift** (New file)
2. **Update SimpleTimelineView.swift** (Hour markers)
3. **Update ExpandableWindowBanner.swift** (Main content)
4. **Update WindowFoodsList.swift** (Meal items)
5. **Test and adjust layout if needed**
6. **Update secondary files if time permits**

## Success Criteria

- [ ] All text ≥ 12px
- [ ] Opacity values ≥ 0.55
- [ ] No text truncation
- [ ] Design aesthetic preserved
- [ ] Smooth animations maintained
- [ ] Works on all iPhone sizes
- [ ] User confirms improved readability

## Risk Mitigation

1. **If layout breaks**: Revert to smaller scale (1.2x)
2. **If text truncates**: Add `.minimumScaleFactor(0.9)`
3. **If animations lag**: Reduce opacity animation complexity
4. **If overlaps fail**: Adjust window spacing calculations

## Time Estimate

- Step 1 (Typography file): 10 minutes
- Steps 2-5 (Update components): 30 minutes
- Step 6 (Layout adjustments): 15 minutes
- Step 7 (Testing): 20 minutes
- Step 8-9 (Verification & cleanup): 10 minutes

**Total**: ~85 minutes

## Notes for Implementation

- Start with TimelineTypography.swift to establish the system
- Test after each major component update
- Keep original values commented for easy rollback
- Watch for any performance impacts with larger text
- Priority is readability over perfect layout preservation

## Context Window Status
Planning phase at approximately 25% context usage. Ready for implementation in Phase 3.