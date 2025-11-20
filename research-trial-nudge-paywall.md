# Research: Trial Nudge & Paywall System Redesign
## Converting Persistent Banner to Nudge + Hard Paywall

**Investigation Date:** 2025-11-19
**Status:** Phase 1 - Research Complete
**Next Phase:** Planning (requires user design input)

---

## 📋 Investigation Topic

Replace the current persistent "Free Trial Active" banner with:
1. **Initial Nudge** - Subtle notification that informs user of trial status at first
2. **Hard Paywall** - Mandatory subscription popup when trial expires (no dismiss option)

---

## 🔍 Current Implementation Analysis

### 1. Persistent Trial Banner (GracePeriodBanner.swift)

**Location:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Components/GracePeriodBanner.swift`

**Current Behavior:**
- Shown at **top of screen** overlaying all content
- **Always visible** when `isInGracePeriod == true`
- Displays:
  - "Free Trial Active" text
  - Remaining scans count
  - Remaining hours
  - "Subscribe" button
- Has **two states**:
  - **Collapsed** (line green bar with minimal text)
  - **Expanded** (full banner with all info)
- **Auto-collapses** after 5 seconds
- User can tap to toggle between states

**Integration Point:** `MainAppView.swift:58-79`
```swift
@ViewBuilder
private var gracePeriodBannerOverlay: some View {
    if gracePeriodManager.isInGracePeriod {
        VStack(spacing: 0) {
            GracePeriodBanner(isCollapsed: $isGracePeriodBannerCollapsed)
                .task(id: isGracePeriodBannerCollapsed) {
                    // Auto-collapse after 5 seconds
                    if !isGracePeriodBannerCollapsed {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isGracePeriodBannerCollapsed = true
                        }
                    }
                }
            Spacer()
        }
    }
}
```

**Visual Appearance:**
- **Collapsed:** Lime green bar (#C0FF73) with dark text
- **Expanded:** Black background with lime green accent, white text
- Ignores safe area (extends into status bar)

---

### 2. Trial Welcome Paywall (Already Exists!)

**Location:** `GracePeriodManager.swift:180-209`

**Discovery:** The app **already has** a trial welcome system that shows after first action!

**Current Trigger Logic:**
```swift
func showTrialWelcomeIfNeeded() async {
    guard isInGracePeriod && !hasSeenTrialWelcome else { return }

    hasSeenTrialWelcome = true
    // Save to Firestore...

    NotificationCenter.default.post(
        name: .showPaywall,
        object: "trial_welcome"  // Placement string
    )
}
```

**Called After:**
1. First meal scan completion (`MealCaptureService.swift:194`)
2. First window generation completion (`AIWindowGenerationService.swift:482`)

**Current Presentation:**
- Shows as **dismissible sheet** (not blocking)
- Uses **generic text** instead of trial-specific welcome:
  - Title: "Subscribe for Access" (default case)
  - Subtitle: "Continue your nutrition journey with full access to all features."
- Has close button (X) in top-right

**Problem:** Generic text doesn't explain the trial benefits or urgency!

---

### 3. Hard Paywall (Trial Expired)

**Location:** `ContentView.swift:126-163`

**Current Condition:**
```swift
if !subscriptionManager.isSubscribed
   && !gracePeriodManager.isInGracePeriod
   && gracePeriodManager.gracePeriodEndDate != nil {
    // Show hard paywall
}
```

**Presentation:**
- **Full-screen** blocking view (not dismissible in production)
- Replaces entire app content
- Placement: `"grace_period_expired"`
- Text:
  - Title: "Free Trial Ended"
  - Subtitle: "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition."

**DEBUG Mode Difference:**
- `onDismiss` callback that **resets trial** for testing
- In production: `onDismiss` not provided → no close button

**This already works as desired!** Just needs the banner removal.

---

### 4. Grace Period System Details

**Location:** `GracePeriodManager.swift`

**Trial Limits:**
- **Duration:** 24 hours
- **Free Scans:** 4 meals
- **Free Window Gens:** 1 generation
- Stored in: `users/{userId}/subscription/gracePeriod` (Firestore)
- Backup in: UserDefaults for offline scenarios

**Tracking Properties:**
```swift
@Published var isInGracePeriod: Bool = false
@Published var remainingScans: Int = 4
@Published var remainingWindowGens: Int = 1
@Published var gracePeriodEndDate: Date?
@Published var hasSeenPaywallOnce: Bool = false
@Published var hasSeenTrialWelcome: Bool = false  // For nudge
```

**Other Paywall Triggers:**
- `meal_scan_limit_reached` - After using 4 scans
- `window_gen_limit_reached` - After 1 window generation
- All shown as **dismissible sheets** (not blocking)

---

## 🎯 Key Questions for User

### 1. What Type of "Nudge" Do You Want?

**Option A: Improve Existing Trial Welcome Paywall**
- **When:** After first meal scan OR first window generation
- **What:** Change generic text to trial-specific welcome message
- **How:** Dismissible sheet (current behavior)
- **Example Text:**
  ```
  Title: "Welcome to Your Free Trial!"
  Subtitle: "You have 24 hours and 4 meal scans to experience NutriSync.
            Subscribe anytime to unlock unlimited access."
  ```
- **Pros:** Already implemented, just needs better copy
- **Cons:** Only shows once, might be missed

**Option B: Toast Notification**
- **When:** Immediately when user first opens the app (after onboarding)
- **What:** Small toast at bottom of screen with trial info
- **How:** Auto-dismisses after 5 seconds, user can tap to dismiss
- **Example:** "Free trial active: 4 scans, 24 hours remaining"
- **Pros:** Non-intrusive, familiar pattern
- **Cons:** Easy to miss, less engaging

**Option C: One-Time Banner**
- **When:** First time user sees the main app
- **What:** Banner similar to current, but **only shows once**
- **How:** Dismissible with X button, never shows again
- **Example:** Similar to current banner but with "Got it" button
- **Pros:** More noticeable than toast
- **Cons:** Still a bit intrusive

**Option D: Alert/Modal**
- **When:** Immediately after onboarding completes
- **What:** Native iOS alert with trial explanation
- **How:** Tap "OK" to dismiss
- **Example:** "You're on a 24-hour free trial with 4 meal scans. Subscribe anytime for unlimited access."
- **Pros:** Guaranteed to be seen
- **Cons:** Blocks interaction until dismissed

**Option E: Keep Trial Welcome + Remove Persistent Banner**
- **When:** After first action (existing behavior)
- **What:** Improve trial welcome text, remove persistent banner
- **How:** No changes to logic, just copy improvements
- **Pros:** Minimal code changes, clean UI
- **Cons:** User might not know they're on trial until first action

### 2. Should Trial Info Be Accessible After Nudge Dismissal?

**Scenario:** User dismisses the nudge, then wonders "how many scans do I have left?"

**Option A: Settings/Profile Tab**
- Add "Subscription Status" section showing trial info
- Always accessible but requires user to know where to look

**Option B: Small Indicator**
- Subtle badge/icon in top corner (like notification dot)
- Tapping shows trial details sheet
- Less intrusive than full banner

**Option C: No Access**
- Once dismissed, user can't see trial info again
- Only shown when limits approached (e.g., "1 scan remaining")

**Option D: Show on Scan/Window Actions**
- Display trial info inline when user is about to scan or generate
- Contextual and relevant

### 3. Paywall Timing Preferences

**Current Triggers:**
1. **Trial welcome** - After first scan/window generation (once)
2. **Limit reached** - After 4 scans OR 1 window gen (dismissible)
3. **Time expired** - After 24 hours (hard paywall)

**Question:** Should we add more paywall opportunities?

**Option A: Keep Current Triggers**
- 3 touchpoints total (welcome, limit, expired)
- Not too aggressive

**Option B: Add Mid-Trial Reminder**
- Show dismissible paywall at 50% time remaining (12 hours)
- "Your trial expires in 12 hours - subscribe now to keep your progress!"

**Option C: Show on Every Scan After Trial Welcome**
- After seeing welcome paywall, every subsequent scan shows brief upsell
- More aggressive, might annoy users

**Option D: Smart Timing Based on Engagement**
- If user scans 3 meals quickly → show paywall earlier
- If user seems engaged → upsell more aggressively

---

## 💡 Technical Constraints

### 1. Existing Hard Paywall Works Well
- `ContentView.swift:126-163` already handles expired trial correctly
- Shows full-screen blocking view when:
  - `isSubscribed == false`
  - `isInGracePeriod == false`
  - `gracePeriodEndDate != nil` (trial was initialized)
- **No changes needed** for hard paywall functionality!

### 2. Trial Welcome System Exists
- `showTrialWelcomeIfNeeded()` already implemented
- Just needs **better text in PaywallView**
- Currently uses default case instead of specific "trial_welcome" case

### 3. SwiftUI Sheet vs Full-Screen Cover
- **Sheet:** Dismissible by default, can swipe down
- **Full-Screen Cover:** Blocks everything, requires explicit dismiss
- Current welcome uses sheet (good for nudge)
- Expired uses full-screen (good for hard paywall)

### 4. Notification System Already in Place
- `NotificationCenter.default.post(name: .showPaywall, object: placement)`
- Received in `ContentView.swift:218-223`
- Easy to trigger new nudge types

---

## 🔧 Implementation Options

### Option 1: Minimal Changes (RECOMMENDED)
**Changes:**
1. **Remove** persistent `GracePeriodBanner` from `MainAppView.swift`
2. **Update** `PaywallView.swift` to handle "trial_welcome" placement specifically:
   ```swift
   case "trial_welcome":
       return "Welcome to Your Free Trial!"
   // Subtitle with trial details
   ```
3. **Keep** hard paywall logic in `ContentView.swift` (already works)

**Files Modified:** 2 files (MainAppView.swift, PaywallView.swift)
**Complexity:** Low
**User Experience:** Clean, non-intrusive nudge after first action

---

### Option 2: Add Initial Toast Nudge
**Changes:**
1. All changes from Option 1
2. **Create** `TrialToastView.swift` - small toast component
3. **Add** toast trigger in `MainAppView.swift` on first load
4. **Track** `hasSeenInitialToast` in GracePeriodManager

**Files Modified:** 4 files
**Complexity:** Medium
**User Experience:** User sees trial info immediately + welcome paywall later

---

### Option 3: Replace Banner with Collapsible Indicator
**Changes:**
1. **Create** `TrialIndicatorBadge.swift` - small icon in top corner
2. **Add** sheet presentation when tapped showing trial details
3. **Remove** persistent banner
4. **Keep** trial welcome paywall

**Files Modified:** 3 files
**Complexity:** Medium
**User Experience:** Always accessible trial info, non-intrusive

---

### Option 4: One-Time Welcome Banner
**Changes:**
1. **Modify** `GracePeriodBanner.swift` to show **only once**
2. **Add** "Got it" button to dismiss permanently
3. **Track** `hasSeenTrialBanner` in GracePeriodManager
4. **Keep** trial welcome paywall as backup

**Files Modified:** 2 files
**Complexity:** Low
**User Experience:** Familiar banner pattern, but not persistent

---

## 🧪 Edge Cases to Consider

### 1. User Misses the Nudge
- **Problem:** User dismisses nudge, never sees trial info again
- **Solution:** Show trial details in Settings or on scan actions

### 2. User Opens App, Closes Immediately
- **Problem:** If nudge only shows once, user might miss it
- **Solution:** Don't mark as "seen" until user interacts with it

### 3. Offline Scenarios
- **Problem:** Grace period data might not sync from Firestore
- **Solution:** Already handled - UserDefaults backup in GracePeriodManager

### 4. Trial Expired While App Open
- **Problem:** User is mid-session when 24 hours expires
- **Solution:** Already handled - `checkGracePeriodExpiration()` checks on state change

### 5. Subscription During Trial
- **Problem:** User subscribes, but still sees trial UI
- **Solution:** Already handled - `isSubscribed` check hides grace period UI

### 6. Device Changes
- **Problem:** User tries to get new trial on different device
- **Solution:** Already handled - `gracePeriodDevices` collection tracks device ID

---

## ✅ Validation Checklist

To ensure correct implementation, verify:

- [ ] Persistent banner **removed** when `isInGracePeriod == true`
- [ ] Trial nudge **shown exactly once** (or based on user preference)
- [ ] Trial info **accessible** after nudge dismissed (if desired)
- [ ] Trial welcome paywall has **trial-specific text**
- [ ] Hard paywall **blocks app** when `isInGracePeriod == false && gracePeriodEndDate != nil`
- [ ] Hard paywall has **no dismiss button** in production
- [ ] All trial states tested:
  - [ ] Fresh trial start (0 scans, 24 hours)
  - [ ] Mid-trial (2 scans, 12 hours remaining)
  - [ ] Limit reached (4 scans used)
  - [ ] Time expired (24 hours passed)
  - [ ] Subscribed state (no trial UI)
- [ ] Offline scenarios work (UserDefaults backup)
- [ ] Swift compilation succeeds for all modified files
- [ ] No mock data references introduced

---

## 📝 Recommendations

**Based on Screenshots & UX Best Practices:**

### Recommended Approach: **Option 1 (Minimal Changes)**

**Why:**
1. **Persistent banner is visually heavy** - removes significant screen space
2. **Trial welcome already exists** - just needs better copy
3. **Hard paywall already works perfectly** - no changes needed
4. **Minimal code changes** - lower risk of bugs
5. **Clean user experience** - user sees app, takes action, gets welcomed to trial

**Implementation Plan:**
1. Remove `GracePeriodBanner` overlay from `MainAppView.swift`
2. Update `PaywallView.swift` to handle "trial_welcome" with compelling text:
   ```
   Title: "Welcome to Your 24-Hour Trial! 🎉"
   Subtitle: "You have 4 free meal scans to experience AI-powered nutrition tracking.
             Subscribe anytime for unlimited access and personalized meal windows."
   Features: (same as current paywall)
   ```
3. Test all trial states

**What User Sees:**
1. **Onboarding completes** → Clean app interface (no banner)
2. **First meal scan** → AI analyzes meal → Trial welcome paywall appears
3. **User dismisses** → Continues using app normally
4. **Limit reached** → "You've used 4/4 scans" paywall (dismissible)
5. **Trial expires** → Hard paywall (must subscribe or leave)

**If User Wants Trial Info Accessible:**
Add small "ℹ️" icon in Settings showing trial status when tapped.

---

## 📊 Files Requiring Changes

### Option 1 (Minimal - Recommended):
1. **MainAppView.swift** - Remove `gracePeriodBannerOverlay` (lines 58-79)
2. **PaywallView.swift** - Add "trial_welcome" case (lines 270-295)

### Option 2 (Toast Nudge):
1. MainAppView.swift (remove banner)
2. PaywallView.swift (trial welcome text)
3. **TrialToastView.swift** (NEW - toast component)
4. GracePeriodManager.swift (add `hasSeenInitialToast`)

### Option 3 (Badge Indicator):
1. MainAppView.swift (remove banner, add badge)
2. PaywallView.swift (trial welcome text)
3. **TrialIndicatorBadge.swift** (NEW - badge component)

### Option 4 (One-Time Banner):
1. **GracePeriodBanner.swift** - Add one-time display logic
2. GracePeriodManager.swift - Track `hasSeenTrialBanner`

---

## 🎨 Design Considerations

### Banner Removal Impact:
- **Pros:**
  - **Cleaner UI** - More screen space for content
  - **Less intrusive** - User focused on app features
  - **Modern UX** - Most apps don't show persistent trial banners

- **Cons:**
  - **Less trial awareness** - User might not know they're on trial
  - **Urgency reduction** - No visible countdown creates less FOMO

- **Mitigation:**
  - Strong trial welcome messaging
  - In-context trial reminders (e.g., "2 scans remaining" before scan)
  - Settings page with trial info

### Trial Welcome Paywall Design:
Current paywall already looks great (based on PaywallView.swift):
- Dark theme background
- Lime green accent (#C0FF73) for CTAs
- Feature list with checkmarks
- Package selection cards
- "Start for [price]" button

**Just needs trial-specific copy!**

---

## 📞 Questions for User (REQUIRED FOR PLANNING)

Before creating implementation plan, please confirm:

1. **Which nudge approach do you prefer?**
   - A) Improve trial welcome (after first scan) - MINIMAL CHANGES
   - B) Add initial toast notification - MEDIUM CHANGES
   - C) Small badge indicator in corner - MEDIUM CHANGES
   - D) One-time banner (shows once, then hides) - SMALL CHANGES
   - E) Other (describe)

2. **Should trial info be accessible after nudge?**
   - A) Yes, in Settings tab
   - B) Yes, small indicator/badge
   - C) Yes, show inline before actions (scan/generate)
   - D) No, only show at limits/expiration

3. **Trial welcome paywall text - which tone?**
   - A) Welcoming/Celebratory: "Welcome to Your Trial! 🎉"
   - B) Informative/Neutral: "You're on a Free Trial"
   - C) Urgent/FOMO: "Limited Time: 24-Hour Trial Started!"
   - D) Educational: "Here's What You Get in Your Trial"

4. **Any additional paywall triggers?**
   - A) Keep current (welcome, limit, expired)
   - B) Add mid-trial reminder (12 hours)
   - C) Show brief upsell on every scan after welcome
   - D) Smart/dynamic timing based on engagement

5. **DEBUG mode behavior for hard paywall?**
   - A) Keep current (allows dismissal + trial reset)
   - B) Make it identical to production (blocking)
   - C) Add developer menu option to reset trial

---

## 🚀 Next Steps

**After user provides answers to questions above:**

1. **Create** `plan-trial-nudge-paywall.md` with:
   - Exact implementation steps
   - Files to modify with line numbers
   - Test commands for each change
   - Rollback strategy
   - Success criteria

2. **User approves plan** → Start Phase 3 (Implementation)

3. **Implementation workflow:**
   - Make changes according to plan
   - Test with `swiftc -parse` after EACH file edit
   - Commit after EACH working change
   - Monitor context usage (stop at 60%)

---

**Research Phase Complete ✅**

**Created:** 2025-11-19
**Agent:** Research Phase Agent
**Next Phase:** Planning (awaiting user design decisions)
**Estimated Implementation Time:** 1-2 sessions (depending on option chosen)
