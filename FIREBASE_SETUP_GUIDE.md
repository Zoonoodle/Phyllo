# Firebase Setup Guide for Phyllo

## Prerequisites

Before running the app with Firebase integration, you need to:

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create Project" and name it "phyllo-nutrition" (or your preferred name)
3. Enable Google Analytics (optional)

### 2. Add iOS App to Firebase

1. In Firebase Console, click "Add app" and select iOS
2. Enter your bundle ID (find it in Xcode project settings)
3. Download `GoogleService-Info.plist`
4. **Add `GoogleService-Info.plist` to your Xcode project** (drag it into the Phyllo folder)

### 3. Enable Required Firebase Services

In Firebase Console, enable:

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable:
   - Email/Password
   - Apple (requires Apple Developer account configuration)

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in **test mode** for development
4. Choose your preferred location (us-central1 recommended)

#### Storage
1. Go to Storage
2. Click "Get started"
3. Start in test mode for development
4. Choose same location as Firestore

#### Vertex AI (Firebase AI Logic)
1. Go to "Build with Gemini API" in Firebase Console
2. Click "Get started"
3. Enable the Vertex AI API
4. Your project will automatically have access to Gemini models

### 4. Configure App Check (Optional but Recommended)

1. Go to App Check in Firebase Console
2. Register your app
3. For debug builds: Use debug provider
4. For release builds: Use App Attest

### 5. Update Project Configuration

1. Open `Phyllo/Services/AI/VertexAIService.swift`
2. Verify the model name is set to "gemini-2.5-flash"

### 6. Install Dependencies

1. Open Xcode
2. Go to File → Add Package Dependencies
3. Add: `https://github.com/firebase/firebase-ios-sdk.git`
4. Select version 11.0.0 or later
5. Add these packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics
   - FirebaseVertexAI
   - FirebaseAppCheck

### 7. Build and Run

1. Build the project: `⌘+B`
2. If you see missing `GoogleService-Info.plist` error, make sure you added it to the project
3. Run on simulator or device

## Security Rules (For Production)

Update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Nutrition database is read-only
    match /nutritionDatabase/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

Update Storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Temporary meal images
    match /temp_meal_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.resource.size < 10 * 1024 * 1024 // 10MB limit
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Troubleshooting

### "No GoogleService-Info.plist found"
- Make sure you downloaded it from Firebase Console
- Add it to your Xcode project (not just the folder)
- It should appear in the project navigator

### "Permission denied" errors
- Check Firestore and Storage are in test mode
- Verify Authentication is enabled
- Check security rules if in production mode

### Vertex AI errors
- Ensure Vertex AI API is enabled in Google Cloud Console
- Check your Firebase project has billing enabled (Blaze plan)
- Verify the model name is correct

## Next Steps

Once Firebase is configured:
1. The app will use real Vertex AI for meal analysis
2. Images will be stored in Firebase Storage
3. Data will persist in Firestore (once we implement it)
4. Authentication will be ready (once we implement it)