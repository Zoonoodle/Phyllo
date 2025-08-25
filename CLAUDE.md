# NutriSync (Phyllo) - AI-Powered Nutrition Coach
## Development Guide & Technical Documentation

**Project:** NutriSync - Intelligent Meal Window & Nutrition Tracking System  
**Platform:** iOS 17+ (SwiftUI 6)  
**Backend:** Firebase (Firestore, Auth, Storage, Functions)  
**AI Engine:** Google Vertex AI (Gemini Flash for meal analysis, Gemini Pro for window generation)  
**Architecture:** MVVM with @Observable, Protocol-oriented services

---

## 🎯 Core Concept & Vision

NutriSync revolutionizes nutrition tracking by focusing on **meal window timing** rather than simple calorie counting. The app creates personalized eating schedules based on:
- Individual circadian rhythms and sleep patterns
- Specific nutrition goals (weight loss, muscle gain, performance, sleep optimization)
- Real-world constraints (work schedule, workouts, social commitments)
- Scientific research on nutrient timing and metabolic optimization

**Key Differentiator:** Instead of asking "what did you eat?", we optimize "when should you eat?" and adapt in real-time.

---

## 🚀 Development Workflow (MANDATORY)

### Git & Version Control
```bash
# ALWAYS work on main branch
git status                                    # Check current state
git add -A                                    # Stage all changes
git commit -m "feat: description"            # Commit with clear message
git push origin main                          # Push after EVERY feature/fix

# Commit message format:
# feat: new feature implementation
# fix: bug fix
# refactor: code improvement
# docs: documentation update
# style: UI/formatting changes
# test: test additions/modifications
```

### Build & Debug Strategy (Large Project Optimization)

**⚠️ CRITICAL: ALWAYS TEST BEFORE COMMITTING**
```bash
# MANDATORY WORKFLOW - NO EXCEPTIONS:
# 1. After making changes, compile ALL edited files FIRST
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  Path/To/EditedFile1.swift Path/To/EditedFile2.swift

# 2. Type-check for semantic validation if parse succeeds
xcrun swift-frontend -typecheck \
  -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -module-name NutriSync \
  -import-objc-header NutriSync-Bridging-Header.h \
  Path/To/EditedFile1.swift Path/To/EditedFile2.swift

# 3. ONLY if compilation succeeds, then commit and push
git add -A && git commit -m "fix: description" && git push

# 4. Full build only when absolutely necessary (avoid due to timeouts)
# Instead, rely on manual testing in Xcode

# ❌ NEVER DO THIS:
# - Mark "Test the fix" as complete without compiling
# - Commit without testing edited files
# - Skip compilation because "it should work"
```

### Testing Protocol

**WHEN YOU CREATE A "TEST" TODO:**
- It means ACTUALLY compile the code
- It means ACTUALLY run the test commands
- It means FIXING any errors before marking complete
- NEVER mark "Test" todos complete without running tests

1. **Compilation Testing** (MANDATORY before EVERY commit):
   ```bash
   swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
     -target arm64-apple-ios17.0 \
     ALL_EDITED_FILES.swift
   ```
2. **Manual Testing**: Build and run in Xcode simulator
3. **Screenshot Documentation**: Capture UI changes for review
4. **Edge Case Testing**: 
   - Midnight crossover scenarios
   - Timezone changes
   - Network failures
   - Empty states
5. **User Feedback Integration**: Implement based on screenshots/feedback

---

## 🏗 Architecture & Code Structure

### Project Structure
```
NutriSync/
├── Models/                 # Data structures
│   ├── UserProfile.swift   # User settings, goals, preferences
│   ├── MealWindow.swift    # Eating window definitions
│   ├── LoggedMeal.swift    # Analyzed meal data
│   └── CheckInData.swift   # Daily check-in responses
├── Services/              
│   ├── AI/                 # AI integration
│   │   ├── VertexAIService.swift        # Gemini API wrapper
│   │   └── MealAnalysisAgent.swift      # Meal photo analysis
│   ├── DataProvider/       # Data layer abstraction
│   │   ├── FirebaseDataProvider.swift   # Production data
│   │   └── MockDataProvider.swift       # Development/testing
│   ├── WindowGenerationService.swift     # AI window scheduling
│   └── ClarificationManager.swift        # Follow-up questions
├── ViewModels/             # Business logic
├── Views/                  # SwiftUI components
│   ├── Focus/              # Main dashboard tab
│   ├── Momentum/           # Progress tracking tab
│   ├── Scan/               # Meal capture tab
│   └── CheckIn/            # Daily check-ins
└── PhylloApp.swift         # App entry point
```

### Key Design Patterns
- **Protocol-Oriented**: `DataProviderProtocol` for Firebase/Mock switching
- **@Observable**: Modern SwiftUI 6 state management
- **Dependency Injection**: Services passed through environment
- **Coordinator Pattern**: Complex flows like onboarding
- **Repository Pattern**: Data access abstraction

---

## 🔥 Firebase Integration

### Current Priority: REMOVE ALL MOCK DATA
```swift
// ❌ OLD (Remove all instances)
@StateObject private var dataProvider = MockDataManager.shared

// ✅ NEW (Use everywhere)
@EnvironmentObject private var dataProvider: FirebaseDataProvider
```

### Firestore Structure
```javascript
users/{userId}/
  ├── profile/               // UserProfile document
  ├── goals/                 // UserGoals document
  ├── meals/{mealId}/        // LoggedMeal documents
  ├── windows/{date}/        // Daily MealWindow array
  ├── checkIns/{date}/       // Daily CheckInData
  └── insights/{insightId}/  // AI-generated insights

// Shared collections
recipes/{recipeId}/          // Community recipes
foodDatabase/{foodId}/       // Cached food items
```

### Security Rules
```javascript
// Basic security for nutrition app
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read for shared content
    match /recipes/{document=**} {
      allow read: if request.auth != null;
    }
    
    // Rate limiting for AI calls (Cloud Functions)
    // Max 100 meal scans per day per user
    // Max 10 window generations per day per user
  }
}
```

### Storage Rules (Meal Photos)
```javascript
// Auto-delete meal photos after 24 hours to save costs
// Compress images to max 500KB before upload
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/meals/{mealId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 500 * 1024; // 500KB max
    }
  }
}
```

---

## 🤖 AI Integration & Cost Management

### Gemini API Usage & Costs
```swift
// COST TARGETS:
// - Meal Analysis: $0.01-0.03 per scan
// - Window Generation: $0.01-0.03 per generation

struct GeminiCostOptimization {
    // Gemini Flash (for meal analysis)
    static let flashInputCost = 0.075 / 1_000_000  // per token
    static let flashOutputCost = 0.30 / 1_000_000   // per token
    static let maxFlashTokens = 2000  // Limit response length
    
    // Gemini Pro (for complex window generation)
    static let proInputCost = 0.50 / 1_000_000     // per token
    static let proOutputCost = 1.50 / 1_000_000    // per token
    static let maxProTokens = 1500    // Limit response length
    
    // Image compression before analysis
    static let maxImageSize = 500_000  // 500KB compressed
    static let jpegQuality: CGFloat = 0.7
}

// Optimize prompts for token efficiency
extension MealAnalysisPrompt {
    static let efficient = """
    Analyze meal photo. Return JSON only:
    {
      "items": [{"name": "", "portion": "", "calories": 0, "protein": 0, "carbs": 0, "fat": 0}],
      "confidence": 0.0-1.0,
      "clarifications": ["question1", "question2"] // Max 2
    }
    """
}
```

### Clarification System Rules
- **Maximum 2 questions per meal scan**
- **Priority order**: Protein type > Portion size > Cooking method > Ingredients
- **Skip if confidence > 0.85**
- **Learn from feedback**: Track thumbs up/down to improve prompts

---

## 🎨 UI/UX Guidelines

### Design System
```swift
// Color Palette (Dark Theme)
extension Color {
    static let phylloBackground = Color(hex: "0a0a0a")      // Near black
    static let phylloCard = Color.white.opacity(0.03)       // Subtle cards
    static let phylloAccent = Color(hex: "10b981")          // Green (use sparingly 10-20%)
    static let phylloText = Color.white                     // Primary text
    static let phylloTextSecondary = Color.white.opacity(0.7)
    static let phylloTextTertiary = Color.white.opacity(0.5)
}

// Component Standards
struct PhylloDesignSystem {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 12
    static let animation = Animation.spring(response: 0.4, dampingFraction: 0.8)
}
```

### Three-Tab Navigation
1. **Focus Tab** (Primary): Current window, upcoming meals, real-time progress
2. **Momentum Tab**: Analytics, insights, weekly patterns
3. **Scan Tab**: Camera/voice input for meal logging

---

## 🚧 Current Development Priorities

### Phase 1: Firebase Migration (CURRENT)
- [ ] Remove ALL MockDataManager dependencies (47+ files)
- [ ] Implement FirebaseDataProvider for all data operations
- [ ] Set up Firebase Auth with anonymous upgrade flow
- [ ] Configure Firestore security rules
- [ ] Test data persistence and sync

### Phase 2: AI Window Generation Fixes
- [ ] Handle midnight crossover edge cases
- [ ] Implement timezone change detection
- [ ] Fix redistribution logic for missed meals
- [ ] Add workout-aware window timing
- [ ] Optimize token usage for cost targets

### Phase 3: UI Polish (WITH USER INPUT)
- [ ] Refine Focus tab layout based on feedback
- [ ] Improve animation transitions
- [ ] Add haptic feedback for interactions
- [ ] Implement proper loading states
- [ ] Create empty state designs

---

## 📊 Key Features Implementation

### Meal Window System
```swift
// Window Generation Logic
struct WindowGenerationRules {
    // Goal-specific patterns
    static let patterns: [UserGoal: WindowPattern] = [
        .loseWeight: .intermittentFasting(16, windows: 3),
        .buildMuscle: .frequentFeeding(windows: 5-6),
        .improvePerformance: .activityCentered,
        .betterSleep: .circadianOptimized
    ]
    
    // Window purposes (affects macro distribution)
    enum WindowPurpose {
        case preWorkout      // Higher carbs
        case postWorkout     // High protein + carbs
        case sustainedEnergy // Balanced macros
        case recovery        // Protein focus
        case metabolicBoost  // Lower carbs
        case sleepOptimized  // Light, early timing
    }
}
```

### Check-In System
```swift
// Daily check-ins for pattern recognition
struct CheckInSchedule {
    static let checkIns = [
        "morning": ["wakeTime", "sleepQuality", "dayFocus"],
        "postMeal": ["energyLevel", "fullness", "mood"],
        "evening": ["dailyReflection", "tomorrowPlans"],
        "workout": ["timing", "intensity", "nutrition needs"]
    ]
}
```

---

## 🧪 Testing & Quality Assurance

### Manual Testing Checklist
- [ ] New user onboarding flow (all paths)
- [ ] Meal photo capture and analysis
- [ ] Voice input transcription
- [ ] Window generation for each goal type
- [ ] Missed meal redistribution
- [ ] Check-in completion
- [ ] Offline mode handling
- [ ] Push notification delivery

### Edge Cases to Test
- [ ] User changes timezone
- [ ] Meal logged at 11:59 PM
- [ ] Network failure during photo upload
- [ ] Rapidly switching between tabs
- [ ] Background app refresh
- [ ] Low storage scenarios

---

## 📝 Documentation Requirements

### When Adding Features
1. **Update README.md** with feature description
2. **Add inline comments** for complex logic
3. **Document API changes** in service files
4. **Update this CLAUDE.md** with architectural changes

### Code Comment Standards
```swift
// ✅ GOOD: Explains WHY
// Redistribute remaining macros to later windows when user 
// misses a meal to maintain daily targets

// ❌ BAD: Explains WHAT (obvious from code)
// This function redistributes macros
```

---

## 🚀 Performance Optimization

### Current Issues & Solutions
```swift
// ISSUE: Build timeouts with 100+ files
// SOLUTION: Use file-specific compilation (see Build Strategy above)

// ISSUE: Memory usage with meal photos
// SOLUTION: Compress before upload, release after analysis
extension UIImage {
    func compressed(quality: CGFloat = 0.7, maxSize: Int = 500_000) -> Data? {
        // Implementation in Extensions/UIImage+Compression.swift
    }
}

// ISSUE: Firestore read costs
// SOLUTION: Aggressive local caching
class FirestoreCacheManager {
    static let mealCacheDuration: TimeInterval = 86400  // 24 hours
    static let windowCacheDuration: TimeInterval = 3600 // 1 hour
}
```

---

## 🔐 Security & Privacy

### Data Protection
- **Minimal PII**: Only store necessary user data
- **Photo Deletion**: Auto-remove after 24 hours
- **Encryption**: Use Firebase's built-in encryption
- **Anonymous Start**: Users can try without account

### API Key Management
```swift
// Store in Firebase Remote Config or Environment
enum APIKeys {
    static var geminiAPIKey: String {
        // Fetch from Firebase Remote Config
        RemoteConfig.remoteConfig().configValue(forKey: "gemini_api_key").stringValue
    }
}
```

---

## 📱 Device Support

- **Minimum iOS**: 17.0
- **Devices**: iPhone only (iPad later)
- **Orientation**: Portrait only
- **Offline Mode**: Limited (cached data only)

---

## 🎯 Success Metrics

### Performance Targets
- App launch: < 2 seconds
- Meal analysis: < 10 seconds
- Window generation: < 5 seconds
- Clarification questions: ≤ 2 per meal
- Crash rate: < 0.1%

### User Experience Goals
- Onboarding completion: > 90%
- Daily active usage: > 70%
- Meal logging accuracy: > 85% confidence
- User satisfaction: > 4.5 stars

---

## 🛠 Quick Reference Commands

```bash
# Daily workflow - ALWAYS FOLLOW THIS ORDER
git pull                                      # Start fresh
# Make changes...
swiftc -parse [ALL edited files]             # MANDATORY: Test compilation
# If compilation fails, FIX BEFORE COMMITTING
git add -A && git commit -m "feat: X" && git push  # Ship ONLY after testing

# Debug specific file
xcrun swift-frontend -typecheck -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -target arm64-apple-ios17.0 -module-name NutriSync Path/To/File.swift

# Find all mock data usage (to remove) - ALWAYS use ripgrep (rg)
rg "MockDataManager" --type swift .

# Check Firebase usage - ALWAYS use ripgrep (rg)
rg "FirebaseDataProvider" --type swift .
```

---

## 📞 Support & Resources

- **Firebase Console**: https://console.firebase.google.com
- **Vertex AI Console**: https://console.cloud.google.com/vertex-ai
- **Apple Developer**: https://developer.apple.com/account
- **SwiftUI Docs**: https://developer.apple.com/xcode/swiftui/

---

**Remember - MANDATORY RULES**: 
1. **ALWAYS compile edited files BEFORE committing** - No exceptions!
2. **Test todos mean ACTUAL testing** - Not just marking complete
3. Push after EVERY feature/change (but ONLY after testing)
4. Never commit if compilation fails - fix errors first
5. Remove mock data ASAP
6. Keep costs under $0.03 per AI operation
7. Manual test everything in Xcode
8. Document as you code