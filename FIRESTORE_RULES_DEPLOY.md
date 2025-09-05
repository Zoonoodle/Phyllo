# Deploying Firestore Security Rules

## Quick Fix for Development

The app is failing because Firestore security rules are blocking access. To fix this immediately:

### Option 1: Deploy Development Rules (Recommended for Testing)

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not done):
   ```bash
   firebase init firestore
   ```
   - Select your existing Firebase project
   - Use the default `firestore.rules` file
   - Use the default `firestore.indexes.json` file

4. **Deploy the development rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option 2: Manual Update via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your NutriSync project
3. Navigate to **Firestore Database** → **Rules** tab
4. Replace the existing rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development mode - allows dev_user_001 access
    match /users/dev_user_001/{document=**} {
      allow read, write: if true;
    }
    
    // Allow preview user access
    match /users/preview-user/{document=**} {
      allow read, write: if true;
    }
  }
}
```

5. Click **Publish**

### Option 3: Temporary Open Access (NOT for Production)

For immediate testing only, you can temporarily open all access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **WARNING**: This allows anyone to read/write your database. Only use for quick testing!

## What This Fixes

After deploying these rules, the app will be able to:
- Save morning check-in data
- Generate meal windows
- Read/write user profile data
- Store and retrieve meals

## Production Rules

Before going to production, update the rules to require authentication:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared content
    match /recipes/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

## Next Steps

After deploying the rules:
1. Restart the app in the simulator
2. Complete the morning check-in
3. Windows should generate successfully

## Monitoring

Check Firebase Console → Firestore → Usage tab to monitor:
- Read/write operations
- Security rule evaluations
- Any denied operations