# MANDATORY Context Engineering Workflow
## Multi-Agent Development Protocol

Last Updated: 2025-08-29

---

## ⚠️ THIS WORKFLOW IS MANDATORY FOR ALL DEVELOPMENT

**No exceptions. Every feature, bug fix, or modification MUST follow this protocol.**

---

## 📋 Overview

This workflow manages Claude's 200k context window limitation by:
- Distributing work across multiple agent sessions
- Preserving critical context between sessions
- Ensuring thorough research before implementation
- Maintaining progress continuity

---

## 🔄 The Five-Phase Protocol

### PHASE 1: RESEARCH (Agent Session 1)
**Purpose:** Deep analysis and understanding

**MANDATORY Actions:**
1. Thoroughly scan entire codebase for patterns
2. Identify all affected files and dependencies
3. Document edge cases and constraints
4. Research external documentation if needed
5. Run test commands to validate assumptions

**Output:** `research-[feature-name].md`

**Example:**
```bash
# Agent 1 creates:
research-firebase-migration.md
research-meal-window-redistribution.md
research-performance-optimization.md
```

---

### PHASE 2: PLANNING (Agent Session 2)
**Purpose:** Strategic implementation planning with human input

**MANDATORY Actions:**
1. Read the research document thoroughly
2. Create step-by-step implementation plan
3. Ask human for clarification on ambiguous points
4. Define success criteria and test cases
5. Establish rollback procedures

**Output:** `plan-[feature-name].md`

**Human Interaction Required:**
- Approve approach selection
- Clarify business requirements
- Confirm priority and scope

---

### PHASE 3: IMPLEMENTATION (Agent Session 3+)
**Purpose:** Execute the plan systematically

**MANDATORY Actions:**
1. Read plan document completely
2. Follow implementation steps exactly
3. Test after each major step
4. Commit working increments
5. Monitor context usage continuously

**Context Management:**
- **STOP at 40% context remaining** (when 60% used)
- Create `progress-[feature-name].md` before stopping
- Document exactly where you stopped

**Output:** Code changes + `progress-[feature-name].md` (if needed)

---

### PHASE 4: CONTINUATION (Agent Session 4+)
**Purpose:** Resume work seamlessly

**MANDATORY Actions:**
1. Read ALL relevant documents:
   - Original research
   - Plan
   - Latest progress
2. Resume from exact stopping point
3. Continue implementation
4. Repeat Phase 3 monitoring

**Loop Until:** Implementation complete OR user verification needed

---

### PHASE 5: REVIEW & CLEANUP (Final Agent Session)
**Purpose:** Ensure quality and clean up

**MANDATORY Actions:**
1. Request user testing and verification
2. Fix any issues found
3. Run final compilation and tests
4. Delete temporary .md files (NOT base templates)
5. Update `codebase-todolist.md`
6. Commit and push final changes

**User Verification Required:**
- Test all functionality
- Confirm edge cases handled
- Approve for completion

---

## 📁 File Naming Convention

### Temporary Files (deleted after completion):
```
research-[feature-name].md
plan-[feature-name].md  
progress-[feature-name].md
```

### Permanent Files (never delete):
```
progress.md          # Template
plan.md             # Template
research.md         # Template
codebase-todolist.md # Master tracking
CONTEXT-ENGINEERING-WORKFLOW.md # This file
```

---

## 🚨 Context Window Management

### Monitoring Rules:
- Check context usage every 10-15 operations
- Calculate: `Context Used = (Tokens Used / 200,000) * 100`
- **HARD STOP at 60% usage** (120,000 tokens)

### When Approaching Limit:
1. Complete current atomic operation
2. Create comprehensive progress document
3. Commit all working code
4. End session with clear handoff notes

---

## 📊 Progress Document Requirements

Each `progress-[feature-name].md` MUST include:

1. **Exact Stopping Point**
   - File being edited
   - Line number
   - Operation in progress

2. **Completed Steps**
   - Checklist from plan.md
   - What's done vs. remaining

3. **Critical Context**
   - Decisions made
   - Patterns discovered  
   - Problems encountered

4. **Next Actions**
   - Immediate next step
   - Remaining work estimate

---

## 🎯 Success Criteria

A task is ONLY complete when:
- [ ] All plan steps executed
- [ ] Tests pass
- [ ] Edge cases handled
- [ ] User has verified functionality
- [ ] Performance targets met
- [ ] Code follows conventions
- [ ] Temporary files deleted
- [ ] Codebase todolist updated

---

## 💀 Failure Recovery

If an agent session fails:
1. Next agent reads all existing documents
2. Identifies last known good state
3. Creates recovery plan
4. Proceeds with caution

---

## 🔐 Workflow Enforcement

**This workflow is MANDATORY because:**
1. Prevents context overflow crashes
2. Ensures thorough analysis before coding
3. Maintains work continuity
4. Enables parallel development
5. Creates audit trail
6. Facilitates debugging

**Violations will result in:**
- Incomplete implementations
- Lost work
- Context overflow
- Inconsistent code
- Wasted sessions

---

## 📝 Example Workflow Execution

```bash
# Session 1 (Research Agent)
User: "Implement Firebase migration"
Agent: *Creates research-firebase-migration.md after deep analysis*

# Session 2 (Planning Agent)  
User: *Provides research-firebase-migration.md*
Agent: *Creates plan-firebase-migration.md with human input*

# Session 3 (Implementation Agent)
User: *Provides plan + research*
Agent: *Implements until 60% context used*
Agent: *Creates progress-firebase-migration-1.md*

# Session 4 (Continuation Agent)
User: *Provides all previous docs*
Agent: *Continues from stopping point*
Agent: *Completes implementation*

# Session 5 (Review Agent)
User: *Tests and approves*
Agent: *Cleans up files, updates todolist*
```

---

## ⚡ Quick Reference Commands

```bash
# Find all temporary work files
ls -la | grep -E "research-|plan-|progress-" | grep -v ".md$"

# Check context usage (hypothetical)
echo "Approximately 60% context used - time to stop"

# Create progress document
touch progress-$(date +%Y%m%d-%H%M%S).md

# Clean up after completion
rm research-*.md plan-*.md progress-*.md
```

---

**REMEMBER: This workflow is not optional. It is the required process for ALL development work on this codebase.**

---

*Last Modified: 2025-08-29 by Context Engineering Protocol Implementation*