why# NutriSync Codebase Master Todo List
## Overall Project Tracking

Last Updated: 2025-08-29

---

## 🎯 Active Development Tasks

### Priority 0: TestFlight Release Requirements
- [x] **Onboarding Screens Conversion** - Adapt MacroFactorOnboarding to NutriSync
  - Status: COMPLETED (2025-08-30)
  - Sessions Required: 3-4
  - Complexity: Medium
  - Note: Keep aesthetic, update text/branding
  
- [ ] **Meal Scan Accuracy Improvement** - Switch to Gemini 2.5 Pro
  - Status: Not Started  
  - Sessions Required: 2-3
  - Complexity: High
  - Note: Current 2.0 Flash Thinking less accurate than 2.5 Pro
  
- [x] **Check-In Views Polish** - UI/UX improvements
  - Status: COMPLETED (2025-08-31)
  - Sessions Required: 4 (research, planning, implementation, continuation)
  - Complexity: Medium
  - Implemented: Sliders with haptics, time selectors, activity categories, TimeBlockBuilder
  
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

### Priority 1: Critical Infrastructure
- [ ] **Firebase Migration** - Replace MockDataManager in 47+ files
  - Status: Not Started
  - Sessions Required: 5-7
  - Complexity: High
  
- [ ] **AI Window Generation Fixes** - Handle midnight/workout edge cases
  - Status: Not Started
  - Sessions Required: 2-3
  - Complexity: Medium

### Priority 2: Core Features
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

---

## 🐛 Known Bugs

- [ ] **Build Timeout Issues** - Full xcodebuild times out
  - Workaround: Use file-specific compilation
  - Priority: Medium
  
- [ ] **Token Usage Optimization** - Keep AI operations under $0.03
  - Current: Unknown
  - Target: <$0.03 per operation
  - Priority: Medium

---

## 🔄 Completed Tasks

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

**Total Tasks:** 17
**Completed:** 11
**In Progress:** 0
**Not Started:** 6
**Completion Rate:** 65%

### TestFlight Readiness: 20%
- [ ] Core features complete
- [ ] UI/UX polished
- [ ] Multi-user testing ready
- [x] Onboarding flow complete
- [ ] AI accuracy optimized

---

## 🚀 Next Up Queue

### TestFlight Sprint (Priority 0)
1. Onboarding screens conversion (MacroFactor → NutriSync)
2. Meal scan accuracy improvement (Gemini 2.5 Pro migration)
3. Check-In views polish (with user input)
4. Missed Windows view implementation
5. Scan view enhancement

### Infrastructure (Priority 1)
1. Complete SimplePerformanceView implementation
2. Begin Firebase Migration Sprint
3. Implement real-time meal window redistribution

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
