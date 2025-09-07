# Plan: Performance Tab Redesign Implementation
## Transform "Gamey" Performance to Professional Schedule-Level Design

---

## User Design Decisions (Confirmed)

1. **Hero Component:** Option A - Three mini-cards (Timing, Nutrients, Adherence)
2. **Architecture:** Option A - Complete tab elimination (single scrollable view)  
3. **Colors:** Option B - Contextual but muted (subtle green/yellow/red only when meaningful)
4. **Priority Order:** As listed (Design tokens → Hero → Cards → Copy → Animations)
5. **Data:** Analyze and fix calculation issues, preserve micronutrients, REMOVE streak/fasting
6. **Testing:** User will self-test and provide feedback

---

## Design Inspiration: shadcn Dashboard Cards

Based on the provided screenshot, we'll adopt:
- **Card Structure:** Dark background (#0a0a0a), subtle borders (#ffffff08)
- **Typography Hierarchy:** 
  - Small label (gray, uppercase, 11px)
  - Large value (white, bold, 24-32px)  
  - Trend indicator (small icon + percentage)
  - Supporting text (gray, 13px)
- **Spacing:** Consistent 16px padding, 12px between elements
- **Visual Weight:** Numbers are focal point, everything else supports

---

## Implementation Phases

### Phase 1: Design Token Adoption & Foundation (Steps 1-5)
**Goal:** Establish Schedule tab's design system throughout Performance views

### Phase 2: Hero Component Replacement (Steps 6-10)
**Goal:** Replace tri-color ring with three professional mini-cards

### Phase 3: Card System Unification (Steps 11-15)
**Goal:** Convert all components to Schedule-style cards

### Phase 4: Copy & Polish (Steps 16-20)
**Goal:** Professional microcopy and final refinements

---

## Detailed Implementation Steps

### PHASE 1: Design Token Foundation

#### Step 1: Create PerformanceDesignSystem.swift
**File:** `NutriSync/Views/Momentum/PerformanceDesignSystem.swift`
**Action:** Create unified design tokens matching Schedule tab
```swift
struct PerformanceDesignSystem {
    // Colors (from Schedule tab)
    static let background = Color(hex: "0a0a0a")
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBorder = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // Contextual colors (muted)
    static let successMuted = Color(hex: "10b981").opacity(0.8)
    static let warningMuted = Color(hex: "eab308").opacity(0.8)
    static let errorMuted = Color(hex: "ef4444").opacity(0.8)
    
    // Layout
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let borderWidth: CGFloat = 1
    
    // Typography (from TimelineTypography)
    static let labelFont = Font.system(size: 11, weight: .medium)
    static let valueFont = Font.system(size: 24, weight: .bold)
    static let supportingFont = Font.system(size: 13, weight: .regular)
    static let trendFont = Font.system(size: 12, weight: .medium)
}
```

#### Step 2: Update NutritionDashboardView Structure
**File:** `NutriSync/Views/Momentum/NutritionDashboardView.swift`
**Action:** Remove tab system, implement single scrollable view
- Remove `TabView` and tab enum
- Replace with `ScrollView` → `VStack`
- Remove NOW/TODAY/WEEK/INSIGHTS sections
- Keep only essential performance metrics

#### Step 3: Analyze & Document Calculation Issues
**Files to Review:**
- `SimplePerformanceView.swift` lines 563-685
- `NutritionDashboardViewModel.swift`
**Issues to Fix:**
- Timing score penalizes too harshly for slight deviations
- Nutrient score doesn't account for meal-in-progress
- Adherence score counts skipped optional windows as missed
**Documentation:** Add calculation fix notes to code

#### Step 4: Create PerformanceCard Component
**File:** `NutriSync/Views/Momentum/Components/PerformanceCard.swift`
**Action:** Base card matching shadcn style
```swift
struct PerformanceCard<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
            .padding(PerformanceDesignSystem.cardPadding)
            .background(PerformanceDesignSystem.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PerformanceDesignSystem.cornerRadius)
                    .stroke(PerformanceDesignSystem.cardBorder, lineWidth: 1)
            )
            .cornerRadius(PerformanceDesignSystem.cornerRadius)
    }
}
```

#### Step 5: Test Phase 1 Changes
**Commands:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Momentum/PerformanceDesignSystem.swift \
  NutriSync/Views/Momentum/NutritionDashboardView.swift \
  NutriSync/Views/Momentum/Components/PerformanceCard.swift
```

---

### PHASE 2: Hero Component Implementation

#### Step 6: Create PerformancePillarCard Component
**File:** `NutriSync/Views/Momentum/Components/PerformancePillarCard.swift`
**Action:** Individual metric card (used 3x in hero)
```swift
struct PerformancePillarCard: View {
    let title: String
    let value: Int
    let trend: TrendDirection
    let trendValue: String
    let status: PerformanceStatus
    
    enum TrendDirection {
        case up, down, stable
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
    
    enum PerformanceStatus {
        case excellent, good, needsWork
        var color: Color {
            switch self {
            case .excellent: return PerformanceDesignSystem.successMuted
            case .good: return PerformanceDesignSystem.textSecondary
            case .needsWork: return PerformanceDesignSystem.warningMuted
            }
        }
    }
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 8) {
                // Label
                Text(title.uppercased())
                    .font(PerformanceDesignSystem.labelFont)
                    .foregroundColor(PerformanceDesignSystem.textTertiary)
                
                // Value
                Text("\(value)%")
                    .font(PerformanceDesignSystem.valueFont)
                    .foregroundColor(status.color)
                
                // Trend
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10))
                    Text(trendValue)
                        .font(PerformanceDesignSystem.trendFont)
                }
                .foregroundColor(PerformanceDesignSystem.textSecondary)
                
                // Progress bar (subtle)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(status.color.opacity(0.6))
                            .frame(width: geometry.size.width * CGFloat(value) / 100, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}
```

#### Step 7: Create Hero Section Layout
**File:** Update `NutritionDashboardView.swift`
**Action:** Replace tri-color ring with three cards
```swift
// In main ScrollView
VStack(spacing: PerformanceDesignSystem.cardSpacing) {
    // Hero: Three pillars
    HStack(spacing: PerformanceDesignSystem.cardSpacing) {
        PerformancePillarCard(
            title: "Timing",
            value: viewModel.timingScore,
            trend: .up,
            trendValue: "+12%",
            status: viewModel.timingStatus
        )
        
        PerformancePillarCard(
            title: "Nutrients",
            value: viewModel.nutrientScore,
            trend: .down,
            trendValue: "-5%",
            status: viewModel.nutrientStatus
        )
        
        PerformancePillarCard(
            title: "Adherence",
            value: viewModel.adherenceScore,
            trend: .stable,
            trendValue: "0%",
            status: viewModel.adherenceStatus
        )
    }
}
```

#### Step 8: Remove AppleStyleRing Dependencies
**Files to Modify:**
- Remove all `AppleStyleRing` instances
- Delete `AppleActivityRing.swift` if unused elsewhere
- Update `SimplePerformanceView.swift` to remove ring animations

#### Step 9: Implement Calculation Fixes
**File:** `NutritionDashboardViewModel.swift`
**Fixes:**
```swift
// Timing: More forgiving thresholds
// Within window: 100%
// 0-30min early/late: 85%
// 30-60min: 70%
// 60min+: 50%

// Nutrients: Account for in-progress meals
// Don't penalize if current window is active

// Adherence: Ignore optional windows
// Only count required meal windows
```

#### Step 10: Test Phase 2 Changes
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Momentum/Components/PerformancePillarCard.swift \
  NutriSync/Views/Momentum/NutritionDashboardView.swift
```

---

### PHASE 3: Card System Unification

#### Step 11: Create CurrentWindowCard
**File:** `NutriSync/Views/Momentum/Components/CurrentWindowCard.swift`
**Action:** Match Schedule's window banner style
```swift
struct CurrentWindowCard: View {
    let window: MealWindow
    @ObservedObject var viewModel: NutritionDashboardViewModel
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(window.name)
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    // Time remaining pill
                    if let remaining = window.timeRemaining {
                        Text(remaining)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // Progress
                HStack {
                    Label("\(window.consumedCalories) / \(window.targetCalories) cal", 
                          systemImage: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Action hint
                if window.consumedCalories < window.targetCalories {
                    Text("Add \(window.targetCalories - window.consumedCalories) calories")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}
```

#### Step 12: Create NextWindowCard
**File:** `NutriSync/Views/Momentum/Components/NextWindowCard.swift`
**Action:** Upcoming window preview
```swift
struct NextWindowCard: View {
    let window: MealWindow
    
    var body: some View {
        PerformanceCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(window.name)
                        .font(.system(size: 15, weight: .medium))
                    Text(window.timeRange)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Text("Soon")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PerformanceDesignSystem.warningMuted.opacity(0.2))
                    .cornerRadius(6)
            }
        }
    }
}
```

#### Step 13: Create InsightCard
**File:** `NutriSync/Views/Momentum/Components/InsightCard.swift`
**Action:** Single actionable insight
```swift
struct InsightCard: View {
    let insight: String
    let action: String?
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow.opacity(0.6))
                    Text("Insight")
                        .font(PerformanceDesignSystem.labelFont)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(insight)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = action {
                    Button(action: {}) {
                        Text(action)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PerformanceDesignSystem.successMuted)
                    }
                }
            }
        }
    }
}
```

#### Step 14: Remove Streak/Fasting Components
**Action:** Delete or comment out:
- Streak tracking UI
- Fasting timer display  
- Related ViewModels properties
- Keep data collection but hide from UI

#### Step 15: Test Phase 3 Changes
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Momentum/Components/CurrentWindowCard.swift \
  NutriSync/Views/Momentum/Components/NextWindowCard.swift \
  NutriSync/Views/Momentum/Components/InsightCard.swift
```

---

### PHASE 4: Copy & Polish

#### Step 16: Update Microcopy Throughout
**Files:** All Performance components
**Changes:**
- "Needs work" → "Add protein for target"
- "Overall" → Remove, let numbers speak
- Generic percentages → Contextual messages
- Time displays → Match Schedule format ("2h 37m left")

#### Step 17: Implement Loading States
**File:** `NutritionDashboardView.swift`
```swift
if viewModel.isLoading {
    VStack {
        // Skeleton cards matching real layout
        ForEach(0..<3, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .frame(height: 120)
                .shimmering()
        }
    }
}
```

#### Step 18: Add Subtle Animations
**All card components:**
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.scores)
.transition(.opacity.combined(with: .scale(scale: 0.98)))
```

#### Step 19: Final Layout Assembly
**File:** `NutritionDashboardView.swift`
**Structure:**
```swift
ScrollView {
    VStack(spacing: 16) {
        // Header
        PerformanceHeader()
        
        // Hero: 3 pillar cards
        HStack { /* 3 PerformancePillarCards */ }
        
        // Current window (if active)
        if let current = viewModel.activeWindow {
            CurrentWindowCard(window: current, viewModel: viewModel)
        }
        
        // Next window
        if let next = viewModel.nextWindow {
            NextWindowCard(window: next)
        }
        
        // Single insight
        if let insight = viewModel.topInsight {
            InsightCard(insight: insight.text, action: insight.action)
        }
    }
    .padding(.horizontal, 16)
}
.background(PerformanceDesignSystem.background)
```

#### Step 20: Final Compilation Test
```bash
# Test ALL modified files
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 \
  NutriSync/Views/Momentum/*.swift \
  NutriSync/Views/Momentum/Components/*.swift
```

---

## Success Criteria

### Design Consistency
- [ ] All cards use identical styling to Schedule tab
- [ ] Typography matches TimelineTypography system
- [ ] Colors are muted and purposeful
- [ ] No competing visual hierarchies

### User Experience
- [ ] Single focal point per card
- [ ] Clear information hierarchy
- [ ] Professional, supportive copy
- [ ] Smooth transitions and loading states

### Technical Quality
- [ ] All calculations fixed and accurate
- [ ] No compilation errors
- [ ] Responsive to data changes
- [ ] Performance optimized

### Clean Code
- [ ] Old tab system completely removed
- [ ] AppleStyleRing dependencies eliminated
- [ ] Streak/fasting UI hidden
- [ ] Consistent component patterns

---

## Risk Mitigation

### Rollback Plan
1. Git commits after each phase
2. Keep original files renamed with `.backup` extension
3. Test in Xcode after each major change
4. User feedback checkpoints

### Known Challenges
- Large file modifications may require multiple context windows
- Firebase data integration must remain intact
- Calculation changes need thorough testing
- Component dependencies might cascade

---

## Next Steps

After plan approval:
1. Start NEW session for Phase 3 (Implementation)
2. Provide this plan: `@plan-performance-redesign.md`
3. Also provide research: `@research-performance-redesign.md`
4. Implementation will follow this plan exactly

---

**PHASE 2: PLANNING COMPLETE. Start NEW session for Phase 3 Implementation.**