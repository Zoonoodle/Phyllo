why# NutriSync Codebase Master Todo List
## Overall Project Tracking

Last Updated: 2025-09-26

---

## 🎯 Active Development Tasks

### Priority 0: TestFlight Release Requirements
- [x] **Onboarding Screens Conversion** - Adapt MacroFactorOnboarding to NutriSync
  - Status: COMPLETED (2025-08-30)
  - Sessions Required: 3-4
  - Complexity: Medium
  - Note: Keep aesthetic, update text/branding
  
  
- [x] **Check-In Views Polish** - UI/UX improvements
  - Status: COMPLETED (2025-08-31)
  - Sessions Required: 4 (research, planning, implementation, continuation)
  - Compl`exity: Medium
  - Implemented: Sliders with haptics, time selectors, activity categories, TimeBlockBuilder
  
- [ ] **Daily Sync Integration** - Complete new DailySync system integration
  - Status: Critical - Partially Implemented
  - Sessions Required: 2-3
  - Complexity: High
  - Note: Currently converts to legacy MorningCheckInData, needs direct integration
  - File: Models/DailySyncData.swift:388
  
- [ ] **FoodAnalysisView Real Data** - Replace hardcoded values
  - Status: High Priority
  - Sessions Required: 1-2
  - Complexity: Medium
  - Note: Multiple TODOs for connecting real data sources
  - Files: Views/Scan/Results/FoodAnalysisView.swift:388-551
  
- [ ] **Missed Windows View** - Handle skipped meal scenarios
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  - Note: REQUIRES user design approval
  
- [ ] **Scan View Enhancement** - Camera/gallery UX improvements
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  - Note: REQUIRES user design approval
  
- [ ] **Barcode Scanning** - Implement barcode lookup for food items
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  - Note: MealCaptureService.swift:230

### Priority 1: Critical Infrastructure
- [x] **Firebase Migration** - Replace MockDataManager in 47+ files
  - Status: COMPLETED (2025-09-26)
  - Sessions Required: 5-7
  - Complexity: High
  - Note: Only 2 legacy references remain, FirebaseDataProvider fully implemented
  
- [ ] **Analytics Implementation** - Complete missing analytics functions
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  - Files: FirebaseDataProvider.swift (lines 763, 865, 1156)
  
- [ ] **AI Window Generation Service** - Implement AIWindowGenerationService
  - Status: Not Started
  - Sessions Required: 3-4
  - Complexity: High
  - File: FirebaseDataProvider.swift:1485

### Priority 2: Core Features
- [ ] **Dynamic Daily Targets** - Different calorie/macro targets for each day
  - Status: Not Started
  - Sessions Required: 3-4
  - Complexity: Medium
  - Note: Like MacroFactor's cycling approach for weight loss/gain
  - Benefits: More effective metabolic adaptation, better adherence
  - Implementation: AI calculates daily variations based on activity, goals, metabolism
  
- [ ] **Voice Recording Implementation** - Add voice input for meal logging
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  - File: Views/Focus/SimplifiedMealLoggingView.swift:201
  
- [ ] **Voice Context Onboarding** - Reduce onboarding screens via intelligent voice input
  - Status: Not Started
  - Sessions Required: 4-5
  - Complexity: High
  - Note: User speaks preferences naturally, AI agent parses and extracts context for window generation
  - Benefits: Could reduce 31 screens to 5-10 screens
  - Implementation: Lower-level agent parses voice→text, extracts goals/preferences/constraints
  
- [ ] **SimplePerformanceView Completion** - Finish Momentum tab implementation
  - Status: In Progress
  - Sessions Required: 1-2
  - Complexity: Low
  
- [ ] **Real-time Meal Window Redistribution** - Dynamic adjustment when meals missed
  - Status: Not Started
  - Sessions Required: 3-4
  - Complexity: High

### Priority 3: UI/UX Improvements
- [ ] **Focus Tab Refinement** - User feedback integration
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium
  
- [ ] **Animation Improvements** - Smooth transitions
  - Status: Not Started
  - Sessions Required: 1-2
  - Complexity: Low
  
- [ ] **Loading States Implementation** - Better UX during async operations
  - Status: Not Started
  - Sessions Required: 1-2
  - Complexity: Low
  
- [ ] **User Profile Integration** - Replace hardcoded user data
  - Status: Not Started
  - Sessions Required: 1-2
  - Complexity: Low
  - Files: SleepVisualizations.swift:13, YourPlanChapter.swift:33,101
  
- [ ] **Password Reset** - Implement password reset functionality
  - Status: Not Started
  - Sessions Required: 1
  - Complexity: Low
  - File: Views/Auth/LoginView.swift:100

---

## 🐛 Known Bugs & Issues

- [ ] **Build Timeout Issues** - Full xcodebuild times out
  - Workaround: Use file-specific compilation
  - Priority: Medium
  
- [ ] **Token Usage Optimization** - Keep AI operations under $0.03
  - Current: Unknown
  - Target: <$0.03 per operation
  - Priority: Medium
  
- [ ] **Clarification Cancellation Logic** - Implement real meal cancellation
  - File: ClarificationQuestionsView.swift:305
  - Priority: Medium
  
- [ ] **Camera Preparation Messages** - Show user feedback during camera init
  - File: ScanTabView.swift:316
  - Priority: Low
  
- [ ] **Push Notification Token** - Send token to server if using remote push
  - File: AppDelegate.swift:27
  - Priority: Low
  
- [ ] **DataProvider Configuration** - Ensure configure() is always called
  - File: DataProviderProtocol.swift:436
  - Priority: High

---

## 🔄 Completed Tasks

### 2025-09-26
- [x] Firebase Migration - Successfully removed MockDataManager from codebase
  - Replaced with FirebaseDataProvider throughout
  - Only 2 legacy references remain for development purposes
  - All main functionality now uses Firebase

### 2025-09-03
- [x] Meal scan loading animation enhancement
  - Created MealAnalysisProgressRing component with open-bottom design
  - Added CompactMealAnalysisLoader with rotating status messages
  - Replaced full-screen loading with inline progress indicators
  - Removed MealAnalysisLoadingView entirely
  - Updated ExpandableWindowBanner and AnalyzingMealCard to use new loaders
  - Progress simulates 0-99% over 3.3 seconds, holds at 99% until complete

### 2025-09-02
- [x] Portrait orientation lock implemented
- [x] Window title truncation fixes (max 15 chars)
- [x] Build error resolutions
  - Fixed haptic feedback implementation
  - Resolved color reference issues
  - Fixed type mismatches in MealCaptureService

### 2025-08-31
- [x] Morning Check-In UI improvements completed
  - Created PhylloSlider with haptic feedback
  - Created TimeScrollSelector for past time selection
  - Created MorningActivity enum with 10 actionable categories
  - Created TimeBlockBuilder for activity scheduling
  - Updated all V2 views with new components
  - Removed 2 deprecated V1 files

### 2025-08-30
- [x] Onboarding screens fully converted (31 screens, no scrolling)
- [x] Split content-heavy screens for better UX
- [x] Fixed all navigation and progress bar issues
- [x] Updated OnboardingPreview with all screens

### 2025-08-29
- [x] Replaced tabbed NutritionDashboardView with SimplePerformanceView
- [x] Fixed meal windows extending past bedtime
- [x] Corrected bedtime date calculation (midnight crossing)
- [x] Expanded time-to-bed validation for late sleepers
- [x] Handled midnight crossing in hoursAffectedBy function

---

## 📊 Progress Metrics

**Total Tasks:** 24
**Completed:** 15
**In Progress:** 1
**Not Started:** 8
**Completion Rate:** 63%

### TestFlight Readiness: 60%
- [ ] Core features complete (Daily Sync integration pending)
- [x] UI/UX polished (mostly complete)
- [x] Firebase backend ready
- [x] Onboarding flow complete
- [ ] AI accuracy optimized
- [ ] Real data integration complete

---

## 🚀 Next Up Queue

### TestFlight Sprint (Priority 0)
1. Onboarding screens conversion (MacroFactor → NutriSync) ✅
2. Check-In views polish (with user input) ✅
3. Daily Sync integration completion (CRITICAL)
4. FoodAnalysisView real data connection (HIGH)
5. Missed Windows view implementation
6. Scan view enhancement

### Infrastructure (Priority 1)
1. Complete SimplePerformanceView implementation
2. Firebase Migration Sprint ✅
3. Implement AIWindowGenerationService
4. Complete analytics implementation
5. Fix DataProvider configuration issues

---

## 📝 Context Engineering Protocol

### MANDATORY Workflow for ALL Tasks:

1. **RESEARCH PHASE** (Agent 1)
   - Deep codebase analysis
   - Create `research-[feature-name].md`
   - Thorough pattern discovery
   
2. **PLANNING PHASE** (Agent 2)
   - Read research document
   - Create `plan-[feature-name].md`
   - Get human clarification
   
3. **IMPLEMENTATION PHASE** (Agent 3+)
   - Execute plan systematically
   - Monitor context usage (stop at 40% remaining)
   - Create `progress-[feature-name].md` when needed
   
4. **CONTINUATION LOOP**
   - New agent reads progress + plans
   - Continue implementation
   - Repeat until complete
   
5. **REVIEW & CLEANUP**
   - User testing and verification
   - Delete temporary .md files
   - Update this todolist

---

## 🎨 Design & Development Guidelines

### ⚠️ CRITICAL: Design Decision Protocol
- **ALL UI/UX changes REQUIRE user approval FIRST**
- **NEVER make autonomous design decisions**
- **ALWAYS present mockups/suggestions for confirmation**
- **User input weighs MORE HEAVILY than AI suggestions**
- **Document all design decisions in research/plan phases**

### Technical Guidelines

- **ALWAYS** follow Context Engineering Protocol
- **NEVER** skip research phase
- **COMPILE** before every commit
- **TEST** edge cases thoroughly
- **DOCUMENT** decisions in appropriate .md files

---

*This is the master tracking document for all NutriSync development tasks*
