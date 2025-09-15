# Settings Menu Implementation Research
## Phase 1: Research Documentation

**Date:** 2025-09-14  
**Feature:** Real Settings Menu with Hamburger Navigation  
**Researcher:** Phase 1 Research Agent

---

## 📊 Executive Summary

The NutriSync app currently has comprehensive settings infrastructure but lacks a unified settings menu. The app uses **gear icons** (not hamburger buttons) in the Schedule and Performance tabs that currently open the DeveloperDashboardView. This research documents the path to implementing a proper settings menu with hamburger navigation.

---

## 🏗 Current Architecture Analysis

### Navigation Structure
- **Main Navigation:** PhylloTabView.swift manages three tabs (Schedule, Momentum, Scan)
- **Tab Implementation:** Custom floating tab bar with sheet-based navigation
- **Current Settings Access:** Gear icons in headers open DeveloperDashboardView via sheet presentation

### Header Components
1. **DayNavigationHeader.swift** (Lines 20-40)
   - Used in Schedule tab (AIScheduleView)
   - Contains gear button that triggers `showingDeveloperDashboard` binding
   - Located at top-right corner

2. **PerformanceHeaderView.swift** (Lines 18-35)
   - Used in Performance tab (NutritionDashboardView)
   - Similar gear button implementation
   - Consistent with DayNavigationHeader design

### Current Flow
```swift
// Current implementation in headers
Button(action: { showingDeveloperDashboard = true }) {
    Image(systemName: "gearshape.fill")
        .font(.system(size: 20))
        .foregroundColor(Color("nutriSyncSecondaryText"))
}
```

---

## 🎯 Existing Settings Infrastructure

### Already Implemented Views

#### 1. AccountSettingsView.swift
- **Location:** Views/Settings/AccountSettingsView.swift
- **Features:**
  - Account status display
  - Email management
  - Sign out functionality
  - Delete account option
  - Privacy policy link
  - Terms of service link
- **State Management:** Uses @EnvironmentObject for AuthenticationService

#### 2. NotificationSettingsView.swift
- **Location:** Views/Settings/NotificationSettingsView.swift
- **Features:**
  - Master push notifications toggle
  - Quiet hours configuration
  - 5 notification types:
    * Check-in reminders
    * Meal window reminders
    * Performance insights
    * Achievements
    * System updates
- **Data Model:** NotificationPreferences struct with 10+ options

#### 3. ScheduleSettingsView.swift
- **Location:** Views/Settings/ScheduleSettingsView.swift
- **Features:**
  - Work schedule configuration
  - Meal timing preferences
  - Fasting protocol selection
  - Activity level settings
- **Integration:** Updates UserProfile directly

### Data Models

#### UserProfile.swift
```swift
struct UserProfile {
    // Personal
    var name: String
    var email: String?
    var dateOfBirth: Date?
    
    // Schedule preferences
    var workSchedule: WorkSchedule
    var mealTimingPreference: MealTimingPreference
    var fastingProtocol: FastingProtocol?
    
    // Goals
    var primaryGoal: UserGoal
    var targetWeight: Double?
    
    // Preferences
    var notificationPreferences: NotificationPreferences
    var measurementSystem: MeasurementSystem
}
```

#### NotificationPreferences.swift
```swift
struct NotificationPreferences {
    var pushEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var checkInReminders: Bool
    var mealWindowReminders: Bool
    var performanceInsights: Bool
    var achievements: Bool
    var systemUpdates: Bool
}
```

---

## 🎨 Design System & UI Patterns

### Color Scheme
```swift
// Dark theme colors
Color("nutriSyncBackground")     // Near black
Color("nutriSyncElevated")       // Slightly elevated surface
Color("nutriSyncCard")           // Card background
Color("nutriSyncAccent")         // Green accent
Color("nutriSyncSecondaryText")  // Dimmed text
```

### Common UI Components
- **PhylloButton:** Standardized button component
- **PhylloCard:** Consistent card styling
- **PhylloToggle:** Custom toggle switches
- **Sheet presentations:** Primary modal pattern

### Animation Patterns
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8))
```

---

## 📋 Required Changes

### Files to Modify

1. **DayNavigationHeader.swift**
   - Replace gear icon with hamburger icon
   - Change binding from `showingDeveloperDashboard` to `showingSettingsMenu`
   - Move icon from right to left side

2. **PerformanceHeaderView.swift**
   - Same changes as DayNavigationHeader
   - Maintain consistency between tabs

3. **AIScheduleView.swift**
   - Add `@State private var showingSettingsMenu = false`
   - Add `.sheet(isPresented: $showingSettingsMenu)`
   - Keep developer dashboard as separate option

4. **NutritionDashboardView.swift**
   - Same state management as AIScheduleView
   - Consistent sheet presentation

### New Files to Create

1. **SettingsMenuView.swift**
   - Main settings hub view
   - Navigation list with sections
   - Links to existing settings views

2. **AppPreferencesView.swift** (Optional)
   - App-specific preferences
   - Theme selection (if implementing)
   - Default units

---

## 🗂 Proposed Settings Menu Structure

```
Settings Menu
├── Account & Profile
│   ├── Profile Information
│   ├── Goals & Targets
│   └── Account Settings → AccountSettingsView
├── Schedule & Preferences
│   └── Schedule Settings → ScheduleSettingsView
├── Notifications
│   └── Notification Settings → NotificationSettingsView
├── App Preferences
│   ├── Units & Measurements
│   ├── Default Views
│   └── Cache Management
├── Data & Privacy
│   ├── Data Export
│   ├── Data Deletion
│   └── Privacy Settings
├── About & Support
│   ├── App Version
│   ├── Support Contact
│   ├── Terms of Service
│   └── Privacy Policy
└── Developer Tools (Debug builds only)
    └── Developer Dashboard → DeveloperDashboardView
```

---

## 🔧 Technical Implementation Details

### Navigation State Management
```swift
// In parent views (AIScheduleView, NutritionDashboardView)
@State private var showingSettingsMenu = false
@State private var showingDeveloperDashboard = false // Keep separate

// Sheet presentation
.sheet(isPresented: $showingSettingsMenu) {
    SettingsMenuView()
}
```

### Hamburger Button Implementation
```swift
// New hamburger button (left side)
Button(action: { showingSettingsMenu = true }) {
    Image(systemName: "line.3.horizontal")
        .font(.system(size: 22, weight: .medium))
        .foregroundColor(Color("nutriSyncSecondaryText"))
}
.frame(width: 44, height: 44) // Larger tap target
```

### Settings Menu Navigation
```swift
struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    
    var body: some View {
        NavigationStack {
            List {
                // Sections with NavigationLink to existing views
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

---

## 🚧 Challenges & Considerations

### 1. Developer Dashboard Access
- **Challenge:** Currently accessed via gear icon
- **Solution:** Add as bottom section in settings menu for debug builds only
- **Implementation:** Use `#if DEBUG` conditional compilation

### 2. State Synchronization
- **Challenge:** Settings changes must propagate to all ViewModels
- **Solution:** Use existing @EnvironmentObject pattern with FirebaseDataProvider
- **Testing:** Verify real-time updates across views

### 3. Navigation Consistency
- **Challenge:** Same experience from both tabs
- **Solution:** Shared SettingsMenuView component
- **Testing:** Verify from all entry points

### 4. Permission Handling
- **Challenge:** Notification permissions require system prompts
- **Solution:** Use existing NotificationManager patterns
- **Edge Case:** Handle permission denial gracefully

### 5. Icon Migration
- **Challenge:** Users expect gear for settings
- **Solution:** Could keep gear icon but move to left as alternative
- **A/B Testing:** Consider user preference

---

## 🔍 Code Patterns to Follow

### Sheet Presentation Pattern
```swift
// From existing implementations
.sheet(isPresented: $showingView) {
    ViewName()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

### List Style Pattern
```swift
// From existing settings views
List {
    Section {
        // Content
    } header: {
        Text("Section Title")
    }
}
.listStyle(InsetGroupedListStyle())
.scrollContentBackground(.hidden)
.background(Color("nutriSyncBackground"))
```

### Toggle Pattern
```swift
// From NotificationSettingsView
Toggle(isOn: $preference) {
    VStack(alignment: .leading, spacing: 4) {
        Text("Setting Name")
            .font(.body)
        Text("Description")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
.tint(Color("nutriSyncAccent"))
```

---

## 📊 Effort Estimation

### Development Time
- **Research Phase:** ✅ Complete
- **Planning Phase:** 1 session (with user input)
- **Implementation Phase:** 2-3 sessions
- **Testing & Polish:** 1 session

### Complexity: **Medium**
- Leverages existing infrastructure
- Clear patterns to follow
- Minimal new functionality

### Risk Level: **Low**
- Non-breaking changes
- Progressive enhancement
- Easy rollback if needed

---

## 🎯 Success Criteria

1. ✅ Hamburger menu accessible from Schedule and Performance tabs
2. ✅ All existing settings views integrated
3. ✅ Developer dashboard still accessible (debug only)
4. ✅ Consistent navigation experience
5. ✅ Settings persist correctly
6. ✅ Clean, intuitive UI following app design patterns

---

## 📝 Next Steps

**PHASE 1: RESEARCH COMPLETE**

To proceed to Phase 2 (Planning):
1. Start a **NEW session**
2. Provide this research document: `@research-settings-menu.md`
3. Agent will create detailed implementation plan with your input
4. You'll be asked to approve design decisions

---

*End of Research Document - Phase 1 Complete*