From a user’s eyes, your Schedule view feels premium while Progress feels a bit “gamey.” Why:
Hierarchy is crystal-clear in Schedule. One big card at a time, clear time stamps, a single focal action (“7m left”). In Progress, the giant neon ring competes with many small tiles—no obvious first read beyond “52%.”
Color is purposeful in Schedule. Mostly neutral dark surfaces with tiny pops (green dot, amber clock). In Progress, saturated red/green/blue dominate—even when nothing’s wrong. Red especially reads as error not status.
Components are consistent in Schedule. Every element is a card with the same radius, border, spacing, icon weight. In Progress, the hero ring, chips, and tiles feel like different design systems.
Copy is calm in Schedule. Specific (“Pre-Workout Power Up, Soon”). Progress copy is vaguer (“Needs work”) and a bit judgmental.
Here’s how to rework Progress so it matches the Schedule theme + professionalism.
1) Establish the same visual system
Surface & borders: Use the same card container as Schedule (same radius, shadow, and 1px border). Avoid “floating” hero widgets.
Type scale: Reuse the exact title/subtitle sizes from Schedule (“Today’s Schedule” / “Saturday, September 6”) for “Performance” and the date.
Iconography: Match SF Symbols weight/size used on Schedule cards. Keep icons leading-left, not floating.
2) Tame the hero and give it a single story
Replace the big tri-color donut with one of these (A/B test both):
A. Three mini-cards (like Schedule cards), one per pillar (Timing, Nutrients, Adherence). Each card: left-aligned icon + label, bold % on the right, and a subtle 6px progress bar underneath. Neutral palette; only use red for true errors.
B. Segmented ring but muted: Dark ring base, a single brand accent for “Overall,” tiny ticks for the three sub-scores, and no red unless failing hard. Move the three pillar scores into compact pill chips under the ring.
Either way, the Overall number is the focal point, not three competing colors.
3) Re-compose the screen like the Schedule (top→detail)
Suggested order (all using the same Schedule-style cards):
Header card
“Performance” (title)
“Saturday, September 6” (subhead)
Pill chips: Timing 100% • Nutrients 10% • Adherence 47% (neutral/brand colors)
Overall card (A or B from above)
Current Window card (mirror the meal cards: title, time left, target/remaining macros as inline tokens)
Next Window card (exact same layout as Schedule’s future meal cards with “Soon” pill)
Key Actions card (if nutrients low, show a friendly CTA: “Log protein source” / “Scan a snack”—avoid “Needs work”)
Streak & Fasting combined in one compact two-column card, not two tiles
Insights card (one-liner insight + “See why” link, keep copy supportive, specific)
4) Color & states (match the Schedule mood)
Primary/neutral first. Use brand blue (or your primary) for progress; use green only for completed/positive; reserve red for errors or missed hard targets.
Dim backgrounds, bright accents. The Schedule’s elegance comes from lots of grey/black with tiny color sparks—do the same.
Empty states: soft, non-judgmental (“No nutrients logged yet. Add one?”) with a single primary button.
5) Microcopy & labels (Schedule tone)
Replace “Needs work” → “Let’s add a nutrient.”
Replace “Overall” ring with a sentence under it: “On track for timing. Focus: protein at lunch.”
Time language like Schedule: “in 2h 37m,” “7m left.”
6) Spacing & rhythm
Adopt the same spacing scale: 8/12/16/24. Keep one column stack on phone (like Schedule). If you keep two-up tiles, only use it inside a single card (e.g., Streak | Fasting), not for the whole page.
7) Motion & feedback
Mirror Schedule’s subtle timer animation: a gentle sweep and a tiny pulsing dot at the “now” point. Avoid bouncy or glowing animations on the ring.
When a pillar improves (e.g., you log protein), animate only that card’s micro-bar, not the whole page.
8) Accessibility & data clarity
Ensure WCAG contrast on bars and text over the dark surfaces.
Replace ambiguous totals (“0/18”) with what matters now: “0/3 key micros left today” or “+25g protein by 1:30 PM.”
Quick wireframe (text)
Performance
Saturday, September 6
[ Overall card ]
52% Overall
“On track for timing. Add protein at lunch.”
[ Pillars card ]
Timing — 100% ▓▓▓▓▓▓▓
Nutrients — 10% ▓░░░░░░
Adherence — 47% ▓▓░░░░
[ Current Window ]
Breakfast • 7m left • 0 cal remaining
Targets met: ✓ timing • Protein +0g to go
[ Next Meal Window ]
Lunch • 11:30 AM–1:00 PM • Soon
Goal: 400 cal • ≥30g protein
[ Streak & Fasting ]
Streak: 14 days | Fasting: 50m since last meal
[ Insight ]
“Front-loading protein improves energy in your afternoon session.” → See why
Implementation checklist
Same card component as Schedule (radius, border, shadow).
Replace red/green/blue donut with single-accent progress + neutral bars.
Reorder content: Overall → Pillars → Current → Next → Extras.
Unify icon sizes/weights with Schedule.
Rewrite microcopy to be specific, supportive, time-anchored.
Add a single primary CTA based on state (e.g., “Plan lunch macros”).
Give me a screenshot of your next pass and I’ll do a pixel-level pass (spacing, weights, labels) to get it to “Schedule-level” polish.
