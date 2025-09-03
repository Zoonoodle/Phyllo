# Plan: Meal Scan Loading Animation Enhancement

## Design Decisions (User Approved)
1. **Remove full-screen loading** - Delete MealAnalysisLoadingView completely
2. **Show loading only in:** Window banners and window detail views
3. **Display percentage:** Yes, show "31%" style text
4. **Status messages:** Keep rotating messages
5. **Colors:** Use window purpose colors in timeline
6. **Priority:** HIGH - Implement immediately

## Implementation Steps

### Step 1: Create Reusable Progress Ring Component
**File:** `Views/Common/MealAnalysisProgressRing.swift`
- Copy ring structure from ExpandableWindowBanner lines 760-786
- Add configurable size parameter (50x50 for inline, 80x80 for card)
- Include percentage text display
- Support window purpose colors
- Add smooth fill animation

### Step 2: Create Compact Meal Analysis Loader
**File:** `Views/Scan/Components/CompactMealAnalysisLoader.swift`
- Combine progress ring with rotating status messages
- Status messages: "Identifying ingredients...", "Calculating nutrition...", "Analyzing portions...", "Finalizing analysis..."
- Message rotation every 2.5 seconds
- Support two sizes: inline (50x50) and card (80x80)
- Accept window purpose for color theming

### Step 3: Delete Full-Screen Loading View
**File:** `Views/Scan/Components/MealAnalysisLoadingView.swift`
- Delete entire file
- Find and fix all references to this component

### Step 4: Update ExpandableWindowBanner
**File:** `Views/Focus/ExpandableWindowBanner.swift` (line 1388)
- Replace "Calculating..." dots animation with CompactMealAnalysisLoader
- Use inline size (50x50)
- Pass window.purpose.color for theming
- Position appropriately in banner layout

### Step 5: Update Window Detail View
**File:** Find and update window detail view (likely in Focus folder)
- Add CompactMealAnalysisLoader with card size (80x80)
- Show when meal is being analyzed
- Use window purpose color

### Step 6: Update AnalyzingMealCard
**File:** `Views/Timeline/AnalyzingMealCard.swift`
- Replace simple dots animation with CompactMealAnalysisLoader
- Use card size (80x80)
- Add proper spacing and layout

### Step 7: Implement Simulated Progress
**Location:** Within CompactMealAnalysisLoader
```swift
// Timing sequence
0-10%: 0.3s - "Identifying ingredients..."
10-30%: 0.7s - "Calculating nutrition..." 
30-60%: 1.0s - "Analyzing portions..."
60-85%: 0.8s - "Finalizing analysis..."
85-99%: 0.5s - Hold at 99% until complete
Total: ~3.3 seconds to 99%
```

### Step 8: Hook Into MealCaptureService
**File:** `Services/AI/MealCaptureService.swift`
- Add progress callback to analysis function
- Pass progress updates to loader component
- Handle completion and error states

### Step 9: Clean Up References
- Search for all uses of MealAnalysisLoadingView
- Replace with appropriate CompactMealAnalysisLoader usage
- Update any navigation or presentation logic

### Step 10: Test All Contexts
- Test in window banner (inline)
- Test in window detail view (card)
- Test in timeline cards
- Verify colors match window purposes
- Confirm smooth animations
- Check percentage updates correctly

## Component Structure

### MealAnalysisProgressRing
```swift
struct MealAnalysisProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat // 50 or 80
    let color: Color // Window purpose color
    let showPercentage: Bool // Always true for our use
}
```

### CompactMealAnalysisLoader
```swift
struct CompactMealAnalysisLoader: View {
    @State private var progress: Double = 0.0
    @State private var currentMessage: String
    let size: LoaderSize // .inline(50) or .card(80)
    let windowColor: Color
    let onComplete: (() -> Void)?
}
```

## Files to Modify/Create

### Create:
1. `Views/Common/MealAnalysisProgressRing.swift`
2. `Views/Scan/Components/CompactMealAnalysisLoader.swift`

### Delete:
1. `Views/Scan/Components/MealAnalysisLoadingView.swift`

### Update:
1. `Views/Focus/ExpandableWindowBanner.swift` (line 1388)
2. `Views/Timeline/AnalyzingMealCard.swift`
3. `Services/AI/MealCaptureService.swift`
4. Any window detail view files
5. Any files referencing MealAnalysisLoadingView

## Success Criteria
- [ ] Full-screen loading completely removed
- [ ] Progress ring shows in window banners
- [ ] Progress ring shows in window detail views
- [ ] Percentage text displays correctly
- [ ] Status messages rotate smoothly
- [ ] Colors match window purposes
- [ ] Animation is smooth and engaging
- [ ] Holds at 99% if analysis takes longer
- [ ] All old loading states replaced
- [ ] No broken references to deleted view

## Testing Checklist
- [ ] Compile all modified files with swiftc
- [ ] Test meal analysis from camera
- [ ] Test meal analysis from photo library
- [ ] Verify loading appears in timeline
- [ ] Verify loading in window details
- [ ] Check different window purpose colors
- [ ] Test completion animation
- [ ] Test error states
- [ ] Verify no memory leaks

## Next Session
Implementation Phase 3 will execute these steps systematically, creating the new components first, then updating integration points, and finally removing the old full-screen view.