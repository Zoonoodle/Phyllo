# Deploy Firestore Rules - Quick Instructions

## The Issue
Your app can't generate windows because Firestore is blocking all access with permission errors.

## Quick Fix - Option 1: Firebase Console (Easiest)

1. Go to: https://console.firebase.google.com
2. Select your NutriSync/Phyllo project
3. Click **Firestore Database** in left menu
4. Click **Rules** tab
5. Replace ALL existing rules with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development access for testing
    match /users/dev_user_001/{document=**} {
      allow read, write: if true;
    }
    
    match /users/preview-user/{document=**} {
      allow read, write: if true;
    }
  }
}
```

6. Click **Publish**
7. Restart your app in the simulator
8. Windows will now generate after check-in!

## Quick Fix - Option 2: Command Line

If you have the right Firebase project ID:

```bash
# First, update .firebaserc with your project ID
echo '{"projects":{"default":"YOUR-PROJECT-ID"}}' > .firebaserc

# Then deploy
firebase deploy --only firestore:rules
```

## What This Fixes

✅ Morning check-in will save successfully
✅ Windows will generate after check-in
✅ User profile data will load
✅ Meals will save and display

## Security Note

These are DEVELOPMENT rules only. Before production, update to require authentication:

```javascript
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```