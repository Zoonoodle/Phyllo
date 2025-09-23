# Daily Sync Redesign Plan
## Replacing "Morning Check-In" with Smart Context-Aware System

---

## 🎯 Core Problems with Current System

1. **Name is restrictive**: "Morning Check-In" doesn't work for:
   - Night shift workers
   - Late risers
   - Different time zones
   - Irregular schedules

2. **Too much data collection**: Currently collecting 10+ data points:
   - Wake time, sleep quality, energy, hunger
   - Day focus (12 options!), mood, activities
   - Window preferences, restrictions, bedtime
   
3. **Doesn't account for already-consumed meals**
4. **Rigid flow**: 7 mandatory screens every time
5. **Not context-aware**: Same questions regardless of time/situation

---

## ✨ New System: "Daily Sync"

### Core Philosophy
> **"Sync your day with your nutrition"** - Works any time, adapts to your context

### Smart Context Detection
The system adapts based on when you open it:

```swift
enum SyncContext {
    case earlyMorning    // 4am-8am: Fresh start
    case lateMorning     // 8am-11am: May have eaten breakfast
    case midday          // 11am-2pm: Likely eaten 1-2 meals
    case afternoon       // 2pm-5pm: Multiple meals consumed
    case evening         // 5pm-9pm: Most meals done
    case lateNight       // 9pm-4am: Night shift or irregular schedule
}
```

---

## 📊 Data Collection Strategy

### ESSENTIAL (Always Collect)
1. **Already Eaten Today** (if time > 8am)
   - Quick meal logging with photo/voice
   - "I already had..." with smart suggestions

2. **Today's Schedule**
   - Work hours (if working day)
   - Major events (1-2 max)
   - Workout time (if planned)

3. **Current State**
   - Energy level (simplified: Low/Good/High)
   - Next meal timing preference

### REMOVE (Unnecessary)
❌ **Sleep quality** - Not directly relevant to nutrition timing
❌ **Hunger level** - Changes throughout day, ask when relevant
❌ **Day focus** - 12 options is overwhelming
❌ **Morning mood** - Not actionable for nutrition
❌ **Window preference** - AI should figure this out
❌ **Planned bedtime** - Can infer from schedule

### OPTIONAL (Context-Dependent)
- **Dietary needs**: Only ask once, store permanently
- **Special circumstances**: Travel, illness, etc.

---

## 🎨 New User Flow

### Screen 1: Smart Greeting
```
"Let's sync your nutrition for [today/tonight]"

Based on time:
- Morning: "Good morning! Let's plan your nutrition"
- Afternoon: "Let's optimize your remaining meals"
- Evening: "Let's adjust for tonight"
- Late night: "Working late? Let's adapt your schedule"
```

### Screen 2: Already Eaten? (Skip if < 8am)
```
"Have you eaten anything today?"

[Yes, log meals] → Quick photo/voice capture
[No, continue]
```

### Screen 3: Today's Schedule (Single Screen)
```
"What's on your schedule?"

Work: [9am-5pm slider]
Workout: [None / Time picker]
Special: [None / Event type + time]

[Smart Suggestions based on history]
```

### Screen 4: Current Energy
```
"How's your energy right now?"

😴 Need fuel
😊 Feeling good  
⚡ High energy

[This affects immediate meal timing]
```

### Screen 5: Confirmation
```
"Perfect! I'll optimize your [X remaining] meals"

[Shows visual preview of day]
[Generate Schedule]
```

---

## 🔄 Adaptive Features

### Time-Based Intelligence
```swift
struct DailySyncLogic {
    func determineQuestions(currentTime: Date) -> [Question] {
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        switch hour {
        case 4..<8:
            // Fresh start - full day planning
            return [.schedule, .energy, .preferences]
            
        case 8..<12:
            // May have eaten breakfast
            return [.alreadyEaten, .schedule, .energy]
            
        case 12..<17:
            // Likely eaten 1-2 meals
            return [.alreadyEaten, .remainingSchedule, .energy]
            
        case 17..<21:
            // Focus on dinner/evening
            return [.alreadyEaten, .eveningPlans, .tomorrowPrep]
            
        default:
            // Night shift/irregular
            return [.customSchedule, .alreadyEaten, .energy]
        }
    }
}
```

### Smart Meal Detection
- If user says they've eaten, quickly log those meals
- Adjust remaining windows accordingly
- Don't regenerate entire day, just redistribute

---

## 📱 UI/UX Improvements

### Visual Changes
1. **Progress indicator**: Dots instead of numbered steps
2. **Skip options**: "Use yesterday's schedule" for regulars
3. **Quick actions**: Common patterns as one-tap options

### Copy Updates
- Remove "morning" from all text
- Use "Daily Sync" or "Nutrition Sync"
- Time-aware greetings

### Speed Optimizations
- Max 3-4 screens (down from 7)
- Smart defaults from history
- One-tap common scenarios

---

## 🚀 Implementation Plan

### Phase 1: Rename & Rebrand (Week 1)
- [ ] Rename `MorningCheckIn` → `DailySync`
- [ ] Update all UI text and navigation
- [ ] Add time-based greetings

### Phase 2: Simplify Data (Week 1-2)
- [ ] Remove unnecessary fields from model
- [ ] Consolidate screens (7 → 4)
- [ ] Add "already eaten" flow

### Phase 3: Smart Context (Week 2-3)
- [ ] Implement `SyncContext` detection
- [ ] Adaptive question flow
- [ ] History-based defaults

### Phase 4: Polish (Week 3-4)
- [ ] Quick actions for common patterns
- [ ] Improved animations
- [ ] User testing and refinement

---

## 💾 Data Model Changes

### Old Model (MorningCheckIn)
```swift
struct MorningCheckIn {
    // 14+ fields!
    let wakeTime: Date
    let plannedBedtime: Date
    let sleepQuality: Int
    let energyLevel: Int
    let hungerLevel: Int
    let dayFocus: Set<DayFocus>  // 12 options!
    let morningMood: MoodLevel?
    let plannedActivities: [String]
    let windowPreference: WindowPreference
    let hasRestrictions: Bool
    let restrictions: [String]
    // ...
}
```

### New Model (DailySync)
```swift
struct DailySync {
    // 6-8 fields max
    let id: UUID
    let timestamp: Date
    let syncContext: SyncContext  // When they synced
    let alreadyConsumed: [QuickMeal]  // If any
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let currentEnergy: EnergyLevel  // Simplified: low/good/high
    let specialEvents: [Event]  // Max 2
}

struct QuickMeal {
    let name: String
    let time: Date
    let calories: Int?  // Optional quick estimate
}
```

---

## 🎯 Success Metrics

### User Experience
- ✅ Average completion time: < 30 seconds (down from 2+ minutes)
- ✅ Screens per sync: 3-4 (down from 7)
- ✅ Works for all schedules (24/7)

### Data Quality
- ✅ More accurate (accounts for already-eaten meals)
- ✅ More relevant (only essential data)
- ✅ More actionable (immediate use in AI generation)

### Engagement
- ✅ Higher completion rates (fewer screens)
- ✅ Works for night shift workers
- ✅ Adapts to user patterns

---

## 🔑 Key Decisions

1. **Name**: "Daily Sync" instead of "Morning Check-In"
2. **Timing**: Works 24/7, adapts to context
3. **Data**: Cut 50% of fields, focus on essentials
4. **Flow**: Dynamic based on time and history
5. **Speed**: 30 seconds max completion time

---

## 📝 Next Steps

1. Get user approval on this plan
2. Create detailed screen mockups
3. Update data models
4. Implement in phases
5. A/B test with users

---

### Alternative Names Considered
- ✅ **Daily Sync** (Winner - clear and flexible)
- Nutrition Sync (Too long)
- Day Setup (Still implies morning)
- Schedule Sync (Too narrow)
- Meal Planning (Doesn't cover adaptation)