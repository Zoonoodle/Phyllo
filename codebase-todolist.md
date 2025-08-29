# NutriSync Codebase Master Todo List
## Overall Project Tracking

Last Updated: 2025-08-29

---

## 🎯 Active Development Tasks

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

### 2025-08-29
- [x] Replaced tabbed NutritionDashboardView with SimplePerformanceView
- [x] Fixed meal windows extending past bedtime
- [x] Corrected bedtime date calculation (midnight crossing)
- [x] Expanded time-to-bed validation for late sleepers
- [x] Handled midnight crossing in hoursAffectedBy function

---

## 📊 Progress Metrics

**Total Tasks:** 11
**Completed:** 5
**In Progress:** 1
**Not Started:** 5
**Completion Rate:** 45%

---

## 🚀 Next Up Queue

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

## 🎨 Development Guidelines

- **ALWAYS** follow Context Engineering Protocol
- **NEVER** skip research phase
- **COMPILE** before every commit
- **TEST** edge cases thoroughly
- **DOCUMENT** decisions in appropriate .md files

---

*This is the master tracking document for all NutriSync development tasks*