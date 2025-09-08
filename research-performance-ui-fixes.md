# Research Document: Performance Tab UI Fixes
Date: 2025-09-08

## Issues Identified

### 1. Text Truncation Problem
**Location:** `PerformancePillarMiniCard.swift`

**Current State:**
- Title text "Timing", "Nutrients", "Adherence" showing as "Ti...", "Nu...", "Ad..."
- Double dots appearance (truncation dots + ellipsis menu icon)
- Fixed card height of 110pt with 16pt padding
- Font size 13pt with lineLimit(1)
- Ellipsis button taking 20pt width

**Root Causes:**
- Insufficient horizontal space for text (only ~50-60pt available)
- HStack layout with rigid spacing constraints
- Three cards sharing screen width with minimal spacing

### 2. Duplicate Macro Bar
**Location:** `PerformanceHeaderView.swift:56`

**Current State:**
- MacroSummaryBar showing cal/P/F/C values in header
- Same component used in Schedule view
- Not appropriate for Performance view context

**Fix Required:**
- Remove or conditionally hide MacroSummaryBar from Performance header

### 3. Card Visibility Issues
**Location:** `PerformanceCard.swift`, `PerformanceDesignSystem.swift`

**Current State:**
- Border opacity: 0.08 (barely visible)
- Card background: #1A1A1A
- App background: #0a0a0a
- No shadow/elevation effects
- Minimal contrast between elements

**Required Improvements:**
- Increase border opacity to 0.15-0.20
- Add shadow for elevation
- Improve color contrast

## File Locations Requiring Changes

1. `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformancePillarMiniCard.swift`
   - Lines 24-36: Title and ellipsis layout
   - Line 74: Height constraint
   - Line 72: Padding values

2. `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformanceHeaderView.swift`
   - Line 56: Remove MacroSummaryBar

3. `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/Components/PerformanceCard.swift`
   - Add shadow effects
   - Update border styling

4. `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Momentum/PerformanceDesignSystem.swift`
   - Line 14: Update cardBorder opacity
   - Consider adjusting cardBackground color

## Constraints & Dependencies

- Cards are used in multiple views (NutritionDashboardView, SimplePerformanceView)
- PerformanceDesignSystem values affect all performance-related components
- Screen width varies across devices (iPhone SE to Pro Max)
- Must maintain accessibility standards

## Proposed Solutions

### Option A: Minimal Changes
1. Remove ellipsis button entirely
2. Remove MacroSummaryBar from header
3. Increase border opacity to 0.15
4. Add subtle shadow

### Option B: Comprehensive Redesign
1. Replace ellipsis with tap gesture on entire card
2. Use dynamic width calculation
3. Implement responsive font sizing
4. Create dedicated PerformanceHeaderView without macro bar
5. Add elevation with shadow and stronger borders

## Testing Requirements
- Test on iPhone SE (smallest screen)
- Verify text fits without truncation
- Ensure cards are visually distinct
- Check tap targets meet accessibility guidelines (44x44pt minimum)

## Edge Cases
- Long translations in other languages
- Dynamic Type (accessibility font sizes)
- Landscape orientation (if supported)
- Dark/Light mode transitions