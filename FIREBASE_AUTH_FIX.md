# Firebase Configuration Fixes

## Issues Found:

1. **Bundle ID Mismatch** 
   - GoogleService-Info.plist expects: `com.NutriSync.NutriSync`
   - Your Xcode project likely has a different bundle ID
   
2. **Anonymous Authentication Disabled**
   - Error: "This operation is restricted to administrators only"
   - Anonymous auth is disabled in Firebase Console

3. **App Check Issues (Non-critical)**
   - DeviceCheckProvider doesn't work in simulator (expected)

## Required Fixes:

### 1. Fix Bundle ID in Xcode
1. Open `NutriSync.xcodeproj` in Xcode
2. Select the NutriSync target
3. Go to "Signing & Capabilities" tab
4. Change Bundle Identifier to: `com.NutriSync.NutriSync`
5. Clean and rebuild the project

### 2. Enable Anonymous Authentication in Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project (phyllo-9cc5a)
3. Navigate to Authentication → Sign-in method
4. Find "Anonymous" in the list
5. Click on it and toggle "Enable"
6. Click "Save"

### 3. (Optional) Disable App Check for Development
If App Check continues to cause issues:
1. Go to Firebase Console → App Check
2. Disable enforcement for development
OR
Comment out App Check in FirebaseConfig.swift temporarily

## After Fixes:
1. Clean build folder in Xcode (Shift+Cmd+K)
2. Delete app from simulator
3. Run the app again

The app should now:
- Successfully configure Firebase
- Sign in anonymously
- Show the onboarding screen