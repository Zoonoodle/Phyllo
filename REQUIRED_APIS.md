# Required Google Cloud APIs for NutriSync

## Essential APIs (Must Enable)

### 1. ✅ Firestore API
- **Status**: Already enabled
- **Purpose**: Database for meals, windows, user data
- **Link**: https://console.cloud.google.com/apis/library/firestore.googleapis.com?project=nutriSync-9cc5a

### 2. ✅ Cloud Storage API  
- **Status**: Already enabled
- **Purpose**: Store meal photos temporarily
- **Link**: https://console.cloud.google.com/apis/library/storage-component.googleapis.com?project=nutriSync-9cc5a

### 3. 🔴 Firebase AI Logic API
- **Status**: NEEDS ENABLING
- **Purpose**: Firebase's Gemini AI integration
- **Link**: https://console.developers.google.com/apis/api/firebasevertexai.googleapis.com/overview?project=474187142933

### 4. 🔴 Vertex AI API
- **Status**: May need enabling
- **Purpose**: Underlying AI platform
- **Link**: https://console.cloud.google.com/apis/library/aiplatform.googleapis.com?project=474187142933

### 5. 🔴 Cloud Resource Manager API
- **Status**: May need enabling
- **Purpose**: Resource management for AI
- **Link**: https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com?project=474187142933

## Optional APIs (For Future Features)

### 6. Firebase Authentication
- **Purpose**: User login/signup (Phase 8)
- **Link**: https://console.firebase.google.com/project/nutriSync-9cc5a/authentication

### 7. Cloud Functions
- **Purpose**: Server-side logic
- **Link**: https://console.cloud.google.com/apis/library/cloudfunctions.googleapis.com?project=nutriSync-9cc5a

### 8. Firebase Cloud Messaging
- **Purpose**: Push notifications
- **Link**: https://console.firebase.google.com/project/nutriSync-9cc5a/messaging

## Quick Enable All Required

1. Click each link marked with 🔴
2. Click "Enable" on each page
3. Wait 3-5 minutes total
4. Restart the app

## Verification

After enabling, you should see these success messages in the app console:
- ✅ Firebase configured successfully
- 🔥 Using Firebase Data Provider
- No "API disabled" errors

## Troubleshooting

If APIs are enabled but still getting errors:
1. Wait 5 more minutes (propagation delay)
2. Check you're using the correct Google account
3. Verify billing is enabled on the Google Cloud project
4. Try clearing Xcode's derived data and rebuilding