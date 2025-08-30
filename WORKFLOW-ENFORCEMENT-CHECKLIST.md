# MANDATORY Workflow Enforcement Checklist
## Every Agent MUST Follow This EXACT Pattern

Last Updated: 2025-08-29

---

## ⚠️ CRITICAL: THIS IS NOT OPTIONAL

**Every Claude agent working on this codebase MUST follow this exact pattern. No exceptions.**

---

## 🔴 PHASE 1: RESEARCH AGENT CHECKLIST

When user says: "Research [feature/bug/task]" or "Start working on [X]"

### IMMEDIATE ACTIONS:
```
1. ✅ Read codebase-todolist.md to understand task
2. ✅ Read CONTEXT-ENGINEERING-WORKFLOW.md 
3. ✅ Create TodoWrite list for tracking
4. ✅ Use Task tool with subagent for deep analysis
5. ✅ Create research-[feature-name].md
6. ✅ Tell user to start NEW SESSION for Phase 2
```

### RESEARCH DOCUMENT MUST CONTAIN:
- [ ] Investigation topic clearly stated
- [ ] Key questions listed (3-5)
- [ ] Pattern analysis with code examples
- [ ] Technical constraints identified
- [ ] Implementation options (at least 2-3)
- [ ] Experiments/tests run with results
- [ ] Validation checklist completed
- [ ] Clear recommendation with rationale
- [ ] "Next Step: Create plan-[feature].md"

### WHAT NOT TO DO:
- ❌ Skip research and start coding
- ❌ Create plan.md in same session
- ❌ Make implementation decisions without research
- ❌ Continue past research phase

### END MESSAGE TEMPLATE:
```markdown
## ✅ PHASE 1: RESEARCH COMPLETE

Created: `research-[feature-name].md`

Key Findings:
- [3-4 bullet points]

## 📋 NEXT STEPS (Following Mandatory Workflow)

For PHASE 2: PLANNING
You need to:
1. Start a NEW agent session
2. Provide: 
   @Phyllo/research-[feature-name].md
   @Phyllo/CONTEXT-ENGINEERING-WORKFLOW.md
3. The planning agent will create plan-[feature-name].md with your input
```

---

## 🟡 PHASE 2: PLANNING AGENT CHECKLIST

When user provides: research-[feature].md

### IMMEDIATE ACTIONS:
```
1. ✅ Read research document COMPLETELY
2. ✅ Read CONTEXT-ENGINEERING-WORKFLOW.md
3. ✅ Create TodoWrite list for planning tasks
4. ✅ ASK USER for design preferences (MANDATORY)
5. ✅ Create plan-[feature-name].md
6. ✅ Get user approval on approach
7. ✅ Tell user to start NEW SESSION for Phase 3
```

### PLAN DOCUMENT MUST CONTAIN:
- [ ] Title and priority clearly stated
- [ ] Reference to research document
- [ ] Step-by-step implementation (numbered)
- [ ] Files to modify for each step
- [ ] Test commands for each step
- [ ] Risk mitigation strategies
- [ ] Rollback plan
- [ ] Completion checklist
- [ ] Success criteria

### MANDATORY USER INTERACTIONS:
```markdown
## 🎨 Design Decisions Needed

Before I create the plan, I need your input on:

1. **[Design Choice 1]**: 
   - Option A: [description]
   - Option B: [description]
   Your preference?

2. **[Design Choice 2]**:
   - Option A: [description]
   - Option B: [description]
   Your preference?

3. **Priority/Scope**:
   - Should we do [minimal/full] implementation?
   - Any specific requirements?
```

### END MESSAGE TEMPLATE:
```markdown
## ✅ PHASE 2: PLANNING COMPLETE

Created: `plan-[feature-name].md`

Plan Summary:
- [X] steps total
- Estimated sessions: [Y]
- Your approved approach: [Option Z]

## 📋 NEXT STEPS (Following Mandatory Workflow)

For PHASE 3: IMPLEMENTATION
You need to:
1. Start a NEW agent session
2. Provide:
   @Phyllo/plan-[feature-name].md
   @Phyllo/research-[feature-name].md
   @Phyllo/CONTEXT-ENGINEERING-WORKFLOW.md
3. The implementation agent will execute the plan
```

---

## 🟢 PHASE 3: IMPLEMENTATION AGENT CHECKLIST

When user provides: plan-[feature].md + research-[feature].md

### IMMEDIATE ACTIONS:
```
1. ✅ Read plan document COMPLETELY
2. ✅ Read research document for context
3. ✅ Read CONTEXT-ENGINEERING-WORKFLOW.md
4. ✅ Create TodoWrite from plan steps
5. ✅ Execute plan EXACTLY as written
6. ✅ Monitor context usage every 10 operations
7. ✅ Create progress-[feature].md at 60% context
8. ✅ Tell user to start NEW SESSION if needed
```

### EXECUTION RULES:
- [ ] Follow plan steps IN ORDER
- [ ] Test after EACH step (swiftc -parse)
- [ ] Commit working increments
- [ ] Update todos as completed
- [ ] Document any deviations

### CONTEXT MONITORING:
```python
# Check every 10 operations
if context_used >= 60%:
    - STOP current work
    - Create progress-[feature].md
    - Commit all changes
    - End session with handoff
```

### PROGRESS DOCUMENT MUST CONTAIN:
```markdown
# Progress: [Feature Name]
## Status at Context Limit (60% used)

### Completed Steps:
- [x] Step 1: [description]
- [x] Step 2: [description]
- [ ] Step 3: [IN PROGRESS - stopped at line X]
- [ ] Step 4: [not started]

### Current File Being Edited:
`path/to/file.swift` - Line [X]
Operation: [what you were doing]

### Key Decisions Made:
- Chose [X] because [Y]
- Implemented [Z] pattern

### Next Actions:
1. Continue from line [X] in [file]
2. Complete step 3
3. Test the implementation

### Critical Context:
- [Important finding 1]
- [Pattern discovered 2]
```

---

## 🔵 PHASE 4: CONTINUATION AGENT CHECKLIST

When user provides: progress-[feature].md + plan + research

### IMMEDIATE ACTIONS:
```
1. ✅ Read ALL three documents
2. ✅ Read CONTEXT-ENGINEERING-WORKFLOW.md
3. ✅ Create TodoWrite from remaining steps
4. ✅ Resume from EXACT stopping point
5. ✅ Continue implementation
6. ✅ Monitor context usage
7. ✅ Repeat until complete
```

### NEVER DO:
- ❌ Start from beginning
- ❌ Skip completed steps
- ❌ Change approach without user approval

---

## 🟣 PHASE 5: REVIEW AGENT CHECKLIST

When implementation is complete:

### IMMEDIATE ACTIONS:
```
1. ✅ Request user testing
2. ✅ Fix any issues found
3. ✅ Run final compilation tests
4. ✅ Delete temporary .md files
5. ✅ Update codebase-todolist.md
6. ✅ Commit and push final changes
```

### CLEANUP COMMANDS:
```bash
# After user approval
rm research-[feature].md
rm plan-[feature].md  
rm progress-[feature]*.md

# Update master list
# Edit codebase-todolist.md - mark task complete
```

---

## 🚫 COMMON VIOLATIONS TO AVOID

### Research Phase Violations:
- ❌ "Let me just make a quick fix" (NO! Research first!)
- ❌ "I'll create the plan now" (NO! New session!)
- ❌ "The research is simple, I'll implement" (NO! Follow phases!)

### Planning Phase Violations:
- ❌ "Based on research, I'll implement..." (NO! Plan only!)
- ❌ "The plan is obvious, starting coding" (NO! Get user input!)
- ❌ Making design decisions without user (NO! Ask first!)

### Implementation Phase Violations:
- ❌ "I have a better idea than the plan" (NO! Follow plan!)
- ❌ "I'll skip testing this step" (NO! Test everything!)
- ❌ Ignoring context limit (NO! Stop at 60%!)

---

## 📝 ENFORCEMENT VERIFICATION

Every agent should verify:

```markdown
Am I in the correct phase?
- [ ] Did user provide research.md? → I'm in PLANNING
- [ ] Did user provide plan.md? → I'm in IMPLEMENTATION  
- [ ] Did user provide progress.md? → I'm in CONTINUATION
- [ ] Did user ask to start fresh? → I'm in RESEARCH

Am I following the rules?
- [ ] Created appropriate .md file for my phase
- [ ] Using TodoWrite to track progress
- [ ] Monitoring context usage (if implementing)
- [ ] Getting user input (if planning)
```

---

## 🔥 CRITICAL REMINDERS

1. **EVERY TASK** follows this workflow - no exceptions
2. **ALWAYS** create the appropriate .md file for your phase
3. **NEVER** skip phases or combine them
4. **ALWAYS** tell user to start new session for next phase
5. **Design decisions** REQUIRE user input - never assume

---

## 💀 FAILURE CONSEQUENCES

Not following this workflow results in:
- Incomplete implementations
- Lost work from context overflow
- Inconsistent code quality
- Wasted agent sessions
- User frustration
- Project delays

---

**THIS DOCUMENT IS LAW. FOLLOW IT EXACTLY.**

*Last Updated: 2025-08-29 - Enforcement Version 1.0*