# Phyllo Backend Implementation Plan
## Comprehensive Roadmap for Firebase + Vertex AI Integration

**Version:** 1.0  
**Date:** January 2025  
**Approach:** Phased Implementation with Developer Dashboard Simulation  

---

## 🎯 Executive Summary

This document outlines the complete backend transformation of Phyllo from a mock-data prototype to a production-ready nutrition intelligence platform. The implementation follows a phased approach with developer dashboard simulation capabilities maintained throughout.

### Key Decisions:
- **AI:** Vertex AI SDK with Gemini 2.5 Flash only (no Cloud Functions)
- **Database:** Firestore for all data storage
- **Nutrition Data:** USDA database for micronutrients
- **Images:** Compress and auto-delete after 24 hours
- **Offline:** Limited functionality (view-only mode)
- **Developer Dashboard:** Maintain simulation capabilities
- **Auth:** Implement last (use dev dashboard for testing)

---

## 📊 Current State Analysis

### Mock Data Dependencies
- **47+ files** directly use `MockDataManager.shared`
- **Complete UI/UX** built on simulated data
- **Zero persistence** between app sessions
- **Time simulation** for testing scenarios

### Core Functionality to Replace
1. Meal photo analysis (currently 3-second fake delay)
2. Meal window calculations (client-side logic)
3. Nutrition tracking (hardcoded values)
4. Check-in system (no persistence)
5. Nudge notifications (memory-based triggers)
6. Progress analytics (calculated on mock data)

---

## 🏗️ Firestore Data Architecture

### Collection Structure

```yaml
users/
  {userId}/
    profile: UserProfile document
    goals: UserGoals document
    preferences: UserPreferences document
    
    meals/
      {mealId}/
        base: LoggedMeal document
        micronutrients: MicronutrientData subcollection
        ingredients: Ingredients subcollection
        analysis: AIAnalysisResult document
        
    windows/
      {windowId}/
        config: MealWindow document
        consumed: WindowConsumption document
        
    checkIns/
      morning/
        {date}/: MorningCheckIn document
      postMeal/
        {checkInId}/: PostMealCheckIn document
        
    nudges/
      {nudgeId}/: NudgeRecord document
      
    analytics/
      daily/
        {date}/: DailyAnalytics document
      weekly/
        {weekId}/: WeeklyAnalytics document

# Global Collections
nutritionDatabase/
  foods/
    {foodId}/: FoodItem document with USDA data
  
  barcodes/
    {barcode}/: BarcodeMapping document

systemConfig/
  vertexAI/: API configuration
  features/: Feature flags
  
developerSimulations/
  {simulationId}/
    config: SimulationConfig
    userData: Simulated user data
```

### Document Schemas

#### UserProfile
```typescript
interface UserProfile {
  id: string;
  email: string;
  displayName: string;
  createdAt: Timestamp;
  
  // Schedule
  typicalWakeTime: string; // "07:00"
  typicalSleepTime: string; // "23:00"
  timezone: string;
  
  // Preferences
  preferredMealCount: number; // 3-6
  intermittentFastingProtocol?: 'IF16_8' | 'IF18_6' | 'OMAD';
  
  // Metrics
  height: number; // cm
  weight: number; // kg
  age: number;
  biologicalSex: 'male' | 'female';
  
  // Subscription
  subscriptionStatus: 'free' | 'premium';
  subscriptionExpiry?: Timestamp;
}
```

#### LoggedMeal
```typescript
interface LoggedMeal {
  id: string;
  userId: string;
  name: string;
  timestamp: Timestamp;
  
  // Nutrition
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  
  // Window Assignment
  windowId?: string;
  windowDate: string; // "2025-01-27"
  
  // AI Analysis
  imageUrl?: string; // Cloud Storage URL
  imageDeleteAt?: Timestamp; // 24 hours after creation
  voiceTranscript?: string;
  analysisMethod: 'photo' | 'voice' | 'barcode' | 'manual';
  confidenceScore: number; // 0-1
  
  // Metadata
  createdAt: Timestamp;
  lastModified: Timestamp;
}
```

#### MealWindow
```typescript
interface MealWindow {
  id: string;
  userId: string;
  date: string; // "2025-01-27"
  
  // Timing
  startTime: Timestamp;
  endTime: Timestamp;
  
  // Targets
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
  
  // Purpose & Flexibility
  purpose: WindowPurpose;
  flexibility: 'strict' | 'moderate' | 'flexible';
  
  // Redistribution
  originalCalories: number;
  redistributionReason?: string;
  redistributedAt?: Timestamp;
  
  // Status
  status: 'upcoming' | 'active' | 'completed' | 'missed';
  mealsLogged: string[]; // meal IDs
}
```

---

## 🤖 Vertex AI Integration Architecture

### Setup & Configuration

```swift
// VertexAIService.swift
class VertexAIService {
    private let model: GenerativeModel
    private let visionModel: GenerativeModel
    
    init() {
        // Initialize Vertex AI SDK
        let vertexAI = VertexAI(
            projectId: "phyllo-nutrition",
            location: "us-central1"
        )
        
        // Text + Vision model for meal analysis
        self.model = vertexAI.generativeModel(
            modelName: "gemini-2.5-flash-002",
            generationConfig: GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 2048
            ),
            safetySettings: [
                SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh)
            ]
        )
    }
}
```

### Meal Analysis Pipeline

```swift
// 1. Photo Analysis Request
struct MealAnalysisRequest {
    let image: UIImage
    let voiceTranscript: String?
    let userContext: UserNutritionContext
    let mealWindow: MealWindow
}

// 2. Structured Prompt Template
let analysisPrompt = """
You are an expert nutritionist analyzing a meal photo for precise tracking.

USER CONTEXT:
- Goal: \(userContext.primaryGoal)
- Daily Targets: \(userContext.dailyMacros)
- Current Window: \(mealWindow.purpose) (\(mealWindow.remainingMacros))
- Time of Day: \(mealWindow.timeDescription)

VOICE DESCRIPTION (if provided): \(voiceTranscript ?? "None")

ANALYZE THE MEAL IMAGE AND PROVIDE:

1. MEAL IDENTIFICATION
   - Name: [concise meal name]
   - Confidence: [0-100%]
   - Main Components: [list key ingredients]

2. PORTION ESTIMATION
   - Total Volume: [cups/oz/grams]
   - Serving Size: [standard portions]
   
3. NUTRITION CALCULATION
   - Calories: [number]
   - Protein: [grams]
   - Carbs: [grams]
   - Fat: [grams]
   
4. MICRONUTRIENTS (from USDA database)
   - List top 5 micronutrients with amounts
   
5. CLARIFICATION NEEDS
   - Questions: [array of specific questions if needed]
   - Options: [multiple choice answers for each question]

FORMAT AS JSON:
{
  "mealName": string,
  "confidence": number,
  "ingredients": [{"name": string, "amount": string}],
  "nutrition": {
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "micronutrients": [{"name": string, "amount": number, "unit": string}],
  "clarifications": [{"question": string, "options": [string]}]
}
"""

// 3. Background Processing
func analyzeMeal(_ request: MealAnalysisRequest) async throws -> MealAnalysis {
    // Create multimodal content
    let imageData = request.image.jpegData(compressionQuality: 0.8)!
    let imagePart = ModelContent.Part.data(mimetype: "image/jpeg", imageData)
    
    // Generate with search capability
    let response = try await model.generateContent(
        imagePart,
        analysisPrompt,
        tools: [Tool.googleSearch()] // Enable search for nutrition data
    )
    
    // Parse JSON response
    return try JSONDecoder().decode(MealAnalysis.self, from: response.text.data(using: .utf8)!)
}
```

### Clarification System

```swift
// Adaptive clarification based on confidence
struct ClarificationEngine {
    func processClarifications(_ analysis: MealAnalysis) -> ClarificationFlow? {
        // Only show clarifications if:
        // 1. Confidence < 80%
        // 2. Missing critical nutrition data
        // 3. Ambiguous ingredients
        
        guard analysis.confidence < 0.8 || 
              analysis.clarifications.count > 0 else {
            return nil
        }
        
        return ClarificationFlow(
            questions: analysis.clarifications,
            onComplete: { answers in
                // Re-analyze with additional context
            }
        )
    }
}
```

---

## 🔄 Data Flow Transformations

### 1. Meal Logging Flow (Mock → Production)

#### Current Mock Flow
```swift
MockDataManager.startAnalyzingMeal() 
→ 3 second delay 
→ Generate fake data 
→ Add to memory array
```

#### New Production Flow
```swift
MealCaptureService.captureMeal()
├─ Upload compressed image to Cloud Storage
├─ Create analyzing meal document in Firestore
├─ Start background Vertex AI analysis
├─ Return to user immediately
└─ Update UI with real-time Firestore listeners

VertexAIService.analyzeMeal() // Background
├─ Process image with Gemini 2.5 Flash
├─ Query USDA for micronutrients if needed
├─ Update Firestore with results
├─ Trigger clarification flow if needed
└─ Complete meal logging on success

FirestoreListener.onMealComplete()
├─ Update local UI state
├─ Trigger window redistribution
├─ Schedule post-meal check-in
└─ Show celebration nudge
```

### 2. Window Calculation (Mock → Production)

#### Current Mock Logic
```swift
MealWindow.mockWindows() // Hardcoded patterns
```

#### New Production Logic
```swift
WindowCalculationService {
    func generateDailyWindows(
        profile: UserProfile,
        goals: UserGoals,
        morningCheckIn: MorningCheckIn
    ) -> [MealWindow] {
        
        // Client-side calculations
        let dayStart = morningCheckIn.wakeTime
        let dayEnd = profile.typicalSleepTime - 3.hours
        let eatingWindow = dayEnd - dayStart
        
        // Apply goal-specific patterns
        switch goals.primaryGoal {
        case .weightLoss:
            return generateIntermittentFastingWindows(start: dayStart + 5.hours)
        case .muscleGain:
            return generateHighFrequencyWindows(count: 5-6)
        case .performance:
            return generateCircadianOptimizedWindows()
        }
        
        // Save to Firestore
        windows.forEach { window in
            db.collection("users/\(userId)/windows").document(window.id).setData(window)
        }
    }
}
```

### 3. Nudge System (Mock → Production)

#### Current Mock Triggers
```swift
NudgeManager checks MockDataManager state in memory
```

#### New Production System
```swift
// Cloud Scheduler → Firestore Triggers
CloudScheduler jobs:
├─ Morning check-in reminder (6 AM - 11 AM)
├─ Active window checks (every 15 min)
├─ Post-meal check-ins (30 min after meal)
└─ Missed window alerts (5 min after close)

// Local Push Notifications
PushNotificationService {
    func scheduleWindowNotifications(windows: [MealWindow]) {
        windows.forEach { window in
            // 15 min before window starts
            scheduleNotification(
                id: "\(window.id)-start",
                title: "Meal Window Starting Soon",
                body: "\(window.purpose.displayName) window begins in 15 minutes",
                date: window.startTime - 15.minutes
            )
            
            // Active window reminder
            if window.flexibility != .strict {
                scheduleNotification(
                    id: "\(window.id)-active",
                    title: "Active Meal Window",
                    body: "\(window.timeRemaining) remaining in your \(window.purpose) window",
                    date: window.startTime + 30.minutes
                )
            }
        }
    }
}
```

---

## 🛠️ Developer Dashboard Transformation

### Maintaining Simulation Capabilities

```swift
// DeveloperDashboardService.swift
class DeveloperDashboardService {
    private var simulationMode: Bool = false
    private var simulatedUserId: String?
    
    func enableSimulation(config: SimulationConfig) {
        simulationMode = true
        
        // Create temporary user in Firestore
        simulatedUserId = "dev_sim_\(UUID())"
        
        // Override data sources
        DataSourceProvider.shared.override(
            meals: SimulatedMealService(config),
            windows: SimulatedWindowService(config),
            nudges: SimulatedNudgeService(config)
        )
    }
    
    func simulateScenarios() {
        // Time travel
        TimeProvider.shared.setSimulatedTime(Date())
        
        // Instant meal generation with real Vertex AI
        generateSimulatedMeal(
            name: "Grilled Chicken Salad",
            targetMacros: MacroTargets(p: 35, c: 20, f: 15),
            analyzeWithAI: true
        )
        
        // Edge case testing
        simulateMissedWindows(count: 3)
        simulateLowEnergyPattern()
        simulateGoalAchievement()
    }
}
```

### Developer Dashboard Features
1. **User Simulation** - Create test users with specific goals
2. **Time Control** - Jump to any time/date
3. **Meal Generation** - Create meals with real AI analysis
4. **Window Testing** - Test redistribution edge cases
5. **Nudge Preview** - Trigger any nudge type
6. **Data Reset** - Clear simulation data
7. **Performance Metrics** - API call monitoring

---

## 📋 Implementation Phases

### Phase 1: Meal Photo Capture & Analysis (Week 1-2)
**Goal:** Replace mock meal analysis with real Vertex AI

#### Tasks:
1. **Set up Vertex AI SDK**
   - Configure project credentials
   - Initialize Gemini 2.5 Flash model
   - Implement error handling

2. **Create MealAnalysisService**
   - Image compression pipeline
   - Cloud Storage integration
   - Background analysis flow
   - Structured prompt engineering

3. **Implement Firestore Integration**
   - Create meal documents
   - Real-time listeners
   - Offline queue for resilience

4. **Update UI Components**
   - Replace mock delays with real loading states
   - Add progress indicators
   - Handle analysis errors gracefully

5. **USDA Micronutrient Integration**
   - Set up USDA API access
   - Cache common foods locally
   - Fallback for missing data

**Deliverables:**
- Working photo analysis with real nutrition data
- Firestore persistence of meals
- Background processing with UI updates
- Error handling and retry logic

**Success Metrics:**
- Analysis completion < 10 seconds
- Accuracy > 85% for common foods
- Clarification questions < 2 per meal

---

### Phase 2: Meal Window Scheduling (Week 3-4)
**Goal:** Dynamic window generation with client-side calculations

#### Tasks:
1. **WindowCalculationService**
   - Port mock window logic to production
   - Add exercise schedule integration
   - Implement goal-specific patterns

2. **Firestore Window Management**
   - Daily window generation
   - Real-time status updates
   - Historical window tracking

3. **Window-Meal Assignment**
   - Automatic assignment logic
   - Manual reassignment support
   - Cross-day meal handling

4. **Redistribution System**
   - Real-time macro recalculation
   - Goal-aware constraints
   - User transparency

**Deliverables:**
- Automated daily window generation
- Real-time window status tracking
- Smart meal-to-window assignment
- Dynamic redistribution

---

### Phase 3: Basic Nutrition Tracking (Week 5)
**Goal:** Complete nutrition data persistence and calculations

#### Tasks:
1. **Nutrition Aggregation Service**
   - Daily totals calculation
   - Window-specific summaries
   - Micronutrient tracking

2. **Progress Tracking**
   - Real-time progress updates
   - Historical data queries
   - Trend calculations

3. **Data Visualization Updates**
   - Connect charts to Firestore
   - Implement data caching
   - Optimize query performance

**Deliverables:**
- Real-time nutrition tracking
- Historical data access
- Performance optimizations

---

### Phase 4: Check-In System (Week 6)
**Goal:** Persistent check-in data with pattern analysis

#### Tasks:
1. **Check-In Data Models**
   - Firestore schema implementation
   - Validation rules
   - Privacy considerations

2. **Check-In Flows**
   - Morning check-in persistence
   - Post-meal check-in scheduling
   - Data collection optimization

3. **Pattern Recognition**
   - Sleep-energy correlations
   - Meal timing insights
   - Mood-food relationships

**Deliverables:**
- Persistent check-in system
- Pattern analysis foundation
- User insights generation

---

### Phase 5: Nudge Notifications (Week 7)
**Goal:** Proactive coaching with push notifications

#### Tasks:
1. **Push Notification Setup**
   - iOS permission flow
   - Notification scheduling
   - Deep linking support

2. **Nudge Orchestration**
   - Priority queue implementation
   - Smart timing logic
   - Dismissal tracking

3. **Cloud Scheduler Integration**
   - Scheduled nudge checks
   - Batch notification sending
   - Failure handling

**Deliverables:**
- Working push notifications
- Smart nudge timing
- User preference controls

---

### Phase 6: Onboarding Flow (Week 8)
**Goal:** Seamless new user experience

#### Tasks:
1. **Onboarding Data Collection**
   - Goal selection persistence
   - Profile creation
   - Initial window generation

2. **Personalization Engine**
   - Goal-based calculations
   - Initial recommendations
   - Tutorial progression

3. **First-Run Experience**
   - Guided app tour
   - Sample meal logging
   - Initial nudge education

**Deliverables:**
- Complete onboarding flow
- Personalized initial setup
- New user retention optimization

---

### Phase 7: Progress Analytics (Week 9)
**Goal:** Comprehensive progress tracking

#### Tasks:
1. **Analytics Aggregation**
   - Daily/weekly summaries
   - Goal progress calculation
   - Trend identification

2. **Visualization Updates**
   - Connect Momentum tab to real data
   - Implement caching strategy
   - Add comparison views

3. **Export Functionality**
   - PDF report generation
   - Data export options
   - Sharing capabilities

**Deliverables:**
- Real-time analytics
- Historical comparisons
- Export functionality

---

### Phase 8: User Authentication (Week 10)
**Goal:** Secure user accounts with Firebase Auth

#### Tasks:
1. **Firebase Auth Setup**
   - Email/password authentication
   - Social login (Apple, Google)
   - Password reset flow

2. **User Data Migration**
   - Connect auth to user profiles
   - Security rules implementation
   - Data privacy compliance

3. **Account Management**
   - Profile editing
   - Account deletion
   - Data portability

**Deliverables:**
- Secure authentication
- Account management
- Privacy compliance

---

## 🚀 Migration Strategy

### Hard Cutover Approach

```swift
// AppDelegate.swift
class AppDelegate {
    func application(_ application: UIApplication, didFinishLaunching) {
        if ProcessInfo.processInfo.arguments.contains("--use-mock-data") {
            // Developer mode with mock data
            DataProvider.shared = MockDataProvider()
        } else {
            // Production mode with Firebase
            DataProvider.shared = FirebaseDataProvider()
        }
    }
}

// DataProvider Protocol
protocol DataProvider {
    func getMeals() async throws -> [LoggedMeal]
    func getWindows() async throws -> [MealWindow]
    func saveMeal(_ meal: LoggedMeal) async throws
    // ... other methods
}
```

### Testing Strategy
1. **Unit Tests** - Mock Firestore for fast tests
2. **Integration Tests** - Test emulator for real Firebase
3. **E2E Tests** - Developer dashboard scenarios
4. **Performance Tests** - Ensure <10s meal analysis

---

## 📊 Success Metrics & Monitoring

### Key Performance Indicators
```yaml
Technical Metrics:
  - Meal analysis time: < 10 seconds
  - API error rate: < 1%
  - Offline sync success: > 95%
  - Push delivery rate: > 90%
  
User Experience:
  - Clarification questions: < 2 per meal
  - Daily active usage: > 70%
  - Feature adoption: > 80%
  - Crash-free rate: > 99.5%
  
Cost Optimization:
  - Vertex AI calls: < $0.10 per user/day
  - Storage costs: < $0.05 per user/month
  - Firestore reads: Optimize with caching
```

### Monitoring Setup
```swift
// Analytics Service
AnalyticsService.track("meal_analysis_started", [
    "method": analysisMethod,
    "has_voice": voiceTranscript != nil,
    "window_type": currentWindow?.purpose
])

AnalyticsService.track("meal_analysis_completed", [
    "duration": analysisTime,
    "confidence": confidence,
    "clarifications_needed": clarificationCount,
    "error": error?.localizedDescription
])
```

---

## 🔒 Security & Privacy

### Firestore Security Rules
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
    
    // Developer simulations require special claim
    match /developerSimulations/{document=**} {
      allow read, write: if request.auth.token.developer == true;
    }
  }
}
```

### Data Privacy
1. **Image Handling** - Auto-delete after 24 hours
2. **Health Data** - Encrypted at rest
3. **GDPR Compliance** - Data export/deletion
4. **Analytics** - Anonymized tracking only

---

## 🎯 Next Steps

1. **Immediate Actions:**
   - Set up Firebase project
   - Configure Vertex AI credentials
   - Create base Firestore schema
   - Implement data provider protocol

2. **Week 1 Focus:**
   - Complete Phase 1 setup
   - Test Vertex AI integration
   - Validate USDA API access
   - Build first real meal analysis

3. **Ongoing:**
   - Daily progress reviews
   - Performance monitoring
   - Cost tracking
   - User feedback integration

---

## 📝 Appendix

### A. Technology Stack
- **Frontend:** SwiftUI 6, iOS 17+
- **Backend:** Firebase (Firestore, Auth, Storage)
- **AI:** Vertex AI SDK, Gemini 2.5 Flash
- **Nutrition:** USDA FoodData Central API
- **Analytics:** Firebase Analytics
- **Monitoring:** Firebase Crashlytics
- **Notifications:** iOS Push Notifications

### B. Estimated Costs (per 1000 users/month)
- Vertex AI: ~$100 (10 meals/day/user)
- Firestore: ~$50 (reads/writes)
- Storage: ~$10 (compressed images)
- USDA API: Free tier sufficient
- Total: ~$160/month

### C. Risk Mitigation
- **AI Latency:** Background processing, progress indicators
- **Offline Usage:** Queue system with sync
- **Cost Overruns:** Usage caps, monitoring alerts
- **Data Loss:** Regular backups, transaction logs

---

This plan provides a complete roadmap for transforming Phyllo from a mock-data prototype to a production-ready nutrition intelligence platform. Each phase builds on the previous one, allowing for iterative development and continuous testing through the developer dashboard.