# Dev Log #1 - Recording Script (What To Say)

---

## [0:00-0:10] HOOK

**ON CAMERA:**
"This is Google Calendar... but for meals. It schedules every meal, tells me exactly when and what to eat, and it fixed my 3pm energy crashes, helped me sleep better, and I finally started gaining muscle. Let me show you."

---

## [0:10-0:45] YOUR STORY

**ON CAMERA:**
"I'm Brennen. I'm a developer. And for years I had this problem: I'd crash hard at 3pm—like, couldn't function without a nap. Then I couldn't fall asleep at night. And I was eating a ton but couldn't gain weight.

I tried tracking everything in MyFitnessPal. Hit my calories, hit my macros. Nothing changed.

Then I found research on meal timing and scheduling; eating at the right TIMES with the right foods. I tried making a rough plan, stuck to it, and it worked immediately. Energy crashes gone. Started sleeping. Finally gaining muscle.

But planning it took hours every week—calculating windows, planning meals, tracking everything. So I built this app to automate the entire system."

---

## [0:45-2:00] ONBOARDING WALKTHROUGH

**ON CAMERA (INTRO):**
"So let's walk through the onboarding. I'm not going to explain every single screen, but I want to show you the main sections and what data we're collecting—because that's what makes the window generation actually work. The Goals section in particular is really interesting—I'll spend a bit more time there."

### GetStarted / Welcome
**VOICEOVER:**
"First, there's a quick intro—explains the core concept. Meal windows, not meal tracking. Nothing fancy here."

### Basics Section
**VOICEOVER:**
"Then we get into the Basics section. This is where the app collects personal metrics including: age, height, weight, biological sex. This is used for calculating baseline caloric needs and macro targets."

### Goals - Your Transformation
**VOICEOVER:**
"Then we hit the Goals section—this is where it gets interesting. First, there's an intro screen about what optimizing meal timing can actually do for you."

### Goals - Multi-Select Grid
**VOICEOVER:**
"Then you pick your goals. And here's the cool part—you can select multiple. Weight management, build muscle, steady energy, better sleep, athletic performance, metabolic health. Pick as many as you want."

### Goals - Ranking Screen
**VOICEOVER:**
"Now here's where it gets really smart. If you picked multiple goals, it asks you to rank them by priority. Because realistically, you can't optimize for everything equally—so the app asks: what matters most to you?"

**VOICEOVER (CONTINUED):**
"Your top two ranked goals get deep customization—detailed questions about preferences, timing, sensitivity. Goals ranked third or lower? The app uses smart defaults based on research. So you're not answering 50 questions, but you're still getting a personalized plan."

### Goals - Weight Management (Quick)
**VOICEOVER:**
"And if you selected Weight Management, it asks follow-up questions—lose, maintain, or gain, and by how much. Standard stuff."

### Schedule Section
**VOICEOVER:**
"Then Schedule—this is the most important part. Wake time, sleep time, workout time. This is what the AI uses to actually build your windows. If you work out at 7am, your first window is pre-workout. If you sleep at 10:30pm, your last meal window ends at least 3 hours before that. This is where the magic happens."

### Preferences Section
**VOICEOVER:**
"Finally, Preferences. Dietary restrictions, allergies, foods you hate. This affects the food suggestions the app gives you later. If you're vegetarian, you're not getting chicken and rice suggestions. If you're lactose intolerant, no dairy."

### Confirmation
**VOICEOVER:**
"That's it. Five sections, maybe two minutes to complete. Now the app has everything it needs to generate your personalized meal windows."

---

## [2:00-2:45] TECH STACK BREAKDOWN

**ON CAMERA:**
"Alright, quick tech breakdown before we see the windows—because this is actually a pretty sophisticated stack."

**VOICEOVER:**
"The entire app is built with SwiftUI—Apple's modern declarative UI framework. For local data persistence, I'm using SwiftData, which stores all your personal metrics, preferences, and meal logs directly on your device.

For cloud services, I'm using Firebase—specifically Firestore for cloud database sync, Firebase Auth for user accounts, and Firebase Storage for meal photos.

Authentication is flexible—you can sign in with Apple, Google, or email. I integrated Sign in with Apple and Google Sign-In for a seamless experience.

And for AI, I'm using Vertex AI from Google Cloud. That's what powers the meal window generation and the context-based food scanning. When you take a photo of your meal, the app sends the image plus your current window context to Vertex AI, which analyzes it and returns structured nutrition data.

So the architecture is: local-first with SwiftData for speed and privacy, Firebase for cloud sync and authentication, and Vertex AI for the intelligent features. Everything sensitive stays on your device unless you explicitly sync it."

**ON CAMERA:**
"Modern stack, privacy-focused architecture. Now let's see what it generated."

---

## [2:45-3:20] DAILYSYNC - ADAPTIVE CONTEXT INPUT

**ON CAMERA:**
"So here's what makes this different. Every morning, the app asks you: How's your day looking? And you just... talk to it."

**VOICEOVER:**
"I'm telling it about my workout time, my school schedule, robotics practice. All the stuff that affects when I can actually eat. This isn't just 'when do you wake up'—it's understanding your entire day, in your own words."

---

## [3:20-3:45] AI ANALYSIS & WINDOW GENERATION

**VOICEOVER:**
"Then the AI analyzes everything—your schedule, your workout time, your goals from onboarding—and generates personalized meal windows that actually fit your life."

---

## [3:45-4:10] GENERATED SCHEDULE

**VOICEOVER:**
"And here's what it generated. 'Pre-Training Fuel Surge' right before my workout. 'Post-Workout Recovery Feast' after. Every window has a purpose, custom macro targets, and they're timed around my actual schedule—school, workout, robotics."

**ON CAMERA:**
"This is the schedule. Let's look at what's actually in these windows."

---

## [4:10-4:35] WINDOW DETAILS

**VOICEOVER:**
"When you tap into a window, you get tailored suggestions. Look at this breakfast window—'Anabolic Kickstart.' The app knows my goal is muscle building, so it's suggesting high-protein options."

**VOICEOVER (CONTINUED):**
"Then look at the dinner window—'Evening Growth Window.' It's adjusting recommendations based on my evening activities—robotics, video editing—while still supporting muscle growth. Everything's contextual."

---

## [4:35-5:25] VOICE-FIRST FOOD SCANNING

**ON CAMERA:**
"Now let's actually log a meal. This is where the context-based scanning comes in. Instead of typing everything out, you just... describe it."

**VOICEOVER:**
"I'm selecting a photo from my library—just a bowl of cereal. Then I describe it. I'm keeping it simple: just 'honey bunches of oats.' I'm not specifying which type, how much, what kind of milk. The AI is going to figure that out and ask me for clarification."

**VOICEOVER (CONTINUED):**
"See that? The AI identified the specific brand—'Honey Bunches of Oats with Strawberries'—and it's asking clarification questions with smart defaults already selected. It knows I probably had 1.5 cups with 2% milk based on typical servings. I can adjust if needed, or just accept the defaults. This is way faster than manual entry."

---

## [5:25-5:50] MEAL DETAIL VIEW

**VOICEOVER:**
"Now let's look at what the app actually tracked from that meal."

**VOICEOVER (CONTINUED):**
"This is the NutriSync Petals view—it breaks down micronutrients by category. See how the cereal hit 95% of my vitamin B12 for the day? But only 33% of riboflavin. The app is tracking way more than just calories—it's showing me which micronutrients I'm getting from each meal, so I can see patterns and make better choices later."

---

## [5:50-6:15] DAILY SUMMARY

**VOICEOVER:**
"Now here's where the goal ranking from onboarding actually matters. Let me show you the Daily Summary."

**VOICEOVER (CONTINUED):**
"Remember how I ranked my goals during onboarding? Muscle building was #1, steady energy was #2. This is the plan the app generated based on those priorities. It's not just showing me what to eat—it's explaining WHY each window exists and how it supports my top goals."

---

## [6:15-6:30] PERFORMANCE TAB & WRAP

**VOICEOVER:**
"There's also a performance tab that tracks adherence over time. Right now I'm at 34%—just getting started. But as you hit your windows consistently, this score builds momentum."

**ON CAMERA:**
"And that's the full flow. Voice-first, context-aware, goal-driven. From daily context input to personalized windows to intelligent scanning with clarification questions to micronutrient tracking. It's not just tracking what you ate—it's understanding why, when, and how it fits into your actual life."

---

## [6:30-7:15] WHY YOU NEED THIS

**ON CAMERA:**
"Here's why this matters.

If you get energy crashes in the afternoon—it's probably your meal timing.

If you can't fall asleep at night—you're eating too late.

If you're trying to gain muscle but it's not working—you're eating at the wrong times.

Every nutrition app makes you do the planning yourself. This automates the entire system—schedules your meals, suggests what to eat, and adapts to your life in real-time.

[hold up phone]

This is the app I wish existed when I was struggling. So I built it."

---

## [7:15-7:45] CALL TO ACTION

**ON CAMERA:**
"I'm opening up beta testing right now. I need 100 people to try this and give me feedback.

If this resonates with you—energy crashes, bad sleep, trouble gaining muscle—the link is in the description. Completely free during beta.

I'm also posting weekly dev logs, so subscribe if you want to follow the build.

Thanks for watching. Now go fix your meal timing."
