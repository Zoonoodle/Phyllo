# Research: Clickable Daily Summary Feature

**Date**: 2025-09-03  
**Feature**: Make top daily summary clickable to show comprehensive day view  
**Agent**: Research Phase (Phase 1)

---

## 📋 Feature Requirements

The user wants to add functionality where clicking the top daily calories/macros summary shows a comprehensive day view including:

1. **NutriSync Ring** - Daily totals (same design as window view)
2. **Full Day Macros** - Aggregate protein, fat, carbs for entire day
3. **Micronutrient Petals** - Daily micronutrient patterns
4. **All Logged Foods** - Complete list of foods logged throughout the day
5. **Day Purpose** - AI-generated explanation of daily nutrition strategy (replaces "Window Purpose")

---

## 🔍 Current Implementation Analysis

### 1. Daily Summary Component
- **Location**: `DayNavigationHeader.swift`
- **Component**: `MacroSummaryBar`
- **Current State**: Not clickable, displays progress bars for calories/macros
- **Required Change**: Add tap gesture and navigation trigger

### 2. Window Banner Pattern (Reference for New View)
- **Location**: `ExpandableWindowBanner.swift` and `WindowDetailOverlay.swift`
- **Pattern**: Uses `.sheet()` modifier for modal presentation
- **Components**: Window purpose, macros, food suggestions, tips
- **Reusable Elements**: Layout structure, navigation pattern, component hierarchy

### 3. Data Aggregation Infrastructure
- **Location**: `ScheduleViewModel.swift`
- **Available**: `todaysMeals` property for daily meals
- **Functions**: Window-specific aggregation exists
- **Gap**: Need daily-level aggregation functions for micronutrients

### 4. AI Window Generation Service
- **Location**: `AIWindowGenerationService.swift`
- **Current**: Generates "Window Purpose" for each eating window
- **Required**: Extend to generate "Day Purpose" alongside windows
- **Format**: JSON response structure needs new `dayPurpose` field

### 5. Existing Visualization Components
- **NutriSync Ring**: `MacroNutritionPage.swift`
- **Micronutrient Petals**: `MicroNutritionPage.swift`
- **Food Lists**: `WindowDetailOverlay.swift` has logged foods section

---

## 🏗 Technical Architecture

### Navigation Flow
```
MacroSummaryBar (tap) 
→ Set @State showDayDetail = true
→ Present DayDetailView via .sheet()
→ Load aggregated daily data
→ Display comprehensive day overview
```

### Data Flow
```
ScheduleViewModel 
→ Aggregate todaysMeals
→ Calculate daily totals (calories, macros, micronutrients)
→ Pass to DayDetailView
→ Render in components
```

### AI Generation Flow
```
Morning Check-in 
→ AIWindowGenerationService
→ Generate windows + NEW dayPurpose
→ Store in Firestore
→ Display in DayDetailView
```

---

## 📁 Files to Create

### 1. `DayDetailView.swift`
- Main container for day summary
- Similar structure to `WindowDetailOverlay`
- Coordinates all sub-components

### 2. `DayPurposeCard.swift`
- Display AI-generated day purpose
- Shows daily strategy and expected outcomes
- Styled like window purpose but day-focused

### 3. `DailyNutriSyncRing.swift`
- Aggregate version of window ring
- Shows full day progress vs targets
- Uses same visual design

### 4. `DailyMicronutrientPetals.swift`
- Day-level micronutrient visualization
- Aggregates all meal micronutrients
- Shows patterns across the day

### 5. `DailyFoodsList.swift`
- Chronological list of all logged foods
- Groups by window with timestamps
- Shows complete daily intake

---

## 📝 Files to Modify

### 1. `DayNavigationHeader.swift`
- Add `@Binding var showDayDetail: Bool`
- Add `.onTapGesture` to `MacroSummaryBar`
- Add visual feedback for tappability

### 2. `AIScheduleView.swift`
- Add `@State private var showDayDetail = false`
- Add `.sheet(isPresented: $showDayDetail)`
- Pass necessary data to `DayDetailView`

### 3. `ScheduleViewModel.swift`
- Add `dailyMicronutrients` computed property
- Add helper functions for daily aggregation
- Expose day-level data properties

### 4. `AIWindowGenerationService.swift`
- Update prompt to include day purpose generation
- Add `dayPurpose` to response structure
- Parse and store day purpose data

### 5. `MealWindow.swift` (Model)
- Consider adding `dayPurpose` property
- Or create separate `DayPurpose` model
- Ensure proper Firestore serialization

---

## 🎨 UI/UX Patterns to Follow

### From Window Banner
- Header with navigation title
- Dismissible with drag indicator
- Card-based section layout
- Consistent spacing (24pt between sections)
- Use of `PhylloDesignSystem` constants

### Color Usage
- Background: `phylloBackground`
- Cards: `phylloCard` (white.opacity(0.03))
- Accent: `phylloAccent` (green, use sparingly)
- Text hierarchy: primary, secondary, tertiary

### Animation
- Spring animations for transitions
- Smooth sheet presentation
- Haptic feedback on tap

---

## 🔄 Implementation Options

### Option A: Extend Window Generation Response
**Pros**: Single AI call, consistent data
**Cons**: Requires backend change, affects existing functionality

### Option B: Separate Day Purpose Generation
**Pros**: Isolated feature, no risk to existing
**Cons**: Additional AI call, potential inconsistency

### Option C: Generate Day Purpose Client-Side
**Pros**: No backend changes needed
**Cons**: Less intelligent, basic templating only

**Recommendation**: Option A - Extend existing generation for consistency

---

## 🚨 Edge Cases & Considerations

### 1. Empty States
- No meals logged yet
- Partial day data
- Missing check-in data

### 2. Data Aggregation
- Handle nil/missing micronutrients
- Account for deleted meals
- Timezone changes affecting "today"

### 3. Performance
- Large number of meals (10+)
- Heavy aggregation calculations
- Image loading in food list

### 4. AI Generation
- Handle missing day purpose gracefully
- Default fallback text
- Cost implications of longer prompts

---

## 📊 Data Models Required

### DayPurpose Structure
```swift
struct DayPurpose: Codable {
    let title: String           // "Today's Focus"
    let description: String     // Overall strategy
    let keyStrategies: [String] // Max 3
    let expectedOutcomes: [String] // Max 2
    let generatedAt: Date
}
```

### Daily Aggregation Data
```swift
struct DailyNutritionSummary {
    let date: Date
    let totalCalories: Int
    let totalProtein: Int
    let totalFat: Int
    let totalCarbs: Int
    let micronutrients: [String: Double]
    let meals: [LoggedMeal]
    let windows: [MealWindow]
    let dayPurpose: DayPurpose?
}
```

---

## ✅ Success Criteria

1. **Clickability**: MacroSummaryBar responds to taps with visual feedback
2. **Navigation**: Sheet presents smoothly with proper dismissal
3. **Data Accuracy**: Daily totals match sum of all logged meals
4. **AI Integration**: Day purpose generates alongside windows
5. **Performance**: View loads within 1 second
6. **Consistency**: Follows existing app patterns and design

---

## 🎯 Next Steps (Phase 2: Planning)

1. Get user input on:
   - Preference for AI generation approach (A, B, or C)
   - Day Purpose content priorities
   - Visual layout preferences
   - Performance vs feature completeness trade-offs

2. Create detailed implementation plan
3. Define step-by-step coding tasks
4. Establish testing criteria

---

## 📝 Notes

- This feature significantly enhances daily overview capabilities
- Follows established patterns from window banner implementation
- Requires both frontend UI work and backend AI service updates
- Consider phased rollout: Basic view first, then AI enhancements

---

**PHASE 1: RESEARCH COMPLETE**

Start a NEW session for Phase 2: Planning with user input.