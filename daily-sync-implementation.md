# Daily Sync Implementation Checklist

## 🚀 Quick Start Actions

### Immediate Fixes (Day 1)
```bash
# File renames needed:
MorningCheckInCoordinator.swift → DailySyncCoordinator.swift
MorningCheckInViewModel.swift → DailySyncViewModel.swift
MorningCheckInData.swift → DailySyncData.swift
MorningCheckInNudge.swift → DailySyncNudge.swift
```

### Text Updates (Day 1-2)
- [ ] Replace all "morning check-in" → "daily sync"
- [ ] Update nudge text: "Time for your morning check-in" → "Let's sync your nutrition"
- [ ] Fix menu item: "Morning Check-In" → "Daily Sync"
- [ ] Update onboarding text explaining the feature

---

## 📦 Core Code Changes

### 1. New Context Detection
```swift
// Add to DailySyncViewModel.swift
func getCurrentContext() -> SyncContext {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 4..<8: return .earlyMorning
    case 8..<11: return .lateMorning
    case 11..<14: return .midday
    case 14..<17: return .afternoon
    case 17..<21: return .evening
    default: return .lateNight
    }
}
```

### 2. Simplified Data Model
```swift
// Replace bloated MorningCheckIn with:
struct DailySync {
    let id: UUID
    let timestamp: Date
    let syncContext: SyncContext
    let alreadyConsumed: [QuickMeal]
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let currentEnergy: SimpleEnergyLevel
    let specialEvent: Event?
}

enum SimpleEnergyLevel: String {
    case low = "Need fuel"
    case good = "Feeling good"
    case high = "High energy"
}
```

### 3. Dynamic Screen Flow
```swift
// In DailySyncCoordinator
func getScreenFlow() -> [DailySyncScreen] {
    let context = getCurrentContext()
    var screens: [DailySyncScreen] = []
    
    // Always show greeting
    screens.append(.greeting(context))
    
    // Only ask about eaten meals after 8am
    if context != .earlyMorning {
        screens.append(.alreadyEaten)
    }
    
    // Schedule (simplified)
    screens.append(.todaySchedule)
    
    // Current state (only if needed)
    if shouldAskEnergy(context) {
        screens.append(.currentEnergy)
    }
    
    return screens
}
```

---

## 🗄️ Database Migration

### Firestore Updates
```javascript
// Old structure
users/{userId}/checkIns/morning/{date}

// New structure  
users/{userId}/dailySync/{date}

// Migration function
async function migrateMorningCheckIns() {
    // Copy morning checkIns to dailySync
    // Map old fields to new simplified model
    // Delete deprecated fields
}
```

### UserDefaults Keys
```swift
// Update all keys
"lastMorningCheckIn" → "lastDailySync"
"skipMorningCheckIn" → "skipDailySync"
"morningCheckInReminder" → "dailySyncReminder"
```

---

## 🎨 UI File Updates

### Files to Modify
1. `DailySyncCoordinator.swift` (renamed)
   - Reduce from 7 to 4 screens max
   - Add context detection
   - Dynamic flow

2. `AlreadyEatenView.swift` (NEW)
   - Quick meal logger
   - Photo/voice input
   - Smart suggestions

3. `ScheduleInputView.swift` (SIMPLIFIED)
   - Single screen for all schedule items
   - Smart defaults
   - Optional fields

4. Remove/Archive:
   - `SleepQualityViewV2.swift`
   - `HungerLevelViewV2.swift`  
   - `DayFocusViewV2.swift`
   - `PlannedBedtimeViewV2.swift`

---

## 🧪 Testing Scenarios

### Time-Based Testing
```swift
// Test at different times
func testEarlyMorning() // 6am - full flow
func testLateM orning() // 10am - with eaten meals
func testAfternoon()   // 3pm - remaining meals only
func testEvening()     // 8pm - next day prep
func testLateNight()   // 11pm - night shift mode
```

### User Scenarios
- [ ] Regular 9-5 worker
- [ ] Night shift nurse  
- [ ] Intermittent faster
- [ ] Traveler (timezone change)
- [ ] Weekend vs weekday

---

## 📊 Tracking Success

### Key Metrics to Monitor
```swift
struct DailySyncMetrics {
    let completionRate: Double      // Target: >90%
    let avgCompletionTime: TimeInterval  // Target: <30s
    let screensShown: Int           // Target: 3-4
    let dropOffScreen: String?      // Identify problem screens
    let timeOfDayDistribution: [SyncContext: Int]  // Usage patterns
}
```

### A/B Test Plan
- 50% users: Old morning check-in (control)
- 50% users: New daily sync (test)
- Measure: Completion rate, time, satisfaction
- Duration: 2 weeks

---

## ⚡ Quick Wins First

### Day 1-2: Cosmetic Changes
1. Rename feature everywhere
2. Update menu text and nudges
3. Change notification text

### Week 1: Core Simplification  
1. Remove unnecessary screens
2. Add "already eaten" flow
3. Simplify data model

### Week 2: Smart Features
1. Context detection
2. Adaptive questions
3. History-based defaults

### Week 3: Polish
1. Animations
2. Quick actions
3. User feedback integration

---

## 🎯 Definition of Done

- [ ] Works at ANY time of day
- [ ] Handles already-eaten meals
- [ ] Completion in <30 seconds
- [ ] 4 screens maximum
- [ ] Night shift support
- [ ] Smart defaults from history
- [ ] All "morning" references removed
- [ ] Database migration complete
- [ ] A/B test shows improvement