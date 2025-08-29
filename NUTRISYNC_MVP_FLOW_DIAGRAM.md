# NutriSync MVP App Flow Diagram 🚀

## Overview
This document presents a comprehensive Miro-style flow diagram of the NutriSync MVP, showing all user journeys, technical architecture, and data flows.

```
┌─────────────────────────────────────────────────────────────────┐
│                    🎯 NUTRISYNC MVP FLOW                        │
│                 "From Timeline to Transformation"                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ App Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              APP STRUCTURE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                 │
│  │   Frontend  │     │   Backend   │     │     AI      │                 │
│  │  (SwiftUI)  │ ←→  │  (Firebase) │ ←→  │  (Gemini)   │                 │
│  └─────────────┘     └─────────────┘     └─────────────┘                 │
│         ↓                    ↓                    ↓                        │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                 │
│  │   3 Tabs    │     │  Firestore  │     │ Multi-Tool  │                 │
│  │ Schedule    │     │    Auth     │     │   Agent     │                 │
│  │ Momentum    │     │  Storage    │     │  Analysis   │                 │
│  │ Scan        │     │  Functions  │     │             │                 │
│  └─────────────┘     └─────────────┘     └─────────────┘                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚦 User Journey Map

### 1️⃣ FIRST LAUNCH & ONBOARDING

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ONBOARDING FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│     [App Launch]                                                            │
│          ↓                                                                  │
│     ┌─────────┐                                                           │
│     │ Welcome │ → "Your AI Nutrition Coach"                               │
│     └────┬────┘                                                           │
│          ↓                                                                  │
│     ┌─────────┐                                                           │
│     │  Goals  │ → Select Primary Goal:                                    │
│     └────┬────┘   • Weight Loss                                          │
│          ↓        • Muscle Gain                                          │
│          ↓        • Energy Optimization                                   │
│          ↓        • Health Improvement                                    │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │  Body   │ → Height, Weight, Age, Gender                           │
│     │ Metrics │   Activity Level (1-5 scale)                            │
│     └────┬────┘                                                           │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │  Sleep  │ → Typical Wake Time                                      │
│     │Schedule │   Typical Bed Time                                       │
│     └────┬────┘   Sleep Quality Goals                                    │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │  Meal   │ → Eating Window Preference:                              │
│     │ Timing  │   • 16:8 Fasting                                        │
│     └────┬────┘   • 3 Meals + Snacks                                    │
│          ↓        • Flexible                                            │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │Workout  │ → Training Days/Week                                     │
│     │Schedule │   Typical Workout Times                                  │
│     └────┬────┘                                                           │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │ Review  │ → Generated Meal Windows                                 │
│     │  Plan   │   Daily Macro Targets                                    │
│     └────┬────┘   Confirm or Adjust                                      │
│          ↓                                                                │
│     ┌─────────┐                                                           │
│     │Notific. │ → Enable Push Notifications                              │
│     │ & Perms │   Camera, Microphone, Speech                            │
│     └────┬────┘                                                           │
│          ↓                                                                │
│    [Main App]                                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2️⃣ DAILY USER FLOW - MORNING

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MORNING ROUTINE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [6:00 AM - User Wakes Up]                                                 │
│          ↓                                                                  │
│  ┌──────────────┐                                                         │
│  │Morning Nudge │ → "Good morning! Ready to check in?"                    │
│  └──────┬───────┘                                                         │
│          ↓                                                                  │
│  ┌──────────────┐     ┌─────────────────┐                               │
│  │   Morning    │     │  Data Captured: │                               │
│  │  Check-In    │ →   │  • Wake Time    │                               │
│  │              │     │  • Sleep Quality│                               │
│  │ 1. Wake Time │     │  • Day Focus    │                               │
│  │ 2. Sleep (5) │     └─────────────────┘                               │
│  │ 3. Day Focus │              ↓                                         │
│  └──────┬───────┘     ┌─────────────────┐                               │
│          ↓            │Window Generation │                               │
│          ↓            │   Algorithm      │                               │
│          ↓            └────────┬─────────┘                               │
│          ↓                     ↓                                         │
│  ┌──────────────┐     ┌─────────────────┐                               │
│  │  Schedule    │ ←   │ Generated:      │                               │
│  │    View      │     │ • 4-6 Windows   │                               │
│  │              │     │ • Timed to Goals│                               │
│  │  Timeline    │     │ • Macro Targets │                               │
│  │  7AM - 10PM  │     └─────────────────┘                               │
│  └──────────────┘                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3️⃣ MEAL CAPTURE FLOW

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MEAL SCANNING FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [User Taps Scan Tab]                                                      │
│          ↓                                                                  │
│  ┌──────────────┐                                                         │
│  │Camera Preview│ → Real-time camera feed                                 │
│  │              │   Capture button prominent                              │
│  └──────┬───────┘                                                         │
│          ↓ [Capture]                                                       │
│  ┌──────────────┐                                                         │
│  │ Photo Taken  │ → Image captured                                        │
│  └──────┬───────┘                                                         │
│          ↓                                                                  │
│  ┌──────────────┐     ┌─────────────────────┐                           │
│  │Voice Overlay │     │ Speech Recognition  │                           │
│  │              │ →   │ • Real-time STT     │                           │
│  │ "Describe    │     │ • Context added     │                           │
│  │  your meal"  │     └─────────────────────┘                           │
│  └──────┬───────┘                                                         │
│          ↓                                                                  │
│  ┌──────────────┐     ┌─────────────────────────────┐                   │
│  │  Analyzing   │     │  AI Agent Orchestration    │                   │
│  │              │     ├─────────────────────────────┤                   │
│  │ • Progress   │ ←   │ 1. Initial Analysis         │                   │
│  │ • Agent Info │     │ 2. Brand Detection?         │                   │
│  │              │     │ 3. Deep Analysis?           │                   │
│  └──────┬───────┘     │ 4. Nutrition Lookup?       │                   │
│          ↓            └─────────────────────────────┘                   │
│          ↓                                                               │
│  ┌──────────────┐     ┌─────────────────────┐                           │
│  │Clarification │     │ If Needed:          │                           │
│  │  Questions   │ →   │ • Portion Size?     │                           │
│  │              │     │ • Cooking Method?   │                           │
│  │ (Optional)   │     │ • Ingredients?      │                           │
│  └──────┬───────┘     └─────────────────────┘                           │
│          ↓                                                               │
│  ┌──────────────────────────────────────┐                               │
│  │      MEAL ANALYSIS RESULTS           │                               │
│  ├──────────────────────────────────────┤                               │
│  │ Tab 1: Nutrition                     │                               │
│  │ • Calories & Macros                  │                               │
│  │ • 18+ Micronutrients                 │                               │
│  │ • Progress Bars                      │                               │
│  ├──────────────────────────────────────┤                               │
│  │ Tab 2: Ingredients                   │                               │
│  │ • Color-coded chips                  │                               │
│  │ • Food groups                        │                               │
│  │ • Portions                           │                               │
│  ├──────────────────────────────────────┤                               │
│  │ Tab 3: Insights                      │                               │
│  │ • Window-specific tips               │                               │
│  │ • Health impact petals               │                               │
│  │ • AI recommendations                 │                               │
│  └──────────────┬───────────────────────┘                               │
│                 ↓ [Confirm]                                              │
│          ┌──────────────┐                                                │
│          │   Saved &    │ → Meal appears in timeline                    │
│          │ Navigate to  │   Animation to window                         │
│          │  Schedule    │                                                │
│          └──────────────┘                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4️⃣ MEAL WINDOW MANAGEMENT

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ACTIVE WINDOW FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [Window Becomes Active]                                                    │
│          ↓                                                                  │
│  ┌──────────────┐                                                         │
│  │Window Nudge  │ → "Lunch window open! 2h to eat"                       │
│  └──────┬───────┘                                                         │
│          ↓                                                                  │
│  ┌─────────────────────────────┐                                         │
│  │    EXPANDED WINDOW VIEW      │                                         │
│  ├─────────────────────────────┤                                         │
│  │ • Time Remaining: 1h 45m     │                                         │
│  │ • Target: 650 cal            │                                         │
│  │ • Remaining Macros           │                                         │
│  │   P: 35g  C: 75g  F: 20g    │                                         │
│  │ • Window Purpose:            │                                         │
│  │   "Sustained Energy"         │                                         │
│  │ • Smart Suggestions          │                                         │
│  └──────────────┬───────────────┘                                         │
│                 ↓                                                         │
│         [User Logs Meal]                                                  │
│                 ↓                                                         │
│  ┌─────────────────────────────┐                                         │
│  │    WINDOW UPDATES LIVE       │                                         │
│  ├─────────────────────────────┤                                         │
│  │ • Meal Added to Timeline     │                                         │
│  │ • Remaining Macros Update    │                                         │
│  │ • Progress Bar Fills         │                                         │
│  │ • Micronutrients Track       │                                         │
│  └──────────────┬───────────────┘                                         │
│                 ↓                                                         │
│         [30 min after meal]                                              │
│                 ↓                                                         │
│  ┌──────────────┐     ┌─────────────────┐                               │
│  │ Post-Meal    │     │ Data Captured:  │                               │
│  │ Check-In     │ →   │ • Energy Level  │                               │
│  │              │     │ • Fullness      │                               │
│  │ • Energy (5) │     │ • Mood/Focus    │                               │
│  │ • Fullness   │     └─────────────────┘                               │
│  │ • Mood       │              ↓                                         │
│  └──────┬───────┘     ┌─────────────────┐                               │
│          ↓            │ Pattern Analysis │                               │
│          ↓            │ Engine Updates   │                               │
│          ↓            └─────────────────┘                               │
│          ↓                                                               │
│  [Window Closes]                                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5️⃣ MOMENTUM & ANALYTICS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MOMENTUM TAB FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [User Taps Momentum]                                                      │
│          ↓                                                                  │
│  ┌─────────────────────────────────────────┐                             │
│  │         4-CARD GRID LAYOUT              │                             │
│  ├─────────────────────────────────────────┤                             │
│  │                                          │                             │
│  │  ┌──────────────┐  ┌──────────────┐    │                             │
│  │  │ NutriSync    │  │   Social     │    │                             │
│  │  │   Score      │  │ Leaderboard  │    │                             │
│  │  │              │  │              │    │                             │
│  │  │    87/100    │  │  #3 of 12    │    │                             │
│  │  └──────┬───────┘  └──────┬───────┘    │                             │
│  │         ↓ [Tap]           ↓ [Tap]       │                             │
│  │  ┌──────────────┐  ┌──────────────┐    │                             │
│  │  │   Metrics    │  │   Weekly     │    │                             │
│  │  │  & Goals     │  │  Momentum    │    │                             │
│  │  │              │  │              │    │                             │
│  │  │ 73% to goal  │  │  ↗️ Trending  │    │                             │
│  │  └──────┬───────┘  └──────┬───────┘    │                             │
│  │         ↓                 ↓             │                             │
│  └─────────┼─────────────────┼─────────────┘                             │
│            ↓                 ↓                                            │
│  ┌─────────────────────────────────────────┐                             │
│  │        DETAILED ANALYTICS VIEW          │                             │
│  ├─────────────────────────────────────────┤                             │
│  │ • Macro Trends (7-day charts)           │                             │
│  │ • Micronutrient Status                  │                             │
│  │ • Energy/Meal Correlations              │                             │
│  │ • Sleep/Nutrition Patterns              │                             │
│  │ • Goal Progress Tracking                │                             │
│  │ • Personalized Insights:                │                             │
│  │   "Your 3pm energy dips correlate       │                             │
│  │    with high-carb lunches"              │                             │
│  └─────────────────────────────────────────┘                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 System Flows & Integrations

### NUDGE SYSTEM FLOW

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NUDGE ORCHESTRATION                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     │
│  │   Time-Based    │     │  Context-Based  │     │  Data-Based     │     │
│  │    Triggers     │     │    Triggers     │     │   Triggers      │     │
│  ├─────────────────┤     ├─────────────────┤     ├─────────────────┤     │
│  │ • Window Start  │     │ • First Launch  │     │ • Missed Window │     │
│  │ • Window End    │     │ • Goal Change   │     │ • Low Nutrients │     │
│  │ • Check-in Time │     │ • New Feature   │     │ • Pattern Found │     │
│  └────────┬────────┘     └────────┬────────┘     └────────┬────────┘     │
│           └───────────────────────┼───────────────────────┘              │
│                                   ↓                                        │
│                         ┌─────────────────┐                               │
│                         │  Nudge Manager  │                               │
│                         │                 │                               │
│                         │ • Priority Queue│                               │
│                         │ • Smart Timing  │                               │
│                         │ • User Prefs    │                               │
│                         └────────┬────────┘                               │
│                                  ↓                                        │
│      ┌────────────────────────────┴────────────────────────────┐         │
│      ↓                           ↓                              ↓         │
│ ┌──────────┐            ┌──────────────┐            ┌──────────────┐    │
│ │  Toast   │            │   Inline     │            │  Full Screen │    │
│ │  Nudge   │            │   Banner     │            │    Nudge     │    │
│ │          │            │              │            │              │    │
│ │ Quick    │            │ Contextual   │            │ Important    │    │
│ │ Info     │            │ Guidance     │            │ Actions      │    │
│ └──────────┘            └──────────────┘            └──────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### AI AGENT SYSTEM

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      MEAL ANALYSIS AGENT SYSTEM                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐                                                       │
│  │   User Input    │                                                       │
│  ├─────────────────┤                                                       │
│  │ • Photo         │                                                       │
│  │ • Voice Text    │                                                       │
│  │ • Context       │                                                       │
│  └────────┬────────┘                                                       │
│           ↓                                                                │
│  ┌─────────────────────────────────────────┐                             │
│  │      MealAnalysisAgent (Orchestrator)    │                             │
│  ├─────────────────────────────────────────┤                             │
│  │ 1. Analyze confidence & complexity       │                             │
│  │ 2. Detect brands/restaurants            │                             │
│  │ 3. Determine tool strategy              │                             │
│  └──────────────┬──────────────────────────┘                             │
│                 ↓                                                         │
│     ┌───────────┴───────────┬─────────────┬─────────────┐               │
│     ↓                       ↓             ↓             ↓               │
│ ┌───────────┐      ┌──────────────┐ ┌──────────┐ ┌──────────┐         │
│ │  Basic    │      │Brand Search  │ │   Deep   │ │Nutrition │         │
│ │ Analysis  │      │              │ │ Analysis │ │  Lookup  │         │
│ ├───────────┤      ├──────────────┤ ├──────────┤ ├──────────┤         │
│ │ Standard  │      │ McDonald's   │ │ Complex  │ │  USDA    │         │
│ │ Gemini    │      │ Starbucks    │ │ Multi-   │ │ Database │         │
│ │ Analysis  │      │ Official     │ │ Step     │ │ Verify   │         │
│ └─────┬─────┘      └──────┬───────┘ └────┬─────┘ └────┬─────┘         │
│       └───────────────────┼──────────────┼────────────┘               │
│                           ↓              ↓                             │
│                  ┌────────────────────────┐                           │
│                  │   Result Synthesis     │                           │
│                  │ • Merge all data       │                           │
│                  │ • Resolve conflicts    │                           │
│                  │ • Format for display   │                           │
│                  └────────────────────────┘                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW DIAGRAM                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   CLIENT (iOS App)                      BACKEND (Firebase)                 │
│  ┌─────────────────┐                   ┌─────────────────┐                │
│  │   User Action   │                   │   Firestore DB   │                │
│  │                 │ ←─── Read ────    │                  │                │
│  │ • Log Meal      │                   │ Collections:     │                │
│  │ • Check-in      │ ──── Write ───→   │ • users         │                │
│  │ • View Stats    │                   │ • meals         │                │
│  └────────┬────────┘                   │ • windows       │                │
│           │                            │ • checkIns      │                │
│           ↓                            └─────────────────┘                │
│  ┌─────────────────┐                   ┌─────────────────┐                │
│  │  Local Cache    │                   │ Cloud Functions  │                │
│  │                 │ ←─── Sync ────    │                  │                │
│  │ • Recent Meals  │                   │ • Window Gen     │                │
│  │ • Today's Data  │ ──── Trigger ──→  │ • Analytics      │                │
│  │ • User Prefs    │                   │ • Notifications  │                │
│  └─────────────────┘                   └────────┬────────┘                │
│                                                  ↓                         │
│  ┌─────────────────┐                   ┌─────────────────┐                │
│  │  Photo Storage  │                   │  Firebase        │                │
│  │                 │ ──── Upload ───→  │  Storage         │                │
│  │ • Meal Images   │                   │                  │                │
│  │ • Compressed    │ ←─── CDN URL ──   │ • Meal Photos    │                │
│  └─────────────────┘                   └─────────────────┘                │
│                                                                             │
│                        AI SERVICES                                          │
│  ┌─────────────────┐                   ┌─────────────────┐                │
│  │  AI Analysis    │                   │  Vertex AI       │                │
│  │                 │ ──── Request ──→  │                  │                │
│  │ • Photo + Voice │                   │ • Gemini 2.0     │                │
│  │ • Get Nutrition │ ←─── Response ──  │ • Multi-modal    │                │
│  └─────────────────┘                   └─────────────────┘                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 MVP Success Metrics

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SUCCESS DASHBOARD                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────┐    ┌───────────────────────────┐          │
│  │    USER ENGAGEMENT        │    │    TECHNICAL METRICS      │          │
│  ├───────────────────────────┤    ├───────────────────────────┤          │
│  │ • D1 Retention: >80%      │    │ • Crash Rate: <0.5%       │          │
│  │ • D7 Retention: >60%      │    │ • AI Response: <10s       │          │
│  │ • D30 Retention: >40%     │    │ • App Launch: <2s         │          │
│  │ • Daily Active: >70%      │    │ • Photo Analysis: <8s     │          │
│  │ • Meals/Day: >2.5         │    │ • Clarifications: <2/scan │          │
│  └───────────────────────────┘    └───────────────────────────┘          │
│                                                                             │
│  ┌───────────────────────────┐    ┌───────────────────────────┐          │
│  │    HEALTH OUTCOMES        │    │    BUSINESS METRICS       │          │
│  ├───────────────────────────┤    ├───────────────────────────┤          │
│  │ • Goal Progress: >65%     │    │ • App Store: >4.5★        │          │
│  │ • Check-in Rate: >80%     │    │ • Organic Growth: >20%    │          │
│  │ • Window Adherence: >70%  │    │ • Premium Convert: >10%   │          │
│  │ • Nutrient Goals: >75%    │    │ • Support Tickets: <5%    │          │
│  └───────────────────────────┘    └───────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Launch Checklist

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MVP LAUNCH READY                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CORE FEATURES ✓                    INFRASTRUCTURE ✓                       │
│  □ Onboarding Flow                  □ Firebase Setup                       │
│  □ Timeline View                    □ Gemini AI Integration                │
│  □ Meal Scanning                    □ Push Notifications                   │
│  □ Voice Input                      □ Analytics Tracking                   │
│  □ Check-ins                        □ Error Monitoring                     │
│  □ Nudge System                     □ Performance Monitoring               │
│  □ Momentum Analytics                                                       │
│                                     COMPLIANCE ✓                            │
│  QUALITY ✓                          □ Privacy Policy                       │
│  □ <0.5% Crash Rate                 □ Terms of Service                     │
│  □ All Permissions Working          □ App Store Guidelines                 │
│  □ Offline Handling                 □ Health Data Compliance               │
│  □ Error States                     □ GDPR/CCPA Ready                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Design System Reference

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           VISUAL HIERARCHY                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  COLORS                             COMPONENTS                              │
│  • Background: #000000              • NutriSyncCard (20px radius)          │
│  • Elevated: white.opacity(0.03)    • CustomTabBar (floating)              │
│  • Text Primary: white              • TimelineHourRow                      │
│  • Text Secondary: white(0.7)       • NudgeContainer (spring anim)         │
│  • Accent: Bright Green (<10%)      • WindowBanner (expandable)            │
│                                                                             │
│  TYPOGRAPHY                         ANIMATIONS                              │
│  • Headers: SF Pro Display          • Spring: response(0.3)               │
│  • Body: SF Pro Text                • Window slide: easeInOut(0.4)        │
│  • Mono: SF Mono                    • Nudge appear: scale + fade          │
│                                     • Tab switch: smooth transition        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Platform & Device Support

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEVICE COMPATIBILITY                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  iOS VERSION                        FEATURES BY DEVICE                      │
│  • Minimum: iOS 17.0                • iPhone: Full support                 │
│  • Target: iOS 18.0+                • iPad: Responsive UI (Phase 2)        │
│  • SwiftUI 6                        • Apple Watch: Companion (Phase 3)     │
│                                     • Mac: Catalyst (Future)               │
│                                                                             │
│  REQUIRED CAPABILITIES              OPTIONAL INTEGRATIONS                   │
│  • Camera                           • Apple Health                          │
│  • Microphone                       • Siri Shortcuts                        │
│  • Speech Recognition               • Home Screen Widgets                   │
│  • Push Notifications               • Live Activities                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔮 Post-MVP Roadmap Preview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FUTURE ENHANCEMENTS                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PHASE 2 (Months 2-3)               PHASE 3 (Months 4-6)                   │
│  • Barcode Scanning                 • Apple Watch App                       │
│  • Recipe Generation                • AI Meal Planning                      │
│  • Social Groups                    • Restaurant Menus                      │
│  • Weekly Reports                   • Grocery Lists                         │
│  • Apple Health Sync                • Meal Prep Mode                        │
│                                                                             │
│  PHASE 4 (Months 7-12)              PREMIUM FEATURES                       │
│  • Nutritionist Chat                • Advanced Analytics                    │
│  • Meal Plan Templates              • Custom AI Training                   │
│  • Progress Photos                  • Priority Support                      │
│  • Export Features                  • Team/Family Plans                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

*This document represents the complete MVP flow for NutriSync, designed to guide development and ensure all stakeholders understand the user journey, technical architecture, and success metrics.*

**Last Updated:** August 17, 2025  
**Version:** 1.0 MVP