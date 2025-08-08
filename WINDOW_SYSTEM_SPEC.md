## Dynamic Window System – Specification and Phased Plan

This document defines the rules, behaviors, and implementation phases for a comprehensive, adaptive meal window system that responds to morning and post‑meal check‑ins, user goals, and daily context.

### Objectives
- Generate realistic windows with variable durations (not fixed 60 min).
- Adapt window timing, duration, purpose, and macro allocations based on check‑ins (morning and post‑meal) while respecting user goals.
- Keep behavior predictable with guardrails and gentle adjustments.

### Core Concepts
- **Window**: start/end, duration, purpose, flexibility, calorie/macros, confidence, reasons.
- **Flexibility tiers**: strict (±10–15m), moderate (±20–30m), flexible (±45–60m). These map to our existing `WindowFlexibility.timeBuffer`.
- **Grace bands**: soft “before/after” tolerances derived from flexibility; used for UI halo and logic.
- **Templates by goal**: base time splits and purposes per goal; adjusted per user signals.

### Rules (System‑wide)
- Main meals: 105–120 min. Snacks: 45–60 min. Late dinner capped: end no later than sleep − 90 min.
- Minimum gap between windows: 90 min.
- First eating window no earlier than wake + 30–60 min.
- Respect fasting protocol span if configured (e.g., 8–10 hours total eating span).
- Redistribution: if a window is missed, roll 50–70% of its calories to the next two windows (not all into one).
- Never retroactively move past windows; only adjust future windows.

### Inputs
- Morning check‑in: wake time, sleep duration/quality, energy, day focus/activities.
- Post‑meal check‑in: energy, fullness, mood/focus, actual eaten time/macros.
- Profile: primary goal, daily macro/calorie targets, quiet hours.

---

## Phases

### Phase 1 – Foundation (this PR)
- Variable window durations by purpose
  - sustainedEnergy/recovery: 120m
  - metabolicBoost/sleepOptimization: 105m
  - focusBoost/preworkout/postworkout: 60m
- Morning anchoring
  - Anchor all windows to `wakeTime`; set realistic gaps; cap latest end at `sleepTime − 90m`.
- Keep existing flexibility buffers for grace bands (no UI change required).
- Minimal, safe changes in `WindowGenerationService`; no database schema changes.

Acceptance criteria
- Windows render with non‑uniform durations matching purposes.
- No overlaps; reasonable spacing; latest meals respect sleep guardrail.

### Phase 2 – In‑day Adaptation
- After each meal/post‑meal check‑in:
  - Early + hungry/low energy → pull next window earlier 10–20m; extend duration +10–15m; +5% calories.
  - Late + very full → push next window later 10–20m; trim duration −10–15m; −5–10% calories.
  - Missed windows → redistribute 50–70% to next two windows.
- Freeze rules: within 45m of start, limit shifts to ±10m; within 15m, no shift.

### Phase 3 – Learning and Personalization
- WindowConfidence score (0–1) from adherence deltas; tighten/loosen flexibility.
- Weekly drift toward habitual times; template split adjustments per goal/day‑type.

### Phase 4 – UX Enhancements
- Show slim grace halos before/after windows.
- “Why” chips summarizing recent adjustments.
- Dev dashboard controls for durations, grace sizes, redistribution ratio, smoothing α.

### Phase 5 – QA & Metrics
- Simulation tests for no‑overlap/guardrails.
- Tracking: adherence delta, completion rate, avg shifts/day, redistribution %, energy/fullness correlation.

---

## Technical Notes
- Durations implemented via purpose→duration mapping in `WindowGenerationService`.
- Sleep guardrail applied when computing each window’s end time.
- Existing `WindowFlexibility` buffers are the source of grace bands.

