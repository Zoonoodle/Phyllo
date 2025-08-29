# Firebase Security Rules for NutriSync

## Firestore Security Rules

Copy and paste these rules into the Firebase Console under Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for authenticated users only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read/write their own meals
    match /users/{userId}/meals/{mealId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read/write their own meal windows
    match /users/{userId}/mealWindows/{windowId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read/write their own check-ins
    match /users/{userId}/checkIns/{checkInId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // For development/testing - REMOVE IN PRODUCTION
    // Allows unauthenticated access for testing
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Firebase Storage Security Rules

Copy and paste these rules into the Firebase Console under Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to upload/read their own meal images
    match /users/{userId}/meals/{mealId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024 // 10MB max
        && request.resource.contentType.matches('image/.*');
    }
    
    // Temporary uploads folder with auto-deletion
    match /temp/{userId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024 // 10MB max
        && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // For development/testing - REMOVE IN PRODUCTION
    // Allows unauthenticated access for testing
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

## Setup Instructions

1. **Enable Firestore:**
   - Go to https://console.firebase.google.com/project/nutriSync-9cc5a/firestore
   - Click "Create database"
   - Choose "Start in test mode" for now
   - Select your preferred location (us-central1 is recommended)

2. **Enable Storage:**
   - Go to https://console.firebase.google.com/project/nutriSync-9cc5a/storage
   - Click "Get started"
   - Choose "Start in test mode" for now
   - Select the same location as Firestore

3. **Update Security Rules:**
   - For Firestore: Go to Database → Rules tab → Replace with rules above
   - For Storage: Go to Storage → Rules tab → Replace with rules above
   - Click "Publish" for each

4. **Enable Required APIs in Google Cloud Console:**
   - Firestore API: https://console.cloud.google.com/apis/library/firestore.googleapis.com?project=nutriSync-9cc5a
   - Storage API: https://console.cloud.google.com/apis/library/storage-component.googleapis.com?project=nutriSync-9cc5a
   - Cloud Resource Manager API: https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com?project=nutriSync-9cc5a

## Important Notes

- The current rules allow **unauthenticated access** for development
- **BEFORE PRODUCTION**: Remove the catch-all rules that allow read/write: true
- Implement proper authentication flow before going live
- Consider adding rate limiting and quota management

## Lifecycle Rules for Storage

To automatically delete temporary images after 24 hours:

1. Go to Storage in Firebase Console
2. Click on "Lifecycle" tab
3. Add a rule:
   - Condition: "Name/prefix matches: temp/"
   - Action: "Delete"
   - Age: 1 day