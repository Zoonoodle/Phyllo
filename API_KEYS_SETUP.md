# 🔑 API Keys Setup Guide

**Current Status:** SDKs installed ✅ | API keys needed ⚠️

---

## ⚠️ REQUIRED: Replace Placeholder API Keys

In `NutriSync/PhylloApp.swift` lines 34 and 39, you need to replace these placeholder strings:

```swift
// Line 34 - RevenueCat API Key
Purchases.configure(withAPIKey: "YOUR_REVENUECAT_PUBLIC_API_KEY")

// Line 39 - Superwall API Key
Superwall.configure(
    apiKey: "YOUR_SUPERWALL_PUBLIC_API_KEY",
    purchaseController: RevenueCatPurchaseController()
)
```

---

## 1️⃣ Get RevenueCat Public API Key

### Steps:
1. Go to: https://app.revenuecat.com
2. Sign up or log in
3. Click **Create New Project** → Name it "NutriSync"
4. Click **Add App** → Select **iOS**
5. Enter your bundle ID: `com.brennenprice.NutriSync` (or your actual bundle ID)
6. Copy the **Public API Key** (starts with `appl_...`)
7. Paste it in PhylloApp.swift line 34

### ✅ What it looks like:
```swift
Purchases.configure(withAPIKey: "appl_AbCdEfGhIjKlMnOpQrStUvWxYz")
```

---

## 2️⃣ Get Superwall Public API Key

### Steps:
1. Go to: https://superwall.com
2. Sign up or log in
3. Click **Create New Project** → Name it "NutriSync"
4. Click **Add App** → Select **iOS**
5. Enter your bundle ID: `com.brennenprice.NutriSync`
6. Copy the **Public API Key**
7. Paste it in PhylloApp.swift line 39

### ✅ What it looks like:
```swift
Superwall.configure(
    apiKey: "pk_1234567890abcdefghijklmnopqrstuvwxyz",
    purchaseController: RevenueCatPurchaseController()
)
```

---

## 🚀 After Adding API Keys

Once you've replaced both placeholders:

1. **Build the project** in Xcode (Cmd+B)
2. If it builds successfully, move to next steps:
   - Configure Firebase Console for Google Sign-In
   - Update Info.plist with Google URL scheme
   - Create App Store Connect products
   - Configure RevenueCat products
   - Create Superwall paywalls

---

## 📝 Notes

- **Public keys are safe** to commit to Git (they're meant to be in the app)
- **Secret keys** should NEVER be in your code (RevenueCat handles those on the server)
- You can use the same keys for development and production, or create separate projects

---

## 🔗 Quick Links

- **RevenueCat Dashboard:** https://app.revenuecat.com
- **Superwall Dashboard:** https://superwall.com/dashboard
- **RevenueCat Docs:** https://www.revenuecat.com/docs/getting-started
- **Superwall Docs:** https://docs.superwall.com

---

**Next file to check:** After adding keys, see `progress-account-paywall-system.md` for remaining configuration steps.
