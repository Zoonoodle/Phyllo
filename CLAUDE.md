# Phyllo v1.0 - AI-Powered Nutrition Intelligence Platform

**Project:** Phyllo - Smart Nutrition Coach with Meal Window Management  
**Version:** 1.0 (Current Implementation)  
**Platform:** iOS 17+ (SwiftUI 6)  
**Backend:** Firebase (Auth, Firestore, Functions, Storage, Analytics)  
**AI Engine:** Google Gemini 2.5 Flash  
**MCP Tools:** Serena (Code Analysis) + Context7 (Documentation) + BraveSearch  

---

## 🚀 **Current Implementation Overview**

Phyllo is a nutrition tracking app built around **meal windows** - smart eating periods optimized for your goals. The app uses a timeline-based interface to visualize when you should eat throughout the day, with proactive nudges to keep you on track.

### **Core Features Implemented**

1. **Timeline-Based Schedule View** - Visual meal window management
2. **Comprehensive Check-In System** - Morning and post-meal tracking
3. **Smart Nudge System** - Proactive coaching and reminders
4. **Basic Meal Scanning** - Photo, voice, and barcode modes
5. **Momentum Analytics** - Progress tracking and insights
6. **Developer Dashboard** - Mock data management for testing

---

## 🛠️ **Development Workflow (MUST FOLLOW)**

### **Mandatory Build Testing**
Whenever you add or change ANY code:
1. ALWAYS run `xcodebuild` to ensure the project builds successfully
2. Make sure its iPhone 16 Pro simulator, NOT iPhone 15
3. If `xcodebuild` fails, try `swift build` as a fallback
4. For long builds, save the build output to a log file and read it:
   ```bash
   xcodebuild > build_log.txt 2>&1
   # Then read build_log.txt to check for errors
   ```
5. NEVER commit or finish a task without confirming the build succeeds
6. Fix ALL build errors before marking any task as complete
7. **ALWAYS delete build logs after reading them** - Clean up build_log.txt and any other temporary build files immediately after fixing errors or confirming build success

### **Simplified Git Workflow**

#### **Commit-Only Strategy**
Since you're working solo and reviewing all changes, we use a simplified workflow:
- Work directly on main branch
- Claude Code ALWAYS commits after completing any feature/fix
- Clear, descriptive commit messages
- No branches, no PRs, no issues

#### **Commit Message Format**
```
feat: Add new feature
fix: Fix bug  
refactor: Restructure code
docs: Update documentation
style: Format code
test: Add tests
chore: Update dependencies
```

#### **Claude Code Auto-Commit Rules**

1. **After Every Feature/Fix:**
   - Run xcodebuild to ensure it builds
   - Commit ALL changes with descriptive message
   - Push to GitHub automatically

2. **Commit Examples:**
   ```bash
   git commit -m "feat: add morning check-in nudge"
   git commit -m "fix: correct meal window timing calculation"
   git commit -m "refactor: simplify timeline view structure"
   ```

---

## 🏗️ **Current Architecture**

### **Navigation Structure (3 Tabs)**

#### **1. Schedule Tab (Focus)**
- **Timeline View**: Hour-by-hour view from 7 AM to 10 PM
- **Meal Windows**: Visual blocks showing eating periods
- **Current Time Marker**: Real-time position indicator
- **Meal Logging**: Shows meals within their assigned windows
- **Window Details**: Tap to expand and see window-specific nutrition targets

#### **2. Momentum Tab**
- **4-Card Grid Layout**:
  - PhylloScore (overall nutrition score)
  - Social Leaderboard
  - Metrics & Goal Progress
  - Weekly Momentum Trends
- **Detailed Views**: Each card expands to full analytics

#### **3. Scan Tab**
- **Camera Preview**: Full-screen capture interface
- **Mode Selector**: Photo, Voice, or Barcode scanning
- **Quick Actions**: Recent meals and favorites
- **Multi-Step Flow**:
  1. Capture photo
  2. Optional voice description
  3. AI analysis with loading state
  4. Clarification questions (if needed)
  5. Final meal details

---

## 📱 **Key Components**

### **Meal Windows System**

```swift
struct MealWindow {
    // Time-based eating periods with purpose
    let startTime: Date
    let endTime: Date
    let purpose: WindowPurpose // pre-workout, post-workout, sustained energy, etc.
    let targetCalories: Int
    let targetMacros: MacroTargets
    let flexibility: WindowFlexibility // strict, moderate, flexible
}
```

**Window Generation Logic**:
- Adapts to user goals (weight loss = 16:8 fasting)
- Circadian optimization (last meal 3 hours before sleep)
- Workout-aware scheduling
- Dynamic redistribution when windows are missed

### **Check-In System**

**Morning Check-In**:
- Wake time capture
- Sleep quality (1-5 scale with emojis)
- Daily focus selection (work, fitness, family, etc.)
- Triggers meal window generation

**Post-Meal Check-Ins**:
- Energy levels (5 levels with colors)
- Fullness scale (visual indicators)
- Mood/focus tracking
- Appears 30 minutes after meal logging

### **Nudge System**

```swift
enum NudgeType {
    case morningCheckIn           // Prompts morning routine
    case activeWindowReminder     // "15 minutes left in lunch window"
    case missedWindow            // "You missed your snack window"
    case mealCelebration         // Positive reinforcement
    case firstTimeTutorial       // Onboarding guidance
}
```

**Nudge Behavior**:
- Priority-based queuing
- Smart timing (no nudges during sleep hours)
- Dismissible with memory
- Context-aware messaging

### **Mock Data System**

Developer dashboard allows:
- Time simulation (jump to any time of day)
- Instant meal generation
- Goal switching
- Window redistribution testing
- Check-in completion

---

## 🎨 **Design System**

### **Color Palette**
- **Background**: Pure black (#000000) for OLED
- **Elevated**: white.opacity(0.03) for cards
- **Text Hierarchy**: 
  - Primary: white
  - Secondary: white.opacity(0.7)
  - Tertiary: white.opacity(0.5)
- **Accent**: Bright green (used sparingly <10%)
- **Semantic Colors**:
  - Energy windows: Teal
  - Focus windows: Purple
  - Recovery windows: Blue
  - Workout windows: Orange

### **Typography**
- Headers: SF Pro Display
- Body: SF Pro Text
- Monospace: SF Mono (for time labels)
- Dynamic Type supported

### **Components**
- **PhylloCard**: Rounded corners (20px), subtle blur
- **CustomTabBar**: Floating design with haptic feedback
- **TimelineHourRow**: Dynamic height based on content
- **NudgeContainer**: Spring animations, backdrop blur

---

## 🔍 **Data Models**

### **Core Models**

1. **UserGoals**: Primary/secondary goals, activity level, fasting protocols
2. **MealWindow**: Time periods with nutrition targets and purposes
3. **LoggedMeal**: Simple meal with macros and timestamp
4. **CheckInData**: Morning and post-meal check-ins
5. **MicronutrientData**: 18 tracked micronutrients with RDA values

### **Computed Properties**
- Window status (active/upcoming/past)
- Time remaining in active windows
- Meal-to-window assignments
- Daily progress calculations

---

## 🚀 **Features Not Yet Implemented**

### **From Original Plan**
- Advanced onboarding flow
- Voice-first interactions
- Wearable integrations
- Restaurant menu scanning
- Recipe generation
- Social groups and challenges
- Premium/Teams tiers
- Grocery list automation
- Offline mode
- Siri Shortcuts

### **Planned Enhancements**
- Real Firebase integration
- Push notifications
- Apple Health sync
- Barcode database
- Food photo library
- Weekly reports
- Export functionality

---

## 📊 **Current Metrics & Status**

### **Implementation Status**
- ✅ Core navigation and UI
- ✅ Timeline-based meal windows
- ✅ Basic meal logging flow
- ✅ Nudge system
- ✅ Check-in system
- ✅ Mock data for testing
- ⏳ Firebase backend
- ⏳ Real AI integration
- ⏳ Social features
- ⏳ Advanced analytics

### **Known Issues**
- Mock data only (no persistence)
- Simulated AI responses
- Limited micronutrient data
- No real photo analysis
- Basic goal calculations

---

## 🛠️ **Development Priorities**

### **Immediate Next Steps**
1. Firebase authentication setup
2. Real Gemini API integration
3. Persist user data to Firestore
4. Implement actual photo analysis
5. Add push notifications

### **Phase 2 Features**
1. Apple Health integration
2. Barcode scanning with database
3. Social leaderboards with real users
4. Weekly progress reports
5. Food favorites and quick-add

### **Phase 3 Polish**
1. Onboarding flow
2. Premium features
3. Apple Watch app
4. Widget support
5. Shortcuts integration

---

## 💡 **Technical Decisions**

### **Why Timeline View**
- Visual representation of time-based eating
- Natural mental model for meal planning
- Easy to see conflicts and gaps
- Familiar pattern from calendar apps

### **Why Nudges**
- Proactive vs reactive coaching
- Non-intrusive reminders
- Contextual guidance
- Positive reinforcement

### **Why Mock Data Manager**
- Rapid prototyping
- Consistent testing scenarios
- Time simulation capabilities
- Easy demo creation

---

## 📝 **Claude Code Usage Guidelines**

### **Key Commands**

```bash
# Build and test
xcodebuild -scheme Phyllo -sdk iphonesimulator
xcodebuild test -scheme Phyllo -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Git (handled automatically by Claude Code)
git add -A && git commit -m "type: message" && git push

# Project navigation
open Phyllo.xcodeproj
```

### **Common Tasks**

**Add a new nudge type:**
1. Update `NudgeType` enum in NudgeManager
2. Create nudge view component
3. Add trigger logic
4. Test with time simulation

**Modify meal windows:**
1. Update `MealWindow` model if needed
2. Adjust `WindowRedistributionManager`
3. Test with developer dashboard
4. Verify timeline display

**Add new check-in:**
1. Update `CheckInData` models
2. Create UI in appropriate view
3. Add to `CheckInManager`
4. Test flow end-to-end

---

## 🎯 **Definition of Done**

A feature is complete when:
1. ✅ Code builds without warnings
2. ✅ UI matches design system
3. ✅ Animations are smooth (60fps)
4. ✅ Error states handled
5. ✅ Works with mock data
6. ✅ Committed with descriptive message

---

## 🚀 **The Current Phyllo Experience**

Users open Phyllo to see their personalized eating schedule for the day. Smart meal windows guide when to eat for optimal energy and goal achievement. The timeline view makes it easy to plan meals and stay on track. Gentle nudges provide coaching at the right moments. Progress tracking in Momentum tab keeps users motivated.

**From timeline to transformation - Phyllo makes nutrition timing intelligent.** 🌱

---

## 📋 **Quick Reference**

### **File Structure**
```
Phyllo/
├── Views/
│   ├── Focus/          # Timeline and window management
│   ├── Momentum/       # Analytics and progress
│   ├── Scan/          # Meal capture flow
│   ├── Nudges/        # Coaching system
│   └── CheckIn/       # User check-ins
├── Models/            # Data structures
├── Services/          # Business logic
└── Developer/         # Testing tools
```

### **Key Singletons**
- `MockDataManager.shared` - Test data management
- `TimeProvider.shared` - Time simulation
- `NudgeManager.shared` - Nudge orchestration
- `CheckInManager.shared` - Check-in tracking

### **Testing Shortcuts**
- Gear icon → Developer Dashboard
- Time simulation for any scenario
- Add meals instantly
- Complete check-ins with one tap
- Reset all data quickly

---

*This document reflects the current implementation as of January 2025. Features described in "not yet implemented" are planned but not built.*