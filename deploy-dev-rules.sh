#!/bin/bash

# Deploy Firestore Development Rules Script
# This script helps quickly deploy development rules for testing

echo "🔥 NutriSync Firestore Rules Deployment"
echo "========================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI found"
echo ""

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
    echo "⚠️  firebase.json not found. Initializing Firebase..."
    firebase init firestore
fi

# Deploy rules
echo "📝 Deploying Firestore rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Rules deployed successfully!"
    echo ""
    echo "You can now:"
    echo "1. Restart the app in the simulator"
    echo "2. Complete the morning check-in"
    echo "3. Windows should generate automatically"
else
    echo ""
    echo "❌ Deployment failed!"
    echo "Please check your Firebase configuration"
fi