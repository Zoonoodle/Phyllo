# Implementation Plan: Trial Toast Notification & Paywall Redesign
## Replace Persistent Banner with Toast + Improve Trial Welcome

**Plan Date:** 2025-11-19
**Status:** Phase 2 - Planning Complete
**Based on:** `research-trial-nudge-paywall.md`
**Estimated Sessions:** 1-2 (Low-Medium complexity)

---

## 📋 User Design Decisions

✅ **Question 1:** Add toast notification **each time app opens**, showing hours left in trial
✅ **Question 2:** No persistent trial info - only show when approaching limits
✅ **Question 3:** Welcoming tone: "Welcome to Your 24-Hour Trial! 🎉"
✅ **Question 4:** Keep current triggers (welcome, limit reached, expired)
✅ **Question 5:** Keep DEBUG mode with dismiss + reset trial capability

---

## 🎯 Implementation Goals

1. **Remove** persistent `GracePeriodBanner` from top of screen
2. **Create** `TrialToastView` component for subtle notifications
3. **Show toast** every time app opens (foreground) during trial period
4. **Update** trial welcome paywall with welcoming tone
5. **Keep** hard paywall when trial expires (no changes)
6. **Maintain** all existing trial logic (limits, expiration, etc.)

---

## 📁 Files to Modify

### Files to Edit (4 files):
1. **MainAppView.swift** - Remove banner, add toast overlay
2. **PaywallView.swift** - Update trial welcome text
3. **GracePeriodManager.swift** - Add toast display tracking
4. **ContentView.swift** - Add foreground trigger for toast

### Files to Create (1 file):
5. **TrialToastView.swift** - New toast component

### Files to Test (All modified files):
- Compile with `swiftc -parse` after each change
- Manual testing in Xcode simulator

---

## 🔨 Step-by-Step Implementation

### STEP 1: Create Toast Component
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Components/TrialToastView.swift`
**Action:** Create new file

**Code to Write:**
```swift
//
//  TrialToastView.swift
//  NutriSync
//
//  Toast notification showing trial time remaining
//

import SwiftUI

struct TrialToastView: View {
    let hoursRemaining: Int
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)

            Text(timeRemainingText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nutriSyncAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismissToast()
            }
        }
    }

    private var timeRemainingText: String {
        if hoursRemaining > 1 {
            return "Free trial: \(hoursRemaining) hours remaining"
        } else if hoursRemaining == 1 {
            return "Free trial: 1 hour remaining"
        } else {
            return "Free trial: Less than 1 hour remaining"
        }
    }

    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.phylloBackground
            .ignoresSafeArea()

        VStack {
            TrialToastView(hoursRemaining: 18) {
                print("Toast dismissed")
            }
            .padding(.top, 60)

            Spacer()
        }
    }
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Components/TrialToastView.swift
```

**Expected Result:** No compilation errors

---

### STEP 2: Update GracePeriodManager
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/GracePeriodManager.swift`
**Action:** Add method to calculate hours remaining

**Changes:**

**Location 1:** After line 233 (after `remainingTimeFormatted` property)

**Add:**
```swift
/// Get remaining hours as integer (for toast display)
var remainingHours: Int {
    guard let endDate = gracePeriodEndDate, isInGracePeriod else {
        return 0
    }

    let now = Date()
    guard now < endDate else {
        return 0
    }

    let remaining = endDate.timeIntervalSince(now)
    return Int(ceil(remaining / 3600))  // Round up to show at least 1 hour
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Services/GracePeriodManager.swift
```

**Expected Result:** No compilation errors

---

### STEP 3: Update MainAppView - Remove Banner, Add Toast
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/MainAppView.swift`
**Action:** Replace persistent banner with toast notification

**Change 1:** Remove state variable for banner collapse
**Location:** Line 25
**Old:**
```swift
@State private var isGracePeriodBannerCollapsed = false
```
**New:**
```swift
@State private var showTrialToast = false
```

**Change 2:** Replace `gracePeriodBannerOverlay` computed property
**Location:** Lines 57-79
**Old:**
```swift
@ViewBuilder
private var gracePeriodBannerOverlay: some View {
    if gracePeriodManager.isInGracePeriod {
        VStack(spacing: 0) {
            GracePeriodBanner(isCollapsed: $isGracePeriodBannerCollapsed)
                .environmentObject(gracePeriodManager)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: isGracePeriodBannerCollapsed) {
                    // Auto-collapse after 5 seconds if currently expanded
                    if !isGracePeriodBannerCollapsed {
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isGracePeriodBannerCollapsed = true
                        }
                    }
                }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }
}
```
**New:**
```swift
@ViewBuilder
private var trialToastOverlay: some View {
    if showTrialToast && gracePeriodManager.isInGracePeriod {
        VStack(spacing: 0) {
            TrialToastView(
                hoursRemaining: gracePeriodManager.remainingHours,
                onDismiss: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showTrialToast = false
                    }
                }
            )
            .padding(.top, 60)  // Below status bar
            .transition(.move(edge: .top).combined(with: .opacity))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
```

**Change 3:** Update body to use new overlay
**Location:** Lines 27-33
**Old:**
```swift
var body: some View {
    ZStack {
        mainTabView
        gracePeriodBannerOverlay
        welcomeBannerOverlay
        loadingOverlay
    }
}
```
**New:**
```swift
var body: some View {
    ZStack {
        mainTabView
        trialToastOverlay
        welcomeBannerOverlay
        loadingOverlay
    }
}
```

**Change 4:** Add method to show toast (add at end of struct, before closing brace)
**Location:** After line 117 (before closing `}`)
**Add:**
```swift

// MARK: - Trial Toast Methods

func showTrialToastIfNeeded() {
    guard gracePeriodManager.isInGracePeriod else { return }

    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        showTrialToast = true
    }
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/MainAppView.swift
```

**Expected Result:** No compilation errors

---

### STEP 4: Update ContentView - Trigger Toast on Foreground
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/ContentView.swift`
**Action:** Show toast when app becomes active

**Change 1:** Add binding to pass to MainAppView
**Location:** Line 166 (in MainAppView initialization)

**Old:**
```swift
MainAppView(
    showNotificationOnboarding: $showNotificationOnboarding,
    showWelcomeBanner: $showWelcomeBanner,
    isGeneratingFirstDayWindows: $isGeneratingFirstDayWindows,
    scenePhase: scenePhase,
    shouldRefreshData: $shouldRefreshData,
    checkNotificationOnboarding: checkNotificationOnboarding,
    checkFirstDayWindows: checkFirstDayWindows,
    handleScenePhaseChange: handleScenePhaseChange,
    refreshAppData: refreshAppData
)
```

**New:**
```swift
MainAppView(
    showNotificationOnboarding: $showNotificationOnboarding,
    showWelcomeBanner: $showWelcomeBanner,
    isGeneratingFirstDayWindows: $isGeneratingFirstDayWindows,
    scenePhase: scenePhase,
    shouldRefreshData: $shouldRefreshData,
    checkNotificationOnboarding: checkNotificationOnboarding,
    checkFirstDayWindows: checkFirstDayWindows,
    handleScenePhaseChange: handleScenePhaseChange,
    refreshAppData: refreshAppData,
    showTrialToast: showTrialToastOnForeground
)
```

**Change 2:** Add function to show toast
**Location:** After `handleScenePhaseChange` function (around line 295)
**Add:**
```swift

private func showTrialToastOnForeground() {
    // This will be called from MainAppView when app becomes active
    // Toast is only shown if user is in grace period
}
```

**Note:** This is a placeholder - the actual triggering happens in handleScenePhaseChange

**Change 3:** Update handleScenePhaseChange to trigger toast
**Location:** Lines 264-295 (inside the `.active` case)

**Find the `.active` case and add toast trigger:**
```swift
case .active:
    // Check if we need to refresh when becoming active
    if lastBackgroundTimestamp > 0 {
        let currentTime = Date().timeIntervalSince1970
        let timeDifference = currentTime - lastBackgroundTimestamp

        if timeDifference >= refreshThreshold {
            print("🔄 App was inactive for \(Int(timeDifference / 60)) minutes, refreshing data...")
            shouldRefreshData = true
        } else {
            print("📱 App became active after \(Int(timeDifference)) seconds")
        }

        // Reset timestamp
        lastBackgroundTimestamp = 0

        // NEW: Show trial toast if in grace period
        if gracePeriodManager.isInGracePeriod {
            // Small delay to let UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // This will be handled by MainAppView
                NotificationCenter.default.post(
                    name: .showTrialToast,
                    object: nil
                )
            }
        }
    }
```

**Change 4:** Add notification extension
**Location:** After the file's last extension (around line 414)
**Add:**
```swift

// MARK: - Trial Toast Notification

extension Notification.Name {
    static let showTrialToast = Notification.Name("showTrialToast")
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/ContentView.swift
```

**Expected Result:** No compilation errors

---

### STEP 5: Update MainAppView to Receive Notification
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/MainAppView.swift`
**Action:** Listen for toast notification

**Change:** Update `mainTabView` to add notification listener
**Location:** Lines 36-55

**Old:**
```swift
private var mainTabView: some View {
    MainTabView()
        .fullScreenCover(isPresented: $showNotificationOnboarding) {
            NotificationOnboardingView(isPresented: $showNotificationOnboarding)
                .environmentObject(notificationManager)
        }
        .task {
            await checkNotificationOnboarding()
            await checkFirstDayWindows()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase, newPhase)
        }
        .task(id: shouldRefreshData) {
            if shouldRefreshData {
                await refreshAppData()
                shouldRefreshData = false
            }
        }
}
```

**New:**
```swift
private var mainTabView: some View {
    MainTabView()
        .fullScreenCover(isPresented: $showNotificationOnboarding) {
            NotificationOnboardingView(isPresented: $showNotificationOnboarding)
                .environmentObject(notificationManager)
        }
        .task {
            await checkNotificationOnboarding()
            await checkFirstDayWindows()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase, newPhase)
        }
        .task(id: shouldRefreshData) {
            if shouldRefreshData {
                await refreshAppData()
                shouldRefreshData = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTrialToast)) { _ in
            showTrialToastIfNeeded()
        }
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/MainAppView.swift
```

**Expected Result:** No compilation errors

---

### STEP 6: Update PaywallView - Trial Welcome Text
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Subscription/PaywallView.swift`
**Action:** Add specific case for trial_welcome placement

**Change 1:** Update headerTitle computed property
**Location:** Lines 271-282

**Old:**
```swift
private var headerTitle: String {
    switch placement {
    case "window_gen_limit_reached":
        return "Subscribe to Continue"
    case "meal_scan_limit_reached":
        return "Subscribe for Full Access"
    case "grace_period_expired":
        return "Free Trial Ended"
    default:
        return "Subscribe for Access"
    }
}
```

**New:**
```swift
private var headerTitle: String {
    switch placement {
    case "trial_welcome":
        return "Welcome to Your 24-Hour Trial! 🎉"
    case "window_gen_limit_reached":
        return "Subscribe to Continue"
    case "meal_scan_limit_reached":
        return "Subscribe for Full Access"
    case "grace_period_expired":
        return "Free Trial Ended"
    default:
        return "Subscribe for Access"
    }
}
```

**Change 2:** Update headerSubtitle computed property
**Location:** Lines 284-295

**Old:**
```swift
private var headerSubtitle: String {
    switch placement {
    case "window_gen_limit_reached":
        return "You've reached your trial limit. Subscribe to continue with unlimited personalized meal windows."
    case "meal_scan_limit_reached":
        return "You've reached your trial limit. Subscribe to continue with unlimited AI meal analysis."
    case "grace_period_expired":
        return "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition."
    default:
        return "Continue your nutrition journey with full access to all features."
    }
}
```

**New:**
```swift
private var headerSubtitle: String {
    switch placement {
    case "trial_welcome":
        return "You have 4 free meal scans to experience AI-powered nutrition tracking. Subscribe anytime for unlimited access and personalized meal windows."
    case "window_gen_limit_reached":
        return "You've reached your trial limit. Subscribe to continue with unlimited personalized meal windows."
    case "meal_scan_limit_reached":
        return "You've reached your trial limit. Subscribe to continue with unlimited AI meal analysis."
    case "grace_period_expired":
        return "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition."
    default:
        return "Continue your nutrition journey with full access to all features."
    }
}
```

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Subscription/PaywallView.swift
```

**Expected Result:** No compilation errors

---

### STEP 7: Final Compilation Test
**Action:** Compile all modified files together

**Test Command:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Components/TrialToastView.swift \
  NutriSync/Services/GracePeriodManager.swift \
  NutriSync/Views/MainAppView.swift \
  NutriSync/Views/ContentView.swift \
  NutriSync/Views/Subscription/PaywallView.swift
```

**Expected Result:** No compilation errors

---

## ✅ Testing Checklist

### Manual Testing in Xcode:

**Test 1: Toast on App Open (Fresh Trial)**
- [ ] Start fresh trial (24 hours, 4 scans)
- [ ] Open app
- [ ] **Expected:** Toast appears showing "Free trial: 24 hours remaining"
- [ ] **Expected:** Toast auto-dismisses after 4 seconds
- [ ] Background app
- [ ] Foreground app
- [ ] **Expected:** Toast appears again

**Test 2: Toast with Low Time**
- [ ] Set trial to expire in 30 minutes (modify grace period end date)
- [ ] Open app
- [ ] **Expected:** Toast shows "Free trial: 1 hour remaining" (rounds up)
- [ ] Set trial to expire in 15 minutes
- [ ] Open app
- [ ] **Expected:** Toast shows "Free trial: Less than 1 hour remaining"

**Test 3: Toast Manual Dismissal**
- [ ] Open app during trial
- [ ] **Expected:** Toast appears
- [ ] Tap X button on toast
- [ ] **Expected:** Toast slides up and disappears immediately

**Test 4: Trial Welcome Paywall**
- [ ] Start fresh trial
- [ ] Scan first meal
- [ ] Wait for AI analysis to complete
- [ ] **Expected:** Paywall appears with:
  - Title: "Welcome to Your 24-Hour Trial! 🎉"
  - Subtitle: "You have 4 free meal scans to experience..."
  - Features list (existing)
  - Package selection (existing)
- [ ] Tap X to dismiss
- [ ] **Expected:** Paywall dismisses, can continue using app

**Test 5: No Banner Present**
- [ ] Open app during trial
- [ ] **Expected:** NO persistent banner at top
- [ ] **Expected:** Only toast appears (auto-dismisses)
- [ ] Navigate between tabs
- [ ] **Expected:** NO banner visible on any tab

**Test 6: Hard Paywall (Expired Trial)**
- [ ] Let trial expire (24 hours pass) OR manually set grace period end date to past
- [ ] Open app
- [ ] **Expected:** Full-screen blocking paywall with:
  - Title: "Free Trial Ended"
  - Subtitle: "Your 24-hour trial has ended..."
  - NO close button (production)
  - OR close button with reset (DEBUG mode)

**Test 7: Subscribed User (No Trial UI)**
- [ ] Subscribe or mock subscription status
- [ ] Open app
- [ ] **Expected:** NO toast appears
- [ ] **Expected:** NO trial UI anywhere
- [ ] Background and foreground app
- [ ] **Expected:** Still no toast

**Test 8: Edge Cases**
- [ ] **Offline:** Disconnect internet, open app
  - **Expected:** Toast works (UserDefaults backup)
- [ ] **Rapid Backgrounding:** Background/foreground 5 times quickly
  - **Expected:** Toast appears each time (might be annoying but expected)
- [ ] **During Toast Display:** Background app while toast is visible
  - **Expected:** Toast disappears, reappears on foreground

---

## 🚨 Risk Assessment

### Low Risk:
- ✅ Toast is new component - won't break existing features
- ✅ Hard paywall unchanged - already works
- ✅ Trial welcome logic unchanged - just text updates

### Medium Risk:
- ⚠️ Removing banner might cause visual glitches if other components depend on it
  - **Mitigation:** Banner is isolated component, only referenced in MainAppView
- ⚠️ Toast showing on EVERY foreground might be annoying
  - **Mitigation:** User requested this behavior, can adjust in future if needed

### Edge Cases Handled:
- ✅ Toast only shows if `isInGracePeriod == true`
- ✅ Hours calculation rounds up (avoids "0 hours" display)
- ✅ Auto-dismiss prevents toast from staying forever
- ✅ Manual dismiss allows user to remove toast immediately
- ✅ Notification system prevents race conditions

---

## 🔄 Rollback Strategy

If issues arise after implementation:

### Quick Rollback (Revert Changes):
```bash
git checkout HEAD~1 -- NutriSync/Views/MainAppView.swift
git checkout HEAD~1 -- NutriSync/Views/ContentView.swift
rm NutriSync/Views/Components/TrialToastView.swift
```

### Partial Rollback (Keep Toast, Restore Banner):
- Revert MainAppView.swift changes
- Keep TrialToastView.swift for future use
- Restore `gracePeriodBannerOverlay` logic

### Data Safety:
- No database changes
- No UserDefaults changes (except notification listener)
- No Firestore schema changes
- All changes are UI-only → Safe to rollback

---

## 📊 Success Criteria

Implementation is successful when:

- [ ] **Compilation succeeds** for all modified files
- [ ] **No console errors** when running app
- [ ] **Toast appears** when app opens during trial
- [ ] **Toast shows correct hours** remaining
- [ ] **Toast auto-dismisses** after 4 seconds
- [ ] **Toast can be manually dismissed** with X button
- [ ] **No banner visible** at top of screen during trial
- [ ] **Trial welcome paywall** shows welcoming text after first scan
- [ ] **Hard paywall blocks app** when trial expires
- [ ] **DEBUG mode** allows paywall dismissal (keeps current behavior)
- [ ] **Subscribed users** see NO trial UI
- [ ] **All edge cases** tested and working

---

## 🎨 Visual Design Specifications

### Toast Appearance:
- **Size:** Auto-height, full-width minus 32px padding
- **Position:** 60px from top (below status bar)
- **Background:** `Color.white.opacity(0.1)` with blur effect
- **Border:** `Color.nutriSyncAccent.opacity(0.3)`, 1px
- **Corner Radius:** 12px
- **Shadow:** Black 0.2 opacity, 8px radius, 4px Y offset
- **Animation:** Spring (response: 0.4, damping: 0.8)
- **Auto-dismiss:** 4 seconds
- **Icon:** `clock.fill` in lime green (#C0FF73)
- **Text:** System 14pt medium, white color

### Trial Welcome Paywall:
- **Header Icon:** `sparkles` (existing)
- **Title:** "Welcome to Your 24-Hour Trial! 🎉" (size 28pt bold)
- **Subtitle:** Trial-specific explanation (size 17pt)
- **Rest:** Existing paywall design (features, packages, button)

---

## 📝 Implementation Notes

### Why Toast on EVERY Foreground?
- User requested this behavior explicitly
- Keeps trial awareness high
- Prevents "forgetting about trial" syndrome
- Can be adjusted later if too intrusive (add tracking to show max 3 times/day)

### Why Not Track "Times Shown"?
- User didn't request limiting frequency
- Simpler implementation (less state to track)
- More aggressive trial awareness = potentially higher conversion
- Can add frequency limiting in Phase 2 if user wants

### Why Round Hours Up?
- Avoids showing "0 hours remaining" when technically still in trial
- More user-friendly ("Less than 1 hour" is clearer)
- Matches common UX patterns

### Why 4-Second Auto-Dismiss?
- Long enough to read
- Short enough not to be annoying
- Can be adjusted if user wants longer/shorter

---

## 🚀 Next Steps

### Phase 3: Implementation

**Before Starting:**
1. ✅ User has approved this plan
2. ✅ Research document reviewed
3. ✅ All design questions answered

**During Implementation:**
1. Follow steps EXACTLY in order
2. Test with `swiftc -parse` after EACH file change
3. Commit after EACH working step
4. Monitor context usage (stop at 60%)
5. Create progress doc if context limit approached

**After Implementation:**
1. Run all manual tests in Xcode
2. Take screenshots of:
   - Toast notification
   - Trial welcome paywall
   - Hard paywall (expired trial)
3. Get user approval
4. Delete temp files (research-*.md, plan-*.md)
5. Update codebase-todolist.md

---

## 📞 Ready for Implementation?

**User: Please confirm you want to proceed with implementation, or request changes to this plan.**

**If approved, I will:**
1. Create `TrialToastView.swift`
2. Update `GracePeriodManager.swift`
3. Update `MainAppView.swift`
4. Update `ContentView.swift`
5. Update `PaywallView.swift`
6. Test all changes with `swiftc -parse`
7. Request manual testing in Xcode

**Estimated time:** 1 session (plenty of context remaining: 67%)

---

**Plan Complete ✅**

**Created:** 2025-11-19
**Agent:** Planning Phase Agent
**Awaiting:** User approval to proceed to Phase 3 (Implementation)
