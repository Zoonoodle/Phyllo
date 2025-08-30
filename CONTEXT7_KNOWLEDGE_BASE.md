# NutriSync Context7 Knowledge Base
## Complete Technical Reference for AI-Powered Nutrition Coaching

---

## 1. SWIFTUI 2025 & iOS 18 FEATURES

### Core Updates
- **@Observable macro**: Enhanced state management with automatic tracking
- **@Entry macro**: Simplified environment values
- **Spring animations**: Now default, with customizable bounce (-1.0 to 1.0)
- **MeshGradient**: 2D gradient effects
- **Tab improvements**: Floating tab bar with sidebar transitions
- **Grid views**: Adaptive, responsive layouts
- **Performance**: Enhanced rendering engine with hardware acceleration

### Animation System
```swift
// Default spring
withAnimation { /* auto spring */ }

// Custom spring
.animation(.spring(duration: 0.6, bounce: 0.3))

// Interpolating spring (preserves velocity)
.animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 10))

// New effects
.symbolEffect(.wiggle)
.symbolEffect(.breathe)
```

### SwiftUI + UIKit Interop
```swift
// Use SwiftUI animations in UIKit
UIView.animate(using: .spring(duration: 0.5, bounce: 0.3)) {
    view.frame = newFrame
}

// Zoom transitions
.fullScreenCover(isPresented: $show) {
    DetailView().zoomTransition(from: sourceView)
}
```

---

## 2. FIREBASE AI LOGIC (VERTEX AI) 2025

### Model Setup
```swift
import FirebaseVertexAI

let vertexAI = VertexAI.vertexAI()

// Gemini Flash (fast, cheap)
let flash = vertexAI.generativeModel(
    model: "gemini-2.0-flash",
    generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2000,
        responseMimeType: "application/json"
    ),
    systemInstruction: "Concise nutrition analysis"
)

// Gemini Pro (complex reasoning)
let pro = vertexAI.generativeModel(
    model: "gemini-2.0-pro",
    generationConfig: GenerationConfig(maxOutputTokens: 1500)
)
```

### Cost Optimization
- **Flash**: $0.075/1M input, $0.30/1M output tokens
- **Pro**: $0.50/1M input, $1.50/1M output tokens
- **Target**: < $0.03 per operation
- **Image compression**: Max 500KB JPEG at 0.7 quality

### Security
```swift
// App Check integration
AppCheck.setAppCheckProviderFactory(factory)
let token = try await AppCheck.appCheck().token()

// Firestore rules
match /users/{userId}/ai_requests/{id} {
    allow read, write: if request.auth.uid == userId;
}
```

### Best Practices
1. Start with Gemini Developer API (free tier)
2. Use structured JSON output with schemas
3. Implement retry logic with exponential backoff
4. Cache responses aggressively
5. Use Remote Config for prompt management
6. Batch similar requests
7. Monitor costs via Firebase Console

---

## 3. MEAL TIMING & CIRCADIAN OPTIMIZATION

### Time-Restricted Eating (TRE) Protocols

#### Weight Loss
- **Window**: 8 hours (16:8)
- **Timing**: 10 AM - 6 PM
- **Distribution**: 40% breakfast, 35% lunch, 25% dinner
- **Key**: Higher protein in first meal

#### Muscle Building
- **Window**: 10-12 hours
- **Timing**: 8 AM - 8 PM
- **Frequency**: 4-5 meals
- **Key**: Protein every 3-4 hours

#### Performance
- **Window**: Activity-centered
- **Pre-workout**: 2-3 hours before
- **Post-workout**: Within 30-60 minutes
- **Key**: Carbs timed around training

#### Sleep Optimization
- **Window**: Early TRE (7 AM - 3 PM ideal)
- **Last meal**: 3+ hours before sleep
- **Key**: Avoid late carbohydrates

### Metabolic Windows

```swift
enum WindowPurpose {
    case preWorkout      // 50% carbs, 30% protein
    case postWorkout     // 40% protein, 40% carbs
    case sustainedEnergy // 33% each macro
    case metabolicBoost  // 40% protein, 25% carbs
    case recovery        // 45% protein, 35% fat
}
```

### Hormonal Timing
- **Morning peaks**: Insulin, cortisol, ghrelin, adiponectin
- **Evening peaks**: Melatonin, growth hormone, leptin, FGF-21

### Molecular Mechanisms
- **Fed state**: Insulin → pAKT → mTOR → anabolism
- **Fasted state**: AMPK → mTOR inhibition → autophagy

### Research Findings
- **Weight loss**: 3% average without calorie restriction
- **Insulin sensitivity**: Improved 15-30%
- **Blood pressure**: Reduced 5-10 mmHg systolic
- **Adherence**: ~80% in studies
- **Benefits**: Independent of calorie restriction

---

## 4. IMPLEMENTATION ALGORITHMS

### Window Generation
```swift
func generateWindows(
    user: UserProfile,
    goal: HealthGoal,
    schedule: DailySchedule
) -> [MealWindow] {
    
    let duration = switch goal {
        case .loseWeight: 8
        case .buildMuscle: 10
        case .performance: 12
        case .betterSleep: 8
    }
    
    let startTime = calculateOptimalStart(
        chronotype: user.chronotype,
        wakeTime: schedule.wakeTime,
        goal: goal
    )
    
    return distributeWindows(
        start: startTime,
        duration: duration,
        workouts: schedule.workouts,
        meals: goal == .buildMuscle ? 5 : 3
    )
}
```

### Circadian Alignment Score
```swift
func circadianScore(meal: Date, wake: Date, sleep: Date) -> Double {
    let afterWake = meal.hours(from: wake)
    let beforeSleep = sleep.hours(from: meal)
    
    var score = 1.0
    if afterWake < 1 { score *= 0.7 }      // Too early
    if afterWake > 12 { score *= 0.8 }     // Too late
    if beforeSleep < 3 { score *= 0.6 }    // Disrupts sleep
    
    return score
}
```

### AI Meal Analysis
```swift
func analyzeMeal(_ image: UIImage) async throws -> MealData {
    let compressed = image.jpegData(compressionQuality: 0.7)!
    
    let prompt = """
    Analyze meal. Return JSON:
    {"items": [{"name": "", "calories": 0, "protein": 0, "carbs": 0, "fat": 0}],
     "confidence": 0.0-1.0,
     "clarifications": ["max 2"]}
    """
    
    let response = try await flashModel.generateContent(prompt, compressed)
    return JSONDecoder().decode(MealData.self, from: response.data)
}
```

---

## 5. ARCHITECTURE PATTERNS

### MVVM with @Observable
```swift
@Observable
class FocusViewModel {
    var currentWindow: MealWindow?
    var todaysMeals: [LoggedMeal] = []
    var windowProgress: Double = 0.0
    
    func loadTodaysData() async {
        // Firebase integration
    }
}
```

### Protocol-Oriented Services
```swift
protocol DataProviderProtocol {
    func fetchWindows(for date: Date) async throws -> [MealWindow]
    func logMeal(_ meal: LoggedMeal) async throws
}

class FirebaseDataProvider: DataProviderProtocol { }
class MockDataProvider: DataProviderProtocol { }
```

### Dependency Injection
```swift
@main
struct NutriSyncApp: App {
    let dataProvider = FirebaseDataProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataProvider)
        }
    }
}
```

---

## 6. UI/UX GUIDELINES

### Color System
```swift
extension Color {
    static let phylloBackground = Color(hex: "0a0a0a")
    static let phylloCard = Color.white.opacity(0.03)
    static let phylloAccent = Color(hex: "10b981") // Use 10-20%
    static let phylloText = Color.white
    static let phylloTextSecondary = Color.white.opacity(0.7)
}
```

### Design Standards
- **Corner radius**: 16pt
- **Padding**: 16pt
- **Spacing**: 12pt
- **Animation**: Spring(response: 0.4, damping: 0.8)

### Three-Tab Navigation
1. **Focus**: Current window, real-time progress
2. **Momentum**: Analytics, patterns, insights
3. **Scan**: Camera/voice meal input

---

## 7. PERFORMANCE OPTIMIZATION

### Build Strategy
```bash
# Test individual files (fast)
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 File.swift

# Type check if needed
xcrun swift-frontend -typecheck File.swift
```

### Memory Management
- Compress images before upload
- Release after analysis
- Cache aggressively with expiry
- Lazy load heavy views

### Cost Controls
- Rate limit: 100 meal scans/day
- Max 10 window generations/day
- Image size: < 500KB
- Token limits: 2000 (Flash), 1500 (Pro)

---

## 8. TESTING CHECKLIST

### Edge Cases
- [ ] Midnight meal logging
- [ ] Timezone changes
- [ ] Network failures during upload
- [ ] Missed meal redistribution
- [ ] Empty states
- [ ] Background refresh
- [ ] Push notification delivery

### Performance Targets
- App launch: < 2 seconds
- Meal analysis: < 10 seconds
- Window generation: < 5 seconds
- Crash rate: < 0.1%

---

## 9. SECURITY & PRIVACY

### Data Protection
- Minimal PII storage
- Auto-delete photos after 24h
- Firebase encryption
- Anonymous start option

### API Security
```swift
// Use Remote Config for keys
RemoteConfig.remoteConfig()
    .configValue(forKey: "gemini_api_key")
    .stringValue
```

---

## 10. QUICK REFERENCE

### Daily Development Workflow
```bash
git pull
# Make changes
swiftc -parse [edited files]  # MANDATORY
git add -A && git commit -m "feat: X" && git push
```

### Common Patterns
```swift
// Window generation
let windows = WindowGenerator.generate(for: user, on: date)

// Meal analysis
let analysis = try await MealAnalyzer.analyze(image)

// Circadian scoring
let score = CircadianOptimizer.score(mealTime, wakeTime, sleepTime)

// Progress tracking
let progress = WindowTracker.calculateProgress(window, meals)
```

### Firebase Structure
```
users/{userId}/
  ├── profile/          // UserProfile
  ├── goals/           // UserGoals
  ├── meals/{id}/      // LoggedMeal
  ├── windows/{date}/  // MealWindow[]
  └── checkIns/{date}/ // CheckInData
```

---

## Context7 Integration Notes

This knowledge base is designed to be stored in Context7 MCP for:
- Quick reference during development
- Consistent implementation patterns
- Cost-aware AI integration
- Evidence-based nutrition protocols
- Performance-optimized SwiftUI patterns

Last Updated: 2025-08-30
Version: 1.0.0