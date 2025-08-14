# TestFlight Release Checklist for Phyllo

## 📋 Pre-Release Requirements

### 1. **App Store Connect Setup** 🏪 📝
- [ ] Create App ID in Apple Developer Portal (see APP_STORE_CONNECT_SETUP.md)
- [ ] Generate provisioning profiles (Development & Distribution)
- [ ] Create app in App Store Connect
- [ ] Set up app metadata (name, description, keywords, categories)
- [ ] Prepare app icons (1024x1024 for App Store)
- [ ] Create screenshots for required device sizes
- [ ] Update Bundle Identifier in Xcode (currently: com.Phyllo.Phyllo)
- [ ] Configure version number (1.0.0) and build number (1)

### 2. **Missing Privacy Permissions** 🔐 ✅
Add to Info.plist:
- [x] `NSCameraUsageDescription` - "Phyllo needs camera access to capture photos of your meals for nutrition analysis"
- [x] `NSPhotoLibraryUsageDescription` - "Phyllo needs photo library access to select meal photos for nutrition analysis"
- [x] `NSHealthShareUsageDescription` - "Phyllo reads health data to provide personalized nutrition recommendations"
- [x] `NSHealthUpdateUsageDescription` - "Phyllo writes nutrition data to track your dietary intake"
- [x] `NSMicrophoneUsageDescription` - "Phyllo uses microphone for voice descriptions of meals"

### 3. **Critical Feature Fixes** 🛠️
- [ ] **Camera capture** - Currently using photo picker, need actual camera capture
- [ ] **Firebase Auth** - Implement actual user authentication flow (currently no login)
- [ ] **User data persistence** - Ensure data saves to Firestore per user
- [ ] **Push notifications** - Complete implementation (currently not functional)

### 4. **App Configuration** ⚙️
- [ ] Set proper Bundle ID (com.yourcompany.phyllo)
- [ ] Increment version number (1.0.0) and build number
- [ ] Configure app capabilities in Xcode:
  - Push Notifications
  - HealthKit (if implementing)
  - Background Modes
- [ ] Add Firebase GoogleService-Info.plist for production

### 5. **Essential Missing Features** 🚨
- [ ] **User onboarding** - Currently goes straight to mock data
- [ ] **Login/Signup flow** - No authentication implemented
- [ ] **Terms of Service & Privacy Policy** - Required for App Store
- [ ] **Error handling** - Network failures, API errors
- [ ] **Loading states** - Proper UI feedback during operations

### 6. **Pre-Submission Testing** ✅
- [ ] Test on physical devices (not just simulator)
- [ ] Test all iOS versions you support (17.0+)
- [ ] Test different screen sizes
- [ ] Verify Firebase production config works
- [ ] Test network error scenarios
- [ ] Memory leak testing
- [ ] Performance profiling

### 7. **TestFlight Specifics** 🚀
- [ ] Archive build with Release configuration
- [ ] Upload to App Store Connect via Xcode
- [ ] Fill out TestFlight information:
  - What to test
  - Test accounts (if needed)
  - Beta app description
- [ ] Add internal testers
- [ ] Submit for Beta App Review (if adding external testers)

### 8. **Legal Requirements** 📄
- [ ] Privacy Policy URL (required)
- [ ] Terms of Service URL (recommended)
- [ ] Age rating questionnaire
- [ ] Export compliance (for encryption)

### 9. **Recommended Additions** 💡
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] Analytics events for key user actions
- [ ] App version check/force update mechanism
- [ ] Basic user settings/profile screen
- [ ] Logout functionality
- [ ] Delete account option (App Store requirement)

## 📅 Timeline Estimates

- **Minimum viable TestFlight**: 2-3 days (critical fixes only)
- **Polished TestFlight**: 1-2 weeks (includes proper auth, camera, notifications)
- **Production-ready**: 3-4 weeks (all features, thorough testing)

## 🚨 Most Critical Items

1. User authentication implementation
2. Info.plist privacy descriptions
3. App Store Connect setup
4. Basic error handling

## 📝 Notes

- TestFlight allows up to 10,000 external testers
- Beta builds expire after 90 days
- Internal testing doesn't require App Review
- External testing requires Beta App Review (usually 24-48 hours)