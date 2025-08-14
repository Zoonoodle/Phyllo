# NutriSync TestFlight Onboarding Plan

**Version:** 1.0  
**Created:** August 2025  
**Purpose:** Comprehensive onboarding flow for TestFlight launch  

---

## 🎯 **Onboarding Philosophy**

Following Opal's powerful call-to-action approach and MacroFactor's organized sectioning, our onboarding will:

1. **Create Urgency**: Show users the impact of poor nutrition on their life
2. **Gather Essentials**: Collect all necessary data in organized sections
3. **Educate on Schedule System**: Explain our unique meal window approach
4. **Build Anticipation**: Show how NutriSync will optimize their energy

---

## 📱 **Screen Flow Overview**

### **Section Navigation Bar** (MacroFactor-inspired)
- Shows progress through 5 sections: Welcome → Profile → Goals → Schedule → Setup
- Clean dots with current section highlighted in green
- Shows completed sections with checkmarks

---

## 🎨 **Design System**

### **Colors**
- **Background**: Dark gray (#0A0A0A) - matching Schedule view
- **Cards**: white.opacity(0.03) with subtle borders
- **Primary Text**: white
- **Secondary Text**: white.opacity(0.5-0.6)
- **Accent**: Bright green (#00D26A) - used sparingly
- **Section Progress**: Gray dots, green for current/completed

### **Typography**
- **Headers**: SF Pro Display, 32pt, bold
- **Subheaders**: SF Pro Text, 16pt, white.opacity(0.7)
- **Body**: SF Pro Text, 17pt
- **Buttons**: SF Pro Text, 17pt, medium

### **Components**
- **Buttons**: Full width, 56pt height, 28pt corner radius
- **Cards**: 20pt corner radius, subtle shadow
- **Input Fields**: Dark background, 16pt corner radius
- **Selection Cards**: Border highlight when selected

---

## 📋 **Detailed Screen Specifications**

### **1. WELCOME SECTION**

#### **Screen 1.1: App Permissions**
**Purpose**: Request necessary permissions upfront  
**Content**:
- App icon and name at top
- "NutriSync needs your permission to:"
- List with icons:
  - 📷 Camera (for meal scanning)
  - 🔔 Notifications (for meal window reminders)
  - 📊 Health Data (optional, for Apple Health sync)
- "Allow Access" button (green)
- "Maybe Later" link at bottom

#### **Screen 1.2: Welcome**
**Purpose**: First impression and value proposition  
**Content**:
- NutriSync logo
- "Transform Your Energy Through Smart Nutrition Timing"
- Subtext: "Join thousands optimizing their daily performance"
- "Get Started" button (full width, green)
- "Already have an account?" link at bottom

#### **Screen 1.3: Impact Calculator** (Opal-inspired)
**Purpose**: Create urgency by showing impact  
**Content**:
- "How's your current energy level?"
- Slider from 1-10 with emoji faces
- Based on selection, show:
  - "At this rate, you'll lose **X hours** of productive time this year"
  - "That's **Y days** of feeling suboptimal"
- Large impact number animated in purple
- "Let's fix this" button

#### **Screen 1.4: The Good News** (Opal-inspired)
**Purpose**: Show the solution  
**Content**:
- "The good news is NutriSync can help you gain back"
- Large number: "**85+ days**"
- "of peak energy and focus per year"
- "Based on your profile and our meal timing optimization"
- "Show Me How" button

---

### **2. PROFILE SECTION**

#### **Screen 2.1: Basic Info**
**Purpose**: Gather essential user data  
**Content**:
```
What should we call you?
[Name input field]

When were you born?
[Date picker - Month, Day, Year]

What's your biological sex?
○ Female  ○ Male

[Next button]
```

#### **Screen 2.2: Body Metrics**
**Purpose**: Calculate caloric needs  
**Content**:
```
What's your height?
[Tab: Imperial | Metric]
[5] ft [7] in  OR  [170] cm

What's your current weight?
[165] lbs  OR  [75] kg

[Next button]
```

#### **Screen 2.3: Body Composition** (MacroFactor-inspired)
**Purpose**: Refine calorie calculations  
**Content**:
- "Estimate your body fat level"
- "Don't worry about being precise - a visual estimate works"
- Grid of 9 body silhouettes with percentages
- Tap to select closest match
- Selected shows green checkmark

---

### **3. GOALS SECTION**

#### **Screen 3.1: Primary Goal**
**Purpose**: Understand user's main objective  
**Content**:
```
What's your primary goal?

○ Lose Weight
  Sustainable fat loss while preserving muscle

○ Build Muscle
  Gain lean mass with minimal fat

○ Improve Energy
  Optimize meal timing for consistent energy

○ Athletic Performance
  Fuel training and enhance recovery

○ General Health
  Balance nutrition for overall wellness
```

#### **Screen 3.2: Weight Goal** (if weight loss/gain selected)
**Purpose**: Set specific targets  
**Content**:
```
What's your target weight?
[Slider showing current → target]
[150] lbs

At what pace?
○ Relaxed (0.5 lb/week)
○ Moderate (1 lb/week) ✓
○ Aggressive (1.5 lb/week)

Estimated completion: [Date]
```

#### **Screen 3.3: Secondary Goals**
**Purpose**: Understand other priorities  
**Content**:
```
Any other goals? (Select all that apply)

□ Better Sleep
□ Improved Focus
□ Stable Mood
□ Reduced Cravings
□ Better Digestion
□ More Energy
□ Athletic Recovery
```

---

### **4. SCHEDULE SECTION** (NutriSync Unique)

#### **Screen 4.1: Schedule Introduction**
**Purpose**: Introduce meal window concept  
**Content**:
- Animated timeline visualization
- "NutriSync uses **Meal Windows**"
- "Strategic eating periods that optimize:"
  - ⚡ Energy levels throughout the day
  - 🎯 Nutrient timing for your goals
  - 🔄 Natural circadian rhythms
- "Learn More" button

#### **Screen 4.2: Daily Routine**
**Purpose**: Understand user's schedule  
**Content**:
```
What time do you usually...

Wake up?
[6:00 AM] ±

Have lunch?
[12:00 PM] ±

Finish work?
[5:00 PM] ±

Go to bed?
[10:00 PM] ±
```

#### **Screen 4.3: Activity Patterns**
**Purpose**: Customize meal windows  
**Content**:
```
How active are you?

○ Sedentary
  Less than 5,000 steps/day

○ Lightly Active
  5,000-10,000 steps/day

○ Active ✓
  10,000-15,000 steps/day

○ Very Active
  More than 15,000 steps/day

Do you exercise?
[3] times per week
```

#### **Screen 4.4: Meal Frequency Preference**
**Purpose**: Determine window structure  
**Content**:
- "How many times do you prefer to eat?"
- Visual cards showing different patterns:

**2 Meals/Day**
- 16:8 Intermittent Fasting
- Best for: Fat loss, simplicity
- Windows: 12pm-8pm

**3 Meals/Day** ✓
- Traditional eating pattern
- Best for: Sustained energy
- Windows: 7am, 12pm, 6pm

**4-5 Meals/Day**
- Frequent feeding
- Best for: Muscle gain, athletes
- Windows: Every 3-4 hours

**Custom**
- Design your own schedule

#### **Screen 4.5: Schedule Preview** (Unique to NutriSync)
**Purpose**: Show personalized meal windows  
**Content**:
- Full day timeline (7 AM - 10 PM)
- Animated meal windows appearing
- "Your Optimized Schedule:"
  - 🌅 Morning Window: 7-9 AM (Energizing breakfast)
  - ☀️ Midday Window: 12-1 PM (Sustaining lunch)
  - 🌆 Evening Window: 5:30-7 PM (Recovery dinner)
- Calories distributed: 25% / 40% / 35%
- "This schedule will help you [user's goal]"
- "Customize" and "Looks Good" buttons

---

### **5. SETUP SECTION**

#### **Screen 5.1: Dietary Preferences**
**Purpose**: Customize meal suggestions  
**Content**:
```
Any dietary preferences?

□ Vegetarian
□ Vegan
□ Gluten-Free
□ Dairy-Free
□ Keto
□ Paleo
□ None of these ✓

Any foods to avoid?
[Add foods...] +
```

#### **Screen 5.2: Calculating Plan**
**Purpose**: Build anticipation  
**Content**:
- Animated circular progress
- "Creating your personalized nutrition plan..."
- Progress messages cycling:
  - "Analyzing your metabolism..."
  - "Optimizing meal windows..."
  - "Calculating macro targets..."

#### **Screen 5.3: Your Plan Summary**
**Purpose**: Show complete plan  
**Content**:
```
Your NutriSync Plan

Daily Targets:
🔥 1,850 calories
🥩 140g protein
🍞 185g carbs
🥑 65g fat

Meal Windows:
⏰ 3 optimized eating periods
📊 16 hours optimized nutrition
😴 8 hours overnight fast

Expected Results:
📈 85% more stable energy
💪 Reach goal weight by [date]
🎯 Peak performance daily
```

#### **Screen 5.4: Notification Setup**
**Purpose**: Enable meal window reminders  
**Content**:
- "Never miss a meal window"
- Preview of notification styles:
  - "🍽️ Lunch window opens in 15 minutes"
  - "⚡ 30 mins left in dinner window"
  - "✅ Great job completing today's nutrition!"
- "Enable Smart Reminders" button
- "Skip for now" link

#### **Screen 5.5: Account Creation**
**Purpose**: Save user data  
**Content**:
```
Create your account

Email
[email@example.com]

Password
[••••••••]

□ Send me weekly progress insights

[Create Account] - green button

Or continue with:
[🍎 Sign in with Apple]
[📧 Sign in with Google]
```

#### **Screen 5.6: Welcome to NutriSync**
**Purpose**: Successful completion  
**Content**:
- Confetti animation
- "You're all set! 🎉"
- "Your first meal window opens at [time]"
- Preview of main app screen
- "Start Tracking" button (green, full width)

---

## 📊 **Data Collection Summary**

### **Required Information**
- Name, birthdate, sex
- Height, weight, body fat estimate
- Primary and secondary goals
- Daily schedule (wake, work, sleep times)
- Activity level and exercise frequency
- Meal frequency preference
- Email and password

### **Optional Information**
- Weight goal and target date
- Dietary preferences and restrictions
- Apple Health access
- Notification preferences

---

## 🚀 **Implementation Notes**

### **Animation Guidelines**
- Use spring animations for all transitions
- Progress dots animate with scale effect
- Impact numbers use count-up animation
- Meal windows slide in from sides
- Success states use haptic feedback

### **Error Handling**
- All inputs validate in real-time
- Clear error messages below fields
- Can't proceed without required fields
- "Back" navigation always available

### **Skip Options**
- Can skip: dietary preferences, notifications, Apple Health
- Cannot skip: basic info, goals, schedule setup
- "Complete Later" option for account creation

### **Accessibility**
- All screens support Dynamic Type
- VoiceOver labels for all elements
- High contrast mode support
- Animations respect reduce motion setting

---

## 📈 **Success Metrics**

### **Onboarding Completion Rate**
- Target: >85% complete full flow
- Track drop-off points by screen
- A/B test different screen orders

### **Time to Complete**
- Target: <4 minutes total
- Track time per section
- Identify screens causing delays

### **Data Quality**
- Measure skip rates per field
- Track accuracy of estimates
- Monitor profile completion rates

---

## 🎯 **Key Differentiators**

1. **Impact Visualization**: Like Opal, show tangible benefits
2. **Meal Window Education**: Unique to NutriSync
3. **Schedule Preview**: See your plan before committing
4. **Progress Sections**: MacroFactor-style organization
5. **Smart Defaults**: Pre-select common options

---

## 📝 **Testing Checklist**

- [ ] All screens render correctly on all iPhone sizes
- [ ] Animations perform at 60fps
- [ ] Form validation works properly
- [ ] Data persists between screens
- [ ] Back navigation maintains state
- [ ] Skip options work correctly
- [ ] Account creation succeeds
- [ ] Plan calculation is accurate
- [ ] Notifications request appears
- [ ] Success screen shows correct data

---

## 🎨 **Visual Mockup Specifications**

### **Schedule Education Screens (NutriSync Unique)**

#### **Mockup 1: Meal Window Concept Introduction**
```
┌─────────────────────────────────┐
│  ━━━━━  ━━━━━  ●●●●●  ━━━━━  ━━━━━  │ (Progress dots)
│                                 │
│      What are Meal Windows?     │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │    [Animated Timeline]    │  │
│  │    7AM ──────────> 10PM   │  │
│  │                           │  │
│  │  ▓▓▓   ▓▓▓▓▓   ▓▓▓▓      │  │ (Animated blocks)
│  │  8-9   12-1    5:30-7     │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Strategic eating periods that  │
│  optimize your energy, focus,   │
│  and metabolism throughout      │
│  the day.                       │
│                                 │
│  • Eat when your body needs it │
│  • Fast when you don't         │
│  • Aligned with circadian rhythm│
│                                 │
│  [    Continue    ] (green)     │
│                                 │
└─────────────────────────────────┘
```

#### **Mockup 2: Traditional vs. Optimized Comparison**
```
┌─────────────────────────────────┐
│  ━━━━━  ━━━━━  ●●●●●  ━━━━━  ━━━━━  │
│                                 │
│    Traditional vs. Optimized    │
│                                 │
│  ┌─── Traditional Eating ────┐  │
│  │ 😴 🥱 😐 😑 😴              │  │
│  │ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓           │  │
│  │ Energy crashes all day     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌─── NutriSync Windows ─────┐  │
│  │ 🚀 💪 ⚡ 🎯 😌              │  │
│  │ ▓▓▓   ▓▓▓▓▓   ▓▓▓▓        │  │
│  │ Sustained peak energy      │  │
│  └───────────────────────────┘  │
│                                 │
│  📈 85% more stable energy      │
│  🎯 Better focus & productivity │
│  💤 Improved sleep quality      │
│                                 │
│  [    See My Schedule    ]      │
│                                 │
└─────────────────────────────────┘
```

#### **Mockup 3: Personalized Benefits Calculator**
```
┌─────────────────────────────────┐
│  ━━━━━  ━━━━━  ●●●●●  ━━━━━  ━━━━━  │
│                                 │
│   Your Optimization Potential   │
│                                 │
│  Based on your profile, meal    │
│  windows can help you:          │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ⚡ Energy Improvement     │  │
│  │  ████████████░░  87%      │  │
│  │                           │  │
│  │  🎯 Focus Enhancement      │  │
│  │  ██████████░░░░  73%      │  │
│  │                           │  │
│  │  💪 Goal Achievement       │  │
│  │  █████████████░  92%      │  │
│  │                           │  │
│  │  😴 Sleep Quality          │  │
│  │  ████████░░░░░░  65%      │  │
│  └───────────────────────────┘  │
│                                 │
│  That's 312 more productive     │
│  hours per year!                │
│                                 │
│  [   Optimize My Schedule   ]   │
│                                 │
└─────────────────────────────────┘
```

#### **Mockup 4: Interactive Schedule Builder**
```
┌─────────────────────────────────┐
│  ━━━━━  ━━━━━  ━━━━━  ●●●●●  ━━━━━  │
│                                 │
│    Build Your Ideal Day         │
│                                 │
│  When do you need energy most?  │
│  (Drag to adjust windows)       │
│                                 │
│  7AM ─────────────────── 10PM   │
│  │                           │  │
│  │ 🌅 ███                    │  │ Morning
│  │      ⇄                    │  │ (Draggable)
│  │                           │  │
│  │        ☀️ █████           │  │ Midday
│  │           ⇄               │  │ (Draggable)
│  │                           │  │
│  │              🌆 ████      │  │ Evening
│  │                 ⇄         │  │ (Draggable)
│  └───────────────────────────┘  │
│                                 │
│  Total eating: 10 hours         │
│  Fasting period: 14 hours       │
│                                 │
│  [Reset] [Apply This Schedule]  │
│                                 │
└─────────────────────────────────┘
```

#### **Mockup 5: Success Visualization**
```
┌─────────────────────────────────┐
│  ━━━━━  ━━━━━  ━━━━━  ━━━━━  ●●●●● │
│                                 │
│    Your Journey Starts Now!     │
│                                 │
│     ┌─────────────────┐         │
│     │   ⭐ Week 1     │         │
│     │ Learn the rhythm│         │
│     └────────┬────────┘         │
│              │                  │
│     ┌────────▼────────┐         │
│     │   🚀 Week 2     │         │
│     │ Feel the energy │         │
│     └────────┬────────┘         │
│              │                  │
│     ┌────────▼────────┐         │
│     │   💪 Week 3     │         │
│     │See the results  │         │
│     └────────┬────────┘         │
│              │                  │
│     ┌────────▼────────┐         │
│     │   🎯 Week 4+    │         │
│     │ Live optimized  │         │
│     └─────────────────┘         │
│                                 │
│  [  Start My Transformation  ]  │
│                                 │
└─────────────────────────────────┘
```

---

## 🎬 **Animation Specifications**

### **Timeline Animations**
- Meal windows fade in sequentially
- Gentle pulse effect on active windows
- Smooth slide transitions between times
- Energy level indicators animate up/down

### **Progress Animations**
- Percentage bars fill from left to right
- Numbers count up with easing
- Success checkmarks scale in with bounce
- Confetti particles for completion

### **Interactive Elements**
- Drag handles appear on hover/touch
- Windows snap to 30-minute increments
- Real-time feedback on window changes
- Haptic feedback on adjustments

---

## 📐 **Component Library**

### **Window Block Component**
```swift
struct MealWindowBlock: View {
    let startTime: String
    let endTime: String
    let icon: String
    let purpose: String
    let calories: Int
    let isActive: Bool
    
    // Renders as colored block with:
    // - Icon and time range
    // - Purpose label
    // - Calorie allocation
    // - Pulse animation if active
}
```

### **Progress Ring Component**
```swift
struct ProgressRing: View {
    let progress: Double
    let label: String
    let icon: String
    let color: Color
    
    // Circular progress indicator
    // Animated fill effect
    // Center icon and percentage
}
```

### **Timeline Component**
```swift
struct DayTimeline: View {
    let windows: [MealWindow]
    let currentTime: Date?
    
    // Horizontal timeline 7AM-10PM
    // Meal windows as blocks
    // Current time indicator
    // Drag gesture support
}
```

---

*This onboarding flow combines the best of Opal's impactful messaging with MacroFactor's thorough data collection, while highlighting NutriSync's unique meal window system.*