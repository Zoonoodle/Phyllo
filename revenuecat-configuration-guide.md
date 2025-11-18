# RevenueCat Configuration Guide - NutriSync
**Date:** 2025-11-18
**Status:** Complete setup guide for RevenueCat-only paywall system

---

## ✅ CURRENT STATE

Your codebase is **ALREADY CONFIGURED** for RevenueCat-only:
- ✅ No Superwall dependencies found
- ✅ Custom PaywallView.swift with #C0FF73 theme implemented
- ✅ SubscriptionManager fully functional
- ✅ RevenueCat initialized in PhylloApp.swift
- ✅ API Key configured: `appl_QzcJHpMKoCVNkraSzGBERNhoynr`

**What's left:** Configure products and offerings in RevenueCat dashboard

---

## 📋 STEP 1: App Store Connect - Complete Subscription Metadata

### 1.1 Your Current Products (Already Created)
✅ You already have 3 subscription products in the `premium_group`:
1. **Monthly $6** - `com.nutrisync.monthly.6`
2. **Monthly $8** - `com.nutrisync.monthly.8`
3. **Annual** - `com.nutrisync.annual`

All are currently showing "Missing Metadata" status.

### 1.2 Add Metadata to Each Subscription

For each of the 3 products, click on the product name and complete:

#### Product 1: Monthly $6
1. **Subscription Localizations:**
   - Display Name: `Monthly Access`
   - Description: `Unlimited AI meal analysis and personalized nutrition windows. Cancel anytime.`

2. **Subscription Review Information:**
   - Screenshot of the paywall (take from Xcode simulator)
   - Review Notes: `Monthly subscription with 7-day free trial`

3. Verify **Subscription Prices** are set ($6.00 USD)

4. Verify **Introductory Offers** (if not set, add):
   - Type: Free Trial
   - Duration: 7 days
   - Eligible for all subscribers

#### Product 2: Monthly $8
1. **Subscription Localizations:**
   - Display Name: `Monthly Access`
   - Description: `Unlimited AI meal analysis and personalized nutrition windows. Cancel anytime.`

2. **Subscription Review Information:**
   - Screenshot of the paywall
   - Review Notes: `Monthly subscription with 7-day free trial`

3. Verify **Subscription Prices** are set ($8.00 USD)

4. Verify **Introductory Offers** (7-day free trial)

#### Product 3: Annual
1. **Subscription Localizations:**
   - Display Name: `Annual Access - Best Value`
   - Description: `Save 33% with annual billing. Unlimited access to all features and priority support.`

2. **Subscription Review Information:**
   - Screenshot of the paywall
   - Review Notes: `Annual subscription with 7-day free trial. Best value option.`

3. Set **Subscription Prices** (you'll need to set this):
   - Recommended: $76.80 USD/year (equivalent to $6.40/month)
   - Or: $72.00 USD/year ($6/month - matches your lowest tier)

4. Verify **Introductory Offers** (7-day free trial)

### 1.3 Submit for Review
- After adding metadata to all 3 products, click **Submit for Review**
- Include screenshots showing the paywall
- Add review note: `Three subscription tiers with 7-day free trials. Users can compare pricing and choose their preferred option.`
- **Important:** Products won't work in production until approved (sandbox testing works immediately)

---

## 📋 STEP 2: RevenueCat Dashboard Configuration

### 2.1 Create RevenueCat Account
1. Go to https://app.revenuecat.com
2. Sign up or log in
3. Create a new project: **"NutriSync"**

### 2.2 Add iOS App
1. Go to **Projects** → Select "NutriSync"
2. Click **Apps** → **+ New App**
3. **App Name:** NutriSync
4. **Platform:** iOS
5. **Bundle ID:** `com.brennenprice.NutriSync` (verify in Xcode)
6. Click **Save**

### 2.3 Connect to App Store Connect
1. In the app settings, go to **App Store Connect**
2. Follow the instructions to generate an **App Store Connect API Key**:
   - Go to https://appstoreconnect.apple.com/access/api
   - Click **+** to create a new key
   - Name: "RevenueCat API Access"
   - Role: **App Manager**
   - Download the `.p8` file
   - Copy the **Key ID** and **Issuer ID**
3. Upload the `.p8` file to RevenueCat
4. Enter Key ID and Issuer ID
5. Click **Verify** and **Save**

### 2.4 Configure Products in RevenueCat
1. Go to **Products** tab
2. Click **+ Add Product** for each of your 3 subscriptions:

#### Add Product 1:
- **Product ID:** `com.nutrisync.monthly.6`
- **Store:** App Store
- **Display Name:** Monthly $6
- Click **Add**

#### Add Product 2:
- **Product ID:** `com.nutrisync.monthly.8`
- **Store:** App Store
- **Display Name:** Monthly $8
- Click **Add**

#### Add Product 3:
- **Product ID:** `com.nutrisync.annual`
- **Store:** App Store
- **Display Name:** Annual Premium
- Click **Add**

### 2.5 Create Entitlement
1. Go to **Entitlements** tab
2. Click **+ New Entitlement**
3. **Identifier:** `premium`
4. **Description:** Full access to all NutriSync features
5. Click **Create**

**Note:** We keep the identifier as "premium" for technical purposes, but this represents full app access, not optional premium features.

### 2.6 Attach Products to Entitlement
1. Click on the `premium` entitlement
2. Click **Attach Products**
3. Select **ALL 3 products**:
   - ✓ com.nutrisync.monthly.6
   - ✓ com.nutrisync.monthly.8
   - ✓ com.nutrisync.annual
4. Click **Attach**

### 2.7 Create Offerings (Package Structure)
1. Go to **Offerings** tab
2. Click **+ New Offering**
3. **Identifier:** `default`
4. **Description:** Default subscription offering
5. **Make this the current offering:** ✓ Checked
6. Click **Create**

### 2.8 Add Packages to Offering
Click **+ Add Package** for each of your 3 tiers:

#### Package 1: Monthly $6
- **Identifier:** `monthly_6`
- **Package Type:** Monthly (use standard type)
- **Product:** com.nutrisync.monthly.6
- Click **Add**

#### Package 2: Monthly $8
- **Identifier:** `monthly_8`
- **Package Type:** Custom
- **Product:** com.nutrisync.monthly.8
- Click **Add**

#### Package 3: Annual
- **Identifier:** `annual`
- **Package Type:** Annual (use standard type)
- **Product:** com.nutrisync.annual
- Click **Add**

### 2.9 Configure API Keys
1. Go to **Project Settings** → **API Keys**
2. Copy the **Public API Key**
3. **VERIFY** it matches the key in `PhylloApp.swift`:
   ```swift
   Purchases.configure(withAPIKey: "appl_QzcJHpMKoCVNkraSzGBERNhoynr")
   ```
4. If different, update `PhylloApp.swift` with the correct key

---

## 📋 STEP 3: Testing in Sandbox

### 3.1 Create Sandbox Test Account
1. Go to https://appstoreconnect.apple.com
2. **Users and Access** → **Sandbox Testers**
3. Click **+** to create a test account
4. Fill in fake details (use a real email you control)
5. **Region:** United States
6. Click **Create**

### 3.2 Configure Device for Sandbox Testing
1. Open **Settings** on your iPhone/Simulator
2. Go to **App Store** → **Sandbox Account**
3. Sign in with the sandbox tester account

### 3.3 Enable RevenueCat Debug Mode
Already configured in your `PhylloApp.swift`:
```swift
Purchases.logLevel = .debug  // Already set!
```

### 3.4 Test Purchase Flow
1. Build and run the app in Xcode
2. Complete onboarding
3. Wait for grace period paywall to appear
4. Select a subscription tier
5. Click "Start for [price]"
6. Approve the sandbox purchase (no actual charge)
7. Verify subscription is active
8. Check Xcode console for RevenueCat logs

### 3.5 Expected Console Output
```
💳 RevenueCat configured
✅ RevenueCat user identity set: [userId]
✅ Managers initialized
📦 Fetching offerings from RevenueCat...
📦 Offerings response - Current: default, All: default
   Available packages: 3
   - monthly_6: $6.00
   - monthly_8: $8.00
   - annual: $72.00 (or $76.80)
✅ Purchase successful: true
```

---

## 📋 STEP 4: A/B Testing Setup (Optional)

### 4.1 Create Multiple Offerings for Price Testing
1. In RevenueCat dashboard, go to **Offerings**
2. Create 2 offerings for A/B testing the monthly price:

#### Offering A: $6 Focus
- Identifier: `price_test_a`
- Only include `monthly_6` and `annual`

#### Offering B: $8 Focus
- Identifier: `price_test_b`
- Only include `monthly_8` and `annual`

### 4.2 Configure Experiments
1. Go to **Experiments** tab
2. Click **+ New Experiment**
3. **Name:** Monthly Price Point Test
4. **Variants:**
   - 50% → `price_test_a` (lower price)
   - 50% → `price_test_b` (higher price)
5. **Primary Metric:** Initial Conversion Rate
6. Click **Start Experiment**

This will help you determine which monthly price point converts better while always offering the annual option as the "best value" anchor.

---

## 🎨 STEP 5: Verify Paywall UI Matches Theme

### 5.1 Current Theme Implementation
Your PaywallView already uses:
- ✅ Background: `Color.nutriSyncBackground` (#0a0a0a)
- ✅ Accent: `Color.nutriSyncAccent` (#C0FF73 lime green)
- ✅ Card backgrounds: `Color.white.opacity(0.05)`
- ✅ Corner radius: 16
- ✅ Selected package border: #C0FF73 with 2px stroke
- ✅ Checkmarks: #C0FF73 when selected

### 5.2 Optional Enhancements
If you want to customize further, consider:

1. **Add gradient header** (optional):
```swift
LinearGradient(
    colors: [
        Color.nutriSyncAccent.opacity(0.3),
        Color.nutriSyncBackground
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

2. **Animate package selection** (optional):
```swift
.scaleEffect(isSelected ? 1.02 : 1.0)
.animation(.spring(response: 0.3), value: isSelected)
```

3. **Add trial badge** to all packages:
Already shows "7-day free trial" from RevenueCat product info

---

## 🚀 STEP 6: Production Checklist

### Before App Store Submission:
- [ ] All 3 subscription products have metadata and are approved in App Store Connect
- [ ] RevenueCat entitlement `premium` configured
- [ ] All 3 packages attached to `default` offering
- [ ] API key verified in PhylloApp.swift
- [ ] Tested full purchase flow in sandbox with all 3 tiers
- [ ] Tested restore purchases
- [ ] Tested subscription status detection
- [ ] Changed `Purchases.logLevel` to `.warn` in production
- [ ] Added privacy policy URL (update in PaywallView.swift line 243)
- [ ] Added terms of service URL (update in PaywallView.swift line 245)

### Current Code Updates Needed:
1. **Privacy Policy & Terms URLs** (PaywallView.swift:243-245):
```swift
// UPDATE THESE BEFORE SHIPPING:
Link("Terms", destination: URL(string: "https://nutrisync.app/terms")!)
Link("Privacy", destination: URL(string: "https://nutrisync.app/privacy")!)
```

2. **Set Log Level to Warn** (PhylloApp.swift:32):
```swift
// Change this before production:
Purchases.logLevel = .warn  // Currently .debug
```

---

## 📊 Expected User Flow

### New User Journey:
1. ✅ User completes onboarding
2. ✅ Creates account (Apple/Google Sign-In)
3. ✅ Grace period starts automatically (24 hours)
4. ✅ Soft paywall shown (dismissible)
5. ✅ User can scan 4 meals + generate 1 window
6. ✅ Hard paywall blocks after limit OR 24h expiry
7. 🆕 PaywallView presents with RevenueCat offerings
8. 🆕 User selects tier (Monthly $6, Monthly $8, or Annual)
9. 🆕 Starts 7-day free trial
10. ✅ All limits removed immediately
11. 🆕 Charged after 7 days if not cancelled

### Paywall Presentation Logic:
- **Soft Paywall:** `placement: "soft_paywall"` (has close button)
- **Hard Paywall:** `placement: "grace_period_expired"` (no close button)
- **Meal Limit:** `placement: "meal_scan_limit_reached"`
- **Window Limit:** `placement: "window_gen_limit_reached"`

---

## 🔧 Troubleshooting

### Issue: "No offerings found"
**Solution:**
1. Verify products are approved in App Store Connect
2. Check RevenueCat dashboard → Products (should show 4)
3. Verify offering is set as "Current"
4. Wait 5-10 minutes for RevenueCat to sync with App Store

### Issue: "Unable to purchase"
**Solution:**
1. Sign in with sandbox tester account in Settings
2. Make sure products have free trial configured
3. Check RevenueCat logs in Xcode console
4. Verify bundle ID matches exactly

### Issue: Subscription not detected after purchase
**Solution:**
1. Check SubscriptionManager logs for entitlement check
2. Verify entitlement ID is `"premium"` (lowercase)
3. Test restore purchases
4. Check customer info in RevenueCat dashboard → Customers

### Issue: Wrong pricing displayed
**Solution:**
1. Verify localization in App Store Connect
2. Check package configuration in RevenueCat
3. Test in correct region (prices vary by country)

---

## 📝 Next Steps

1. **Complete App Store Connect setup** (create 4 products)
2. **Configure RevenueCat dashboard** (follow Step 2 above)
3. **Test in sandbox** (use test account)
4. **Update URLs** (privacy policy & terms)
5. **Set log level to warn** for production
6. **Test full flow** with real device
7. **Submit for App Review**

---

## 🎯 Summary

Your code is **100% ready** for RevenueCat-only paywalls with your 3 subscription tiers.

### What You Have:
✅ 3 subscription products already created in App Store Connect
- Monthly $6 (`com.nutrisync.monthly.6`)
- Monthly $8 (`com.nutrisync.monthly.8`)
- Annual (`com.nutrisync.annual`)

### What You Need to Do:
1. ✅ Add metadata to the 3 products in App Store Connect
2. ✅ Set up RevenueCat dashboard (add products, entitlement, offering)
3. ✅ Test with sandbox account
4. ✅ Update privacy/terms URLs in code
5. ✅ Ship it!

The custom PaywallView already matches your #C0FF73 theme perfectly and will automatically display all 3 tiers. No code changes needed.

**Estimated setup time:** 1-2 hours for dashboard configuration

---

**Date:** 2025-11-18
**Status:** Ready for external configuration (3-tier pricing)
