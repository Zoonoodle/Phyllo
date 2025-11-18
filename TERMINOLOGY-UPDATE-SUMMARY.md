# Terminology Update: "Premium" → "Access"

**Date:** 2025-11-18
**Rationale:** NutriSync is a paid app with a limited trial, not a freemium app. Users need to "subscribe for access" rather than "upgrade to premium features."

---

## ✅ Changes Made

### 1. PaywallView.swift
**Updated strings to reflect paid app model:**

#### Variable Names:
- `premiumFeatures` → `appFeatures`

#### Header Titles:
- ❌ "Upgrade to Premium" → ✅ "Subscribe for Access"
- ❌ "Upgrade to Continue" → ✅ "Subscribe to Continue"
- ❌ "Unlock Unlimited Scans" → ✅ "Subscribe for Full Access"
- ✅ "Free Trial Ended" (kept - accurate)

#### Subtitles:
- ❌ "You've used your free window generation. Upgrade for..." → ✅ "You've reached your trial limit. Subscribe to continue..."
- ❌ "You've used all your free scans. Get unlimited..." → ✅ "You've reached your trial limit. Subscribe to continue..."
- ❌ "Unlock all features and take your nutrition to the next level." → ✅ "Continue your nutrition journey with full access to all features."
- ✅ "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition." (kept - accurate)

### 2. GracePeriodBanner.swift
**Updated banner button:**
- ❌ "Upgrade" button → ✅ "Subscribe" button

### 3. Configuration Guides

#### QUICK-START-REVENUECAT.md:
- ❌ Display Name: `Monthly Premium` → ✅ `Monthly Access`
- ❌ Display Name: `Annual Premium - Best Value` → ✅ `Annual Access - Best Value`
- ❌ Description: "...priority support" → ✅ "Unlimited access to all features and priority support"
- Added note: "Language: Emphasizes 'access' not 'premium' - reflects paid app model with limited trial."

#### revenuecat-configuration-guide.md:
- ❌ Display Name: `Monthly Premium` → ✅ `Monthly Access`
- ❌ Display Name: `Annual Premium - Best Value` → ✅ `Annual Access - Best Value`
- ❌ Entitlement Description: "Premium access to all NutriSync features" → ✅ "Full access to all NutriSync features"
- Added note: "We keep the identifier as 'premium' for technical purposes, but this represents full app access, not optional premium features."

---

## ✅ What Stayed the Same

### Technical Identifiers (Backend):
- ✅ Entitlement ID: `"premium"` (RevenueCat identifier - not user-facing)
- ✅ Product IDs: `com.nutrisync.monthly.6`, etc. (App Store identifiers)

### Features List:
✅ Feature descriptions stayed the same (they describe what users get):
- "Unlimited AI Meal Analysis"
- "Personalized Meal Windows"
- "Smart Window Adjustments"
- "Advanced Analytics"
- "Priority Support"

These describe access to features, which is correct.

---

## 📊 User-Facing Language Summary

### OLD (Freemium Model):
- "Upgrade to Premium"
- "Premium features"
- "Free scans/windows"
- Focus on "upgrading" from free to premium

### NEW (Paid App Model):
- "Subscribe for Access"
- "Full access to features"
- "Trial limit reached"
- Focus on "continuing" access after trial

---

## 🎯 Messaging Strategy

### Before (Freemium Mindset):
> "Try it free! Upgrade to unlock premium features."

### After (Trial-to-Paid Mindset):
> "24-hour trial with 4 scans. Subscribe to continue with unlimited access."

This aligns with the reality:
- ✅ There IS NO free version
- ✅ Trial is LIMITED (time + usage)
- ✅ Subscription is REQUIRED to continue
- ✅ Users are subscribing for ACCESS, not optional extras

---

## 📝 Next Steps for App Store Connect

When adding metadata, use:
- **Monthly $6:** Display Name = `Monthly Access`
- **Monthly $8:** Display Name = `Monthly Access`
- **Annual:** Display Name = `Annual Access - Best Value`

**Descriptions should emphasize:**
- "Unlimited access" not "premium features"
- "Continue using NutriSync" not "unlock extras"
- Trial limitations upfront

---

## 🧪 Testing Checklist

After these changes, verify:
- [ ] Grace period banner shows "Subscribe" button
- [ ] Paywall headers say "Subscribe for Access" (not "Upgrade")
- [ ] Paywall subtitles mention "trial limit reached"
- [ ] No references to "free features" or "premium upgrades"
- [ ] Language feels like "continue using" not "unlock extras"

---

**Status:** ✅ Complete
**Files Modified:** 4 (2 Swift files, 2 markdown guides)
**Breaking Changes:** None (only user-facing strings)
**Technical Changes:** None (entitlement ID stays "premium")

---

**Date:** 2025-11-18
