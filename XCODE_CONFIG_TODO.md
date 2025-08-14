# Xcode Configuration TODO

## Current Settings
- **Bundle Identifier**: `com.Phyllo.Phyllo` (needs update to `com.yourcompany.nutrisync`)
- **Development Team**: `5T7D257WY6`
- **Product Name**: Phyllo (needs update to NutriSync)

## Required Updates

### 1. Update Bundle Identifier
The current bundle ID `com.Phyllo.Phyllo` should be changed to follow Apple's reverse domain notation:
- Example: `com.yourcompany.nutrisync`
- Example: `com.zoonoodle.nutrisync`
- Example: `io.nutrisync.app`

To update:
1. Open Phyllo.xcodeproj
2. Select project → Phyllo target (will rename to NutriSync)
3. Change Bundle Identifier in General tab
4. Also update in Build Settings if needed
5. Rename target from "Phyllo" to "NutriSync"

### 2. Version and Build Numbers
- **Version**: 1.0.0 (for initial release)
- **Build**: 1 (increment for each TestFlight upload)

Location: General tab → Identity section

### 3. Display Name
- Current: "Phyllo"
- Consider: "Phyllo" or "Phyllo Nutrition"

### 4. Deployment Info
- **iOS Deployment Target**: 17.0 (currently set)
- **Device**: iPhone (consider iPad support later)
- **Orientations**: Portrait only (recommended for v1)

### 5. App Icons
Need to add app icons:
1. Open Assets.xcassets
2. Find AppIcon
3. Add all required sizes (Xcode will show which are missing)

### 6. Launch Screen
Verify LaunchScreen is properly configured

### 7. Capabilities to Add
In Signing & Capabilities:
- [ ] Push Notifications
- [ ] HealthKit (if implementing)
- [ ] Background Modes (already added)

## Important Notes
- The bundle ID cannot be changed after app is published to App Store
- Choose bundle ID carefully - it's permanent
- Development team must match your Apple Developer account