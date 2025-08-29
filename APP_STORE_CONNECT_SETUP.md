# App Store Connect Setup Guide for NutriSync

## Prerequisites
- Apple Developer Account ($99/year)
- Admin access to developer.apple.com and appstoreconnect.apple.com
- Xcode installed and signed in with your Apple ID

## Step 1: Create App ID (Apple Developer Portal)

1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** button
4. Select **App IDs** → Continue
5. Select **App** → Continue
6. Fill in:
   - **Description**: NutriSync - Nutrition Coach
   - **Bundle ID**: Explicit, `com.yourcompany.nutrisync` (replace with your actual domain)
   - **Capabilities**: Enable:
     - ✅ Push Notifications
     - ✅ HealthKit
     - ✅ Associated Domains (for Universal Links)
     - ✅ Sign in with Apple (optional, for future)
7. Click **Continue** → **Register**

## Step 2: Create Provisioning Profiles

### Development Profile
1. Go to **Profiles** → **+**
2. Select **iOS App Development** → Continue
3. Select your App ID (NutriSync) → Continue
4. Select your development certificate → Continue
5. Select your test devices → Continue
6. Name it: "NutriSync Development" → Generate
7. Download and double-click to install

### Distribution Profile (App Store)
1. Go to **Profiles** → **+**
2. Select **App Store** → Continue
3. Select your App ID (NutriSync) → Continue
4. Select your distribution certificate → Continue
5. Name it: "NutriSync App Store" → Generate
6. Download and double-click to install

## Step 3: Update Xcode Project Settings

1. Open NutriSync.xcodeproj in Xcode (will rename to NutriSync.xcodeproj later)
2. Select the project → Target "NutriSync" (will rename to "NutriSync" later)
3. Go to **Signing & Capabilities** tab
4. Update:
   - **Team**: Select your developer team
   - **Bundle Identifier**: `com.yourcompany.nutrisync`
   - **Automatically manage signing**: ON (recommended)
5. Add Capabilities:
   - Click **+ Capability**
   - Add **Push Notifications**
   - Add **HealthKit** (check both Clinical Health Records and Background Delivery)
   - Add **Background Modes** (already added)

## Step 4: Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: NutriSync (or "NutriSync - Smart Nutrition Coach" if taken)
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select the one you created
   - **SKU**: nutrisync-nutrition-coach-001
   - **User Access**: Full Access
4. Click **Create**

## Step 5: Configure App Information

### General Information
1. **Category**: 
   - Primary: Health & Fitness
   - Secondary: Food & Drink
2. **Content Rights**: Check if app contains third-party content
3. **Age Rating**: Click **Edit** and complete questionnaire
   - Medical/Treatment Info: Yes (nutrition tracking)
   - Other ratings: Answer honestly

### App Privacy
1. Click **Edit** next to Privacy Policy
2. Add Privacy Policy URL: `https://yourwebsite.com/privacy`
3. Complete privacy questions about data collection

### Pricing and Availability
1. Go to **Pricing and Availability**
2. Select **Free** (or your pricing)
3. Select all territories (or specific ones)

## Step 6: Prepare App Assets

### App Icon
- Size: 1024x1024px
- Format: PNG, no transparency
- No rounded corners (Apple adds them)

### Screenshots (Required Sizes)
1. **6.9" Display** (iPhone 16 Pro Max): 1320 x 2868px
2. **6.5" Display** (iPhone 14 Plus): 1284 x 2778px
3. **5.5" Display** (iPhone 8 Plus): 1242 x 2208px
4. **iPad Pro 12.9"** (optional): 2048 x 2732px

### App Description
**Short Description** (30 chars max):
"Smart meal window nutrition coach"

**Description** (4000 chars max):
```
NutriSync transforms nutrition tracking into personalized intelligence with AI-powered meal analysis and smart meal windows.

KEY FEATURES:
• AI Meal Analysis - Snap a photo for instant nutrition breakdown
• Smart Meal Windows - Optimized eating schedule based on your goals
• Micronutrient Tracking - 18+ nutrients with health impact scores
• Intelligent Reminders - Gentle nudges to keep you on track
• Morning & Post-Meal Check-ins - Track energy, sleep, and progress

WHAT MAKES NUTRISYNC DIFFERENT:
Unlike simple calorie counters, NutriSync learns your patterns and provides actionable insights. Our AI analyzes how different foods affect your energy, sleep, and performance.

FEATURES:
• Photo-based meal logging with ingredient breakdown
• Voice descriptions for better accuracy
• Circadian-optimized meal timing
• Goal-specific meal windows
• Progress tracking with NutriSyncScore
• Detailed micronutrient analysis

Perfect for anyone wanting to optimize their nutrition for better energy, sleep, and overall health.

NutriSync uses HealthKit to read and write nutrition data, providing a complete picture of your health.
```

**Keywords**: 
nutrition, meal tracking, intermittent fasting, AI food scanner, meal windows, macros, micronutrients, health coach, diet tracker, food diary

**Support URL**: `https://yourwebsite.com/support`
**Marketing URL**: `https://yourwebsite.com`

## Step 7: TestFlight Setup

1. In App Store Connect, go to your app
2. Click **TestFlight** tab
3. Complete **Test Information**:
   - Beta App Description
   - Email
   - Privacy Policy URL
   - Beta App Review notes
4. Add **App Store Connect Users** as internal testers
5. Create a **Group** for external testers (later)

## Step 8: Build and Upload

1. In Xcode:
   - Select **Generic iOS Device** as destination
   - Product → Archive
   - Wait for build to complete
2. In Organizer window:
   - Select your archive
   - Click **Distribute App**
   - Choose **App Store Connect**
   - Choose **Upload**
   - Select options (usually defaults)
   - Upload
3. Wait 5-30 minutes for processing
4. Build appears in TestFlight

## Next Steps
- [ ] Create Privacy Policy and Terms of Service
- [ ] Design and create app screenshots
- [ ] Write compelling app description
- [ ] Prepare support website/documentation
- [ ] Set up customer support email