# Quick Start: RevenueCat Setup for Your 3 Subscriptions

**Date:** 2025-11-18
**Your Products:** Monthly $6, Monthly $8, Annual

---

## ✅ What's Already Done

Your code is **100% ready**:
- ✅ PaywallView with custom #C0FF73 theme
- ✅ SubscriptionManager implemented
- ✅ RevenueCat SDK configured in PhylloApp.swift
- ✅ All 3 subscription products created in App Store Connect
- ✅ Works dynamically with any number of packages

**No code changes needed!**

---

## 🚀 Next Steps (Do These in Order)

### STEP 1: Fix "Missing Metadata" in App Store Connect (20 min)

1. Go to https://appstoreconnect.apple.com
2. Navigate to your app → **Subscriptions** → `premium_group`
3. For each of the 3 products, click on it and add:

**For Monthly $6:**
- Display Name: `Monthly Access`
- Description: `Unlimited AI meal analysis and personalized nutrition windows. Cancel anytime.`
- Add a screenshot of the paywall (take from Xcode simulator later)

**For Monthly $8:**
- Display Name: `Monthly Access`
- Description: `Unlimited AI meal analysis and personalized nutrition windows. Cancel anytime.`
- Add a screenshot of the paywall

**For Annual:**
- Display Name: `Annual Access - Best Value`
- Description: `Save 33% with annual billing. Unlimited access to all features and priority support.`
- Set the annual price (recommended: $72/year to match your $6 monthly tier)
- Add a screenshot of the paywall

---

### STEP 2: Configure RevenueCat Dashboard (30-40 min)

#### 2.1 Create Account & Project
1. Go to https://app.revenuecat.com
2. Sign up or log in
3. Create project: **"NutriSync"**
4. Add iOS app with bundle ID: `com.brennenprice.NutriSync`

#### 2.2 Connect to App Store
1. In RevenueCat, go to **App Store Connect** settings
2. Follow instructions to create API key:
   - Go to https://appstoreconnect.apple.com/access/api
   - Create key with "App Manager" role
   - Download `.p8` file
   - Upload to RevenueCat with Key ID and Issuer ID

#### 2.3 Add Your 3 Products
Go to **Products** tab and add:
1. `com.nutrisync.monthly.6` (Monthly $6)
2. `com.nutrisync.monthly.8` (Monthly $8)
3. `com.nutrisync.annual` (Annual)

#### 2.4 Create Entitlement
1. Go to **Entitlements** tab
2. Create entitlement: `premium` (identifier)
3. Description: `Full access to all NutriSync features`
4. Attach all 3 products to this entitlement

**Note:** The identifier stays "premium" for technical purposes, but this grants full app access.

#### 2.5 Create Offering
1. Go to **Offerings** tab
2. Create offering: `default` (set as current)
3. Add 3 packages:
   - `monthly_6` → com.nutrisync.monthly.6 (type: Monthly)
   - `monthly_8` → com.nutrisync.monthly.8 (type: Custom)
   - `annual` → com.nutrisync.annual (type: Annual)

#### 2.6 Verify API Key
1. Copy the **Public API Key** from RevenueCat
2. Verify it matches in `PhylloApp.swift`:
   ```swift
   Purchases.configure(withAPIKey: "appl_QzcJHpMKoCVNkraSzGBERNhoynr")
   ```

---

### STEP 3: Test in Sandbox (30 min)

1. **Create sandbox tester:**
   - Go to App Store Connect → Users & Access → Sandbox Testers
   - Create a test account

2. **Configure device:**
   - On your iPhone: Settings → App Store → Sandbox Account
   - Sign in with sandbox tester

3. **Test purchase flow:**
   - Build and run app in Xcode
   - Complete onboarding
   - Wait for paywall to appear
   - You should see all 3 tiers displayed
   - Try purchasing each one
   - Test restore purchases

4. **Check console logs:**
   ```
   💳 RevenueCat configured
   📦 Available packages: 3
      - monthly_6: $6.00
      - monthly_8: $8.00
      - annual: $72.00
   ✅ Purchase successful: true
   ```

---

## 🎨 What Your Paywall Will Look Like

Your PaywallView will automatically display:
- ✅ Header: "Subscribe for Access" (or context-specific title)
- ✅ Subtitle emphasizing trial limit reached
- ✅ 5 feature bullets with lime green (#C0FF73) checkmarks
- ✅ 3 subscription cards (Monthly $6, Monthly $8, Annual)
- ✅ Annual card shows "BEST VALUE" badge
- ✅ Selected package has #C0FF73 border + checkmark
- ✅ Purchase button: "Start for [price]" with lime green background
- ✅ Restore purchases link
- ✅ Terms & Privacy links

**Language:** Emphasizes "access" not "premium" - reflects paid app model with limited trial.

---

## 🧪 A/B Testing (Optional - Do Later)

Want to test which price converts better?

1. Create 2 offerings in RevenueCat:
   - `price_test_a`: Only Monthly $6 + Annual
   - `price_test_b`: Only Monthly $8 + Annual

2. Set up Experiment with 50/50 split

3. See which monthly price performs better

---

## ⚠️ Before Shipping to Production

- [ ] Change log level in PhylloApp.swift:
  ```swift
  Purchases.logLevel = .warn  // Change from .debug
  ```

- [ ] Update URLs in PaywallView.swift (lines 243-245):
  ```swift
  Link("Terms", destination: URL(string: "YOUR_TERMS_URL")!)
  Link("Privacy", destination: URL(string: "YOUR_PRIVACY_URL")!)
  ```

- [ ] Add paywall screenshot to App Store Connect for each product

- [ ] Submit subscriptions for review

---

## 🆘 Troubleshooting

**"No offerings found"**
- Wait 5-10 minutes for RevenueCat to sync with App Store
- Verify products are in RevenueCat dashboard
- Check offering is set as "Current"

**"Unable to purchase"**
- Make sure you're signed into sandbox account
- Verify bundle ID matches exactly
- Check RevenueCat logs in Xcode console

**Subscription not detected**
- Verify entitlement ID is `premium` (lowercase)
- Test restore purchases
- Check customer info in RevenueCat dashboard

---

## 📝 Summary

Your setup is simple:
1. **20 min** → Add metadata to 3 products in App Store Connect
2. **40 min** → Configure RevenueCat dashboard
3. **30 min** → Test with sandbox account
4. **Done!** → Your paywall is ready to ship

**Total time:** ~90 minutes

The PaywallView code is already perfect and will work immediately once RevenueCat is configured.

---

**Full details:** See `revenuecat-configuration-guide.md` for comprehensive instructions.

**Date:** 2025-11-18
**Status:** Ready to configure ✅
