# Scoring Redesign Progress - Through Phase 5

## Completed Phases

### Phase 1: Core Components (94bb63c)
- `ScoreText` - Displays 1-10 format scores with color coding
- `ScoreProgressBar` - Visual progress bar with `.fromInternal()` helper
- `FactorChip` / `FactorChipGrid` - Shows contributing factors with +/- values
- `InsightBox` - Displays insights with icon and styled container
- Added `displayScore` property to `HealthScore` and `WindowScore` models

### Phase 2: Meal Health Score UI (d9e31d0)
- **FoodAnalysisView.swift** - New `mealScoreSection` with:
  - ScoreText + ScoreProgressBar
  - FactorChipGrid with contributing factors
  - Expandable breakdown section
  - InsightBox for meal insights
- **WindowFoodsList.swift** - Added inline ScoreText to FoodItemCard
- **ExpandableWindowBanner.swift** - MealRowCompact now uses ScoreText (1-10)

### Phase 3: Window Score UI (eab2f6b)
- **ExpandableWindowBanner.swift**:
  - Replaced CompactWindowScore with ScoreText (1-10 format)
  - Added one-line insight text for completed windows
  - Added `windowScoreInsightColor()` helper
- **WindowDetailView.swift** - Complete redesign of WindowScoreSection:
  - ScoreText + ScoreProgressBar
  - InsightBox for adherence insight
  - FactorChipGrid for macro adherence
  - Expandable breakdown with MacroAdherenceRow

### Phase 4: Daily Score UI (1e270b4)
- **DailyScoreDetailView.swift** - Complete redesign:
  - ScoreText (1-10) + ScoreProgressBar + label
  - InsightBox for daily summary
  - FactorChipGrid with 4 factors (adherence, quality, timing, consistency)
  - DailyStatRow components with progress bars
  - Generated insights with weakest area detection
  - DailyScoreHeaderCard component for compact display
- **DayNavigationHeader.swift**:
  - New DailyScoreMini component (1-10 circular display)
  - Replaced ScoreRing with DailyScoreMini in header

### Phase 5: Enhanced Suggestions (NEW)
- **FoodSuggestion.swift** - Added scoring fields:
  - `predictedScore: Double?` - 0-10 scale predicted health score
  - `scoreFactors: [SuggestionScoreFactor]?` - Factors contributing to score
  - New `SuggestionScoreFactor` struct with name, contribution, detail
  - Updated Firestore serialization methods

- **FoodSuggestionService.swift** - Enhanced AI prompt:
  - Updated prompt to request predicted scores and factors
  - Added `sc` (score) and `sf` (score factors) to JSON output
  - New `RawScoreFactor` struct for parsing
  - Maps AI response to `SuggestionScoreFactor` model

- **FoodSuggestionCard.swift** - Complete redesign:
  - Self-contained expandable card (tap to expand/collapse)
  - Collapsed state shows: emoji, name, score (ScoreText), macros, reasoning, chevron
  - Expanded state shows:
    - Predicted score section with ScoreText + ScoreProgressBar
    - "Why This Fits Your Day" explanation
    - Nutrition section with calories and macro boxes
    - Score factors using FactorChipGrid
    - Optional "Log This Meal" button
  - Removed dependency on external sheet

- **FoodSuggestionDetailSheet.swift** - Updated with scoring:
  - Added predicted score display in header with ScoreText
  - New predictedScoreSection with ScoreText + ScoreProgressBar
  - New scoreFactorsSection using FactorChipGrid
  - Preserved existing why/howYoullFeel/supportsGoal sections

- **WhatToEatSection.swift** - Updated integration:
  - Added `onLogSuggestion` callback for log action
  - Removed sheet presentation (cards now self-contained)
  - Updated previews with scored suggestions

## What Remains (Phase 6+)

### Phase 6: Recipe Integration (Optional)
Per `ENHANCED-SUGGESTIONS-DESIGN.md`:
- Create `RecipeSearchService`
- Implement parallel recipe fetching
- Build nutrition verification logic
- Create recipe caching
- Handle fallback scenarios

### Phase 7: Real-Time Suggestion Updates
- Detect meal logged events
- Trigger re-ranking of suggestions
- Update UI in real-time
- Handle edge cases

### Phase 8: Suggestion Notifications
- Create suggestion notification type
- Trigger at T-30 before window
- Handle notification tap (deep link)
- Add notification settings
- Implement in-app badge

### Phase 9: Polish & Edge Cases
- Empty states for all views
- Error handling
- Offline mode graceful degradation
- Performance optimization (caching)
- Accessibility audit

## Key Files Modified in Phase 5

| File | Changes |
|------|---------|
| `Models/FoodSuggestion.swift` | Added predictedScore, scoreFactors, SuggestionScoreFactor |
| `Services/AI/FoodSuggestionService.swift` | AI prompt for scores, parsing for score data |
| `Views/Focus/FoodSuggestionCard.swift` | Complete redesign - expandable with scoring |
| `Views/Focus/FoodSuggestionDetailSheet.swift` | Added scoring sections |
| `Views/Focus/WhatToEatSection.swift` | Updated for new card design |

## Design Docs Location
- `docs/SCORING-SYSTEM-REDESIGN.md` - Full scoring UI spec
- `docs/ENHANCED-SUGGESTIONS-DESIGN.md` - Suggestions system spec
- `docs/MASTER-PLAN-SCORING-SUGGESTIONS.md` - Implementation phases

## Build Status
Phase 5 compiled and built successfully. No known build errors.

## Next Session Prompt

To continue implementing the remaining phases:

```
I'm continuing the NutriSync scoring/suggestions redesign. Phases 1-5 are complete.

## What's Done
- Phase 1-4: Core scoring components and UI across meals, windows, daily scores
- Phase 5: Enhanced suggestions with predicted scores, expandable cards

## What to Implement Next

Choose from:
1. **Phase 6: Recipe Integration** - Add recipe fetching from trusted sources
2. **Phase 7: Real-Time Updates** - Re-rank suggestions when meals logged
3. **Phase 8: Notifications** - Alert users when suggestions ready
4. **Phase 9: Polish** - Error handling, empty states, performance

## Key Files
- `docs/ENHANCED-SUGGESTIONS-DESIGN.md` - Full spec
- `docs/SESSION-PROGRESS-SCORING-PHASE5.md` - Current progress

Start by reading the design docs, then implement the next phase.
```
