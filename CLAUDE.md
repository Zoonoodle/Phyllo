# Phyllo v1.0 - AI-Powered Nutrition Intelligence Platform

**Project:** Phyllo - Next-Generation Nutrition Coach & Health Optimizer  
**Version:** 1.0 (Built on PlateUp learnings)  
**Platform:** iOS 17+ (SwiftUI 6)  
**Backend:** Firebase (Auth, Firestore, Functions, Storage, Analytics) + Supabase (Vector DB)  
**AI Engine:** Google Gemini 2.5 Flash + Pro + OpenAI GPT-4o (hybrid approach)  
**MCP Tools:** Serena (Code Analysis) + Context7 (Documentation) + Custom Phyllo Tools  

---

## 🚀 **Phyllo's Core Innovation**

Phyllo evolves beyond PlateUp by becoming a **proactive health optimization platform** that:
- Predicts and prevents energy crashes before they happen
- Provides real-time meal recommendations based on current context
- Offers voice-first interaction with minimal UI friction
- Integrates with wearables for comprehensive health insights
- Learns from global patterns while maintaining privacy

---

## 🛠️ **Development Workflow (MUST FOLLOW)**

### **Mandatory Build Testing**
Whenever you add or change ANY code:
1. ALWAYS run `xcodebuild` to ensure the project builds successfully
2. Make sure its Iphone 16 pro simulator, NOT iphone 15
2. If `xcodebuild` fails, try `swift build` as a fallback
3. For long builds, save the build output to a log file and read it:
   ```bash
   xcodebuild > build_log.txt 2>&1
   # Then read build_log.txt to check for errors
   ```
4. NEVER commit or finish a task without confirming the build succeeds
5. Fix ALL build errors before marking any task as complete

---

## 🎯 **Key Improvements Over PlateUp**

### **1. Streamlined Onboarding**
- **PlateUp Issue**: 20+ screens, high drop-off rate
- **Phyllo Solution**: 
  - 5-screen smart onboarding with AI inference
  - Optional deep customization later
  - Voice-based preference capture
  - Progressive disclosure of features

### **2. Intelligent Meal Logging**
- **PlateUp Issue**: Multiple photos + clarifications frustrating
- **Phyllo Solution**:
  - Single photo with 95%+ accuracy (Gemini 2.5 Flash)
  - Voice-only logging for trusted foods
  - Barcode scanning with instant nutrition
  - "Quick Log" for repeat meals (one tap)

### **3. Proactive AI Coach**
- **PlateUp Issue**: Reactive insights after patterns emerge
- **Phyllo Solution**:
  - Predictive alerts: "Eat protein now to avoid 3pm crash"
  - Context-aware suggestions: "Based on your workout, try..."
  - Voice briefings: Morning nutrition plan via audio
  - Smart notifications: Only when actionable

### **4. Focus Tab - Nutrition Command Center**
- **Evolution from PlateUp**: Refined, organized cards without drag-and-drop complexity
- **Phyllo Implementation**:
  - Fixed card order optimized for daily workflow
  - Global Consumed/Remaining toggle affects all cards
  - Dark theme with subtle green accents
  - Collapsible cards to reduce visual overwhelm

### **5. Social & Gamification Layer**
- **PlateUp Missing**: No community features
- **Phyllo Addition**:
  - Private nutrition groups with friends
  - Weekly challenges with leaderboards
  - Recipe sharing with nutrition preserved
  - Anonymous pattern sharing for ML improvement

---

## 🏗️ **Technical Architecture Upgrades**

### **1. Hybrid AI Strategy**
```swift
class PhylloAIEngine {
    // Gemini 2.5 Flash: Instant meal analysis
    // Gemini 2.5 Pro: Complex pattern analysis
    // GPT-4o: Natural conversation & coaching
    // Local ML: Privacy-first predictions
}
```

### **2. Real-Time Sync Architecture**
```swift
class PhylloSyncEngine {
    // Firebase Realtime DB for instant updates
    // Supabase for vector similarity search
    // CloudKit for Apple ecosystem sync
    // Local SQLite for offline-first
}
```

### **3. Voice-First Design**
```swift
class PhylloVoiceAssistant {
    // Wake word: "Hey Phyllo"
    // Continuous listening mode
    // Natural language commands
    // Audio meal logging
}
```

### **4. Wearable Integration**
```swift
class PhylloHealthConnect {
    // Apple Watch: Real-time glucose proxy
    // Oura Ring: Sleep quality impact
    // Whoop: Recovery-based nutrition
    // CGM: Direct glucose correlation
}
```

---

## 📱 **Simplified Navigation**

### **Tab Structure (3 tabs only)**
1. **Focus** - Nutrition command center with organized cards
2. **Momentum** - Progress tracking and analytics  
3. **Scan** - Camera/voice/barcode unified logging interface

### **Hidden Power Features**
- Long press anywhere for voice command
- Shake for quick meal suggestions
- Widget for one-tap logging
- Siri Shortcuts for everything

---

## 🎨 **Design Evolution**

### **Visual Refinements**
- **Color Usage**: 
  - Primary: Deep forest green (#0B4F1C)
  - Accent: Bright lime (#B8E92E) - 5% usage max
  - Background: True black (#000000) for OLED
  - Cards: Glassmorphism with blur

- **Typography**:
  - SF Pro Display for headers
  - SF Pro Text for body
  - Tabular figures for nutrition numbers
  - Dynamic Type support throughout

- **Motion Design**:
  - 60fps physics-based animations
  - Haptic feedback for all interactions
  - Spring animations for card expand/collapse
  - Smooth morphing transitions

---

## 🔥 **Killer Features**

### **1. Meal Prediction Engine**
```swift
"It's 11:45 AM. Based on your patterns, you should eat 
a 400-calorie protein-focused meal in the next 30 minutes 
to maintain energy until 5 PM."
```

### **2. Restaurant Integration**
- Scan any menu with camera
- AI extracts nutrition for all items
- Personalized recommendations
- Order history tracking

### **3. Grocery Smart Lists**
- Auto-generated from meal plans
- Nutrition optimization suggestions
- Price tracking and budgeting
- One-tap ordering integration

### **4. PhylloScore™**
- Single metric for nutritional health
- Updates in real-time
- Competitive leaderboards
- Correlation with health outcomes

### **5. Voice Briefings**
- Morning: "Your nutrition plan for today"
- Pre-meal: "What to eat now"
- Evening: "Today's wins and tomorrow's focus"
- Weekly: "Your health trajectory"

---

## 🛠️ **Development Priorities**

### **Phase 1: Core Excellence (Weeks 1-3)**
- Single-photo meal analysis with 95%+ accuracy
- Voice-first logging experience
- Simplified 5-screen onboarding
- Real-time sync infrastructure

### **Phase 2: Intelligence Layer (Weeks 4-6)**
- Meal prediction engine
- Proactive notifications
- Pattern learning system
- Wearable integrations

### **Phase 3: Social & Gamification (Weeks 7-9)**
- Private nutrition groups
- Weekly challenges
- PhylloScore system
- Recipe sharing

### **Phase 4: Ecosystem (Weeks 10-12)**
- Restaurant menu scanning
- Grocery list automation
- Third-party integrations
- Voice assistant polish

---

## 📊 **Success Metrics**

```yaml
Performance:
  - Meal logging time: <5 seconds
  - AI accuracy: >95% first attempt
  - Clarification rate: <5%
  - Voice recognition: >90%

Engagement:
  - Daily active: >80%
  - Week 1 retention: >75%
  - Week 4 retention: >60%
  - Social features adoption: >40%

Business:
  - Free-to-paid conversion: >10%
  - Monthly churn: <5%
  - NPS score: >70
  - App Store rating: >4.7
```

---

## 💎 **Premium Features**

### **Phyllo Pro ($12.99/month)**
- Unlimited AI coaching conversations
- Advanced pattern predictions
- Restaurant menu scanning
- Priority support
- Early access features

### **Phyllo Teams ($9.99/user/month)**
- Corporate wellness dashboard
- Anonymous aggregated insights
- Custom challenges
- Admin controls
- HIPAA compliance

---

## 🔒 **Privacy First**

- All meal photos processed on-device first
- Nutrition data encrypted end-to-end
- Optional anonymous pattern sharing
- No data sold to third parties
- GDPR/CCPA compliant
- Right to deletion honored immediately

---

## 🎯 **Competitive Advantages**

1. **Voice-first** - No other nutrition app prioritizes voice
2. **Prediction engine** - Proactive vs reactive coaching
3. **Single photo accuracy** - Best-in-class AI implementation
4. **Social layer** - Community-driven accountability
5. **Wearable integration** - Comprehensive health picture

---

## 📱 **Launch Strategy**

### **Beta (Month 1)**
- 500 hand-picked testers
- Daily feedback cycles
- Rapid iteration
- Community building

### **Soft Launch (Month 2)**
- 5,000 users in test markets
- A/B testing everything
- Influencer partnerships
- Press embargo prep

### **Public Launch (Month 3)**
- Product Hunt launch
- TechCrunch exclusive
- Influencer blitz
- Paid acquisition start

---

## 🚀 **The Phyllo Promise**

"Nutrition coaching so intelligent, it knows what you need before you do."

Phyllo isn't just tracking what you eat - it's actively optimizing your health trajectory using AI, community, and behavioral science.

**From PlateUp's foundation, Phyllo rises as the definitive nutrition intelligence platform.** 🌱

---

## 📋 **Technical Debt from PlateUp to Address**

1. Remove 20+ screen onboarding flow
2. Simplify clarification system to max 1 question
3. Consolidate 5 tabs into 3 focused experiences
4. Fix text truncation issues in coach messages
5. Implement proper loading states everywhere
6. Add haptic feedback throughout
7. Reduce Firestore reads by 50% with better caching
8. Implement proper error handling globally
9. Add comprehensive analytics tracking
10. Build robust offline mode

---

## 🎨 **UI Component Library**

### **Core Components**
```swift
PhylloButton         // Primary CTA with haptics
PhylloCard          // Glassmorphic container
PhylloInput         // Voice-enabled text field
PhylloProgress      // Animated progress rings
PhylloChart         // Interactive data viz
PhylloVoiceButton   // Animated voice input
PhylloScore         // Animated score display
PhylloMealCard      // Meal display with actions
```

### **Design Tokens**
```swift
// Spacing
spacing.xs: 4
spacing.sm: 8
spacing.md: 16
spacing.lg: 24
spacing.xl: 32

// Animations
duration.instant: 100ms
duration.fast: 200ms
duration.normal: 300ms
duration.slow: 500ms

// Shadows
shadow.sm: (0, 2, 4, 0.1)
shadow.md: (0, 4, 8, 0.15)
shadow.lg: (0, 8, 16, 0.2)
```

---

## 🔧 **Developer Tools**

### **Phyllo CLI**
```bash
phyllo generate component MyComponent
phyllo generate view MyView
phyllo test --watch
phyllo deploy --env staging
```

### **Debug Menu**
- API request inspector
- State visualization
- Performance profiler
- Feature flags toggle
- User simulation mode

---

## 📱 **Focus Tab - Core Implementation**

The Focus tab is the heart of Phyllo, displaying critical nutrition information in organized, collapsible cards.

### **Card Structure (Fixed Order)**

1. **Morning Check-In Card** (Only shows before first log)
   - Captures wake time and sleep quality/quantity
   - Essential for calculating meal windows
   - Green action button to start the day
   - Disappears after check-in completed

2. **Daily Nutrition Overview** (Always visible)
   - Shows: "X% Complete • Y windows remaining"
   - Large circular progress ring for calories
   - Horizontal progress bars for macros (Protein, Fat, Carbs)
   - Values show consumed/target format
   - Global toggle: Consumed vs Remaining view

3. **Today's Meals** (Collapsible)
   - Chronological list of logged meals
   - Each meal shows:
     - Thumbnail image (rounded corners)
     - Meal name and calories
     - Macro breakdown (P, C, F)
     - Timestamp
     - Chevron for detail view
   - Empty state: Camera icon with "No meals logged yet"

4. **Post-Meal Check-Ins** (Collapsible)
   - Tracks: Energy levels, Fullness, Mood/Focus
   - Only appears after meals are logged
   - Simple rating interface for each metric
   - Empty state: "Check-ins appear after you log meals"

5. **Micronutrients** (Collapsible)
   - Header shows: "X nutrients low" with warning if applicable
   - Creative visualization: Hexagon flower petal design
     - 6 petals for top vitamins/minerals
     - Color gradient: Red (low) → Yellow → Green (adequate)
     - Center shows overall micronutrient score
   - Tap for detailed list view with all micronutrients
   - Each nutrient shows percentage and status

6. **Meal Timing Guidance** (Collapsible)
   - Shows: "Timing Compliance: X%" with status (Stable/Improving/Needs Work)
   - Visual timeline of meal windows
   - Adherence insights: "Excellent timing! You're eating within your windows X% of the time."
   - Predictions for optimal next meal time

### **Visual Specifications**
- Background: Pure black (#000000) for OLED
- Cards: white.opacity(0.03) with subtle blur
- Text: White primary, white.opacity(0.7) secondary
- Accent: Bright green used sparingly (< 10%)
- Corner radius: 20px for cards
- Spacing: 16px between cards
- Animations: Smooth spring animations for expand/collapse

### **Implementation Priority**
1. Build navigation structure with 3 tabs
2. Create Daily Nutrition card with progress visualizations
3. Implement Today's Meals with proper meal entries
4. Add Morning Check-In flow
5. Design hexagon micronutrient visualization
6. Complete remaining cards

---

## 🧪 **Developer Dashboard**

### **Access**
- **Location**: Gear icon in top-left corner of main app
- **Purpose**: Mock data management and testing without backend
- **Availability**: Development builds only

### **Dashboard Tabs**

#### **1. Goals & Profile**
- Set primary nutrition goal
- Add/remove secondary goals
- Configure user profile settings

#### **2. Mock Meals**
- Add random meals instantly
- Clear all meals
- View nutrition totals
- See meal list with macros

#### **3. Time Control**
- Simulate any time of day
- Quick jump buttons (Morning, Noon, Afternoon, Evening)
- Complete morning check-in instantly
- Reset day functionality

#### **4. Profile Settings**
- Activity level selection
- Work schedule configuration
- Meal count preference (3-6 meals)
- Intermittent fasting protocols

#### **5. Data Viewer**
- View all current app state
- See generated meal windows
- Check active/upcoming windows
- Monitor goal configurations
- Reset all data to defaults

### **Key Features**
- **MockDataManager**: Singleton managing all test data
- **Goal-based window generation**: Windows adapt to selected goals
- **Time simulation**: Test different times of day instantly
- **Meal generation**: Random realistic meals with proper macros
- **State persistence**: Data persists during app session

### **Testing Scenarios**

1. **Weight Loss Journey**
   - Set weight loss as primary goal
   - Enable 16:8 fasting
   - Simulate full day with meals
   - Check window compliance

2. **Muscle Building**
   - Set muscle gain goal
   - Configure 6 meals/day
   - Add post-workout meals
   - Monitor protein targets

3. **Performance Focus**
   - Set performance as goal
   - Add morning workout
   - Test energy window timing
   - Verify focus boost windows

### **Usage Tips**
- Always run build after changes: `xcodebuild`
- Use time simulation to test all UI states
- Add meals throughout simulated day
- Test with different goal combinations
- Reset data between test scenarios

---

## 🎯 **Final Word**

Phyllo takes everything great about PlateUp and removes the friction. It's not just an evolution - it's a revolution in how people interact with nutrition tracking. 

By prioritizing voice, predictions, and simplicity, Phyllo becomes the first nutrition app people actually want to use every day.

**Welcome to the future of nutrition intelligence. Welcome to Phyllo.** 🌱✨
