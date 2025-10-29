# Implementation Plan: Account Creation + Paywall + Grace Period System

**Feature:** Mandatory account creation, 24-hour grace period with usage limits, hard paywall with price testing

**Plan Date:** 2025-10-29
**Agent Session:** 2 (Planning Phase)
**Based On:** research-account-paywall-system.md

---

## 🎯 IMPLEMENTATION GOALS

### Primary Objectives:
1. Add Google Sign-In alongside Apple Sign-In
2. Make account creation mandatory (remove skip option)
3. Implement 24-hour grace period tracking
4. Implement usage limits (4 scans, 1 window generation)
5. Integrate RevenueCat for subscription management
6. Integrate Superwall for paywall presentation
7. Set up A/B price testing ($6/$8/$10)
8. Show soft paywall (skippable) on first view
9. Show hard paywall (blocking) after grace period expires

### Success Criteria:
- ✅ User completes onboarding → MUST create account
- ✅ Grace period starts automatically after account creation
- ✅ User can use 4 scans + 1 window gen in 24 hours
- ✅ After limits hit → hard paywall blocks usage
- ✅ After subscribing → all limits removed
- ✅ Pricing A/B test functional in Superwall
- ✅ All code compiles without errors
- ✅ End-to-end flow tested in simulator

---

## 📋 IMPLEMENTATION PHASES

### Phase 1: Google Sign-In Integration
**Estimated Time:** 4-6 hours
**Context Impact:** Low (focused changes)

### Phase 2: Grace Period Manager
**Estimated Time:** 6-8 hours
**Context Impact:** Medium (new file + integrations)

### Phase 3: Subscription System
**Estimated Time:** 6-8 hours
**Context Impact:** Medium (new dependencies)

### Phase 4: Paywall Integration
**Estimated Time:** 6-8 hours
**Context Impact:** Medium (UI + logic)

### Phase 5: Feature Gating
**Estimated Time:** 4-6 hours
**Context Impact:** Low (targeted modifications)

### Phase 6: Testing & Polish
**Estimated Time:** 4-6 hours
**Context Impact:** Low (verification only)

---

## 🔧 PHASE 1: GOOGLE SIGN-IN INTEGRATION

### Step 1.1: Add GoogleSignIn SDK
**File:** Project dependencies
**Action:** Add via Swift Package Manager

```swift
// In Xcode: File > Add Packages
// URL: https://github.com/google/GoogleSignIn-iOS
// Dependency Rule: Up to Next Major Version
// Version: 7.0.0
```

**Validation:**
```bash
# Verify package added
xcodebuild -list
```

---

### Step 1.2: Configure Firebase Console
**Location:** Firebase Console → Authentication
**Actions:**
1. Enable Google sign-in provider
2. Copy iOS URL scheme (com.googleusercontent.apps.XXXXXX)
3. Download updated GoogleService-Info.plist (if needed)

---

### Step 1.3: Update Info.plist
**File:** `NutriSync/Info.plist`
**Action:** Add Google URL scheme and client ID

```xml
<!-- Add to existing CFBundleURLTypes array -->
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
</dict>

<!-- Add at root level -->
<key>GIDClientID</key>
<string>YOUR-CLIENT-ID.apps.googleusercontent.com</string>
```

**Validation:**
- Check Info.plist syntax is valid
- Ensure CFBundleURLSchemes matches Firebase Console

---

### Step 1.4: Add Google Sign-In to AccountCreationView
**File:** `NutriSync/Views/Onboarding/AccountCreationView.swift`
**Lines to modify:** Add imports, add button, add handler

**Changes:**

1. **Add import (line 3):**
```swift
import GoogleSignIn
import GoogleSignInSwift
```

2. **Remove skip button (lines 91-94):**
```swift
// DELETE THESE LINES:
Button(action: skipAccountCreation) {
    Text("Skip for Now")
        .foregroundColor(.secondary)
}
```

3. **Add Google Sign-In button (after Apple button, ~line 76):**
```swift
// Google Sign In
Button(action: handleGoogleSignInTap) {
    HStack(spacing: 12) {
        Image("google_logo")  // Need to add to Assets
            .resizable()
            .frame(width: 20, height: 20)
        Text("Continue with Google")
            .font(.system(size: 16, weight: .semibold))
    }
    .frame(maxWidth: .infinity)
    .frame(height: 50)
    .background(Color.white)
    .foregroundColor(.black)
    .cornerRadius(12)
}
```

4. **Add Google Sign-In handler (before existing methods, ~line 127):**
```swift
// MARK: - Google Sign In

private func handleGoogleSignInTap() {
    guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
        errorMessage = "Unable to present sign in"
        showError = true
        return
    }

    GIDSignIn.sharedInstance.signIn(
        withPresenting: presentingViewController
    ) { result, error in
        if let error = error {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else {
            errorMessage = "Failed to get Google credentials"
            showError = true
            return
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        Task {
            await linkAccount(with: credential)
        }
    }
}
```

**Test:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Onboarding/AccountCreationView.swift
```

---

### Step 1.5: Add Google Logo Asset
**File:** Assets.xcassets
**Action:** Add google_logo.png (20x20, 40x40, 60x60)

**Source:** Download from Google Brand Resources or use SF Symbol alternative

---

## 🔧 PHASE 2: GRACE PERIOD MANAGER

### Step 2.1: Create GracePeriodManager.swift
**File:** `NutriSync/Services/GracePeriodManager.swift` (NEW)
**Lines:** ~350 lines

**Structure:**
```swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
@Observable
class GracePeriodManager {
    static let shared = GracePeriodManager()

    // MARK: - Published Properties
    var isInGracePeriod: Bool = false
    var remainingScans: Int = 4
    var remainingWindowGens: Int = 1
    var gracePeriodEndDate: Date?
    var hasSeenPaywallOnce: Bool = false

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let GRACE_PERIOD_HOURS: TimeInterval = 24
    private let MAX_SCANS_IN_GRACE = 4
    private let MAX_WINDOW_GENS_IN_GRACE = 1

    // MARK: - Computed Properties
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Initialization
    func initialize() async {
        await loadGracePeriodStatus()
        await checkGracePeriodExpiration()
    }

    // MARK: - Grace Period Management
    func startGracePeriod() async throws { /* ... */ }
    private func loadGracePeriodStatus() async { /* ... */ }
    func checkGracePeriodExpiration() async { /* ... */ }

    // MARK: - Usage Tracking
    func canScanMeal() -> Bool { /* ... */ }
    func recordMealScan() async throws { /* ... */ }
    func canGenerateWindows() -> Bool { /* ... */ }
    func recordWindowGeneration() async throws { /* ... */ }

    // MARK: - Paywall Triggers
    enum LimitType {
        case scans
        case windowGeneration
        case timeExpired
    }

    func showLimitReachedPaywall(type: LimitType) async { /* ... */ }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let showPaywall = Notification.Name("showPaywall")
    static let gracePeriodExpired = Notification.Name("gracePeriodExpired")
}
```

**Full implementation:** See research document code examples

**Test:**
```bash
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Services/GracePeriodManager.swift
```

---

### Step 2.2: Create Firestore Structure
**Collection:** `users/{userId}/subscription/gracePeriod`

**Document Schema:**
```javascript
{
  startDate: Timestamp,
  endDate: Timestamp,
  remainingScans: Number (0-4),
  remainingWindowGens: Number (0-1),
  hasSeenPaywallOnce: Boolean,
  deviceId: String  // For abuse prevention
}
```

**Collection:** `gracePeriodDevices/{deviceUUID}`

**Document Schema:**
```javascript
{
  usedAt: Timestamp,
  userId: String
}
```

---

### Step 2.3: Integrate with PhylloApp
**File:** `NutriSync/PhylloApp.swift`
**Action:** Add environment object

**Changes:**

1. **Add state object (line ~15):**
```swift
@StateObject private var gracePeriodManager = GracePeriodManager.shared
```

2. **Add environment object (in WindowGroup, line ~30):**
```swift
.environmentObject(gracePeriodManager)
```

3. **Add initialization task (line ~35):**
```swift
.task {
    await gracePeriodManager.initialize()
}
```

**Test:** Compile PhylloApp.swift

---

## 🔧 PHASE 3: SUBSCRIPTION SYSTEM

### Step 3.1: Add RevenueCat SDK
**File:** Project dependencies
**Action:** Add via Swift Package Manager

```swift
// In Xcode: File > Add Packages
// URL: https://github.com/RevenueCat/purchases-ios
// Dependency Rule: Up to Next Major Version
// Version: 4.0.0
```

---

### Step 3.2: Create RevenueCat Account
**External:** https://app.revenuecat.com
**Actions:**
1. Create account
2. Create new project "NutriSync"
3. Add iOS app with bundle ID
4. Copy public API key

---

### Step 3.3: Create App Store Connect Products
**External:** https://appstoreconnect.apple.com
**Actions:**

1. Create Subscription Group: "NutriSync Premium"

2. Create Product 1:
   - Product ID: `com.nutrisync.monthly.6`
   - Reference Name: "Monthly $6"
   - Subscription Duration: 1 Month
   - Price: $5.99
   - Introductory Offer: 7 days free

3. Create Product 2:
   - Product ID: `com.nutrisync.monthly.8`
   - Reference Name: "Monthly $8"
   - Subscription Duration: 1 Month
   - Price: $7.99
   - Introductory Offer: 7 days free

4. Create Product 3:
   - Product ID: `com.nutrisync.monthly.10`
   - Reference Name: "Monthly $10"
   - Subscription Duration: 1 Month
   - Price: $9.99
   - Introductory Offer: 7 days free

5. Create Product 4:
   - Product ID: `com.nutrisync.annual`
   - Reference Name: "Annual"
   - Subscription Duration: 1 Year
   - Price: $76.80
   - Introductory Offer: 7 days free

---

### Step 3.4: Configure RevenueCat Products
**External:** RevenueCat Dashboard
**Actions:**
1. Go to Products tab
2. Add all 4 products from App Store Connect
3. Create Entitlement: "premium"
4. Attach all products to "premium" entitlement

---

### Step 3.5: Create SubscriptionManager.swift
**File:** `NutriSync/Services/SubscriptionManager.swift` (NEW)
**Lines:** ~250 lines

**Structure:**
```swift
import Foundation
import RevenueCat

@MainActor
@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties
    var isSubscribed: Bool = false
    var subscriptionStatus: SubscriptionStatus = .unknown
    var customerInfo: CustomerInfo?

    enum SubscriptionStatus {
        case unknown
        case trial
        case active
        case expired
        case gracePeriod  // Payment issue, still has access
    }

    // MARK: - Initialization
    func initialize() async {
        await checkSubscriptionStatus()
        setupPurchaseObserver()
    }

    // MARK: - Subscription Checking
    func checkSubscriptionStatus() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
            isSubscribed = customerInfo?.entitlements["premium"]?.isActive == true
            updateSubscriptionStatus()
        } catch {
            print("Failed to check subscription: \(error)")
            isSubscribed = false
        }
    }

    private func updateSubscriptionStatus() { /* ... */ }

    // MARK: - Purchase Observer
    private func setupPurchaseObserver() {
        Purchases.shared.delegate = self
    }
}

// MARK: - PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(
        _ purchases: Purchases,
        receivedUpdated customerInfo: CustomerInfo
    ) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
            updateSubscriptionStatus()
        }
    }
}
```

**Test:** Compile SubscriptionManager.swift

---

### Step 3.6: Initialize RevenueCat in PhylloApp
**File:** `NutriSync/PhylloApp.swift`
**Action:** Configure in init()

**Changes:**

1. **Add import (line ~8):**
```swift
import RevenueCat
```

2. **Add state object (line ~16):**
```swift
@StateObject private var subscriptionManager = SubscriptionManager.shared
```

3. **Configure in init (line ~20):**
```swift
init() {
    // Firebase (existing)
    FirebaseConfig.shared.configure()

    // RevenueCat configuration
    Purchases.logLevel = .debug  // Remove in production
    Purchases.configure(withAPIKey: "YOUR_REVENUECAT_PUBLIC_API_KEY")
}
```

4. **Set user identity in ContentView task:**
```swift
.task {
    // After auth complete
    if let userId = Auth.auth().currentUser?.uid {
        try? await Purchases.shared.logIn(userId)
    }
    await subscriptionManager.initialize()
}
```

5. **Add environment object:**
```swift
.environmentObject(subscriptionManager)
```

**Test:** Compile PhylloApp.swift

---

## 🔧 PHASE 4: PAYWALL INTEGRATION

### Step 4.1: Add Superwall SDK
**File:** Project dependencies
**Action:** Add via Swift Package Manager

```swift
// In Xcode: File > Add Packages
// URL: https://github.com/superwall/Superwall-iOS
// Dependency Rule: Up to Next Major Version
// Version: 4.0.0
```

---

### Step 4.2: Create Superwall Account
**External:** https://superwall.com
**Actions:**
1. Create account
2. Create new project "NutriSync"
3. Add iOS app
4. Copy public API key

---

### Step 4.3: Initialize Superwall in PhylloApp
**File:** `NutriSync/PhylloApp.swift`
**Action:** Configure in init()

**Changes:**

1. **Add import (line ~9):**
```swift
import SuperwallKit
```

2. **Configure in init (after RevenueCat, line ~28):**
```swift
// Superwall configuration
Superwall.configure(
    apiKey: "YOUR_SUPERWALL_PUBLIC_API_KEY",
    purchaseController: RevenueCatPurchaseController()
)
```

3. **Set user identity in ContentView task:**
```swift
if let userId = Auth.auth().currentUser?.uid {
    Superwall.shared.identify(userId: userId)
}
```

**Test:** Compile PhylloApp.swift

---

### Step 4.4: Create PaywallView.swift
**File:** `NutriSync/Views/Subscription/PaywallView.swift` (NEW)
**Lines:** ~100 lines

**Structure:**
```swift
import SwiftUI
import SuperwallKit

struct PaywallView: View {
    let placement: String
    var onDismiss: (() -> Void)?
    var onSubscribe: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Superwall handles paywall presentation
            // We just register the event
        }
        .onAppear {
            presentPaywall()
        }
    }

    private func presentPaywall() {
        Superwall.shared.register(event: placement) { result in
            switch result {
            case .presented:
                print("Paywall presented")

            case .purchased:
                print("User subscribed!")
                onSubscribe?()
                dismiss()

            case .closed:
                print("Paywall dismissed")
                onDismiss?()
                dismiss()

            case .error(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
```

**Test:** Compile PaywallView.swift

---

### Step 4.5: Create Paywalls in Superwall Dashboard
**External:** Superwall Dashboard
**Actions:**

**Paywall 1: Soft Paywall (Skippable)**
- Name: "Soft Paywall - Onboarding Complete"
- Design: Custom (use Superwall editor)
- Headlines:
  - "Try NutriSync Free for 24 Hours"
  - "No credit card required"
- Benefits:
  - ✓ 4 AI meal scans
  - ✓ 1 personalized window generation
  - ✓ Full app experience
- CTA Primary: "Start Free Trial"
- CTA Secondary: "Maybe Later" (dismisses)
- Variables:
  - `${user.remainingScans}`
  - `${user.hoursRemaining}`

**Paywall 2: Hard Paywall (Blocking)**
- Name: "Hard Paywall - Grace Period Expired"
- Design: Custom (use Superwall editor)
- Headlines:
  - "Upgrade to Continue"
  - "Keep optimizing your nutrition"
- Benefits:
  - ✓ Unlimited AI meal scans
  - ✓ Daily window generation & adjustments
  - ✓ Advanced analytics & insights
  - ✓ Priority support
- Products: Show all 3 pricing tiers
- CTA: "Subscribe Now"
- NO dismiss button (blocking)

---

### Step 4.6: Create Superwall Campaigns
**External:** Superwall Dashboard → Campaigns
**Actions:**

**Campaign 1: Hard Paywall (Priority 1 - Evaluated First)**
- Name: "Grace Period Expired - Hard Paywall"
- Placements:
  - `onboarding_complete`
  - `meal_scan_limit_reached`
  - `window_gen_limit_reached`
  - `grace_period_expired`
- Paywall: Hard Paywall
- Feature Gating: GATED (must subscribe)
- Audience Rules:
  - `user.hasSeenPaywallOnce == true` OR
  - `user.remainingScans <= 0` OR
  - `user.remainingWindowGens <= 0` OR
  - `user.gracePeriodExpired == true`

**Campaign 2: Soft Paywall (Priority 2 - Default)**
- Name: "First Time - Soft Paywall"
- Placements:
  - `onboarding_complete`
- Paywall: Soft Paywall
- Feature Gating: NON-GATED (can dismiss)
- Audience Rules:
  - Default (everyone not matching Campaign 1)

**Campaign 3: Price Testing**
- Name: "Price A/B Test"
- Placements: All paywalls
- Variants:
  - Variant A (33%): Show $6/month product
  - Variant B (33%): Show $8/month product
  - Variant C (34%): Show $10/month product

---

## 🔧 PHASE 5: FEATURE GATING

### Step 5.1: Update OnboardingCoordinator
**File:** `NutriSync/Views/Onboarding/NutriSyncOnboarding/OnboardingCoordinator.swift`
**Lines to modify:** Add grace period start after onboarding

**Changes:**

1. **Add environment object (line ~12):**
```swift
@EnvironmentObject private var gracePeriodManager: GracePeriodManager
```

2. **In completeOnboarding method (find existing, ~line 500+):**
```swift
private func completeOnboarding() async {
    // Existing code: save profile, goals, etc.
    try await dataProvider.saveUserProfile(profile)
    try await dataProvider.saveUserGoals(goals)

    // NEW: Start grace period
    do {
        try await gracePeriodManager.startGracePeriod()
        print("✅ Grace period started")

        // Show soft paywall (first time, skippable)
        await MainActor.run {
            NotificationCenter.default.post(
                name: .showPaywall,
                object: "onboarding_complete"
            )
        }
    } catch {
        print("❌ Failed to start grace period: \(error)")
    }
}
```

**Test:** Compile OnboardingCoordinator.swift

---

### Step 5.2: Update MealCaptureService
**File:** `NutriSync/Services/MealCaptureService.swift`
**Lines to modify:** Add usage check before capture

**Changes:**

1. **Add property (near top, ~line 20):**
```swift
private let gracePeriodManager = GracePeriodManager.shared
private let subscriptionManager = SubscriptionManager.shared
```

2. **In captureMeal method (find existing, ~line 50):**
```swift
func captureMeal(image: UIImage?, voiceInput: String?) async throws -> AnalyzingMeal {
    // NEW: Check if user can scan
    guard subscriptionManager.isSubscribed || gracePeriodManager.canScanMeal() else {
        // Show hard paywall
        await gracePeriodManager.showLimitReachedPaywall(type: .scans)
        throw MealCaptureError.scanLimitReached
    }

    // Existing meal capture logic...
    let analyzingMeal = ... // existing code

    // NEW: Record scan usage (only if not subscribed)
    if !subscriptionManager.isSubscribed {
        try await gracePeriodManager.recordMealScan()
    }

    return analyzingMeal
}
```

3. **Add error case:**
```swift
enum MealCaptureError: Error {
    case scanLimitReached
    // ... existing cases
}
```

**Test:** Compile MealCaptureService.swift

---

### Step 5.3: Update AIWindowGenerationService
**File:** `NutriSync/Services/AI/AIWindowGenerationService.swift`
**Lines to modify:** Add usage check before generation

**Changes:**

1. **Add properties (near top):**
```swift
private let gracePeriodManager = GracePeriodManager.shared
private let subscriptionManager = SubscriptionManager.shared
```

2. **In generateWindows method (find existing):**
```swift
func generateWindows(for profile: UserProfile) async throws -> [MealWindow] {
    // NEW: Check if user can generate
    guard subscriptionManager.isSubscribed || gracePeriodManager.canGenerateWindows() else {
        await gracePeriodManager.showLimitReachedPaywall(type: .windowGeneration)
        throw WindowGenerationError.generationLimitReached
    }

    // Existing window generation logic...
    let windows = ... // existing code

    // NEW: Record usage (only if not subscribed)
    if !subscriptionManager.isSubscribed {
        try await gracePeriodManager.recordWindowGeneration()
    }

    return windows
}
```

3. **Add error case:**
```swift
enum WindowGenerationError: Error {
    case generationLimitReached
    // ... existing cases
}
```

**Test:** Compile AIWindowGenerationService.swift

---

### Step 5.4: Update ContentView Navigation
**File:** `NutriSync/Views/ContentView.swift`
**Lines to modify:** Add paywall navigation

**Changes:**

1. **Add environment objects (line ~14):**
```swift
@EnvironmentObject private var gracePeriodManager: GracePeriodManager
@EnvironmentObject private var subscriptionManager: SubscriptionManager
```

2. **Add state for paywall (line ~26):**
```swift
@State private var showingPaywall = false
@State private var paywallPlacement = ""
```

3. **Update authenticatedContent (line ~105):**
```swift
@ViewBuilder
private var authenticatedContent: some View {
    if isCheckingProfile {
        LoadingView(message: "Loading your profile...")
    } else if !hasProfile {
        // Onboarding flow
        OnboardingFlowView(...)
    } else if !subscriptionManager.isSubscribed && !gracePeriodManager.isInGracePeriod {
        // Grace period expired and not subscribed - HARD PAYWALL
        PaywallView(
            placement: "grace_period_expired",
            onSubscribe: {
                // Subscription successful - refresh app
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            }
        )
    } else {
        // Either subscribed OR in grace period - show app
        MainAppView(...)
            .sheet(isPresented: $showingPaywall) {
                PaywallView(
                    placement: paywallPlacement,
                    onSubscribe: {
                        showingPaywall = false
                        Task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                    },
                    onDismiss: {
                        showingPaywall = false
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { notification in
                if let placement = notification.object as? String {
                    paywallPlacement = placement
                    showingPaywall = true
                }
            }
    }
}
```

**Test:** Compile ContentView.swift

---

## 🔧 PHASE 6: TESTING & POLISH

### Step 6.1: Add Grace Period UI Indicator
**File:** `NutriSync/Views/Components/GracePeriodBanner.swift` (NEW)
**Lines:** ~80 lines

**Structure:**
```swift
import SwiftUI

struct GracePeriodBanner: View {
    @EnvironmentObject var gracePeriodManager: GracePeriodManager

    var hoursRemaining: Int {
        guard let endDate = gracePeriodManager.gracePeriodEndDate else { return 0 }
        let remaining = endDate.timeIntervalSince(Date())
        return max(0, Int(remaining / 3600))
    }

    var body: some View {
        if gracePeriodManager.isInGracePeriod {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Trial Active")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(gracePeriodManager.remainingScans) scans • \(hoursRemaining)h remaining")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        NotificationCenter.default.post(
                            name: .showPaywall,
                            object: "grace_period_banner"
                        )
                    } label: {
                        Text("Upgrade")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.nutriSyncBackground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.nutriSyncAccent.opacity(0.1))
            }
        }
    }
}
```

**Test:** Compile GracePeriodBanner.swift

---

### Step 6.2: Add Banner to MainAppView
**File:** `NutriSync/Views/MainAppView.swift` (find existing)
**Action:** Add banner at top

**Changes:**
```swift
VStack(spacing: 0) {
    // NEW: Grace period banner
    GracePeriodBanner()
        .environmentObject(gracePeriodManager)

    // Existing TabView
    TabView(selection: $selectedTab) {
        // ... existing tabs
    }
}
```

**Test:** Compile MainAppView.swift

---

### Step 6.3: End-to-End Testing Plan
**Manual Testing Checklist:**

- [ ] 1. Fresh install → complete onboarding
- [ ] 2. Create account with Apple Sign-In
- [ ] 3. Create account with Google Sign-In (test separately)
- [ ] 4. Soft paywall appears (can dismiss)
- [ ] 5. Grace period banner shows in app
- [ ] 6. Scan 1st meal → counter decrements (3 remaining)
- [ ] 7. Scan 2nd meal → counter decrements (2 remaining)
- [ ] 8. Scan 3rd meal → counter decrements (1 remaining)
- [ ] 9. Scan 4th meal → counter decrements (0 remaining)
- [ ] 10. Try to scan 5th meal → HARD PAYWALL blocks
- [ ] 11. Generate windows → counter decrements (0 remaining)
- [ ] 12. Try to generate again → HARD PAYWALL blocks
- [ ] 13. Subscribe to $8/month plan
- [ ] 14. Verify subscription active in RevenueCat
- [ ] 15. Verify unlimited scans now work
- [ ] 16. Verify unlimited window generation works
- [ ] 17. Delete app, reinstall
- [ ] 18. Sign in → subscription restored
- [ ] 19. Verify grace period NOT restarted (device tracked)
- [ ] 20. Cancel subscription (in Settings)
- [ ] 21. Verify app still works until period ends

**Sandbox Testing:**
- Use sandbox Apple ID for test purchases
- Accelerate time in sandbox (1 hour = 5 minutes)
- Test subscription renewal
- Test subscription cancellation
- Test restore purchases

---

### Step 6.4: Compilation Verification
**Run full project compilation:**

```bash
# Parse all modified files
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Onboarding/AccountCreationView.swift \
  NutriSync/Services/GracePeriodManager.swift \
  NutriSync/Services/SubscriptionManager.swift \
  NutriSync/Views/Subscription/PaywallView.swift \
  NutriSync/Services/MealCaptureService.swift \
  NutriSync/Services/AI/AIWindowGenerationService.swift \
  NutriSync/Views/ContentView.swift \
  NutriSync/Views/Components/GracePeriodBanner.swift \
  NutriSync/PhylloApp.swift

# If all pass, ready to build in Xcode
```

---

## ✅ COMPLETION CHECKLIST

### Code Complete:
- [ ] All files created and modified
- [ ] All imports added
- [ ] All compilation errors fixed
- [ ] No force unwraps or unsafe code

### External Setup Complete:
- [ ] Firebase Google auth enabled
- [ ] RevenueCat account created
- [ ] Superwall account created
- [ ] App Store Connect products created
- [ ] RevenueCat products configured
- [ ] Superwall paywalls designed
- [ ] Superwall campaigns created

### Testing Complete:
- [ ] Manual testing checklist passed
- [ ] Sandbox purchases tested
- [ ] Grace period expiration tested
- [ ] Multi-device sync tested
- [ ] Edge cases verified

### Documentation Complete:
- [ ] Code comments added
- [ ] User-facing error messages clear
- [ ] README updated (if applicable)

---

## 🚨 ROLLBACK PLAN

If critical issues found:

1. **Revert Git Commits:**
   ```bash
   git log --oneline  # Find commit before changes
   git revert [commit-hash]
   ```

2. **Disable Features:**
   - Remove Google Sign-In button (restore skip option)
   - Disable grace period checks (allow unlimited usage)
   - Hide paywalls (comment out presentation code)

3. **Restore Old Flow:**
   - Keep anonymous auth only
   - Remove subscription checks

---

## 📊 MONITORING AFTER DEPLOYMENT

### Superwall Dashboard:
- Paywall impression rate
- Conversion rate by variant
- Revenue per install (RPI)
- Trial start rate

### RevenueCat Dashboard:
- Active subscriptions
- Trial conversions
- Monthly recurring revenue (MRR)
- Churn rate

### Firebase Analytics:
- Grace period completion rate
- Scan limit hit rate
- Window gen limit hit rate
- Time to first paywall hit

### App Store Connect:
- Subscription purchases
- Trial starts
- Cancellations
- Revenue

---

## 🎯 SUCCESS METRICS (30 Days Post-Launch)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Onboarding completion | 70%+ | Firebase Analytics |
| Account creation | 95%+ | Firebase Auth |
| Grace period usage | 80%+ use features | Firestore |
| Soft paywall conversion | 5-10% | Superwall |
| Hard paywall conversion | 15-25% | Superwall |
| Blended conversion | 20-30% | RevenueCat |
| Trial-to-paid | 40-50% | RevenueCat |
| Monthly churn | <5% | RevenueCat |
| RPI (Revenue Per Install) | $1.60-2.40 | RevenueCat |

---

## 📝 NOTES & CONSIDERATIONS

### Context Management:
- **Current usage:** ~103k / 200k tokens (51%)
- **Remaining:** 97k tokens (48%)
- **Safe to continue implementation** ✅

If context approaches 60% (120k tokens):
1. Complete current step
2. Create `progress-account-paywall-system.md`
3. Commit working code
4. Tell user to start new session

### Implementation Order Rationale:
1. Google Sign-In first (quick win, validates setup)
2. Grace period manager (core logic, needs testing)
3. Subscription system (external dependencies)
4. Paywall integration (visual, easier to test)
5. Feature gating (connects everything)
6. Testing & polish (verification)

### Risk Mitigation:
- Test each phase independently
- Commit after each working step
- Keep old code commented (easy revert)
- Use feature flags for gradual rollout

---

**Planning Phase Complete**
**Date:** 2025-10-29
**Status:** ✅ READY FOR USER APPROVAL

---

## ❓ QUESTIONS FOR USER APPROVAL

Before proceeding to implementation (Phase 3), please confirm:

### 1. Pricing Strategy
✅ **Confirmed:** A/B test $6/$8/$10 monthly subscriptions
- Annual option: $76.80/year (20% discount)
- 7-day free trial with no credit card

### 2. Grace Period Limits
✅ **Confirmed:**
- 24-hour timer starting after account creation
- 4 meal scans maximum
- 1 window generation maximum
- Hard paywall after ANY limit reached

### 3. Account Creation
✅ **Confirmed:**
- Add Google Sign-In alongside Apple Sign-In
- Make account creation MANDATORY (remove skip option)
- Account linking works for anonymous users

### 4. Paywall Flow
✅ **Confirmed:**
- Soft paywall (skippable) shown ONCE after onboarding
- Hard paywall (blocking) shown after grace period expires
- Hard paywall also shown when scan/window limits hit

### 5. Implementation Timeline
✅ **Confirmed:** 6-phase implementation (~30-40 hours total)
- Can start immediately
- Will test after each phase
- Full testing before TestFlight

---

**USER: Please review and approve to proceed to Phase 3 (Implementation)**

If any changes needed, specify and I'll update the plan before beginning implementation.
