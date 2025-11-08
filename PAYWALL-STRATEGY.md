# NutriSync Paywall Strategy
## 4-Paywall System with 24-Hour Grace Period

---

## 🎯 Overview

NutriSync uses a **4-paywall progressive monetization system** with a transparent 24-hour grace period:

- **24 hours** of free access
- **4 AI meal scans** included
- **1 window generation** included
- **Clear communication** of trial status at every step

---

## 🚪 The 4 Paywalls

### 1. **Trial Welcome** (`trial_welcome`)
**Placement**: `trial_welcome`
**Trigger**: After first successful meal scan OR window generation
**Type**: Soft (dismissible)
**Goal**: Convert early subscribers with transparency

### 2. **Scan Limit Reached** (`meal_scan_limit_reached`)
**Placement**: `meal_scan_limit_reached`
**Trigger**: After using all 4 scans
**Type**: Soft first time, hard if declined once
**Goal**: Convert at point of high engagement

### 3. **Window Gen Limit** (`window_gen_limit_reached`)
**Placement**: `window_gen_limit_reached`
**Trigger**: After using the 1 window generation
**Type**: Soft first time, hard if declined once
**Goal**: Convert power users who want more customization

### 4. **Grace Period Expired** (`grace_period_expired`)
**Placement**: `grace_period_expired`
**Trigger**: 24 hours elapsed
**Type**: Hard (blocking, no dismiss)
**Goal**: Final conversion or churn

---

## 🎨 Paywall #1: Trial Welcome Design

### Visual Hierarchy

```
┌──────────────────────────────────────────────┐
│                                              │
│              [Close X]  (top right)          │
│                                              │
│           ✨ (lime green sparkles)           │
│                                              │
│       Welcome to NutriSync Premium!          │
│           (28pt, bold, white)                │
│                                              │
│     You're on a free 24-hour trial          │
│        (17pt, 70% white opacity)             │
│                                              │
├──────────────────────────────────────────────┤
│  TRIAL STATUS CARD (#252525 background)     │
│                                              │
│   ✓ 3 AI meal scans remaining                │
│   ✓ 1 window generation left                 │
│   ✓ 23 hours to explore                      │
│                                              │
│   (lime green checkmarks, white text)        │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   Subscribe now to unlock unlimited:         │
│   (17pt, bold, white)                        │
│                                              │
│   ✓ Unlimited AI meal analysis               │
│   ✓ Daily personalized windows               │
│   ✓ Smart window adjustments                 │
│   ✓ Advanced analytics & insights            │
│   ✓ Priority support                          │
│                                              │
│   (white checkmarks on lime circles)         │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   PRICING PACKAGES                            │
│                                              │
│   ┌────────────────────────────────────┐    │
│   │  Annual                 BEST VALUE │    │
│   │  $XX.XX/year                       │    │
│   │  Save 40% vs monthly               │    │
│   │                            ◯       │    │
│   └────────────────────────────────────┘    │
│                                              │
│   ┌────────────────────────────────────┐    │
│   │  Monthly                           │    │
│   │  $X.XX/month                       │    │
│   │                            ●       │    │
│   └────────────────────────────────────┘    │
│                                              │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│                                              │
│   [  Subscribe Now - $X.XX/month  ]          │
│   (Lime green #C0FF73, black text)           │
│   (56pt height, rounded corners)             │
│                                              │
│          Continue Free Trial                 │
│          (text button, 50% opacity)          │
│                                              │
│     No credit card needed for trial          │
│        (13pt, 50% white opacity)             │
│                                              │
│          Restore Purchases                   │
│          (13pt, 50% white opacity)           │
│                                              │
│      Terms • Privacy                         │
│      (11pt, 40% white opacity)               │
│                                              │
└──────────────────────────────────────────────┘
```

### Color Specifications

**Background**: `#1A1A1A` (main background)
**Status Card**: `#252525` (elevated surface)
**Feature Cards**: `#252525` (elevated surface)
**Package Cards**: `#252525` with `#C0FF73` 2px border when selected
**Lime Accent**: `#C0FF73` (checkmarks, selected state, button)
**Primary Text**: `#FAFAFA` (white)
**Secondary Text**: `#FAFAFA` at 70% opacity
**Tertiary Text**: `#FAFAFA` at 50% opacity
**Button Text**: `#000000` (black on lime green)

### Copy Guidelines

#### Headline
**Primary**: "Welcome to NutriSync Premium!"
**Secondary**: "You're on a free 24-hour trial"
**Tone**: Celebratory, welcoming, transparent

#### Trial Status
Use **dynamic values** from `GracePeriodManager`:
- `remainingScans` scans remaining
- `remainingWindowGens` window generation\(s) left
- `remainingTimeFormatted` to explore

#### Features List
Focus on **unlimited** benefits:
- Unlimited AI meal analysis
- Daily personalized windows
- Smart window adjustments
- Advanced analytics & insights
- Priority support

#### CTAs
**Primary**: "Subscribe Now - $X.XX/month" (lime green button)
**Secondary**: "Continue Free Trial" (text-only, dismisses)
**Tertiary**: "Restore Purchases" (small text link)

#### Fine Print
"No credit card needed for trial"
"Terms • Privacy" (links)

---

## 🔄 User Flow Examples

### Scenario 1: Early Subscriber (Best Case)
```
1. User completes onboarding
2. First window generation creates today's plan
3. User scans first meal → Success!
4. [TRIAL WELCOME PAYWALL appears]
5. User sees: "3 scans left, 23 hours remaining"
6. User subscribes immediately → Full access unlocked
```

### Scenario 2: Trial Explorer (Common Case)
```
1. User completes onboarding
2. First window generation
3. User scans meal #1 → [TRIAL WELCOME appears]
4. User clicks "Continue Free Trial" (dismisses)
5. User scans meals #2, #3, #4
6. User tries scan #5 → [SCAN LIMIT PAYWALL appears]
7. User subscribes → Full access unlocked
```

### Scenario 3: Time Expirer (Edge Case)
```
1. User explores for 20 hours
2. Uses only 2 scans
3. 24 hours passes
4. [GRACE PERIOD EXPIRED appears] (hard paywall)
5. User must subscribe or loses access
```

---

## 📍 Implementation: Where to Call Paywalls

### 1. Trial Welcome
**File**: `MealCaptureService.swift` (after successful scan)
**File**: `WindowGenerationService.swift` (after successful generation)

```swift
// After first successful meal scan
if mealSaved {
    await gracePeriodManager.showTrialWelcomeIfNeeded()
}

// OR after first window generation
if windowsGenerated {
    await gracePeriodManager.showTrialWelcomeIfNeeded()
}
```

### 2. Scan Limit Reached
**File**: `GracePeriodManager.swift:188-192` (already implemented)

```swift
// Automatically shown when remainingScans reaches 0
if remainingScans <= 0 {
    await showLimitReachedPaywall(type: .scans)
}
```

### 3. Window Gen Limit
**File**: `GracePeriodManager.swift:220-226` (already implemented)

```swift
// Automatically shown when remainingWindowGens reaches 0
if remainingWindowGens <= 0 {
    await showLimitReachedPaywall(type: .windowGeneration)
}
```

### 4. Grace Period Expired
**File**: `ContentView.swift:123-156` (already implemented)

```swift
// Shown automatically when grace period expires
else if !subscriptionManager.isSubscribed &&
        !gracePeriodManager.isInGracePeriod &&
        gracePeriodManager.gracePeriodEndDate != nil {
    SuperwallPaywallView(placement: "grace_period_expired")
}
```

---

## 🎯 Superwall Dashboard Configuration

### Campaign 1: Trial Welcome
**Event**: `trial_welcome`
**Rule**: Show when `isInGracePeriod == true`
**Frequency**: Once per user
**Dismissible**: Yes (shows "Continue Free Trial" button)

### Campaign 2: Scan Limit
**Event**: `meal_scan_limit_reached`
**Rule 1**: Show soft paywall if `hasSeenPaywallOnce == false`
**Rule 2**: Show hard paywall if `hasSeenPaywallOnce == true`
**Frequency**: Every time limit reached
**Dismissible**: Yes (first time), No (second time)

### Campaign 3: Window Gen Limit
**Event**: `window_gen_limit_reached`
**Rule 1**: Show soft paywall if `hasSeenPaywallOnce == false`
**Rule 2**: Show hard paywall if `hasSeenPaywallOnce == true`
**Frequency**: Every time limit reached
**Dismissible**: Yes (first time), No (second time)

### Campaign 4: Grace Expired
**Event**: `grace_period_expired`
**Rule**: ALWAYS show (no conditions)
**Frequency**: Every app open until subscribed
**Dismissible**: NO (hard paywall)

---

## 📊 Dynamic Content

Use **Superwall variables** to show real-time data:

```
{{ remainingScans }} scans remaining
{{ remainingWindowGens }} window generation{{ remainingWindowGens > 1 ? 's' : '' }} left
{{ remainingTime }} to explore
```

**Implementation**:
Set these as Superwall user properties:
```swift
Superwall.shared.setUserAttributes([
    "remainingScans": gracePeriodManager.remainingScans,
    "remainingWindowGens": gracePeriodManager.remainingWindowGens,
    "remainingTime": gracePeriodManager.remainingTimeFormatted
])
```

---

## ✅ Testing Checklist

### Trial Welcome
- [ ] Shows after first meal scan
- [ ] Shows after first window generation (if no scan yet)
- [ ] Only shows once
- [ ] "Continue Free Trial" button dismisses
- [ ] Dynamic remaining counts are correct
- [ ] Links to Terms/Privacy work

### Scan Limit
- [ ] Shows after 4th scan
- [ ] First time is dismissible
- [ ] Second time is hard paywall
- [ ] Purchase flow works

### Window Gen Limit
- [ ] Shows after 1st window generation used
- [ ] First time is dismissible
- [ ] Second time is hard paywall

### Grace Expired
- [ ] Shows after 24 hours
- [ ] Cannot be dismissed
- [ ] Blocks all app access
- [ ] Purchase flow works

### Cross-Paywall
- [ ] Purchasing from any paywall unlocks app
- [ ] RevenueCat status syncs correctly
- [ ] Restore purchases works on all paywalls

---

## 🚀 Next Steps

1. **Create paywalls in Superwall dashboard** using designs above
2. **Configure campaigns** with the rules specified
3. **Add user attributes** to Superwall for dynamic content
4. **Test each scenario** with the checklist above
5. **Monitor conversion rates** and optimize

---

## 💡 Pro Tips

### Maximize Early Conversions
- Show trial welcome **early** (after first success, not after all limits)
- Use **celebratory language** ("Welcome to Premium!" not "Trial Started")
- Emphasize **unlimited** in feature list
- Make "Continue" button **subtle** (text-only, not competing with Subscribe button)

### Optimize Copy
- Use **"remaining"** not "left" (sounds more positive)
- Show **exact time** (23 hours, not "less than 1 day")
- Include **social proof** ("Join 10,000+ users" if you have data)
- Offer **annual discount** prominently (40% savings vs monthly)

### UX Best Practices
- **Never** hide the trial status - always show remaining counts
- **Always** allow restore purchases (legal requirement)
- **Test** on real devices with actual App Store sandbox accounts
- **Monitor** analytics: which paywall converts best?

---

## 📝 Copywriting Examples

### Alternative Headlines
- "🎉 You're in! Free 24-hour trial started"
- "✨ Welcome to your nutrition transformation"
- "🚀 Let's unlock your best nutrition"

### Alternative CTAs
- "Start Unlimited Access - $X.XX/month"
- "Subscribe & Save 40%"
- "Unlock Everything Now"

### Alternative Trial Status
- "Your trial includes: [list]"
- "Try premium free for 24 hours"
- "No strings attached - explore everything"

Choose what fits your brand voice!

---

**Last Updated**: 2025-11-08
**Version**: 1.0
**Author**: Claude Code
