# Settings Menu Implementation Plan
## Phase 2: Planning Documentation

**Date:** 2025-09-15  
**Feature:** Settings Menu with Gear Navigation  
**Planner:** Phase 2 Planning Agent  
**User Preferences:** Fable-inspired design, dark theme, gear icon navigation

---

## 📋 User-Approved Design Decisions

1. **Icon:** Gear icon on left side (settings), hammer icon within menu (dev tools)
2. **Presentation:** Full-screen sheet with navigation stack
3. **Developer Access:** Include at bottom of settings menu (debug builds only)
4. **Initial Scope:** Core settings only (Account, Schedule, Notifications)
5. **Implementation:** Both tabs simultaneously

---

## 🎨 Design Specification (Fable-Inspired)

### Visual Layout
```swift
Settings Menu Structure:
┌─────────────────────────────────┐
│ ← Settings                      │ (Navigation bar)
├─────────────────────────────────┤
│ Your nutrition journey          │ (Section header)
│ 📊 Schedule Settings         >  │
│ 🔔 Notification Settings     >  │
├─────────────────────────────────┤
│ Support                         │ (Section header)
│ 🐛 Report a bug             >  │
│ ❓ Ask a question            >  │
│ 💡 Submit a feature request  >  │
│ 🔒 Privacy policy            >  │
├─────────────────────────────────┤
│ Your account                    │ (Section header)
│ 👤 Account Settings          >  │
│ 📝 Terms of Service          >  │
│ 🗑️ Delete account               │
│ 🚪 Log out                      │
├─────────────────────────────────┤
│ Developer (Debug only)          │ (Section header)
│ 🔨 Developer Dashboard       >  │
├─────────────────────────────────┤
│        user@email.com           │
│    NutriSync • version 1.0.0    │
└─────────────────────────────────┘
```

### Color Scheme
```swift
// Dark theme matching NutriSync design
backgroundColor: Color("nutriSyncBackground")      // Near black
sectionBackground: Color("nutriSyncElevated")      // Slightly elevated
textPrimary: Color.white
textSecondary: Color.white.opacity(0.7)
textTertiary: Color.white.opacity(0.5)
destructiveAction: Color.red.opacity(0.9)
chevronColor: Color.white.opacity(0.3)
```

---

## 📁 File Structure & Implementation Steps

### Step 1: Create SettingsMenuView.swift
**File:** `Views/Settings/SettingsMenuView.swift`
**Priority:** High
**Tasks:**
- Create main settings hub view
- Implement sectioned List with InsetGroupedListStyle
- Add navigation structure
- Apply dark theme styling
- Include conditional developer section

### Step 2: Update DayNavigationHeader.swift
**File:** `Views/Components/DayNavigationHeader.swift`
**Priority:** High
**Tasks:**
- Move gear icon from right to left side
- Change binding from `showingDeveloperDashboard` to `showingSettingsMenu`
- Update icon styling to match design
- Ensure proper frame for tap target (44x44)

### Step 3: Update PerformanceHeaderView.swift
**File:** `Views/Momentum/PerformanceHeaderView.swift`
**Priority:** High
**Tasks:**
- Same changes as DayNavigationHeader
- Maintain consistency between headers
- Test alignment and spacing

### Step 4: Modify AIScheduleView.swift
**File:** `Views/Focus/AIScheduleView.swift`
**Priority:** High
**Tasks:**
- Add `@State private var showingSettingsMenu = false`
- Add sheet presentation for SettingsMenuView
- Remove direct developer dashboard sheet
- Pass binding to header component

### Step 5: Modify NutritionDashboardView.swift
**File:** `Views/Momentum/NutritionDashboardView.swift`
**Priority:** High
**Tasks:**
- Same state management as AIScheduleView
- Consistent sheet presentation
- Update header binding

### Step 6: Create Support Link Handlers
**File:** `Services/SupportService.swift` (NEW)
**Priority:** Medium
**Tasks:**
- Implement email composer for bug reports
- Add feature request handler
- Link to privacy policy URL
- Create question submission flow

### Step 7: Update Account Settings Integration
**File:** `Views/Settings/AccountSettingsView.swift`
**Priority:** Low (already exists)
**Tasks:**
- Verify navigation from settings menu
- Ensure back navigation works
- Test all account actions

### Step 8: Add Version Info Component
**File:** `Views/Settings/Components/VersionInfoView.swift` (NEW)
**Priority:** Low
**Tasks:**
- Display app version from Info.plist
- Show user email if logged in
- Center-align text
- Apply tertiary text color

---

## 🔧 Technical Implementation Details

### Navigation State Management
```swift
// Parent view implementation
struct AIScheduleView: View {
    @State private var showingSettingsMenu = false
    
    var body: some View {
        VStack {
            DayNavigationHeader(
                showingSettingsMenu: $showingSettingsMenu,
                // other parameters...
            )
            // Rest of view...
        }
        .sheet(isPresented: $showingSettingsMenu) {
            SettingsMenuView()
        }
    }
}
```

### Settings Menu Structure
```swift
struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Core Settings
                Section {
                    NavigationLink(destination: ScheduleSettingsView()) {
                        Label("Schedule Settings", systemImage: "calendar")
                    }
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notification Settings", systemImage: "bell")
                    }
                } header: {
                    Text("Your nutrition journey")
                        .textCase(nil)
                }
                
                // Section 2: Support
                Section {
                    // Support links...
                } header: {
                    Text("Support")
                        .textCase(nil)
                }
                
                // Section 3: Account
                Section {
                    // Account options...
                } header: {
                    Text("Your account")
                        .textCase(nil)
                }
                
                // Section 4: Developer (conditional)
                #if DEBUG
                Section {
                    NavigationLink(destination: DeveloperDashboardView()) {
                        Label("Developer Dashboard", systemImage: "hammer")
                    }
                } header: {
                    Text("Developer")
                        .textCase(nil)
                }
                #endif
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color("nutriSyncBackground"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
```

### Gear Button Implementation
```swift
// Updated header component
struct DayNavigationHeader: View {
    @Binding var showingSettingsMenu: Bool
    
    var body: some View {
        HStack {
            // Settings button (left side)
            Button(action: { showingSettingsMenu = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("nutriSyncSecondaryText"))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Date navigation in center
            // ...existing date navigation code...
            
            Spacer()
            
            // Balance right side
            Color.clear.frame(width: 44, height: 44)
        }
    }
}
```

---

## ✅ Testing Checklist

### Functional Testing
- [ ] Settings menu opens from Schedule tab
- [ ] Settings menu opens from Performance tab
- [ ] All navigation links work correctly
- [ ] Back navigation returns to correct tab
- [ ] Account actions execute properly
- [ ] Developer dashboard appears in debug builds only
- [ ] Support links trigger correct actions

### Visual Testing
- [ ] Dark theme applied consistently
- [ ] Icons display correctly
- [ ] Chevrons aligned properly
- [ ] Text hierarchy clear
- [ ] Spacing matches design
- [ ] Version info displays correctly

### Edge Cases
- [ ] Settings menu dismissal saves any changes
- [ ] Rotation handling (if applicable)
- [ ] Memory management with multiple navigations
- [ ] Deep linking from notifications
- [ ] Offline mode behavior

---

## 📊 Success Metrics

1. **Navigation Accessibility**: Settings accessible within 1 tap
2. **Visual Consistency**: Matches Fable-inspired design at 95%+
3. **Performance**: Menu opens in < 0.3 seconds
4. **Discoverability**: Users find settings without guidance
5. **Completion Rate**: Users complete settings tasks successfully

---

## 🚀 Implementation Order

### Session 3 Tasks (Priority Order):
1. Create SettingsMenuView.swift
2. Update both header components
3. Modify parent views (AIScheduleView, NutritionDashboardView)
4. Test basic navigation flow
5. Compile and verify

### Session 4 Tasks (if needed):
6. Create SupportService.swift
7. Add VersionInfoView component
8. Polish animations and transitions
9. Complete testing checklist
10. Final compilation and push

---

## ⚠️ Risk Mitigation

### Potential Issues & Solutions

1. **Navigation Stack Conflicts**
   - Risk: Nested navigation causing issues
   - Solution: Use NavigationStack only at root level

2. **Sheet Presentation Memory**
   - Risk: Memory leaks with repeated presentations
   - Solution: Proper dismiss handling and weak references

3. **Developer Dashboard Access**
   - Risk: Accidentally shipping to production
   - Solution: Use #if DEBUG compiler directive

4. **Support Email Failures**
   - Risk: No email client configured
   - Solution: Fallback to clipboard copy

---

## 📝 Notes

- Keep existing DeveloperDashboardView unchanged
- Preserve all existing settings views functionality
- Follow established animation patterns (.spring)
- Maintain 44pt minimum tap targets
- Use SF Symbols for all icons
- Test thoroughly before marking complete

---

**PHASE 2: PLANNING COMPLETE**

To proceed to Phase 3 (Implementation):
1. Start a **NEW session**
2. Provide this plan: `@plan-settings-menu.md`
3. Include research if needed: `@research-settings-menu.md`
4. Agent will execute implementation following this plan exactly

---

*End of Planning Document - Phase 2 Complete*