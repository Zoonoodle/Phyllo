# Firebase Packages Required for Phyllo

## Package URL
Add this single package to your Xcode project:
```
https://github.com/firebase/firebase-ios-sdk.git
```

**Version:** 11.0.0 or later

## Required Firebase Products

When adding the Firebase SDK package, select these specific products:

### Core Requirements (Phase 1)
1. **FirebaseAnalytics** - Core analytics (required by other services)
2. **FirebaseAuth** - User authentication 
3. **FirebaseFirestore** - Database for all app data
4. **FirebaseStorage** - Image storage for meal photos
5. **FirebaseAI** - AI/ML features with Gemini (formerly FirebaseVertexAI)
6. **FirebaseAppCheck** - Security for API protection

### Future Requirements (Later Phases)
7. **FirebaseMessaging** - Push notifications (Phase 5)
8. **FirebaseCrashlytics** - Crash reporting (Production)
9. **FirebasePerformance** - Performance monitoring (Production)
10. **FirebaseRemoteConfig** - Feature flags (Phase 6+)

## How to Add in Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter the URL: `https://github.com/firebase/firebase-ios-sdk.git`
4. Choose version: **Up to Next Major Version** → **11.0.0**
5. Click **Add Package**
6. Select these packages for now:
   - ✅ FirebaseAnalytics
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseStorage
   - ✅ FirebaseAI
   - ✅ FirebaseAppCheck
7. Click **Add Package**

## Apple Sign In Configuration

For Apple authentication (mentioned in your auth handler URL):

1. In Xcode, select your project → Signing & Capabilities
2. Click **+ Capability**
3. Add **Sign in with Apple**
4. In Firebase Console:
   - Go to Authentication → Sign-in method
   - Enable Apple provider
   - Add your Services ID and configure OAuth

## Bundle Identifier

Based on your project settings, your bundle ID is:
```
com.Phyllo.Phyllo
```

Make sure this matches in:
- Xcode project settings
- Firebase Console iOS app configuration
- Apple Developer account

## Info.plist Requirements

The Firebase SDK will automatically handle most configurations, but for Apple Sign In, you may need to add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.Phyllo.Phyllo</string>
        </array>
    </dict>
</array>
```

## Important Notes

1. **GoogleService-Info.plist** must be added to your Xcode project (not just the folder)
2. The file should appear in the project navigator
3. Make sure it's included in your app target
4. For Vertex AI to work, your Firebase project must be on the **Blaze (pay-as-you-go) plan**

## Verification Steps

After adding packages and GoogleService-Info.plist:

1. Build the project: `⌘+B`
2. Check console output for: "✅ Firebase configured successfully"
3. If you see warnings about missing plist, ensure it's properly added to the project

## Next Steps

Once packages are installed:
1. Rename `FirebaseConfig.real.swift` to `FirebaseConfig.swift` (replacing the mock)
2. Rename `VertexAIService.firebase.swift` to `VertexAIService.swift` (replacing the mock)
3. Build and run the app
4. Test meal photo analysis with real Vertex AI