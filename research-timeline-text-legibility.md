# Research: Timeline Text Legibility Enhancement
## Date: 2025-08-30

## Problem Statement
User reports text in Timeline/Schedule view is too small to read and needs better contrast, while maintaining the exact same design aesthetic.

## Current Implementation Analysis

### File Structure
- **Main View**: `NutriSync/Views/Focus/SimpleTimelineView.swift`
- **Window Components**: `NutriSync/Views/Focus/ExpandableWindowBanner.swift`
- **Layout Manager**: `NutriSync/Views/Focus/TimelineLayoutManager.swift`
- **Food List**: `NutriSync/Views/Focus/WindowFoodsList.swift`
- **Related**: `AIScheduleView.swift`, `WindowDetailView.swift`

### Critical Text Size Issues Identified

#### 1. Extremely Small Text (9-10px) - UNREADABLE
- Macro labels: 9px (smallest in app)
- Duration text: 10px
- Status labels: 10-11px
- Calorie units: 10px

#### 2. Small Text (11-12px) - DIFFICULT TO READ
- Time ranges: 11px
- Timestamps: 11px
- Hour markers: 12px
- Completion text: 11px

#### 3. Borderline Readable (13-14px)
- Food names: 13px
- Window headers: 13-14px
- Main calorie counts: 12-15px (varies)

### Contrast Issues

#### Low Visibility Elements
- `.white.opacity(0.3)` - Almost invisible
- `.white.opacity(0.5)` - Very low contrast
- `.white.opacity(0.7)` - Marginal contrast

#### Color-Coded Elements with Opacity
- Protein: `.orange.opacity(0.8)`
- Fat: `.yellow.opacity(0.8)` 
- Carbs: `.blue.opacity(0.8)`

### Layout Constraints to Preserve

1. **Fixed Dimensions**:
   - Hour height: 80px base
   - Time column width: 48px
   - Window banner padding: 14px
   - Meal card height: 50px

2. **Dynamic Height System**:
   - Content-aware expansion
   - Minimum 30px for empty hours
   - Overlapping window management

3. **Animation Dependencies**:
   - AnimatedInfoSwitcher timing
   - Progress ring animations
   - Transition effects

### Proposed Solutions

#### Solution 1: Global Scale Factor (RECOMMENDED)
Apply 1.25x scale to all text while maintaining hierarchy:
- 9px → 11px
- 10px → 12px
- 11px → 14px
- 12px → 15px
- 13px → 16px
- 14px → 17px

**Pros**: Maintains design proportions, easy to implement
**Cons**: May require layout adjustments for larger text

#### Solution 2: Minimum Size Enforcement
Set floor of 12px for all text:
- Replace all <12px with 12px minimum
- Scale up proportionally from there

**Pros**: Guarantees readability
**Cons**: May lose hierarchy for small elements

#### Solution 3: Typography System Overhaul
Create centralized typography constants:
```swift
struct TimelineTypography {
    static let timeLabel = Font.system(size: 15, weight: .medium)
    static let windowHeader = Font.system(size: 17, weight: .semibold)
    static let foodName = Font.system(size: 16, weight: .medium)
    static let macroValue = Font.system(size: 14, weight: .medium)
    static let macroLabel = Font.system(size: 12)
    static let timestamp = Font.system(size: 14)
}
```

#### Solution 4: Contrast Boost
Increase all opacity values by 0.2-0.3:
- 0.3 → 0.5
- 0.5 → 0.7
- 0.7 → 0.9

### Implementation Approach

1. **Create Typography Constants**: Define standard sizes in a new file
2. **Update Components Systematically**:
   - SimpleTimelineView (hour markers)
   - ExpandableWindowBanner (headers, times)
   - WindowFoodsList (meal items)
   - MealRowCompact (food details)
3. **Adjust Layout if Needed**: 
   - May need to increase hour height slightly
   - Adjust spacing for larger text
4. **Test Across States**:
   - Empty windows
   - Completed windows
   - Active windows
   - Overlapping windows

### Risk Assessment

**Low Risk**:
- Text size increases
- Opacity adjustments
- Color tweaks

**Medium Risk**:
- Layout spacing changes
- Window overlap handling
- Animation timing

**High Risk**:
- Breaking dynamic height calculations
- Disrupting gesture recognizers
- Performance impact from larger text rendering

### Testing Requirements

1. Visual regression testing on all window states
2. Check text truncation and wrapping
3. Verify animations still work smoothly
4. Test on smaller screen sizes (iPhone SE)
5. Validate macro color visibility
6. Check midnight crossover display

### Files to Modify

Primary targets:
1. `SimpleTimelineView.swift` - Hour markers
2. `ExpandableWindowBanner.swift` - Window headers  
3. `WindowFoodsList.swift` - Meal items
4. `TimelineLayoutManager.swift` - May need height adjustments

Secondary targets:
5. `Color+Theme.swift` - Add typography constants
6. `MealRow.swift` - Compact meal display
7. `WindowDetailView.swift` - Detail overlay

### Next Steps (Phase 2: Planning)

1. Review research with user
2. Get approval on scaling approach (1.25x recommended)
3. Decide on contrast improvements
4. Create detailed implementation plan
5. Consider creating a Typography system file
6. Plan incremental testing approach

## Key Decisions Needed from User

1. **Scaling Factor**: 1.2x, 1.25x, or 1.3x?
2. **Minimum Font Size**: 11px or 12px?
3. **Opacity Boost**: How much contrast improvement?
4. **Layout Flexibility**: OK to slightly increase hour heights if needed?
5. **Typography System**: Create centralized constants or inline changes?

## Context Window Note
Research phase completed at approximately 15% context usage. Ready for planning phase in new session.