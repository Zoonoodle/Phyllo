# Research: Daily Context Voice/Text Input for AI Schedule Generation

**Date:** 2025-10-02
**Purpose:** Research current implementation to build a voice/text input view for capturing daily context (similar to "what's your day like today?") that feeds directly into AI window generation.

---

## 1. Current DailySync Workflow & UI Patterns

### DailySyncCoordinator Structure
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/CheckIn/DailySync/DailySyncCoordinator.swift`

**Key Characteristics:**
- **Multi-step flow** with onboarding-style navigation (progress dots, back/next buttons)
- **Dynamic screen flow** based on context (time of day, user history)
- **Screen types:**
  - `greeting` - Welcome screen with contextual icon and message
  - `weightCheck` - Smart weight tracking (goal-based frequency)
  - `alreadyEaten` - Quick meal logging for already consumed food
  - `schedule` - Work hours and workout timing
  - `energy` - Current energy level selection
  - `complete` - Confirmation and window generation trigger

**Current Data Collection:**
```swift
struct DailySync {
    let syncContext: SyncContext      // Time of day context (earlyMorning, midday, etc.)
    let alreadyConsumed: [QuickMeal]  // Previously eaten meals
    let workSchedule: TimeRange?      // Work start/end times
    let workoutTime: Date?            // Planned workout time
    let currentEnergy: SimpleEnergyLevel // low/good/high
    let specialEvents: [SpecialEvent] // Meetings, travel, etc.
}
```

**UI Components Used:**
- `DailySyncHeader(title:subtitle:)` - Title and subtitle text
- `DailySyncProgressDots` - Visual progress indicator
- `DailySyncOptionButton` - Selectable options with icon/title/subtitle
- `DailySyncBottomNav(onBack:onNext:nextButtonTitle:showBack:)` - Navigation controls
- `TimePickerCompact` - Time selection UI

### Current Limitations for Daily Context Input
1. **No free-form text/voice input** - Only structured selections (toggles, pickers, pre-defined options)
2. **Work schedule is rigid** - Only work start/end times, no description of work type or flexibility
3. **Activities are limited** - Only workout time, no meetings, social events, travel details
4. **No "day description"** - No way to say "I have back-to-back meetings until 3pm" or "working from home today, flexible schedule"

---

## 2. AI Window Generation: Current Implementation

### AIWindowGenerationService
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift`

**Current Input Parameters:**
```swift
func generateWindows(
    for profile: UserProfile,
    checkIn: MorningCheckInData?,
    dailySync: DailySync? = nil,
    date: Date
) async throws -> (windows: [MealWindow], dayPurpose: DayPurpose?)
```

**What It Currently Receives:**
1. **User Profile Data:**
   - Goal, age, gender, weight, height, activity level
   - Daily calorie/macro targets
   - Dietary restrictions/preferences
   - Work schedule type (standard, night shift, remote, etc.)
   - Fasting protocol
   - Meal timing preferences

2. **Morning Check-In Data (MorningCheckInData):**
   - Wake time & planned bedtime
   - Sleep quality (0-10)
   - Energy level (0-10)
   - Hunger level (0-10)
   - Day focus (work, relaxing, family, fitness, etc.)
   - Planned activities (array of strings like "Workout 5:30pm-6:30pm")
   - Window preference (specific count, range, or auto)

3. **Daily Sync Data (DailySync):**
   - Already consumed meals with calorie estimates
   - Work schedule (start/end times)
   - Workout time
   - Current energy level
   - Special events (type + time + duration)

**How AI Uses This Data:**
The service builds a comprehensive prompt that includes:
- All profile details and goals
- Sleep/energy/hunger data
- **Planned activities as free-text strings** ← Key insight!
- Already eaten meals and remaining macros
- Work schedule constraints
- Workout timing for pre/post-workout windows

**Activity Parsing Logic:**
```swift
// WorkoutParser extracts workout info from activity strings
let patterns = [
    "workout.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",
    "gym.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",
    "training.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",
    "exercise.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",
    "run.*?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m)?",
    // etc.
]
```

The AI prompt currently accepts `plannedActivities: [String]` which are formatted descriptions like:
- "Workout 5:30pm-6:30pm"
- "Lunch meeting 12:30pm-1:30pm"
- "Work 9am to 5pm"

**Current Schedule Type Detection:**
```swift
enum ScheduleType {
    case earlyBird      // Wake: 4-7am
    case standard       // Wake: 7-10am
    case nightOwl       // Wake: 10am-2pm
    case nightShift     // Wake: 2pm+ or sleep during day
}
```

This affects window naming and timing logic.

---

## 3. Voice Input Implementation Patterns

### Three Voice Input Views Exist:

#### A. RealVoiceInputView (Full-Featured Meal Logging)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Scan/Camera/RealVoiceInputView.swift`

**Key Features:**
- Captured photo background (blurred)
- Full instructional content with tips
- Pause/resume during recording
- Long-press to edit transcription manually
- Info button with detailed tips sheet
- Skip option for no voice input

**UI Pattern:**
```swift
VStack {
    // Top: Info button
    HStack { Spacer(); Button("info.circle") }

    // Middle: Instructions OR transcribed text
    if transcribedText.isEmpty {
        instructionalContent  // Examples and tips
    } else {
        Text(transcribedText) // With edit capability
    }

    Spacer()

    // Center: Listening indicator (animated circle)
    listeningIndicator

    Spacer()

    // Bottom: Controls
    bottomControls  // Cancel + Done buttons
}
```

**Speech Recognition Setup:**
```swift
@State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
@State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
@State private var recognitionTask: SFSpeechRecognitionTask?
@State private var audioEngine = AVAudioEngine()

// Request permissions
SFSpeechRecognizer.requestAuthorization { authStatus in ... }

// Start recording
recognitionRequest.shouldReportPartialResults = true
audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
    self.recognitionRequest?.append(buffer)
}
```

#### B. QuickVoiceAddView (Simplified for Quick Meal Entry)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/CheckIn/DailySync/QuickVoiceAddView.swift`

**Differences from RealVoiceInputView:**
- No photo background (pure black)
- Simpler instructions (just 3 examples)
- Uses `MealCaptureService.shared.startMealAnalysis()` to process
- Compact header with clear context ("Quick Add Meal")
- Processing state with spinner

**Pattern for AI Integration:**
```swift
private func addQuickMeal() {
    isProcessing = true
    Task {
        let _ = try await mealCaptureService.startMealAnalysis(
            image: nil,
            voiceTranscript: transcribedText,
            timestamp: Date()
        )
        onComplete(transcribedText)
        dismiss()
    }
}
```

#### C. PastMealVoiceInputView (Window-Specific Logging)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Focus/PastMealVoiceInputView.swift`

**Unique Features:**
- Takes a `MealWindow` parameter for context
- Shows window name and time range in header
- Uses window's startTime as meal timestamp
- Contextual instructions: "What did you eat for [Window Name]?"

**Example:**
```swift
Text("What did you eat for")
Text(windowTitle)  // "Breakfast", "Lunch", etc.
Text(formatTimeRange(start: window.startTime, end: window.endTime))
```

### Common Voice Input Patterns (Reusable Components)

**1. Listening Indicator (White Circle with Waveform):**
```swift
ZStack {
    // Outer pulse
    Circle()
        .fill(Color.white.opacity(0.1))
        .frame(width: 220, height: 220)
        .scaleEffect(circleScale)

    // Main white circle
    Circle()
        .fill(Color.white)
        .frame(width: 180, height: 180)

    // Waveform OR mic icon
    if isListening {
        HStack(spacing: 6) {
            ForEach(0..<5) { index in
                Capsule()
                    .fill(Color.black)
                    .frame(width: 5, height: audioLevels[index] * 45)
            }
        }
    } else {
        Image(systemName: "mic.fill")
    }
}
.onTapGesture { startRecording() }
```

**2. Editable Text Display:**
```swift
if isEditingText {
    TextField("Edit", text: $editableText, axis: .vertical)
        .focused($isTextFieldFocused)
} else {
    Text(transcribedText)
        .onLongPressGesture(minimumDuration: 0.5) {
            editableText = transcribedText
            isEditingText = true
            isTextFieldFocused = true
        }
}
```

**3. Bottom Controls Pattern:**
```swift
HStack(spacing: 20) {
    // Cancel
    Button(action: { dismiss() }) {
        HStack {
            Image(systemName: "xmark")
            Text("Cancel")
        }
        .foregroundColor(.white.opacity(0.8))
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(30)
    }

    // Done
    Button(action: { submit() }) {
        HStack {
            Image(systemName: "checkmark")
            Text("Done")
        }
        .foregroundColor(.black)
        .padding()
        .background(Color.nutriSyncAccent)
        .cornerRadius(30)
    }
    .disabled(transcribedText.isEmpty)
}
```

---

## 4. Data Models Relevant to Daily Context

### UserProfile (Extended Fields for Context)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserProfile.swift`

**Schedule-Related Fields:**
```swift
var earliestMealHour: Int?
var latestMealHour: Int?
var workSchedule: WorkSchedule = .standard  // standard/night/earlyMorning/evening/flexible/remote
var typicalWakeTime: Date?
var typicalSleepTime: Date?
var fastingProtocol: FastingProtocol = .none
```

**WorkSchedule enum:**
```swift
enum WorkSchedule: String {
    case standard = "standard"        // 9-5
    case earlyMorning = "earlyMorning"
    case evening = "evening"
    case night = "night"
    case flexible = "flexible"
    case remote = "remote"
}
```

### MorningCheckInData (Legacy - Being Replaced)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/CheckInData.swift`

**Relevant Fields:**
```swift
struct MorningCheckIn {
    let wakeTime: Date
    let plannedBedtime: Date
    let sleepQuality: Int
    let energyLevel: Int
    let hungerLevel: Int
    let dayFocus: Set<DayFocus>  // work, relaxing, family, friends, fitness, etc.
    let plannedActivities: [String]  // ← KEY: Free-form activity descriptions
    let windowPreference: WindowPreference
}
```

**DayFocus Options:**
```swift
enum DayFocus: String {
    case work, relaxing, family, friends, date, pets, fitness, selfCare,
         partner, reading, learning, travel
}
```

### DailySync (Current Simplified Model)
**File:** `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/DailySyncData.swift`

**Current Structure:**
```swift
struct DailySync {
    let syncContext: SyncContext
    let alreadyConsumed: [QuickMeal]
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let currentEnergy: SimpleEnergyLevel
    let specialEvents: [SpecialEvent]
}
```

**Missing for Daily Context:**
- ❌ No free-form text description of the day
- ❌ No meeting details
- ❌ No travel plans
- ❌ No flexibility indicators
- ❌ No stress level or mood context
- ❌ No social plans or commitments

---

## 5. Constraints & Patterns to Follow

### Design System (From CLAUDE.md)
```swift
// Colors
Color.phylloBackground = Color(hex: "0a0a0a")      // Near black
Color.phylloCard = Color.white.opacity(0.03)
Color.phylloAccent = Color(hex: "C0FF73")          // Signature lime green
Color.phylloText = Color.white
Color.phylloTextSecondary = Color.white.opacity(0.7)

// Components
PhylloDesignSystem.cornerRadius = 16
PhylloDesignSystem.padding = 16
PhylloDesignSystem.spacing = 12
PhylloDesignSystem.animation = Animation.spring(response: 0.4, dampingFraction: 0.8)
```

### DailySync Flow Pattern (From DailySyncCoordinator)
1. **Progress Dots** at top (if multi-step)
2. **Header** with title + subtitle (using `DailySyncHeader`)
3. **Main Content** area (scrollable if needed)
4. **Bottom Navigation** (using `DailySyncBottomNav`)

### Voice Input Best Practices (From existing views)
1. **Always request permissions first** (`checkSpeechAuthorization()`)
2. **Show permission alert** if denied with "Open Settings" button
3. **Support pause/resume** for longer recordings
4. **Enable manual editing** (long-press to edit)
5. **Real-time transcription** with `shouldReportPartialResults = true`
6. **Audio level visualization** for user feedback
7. **Clear visual states**: idle → listening → paused → transcribed

---

## 6. Technical Implementation Options

### Option 1: Add to DailySync Flow (Recommended)
**Approach:** Insert a new screen in `DailySyncCoordinator` after `schedule` screen

**Pros:**
- Fits existing flow and patterns
- User is already in "sync mode"
- Data naturally flows into window generation
- Reuses existing navigation and UI components

**Cons:**
- Makes DailySync longer (but only for users who want to provide context)
- Need to make it optional/skippable

**Implementation:**
```swift
enum DailySyncScreen {
    case greeting
    case weightCheck
    case alreadyEaten
    case schedule
    case dailyContext  // ← NEW
    case energy
    case complete
}

// In setupFlow()
screens.append(.dailyContext)  // Add conditionally
```

### Option 2: Standalone "Daily Context" Entry Point
**Approach:** Separate view accessible from Focus tab or main menu

**Pros:**
- Doesn't clutter DailySync
- Can be used independently
- More flexible timing

**Cons:**
- Separate navigation flow to build
- Might feel disconnected from window generation
- Harder to ensure it's completed before generating windows

### Option 3: Replace Current Schedule Screen
**Approach:** Enhance the existing schedule screen with voice/text input option

**Pros:**
- No new screens added
- Natural evolution of existing UI
- Keeps DailySync concise

**Cons:**
- Current schedule screen already has work/workout pickers
- Might be confusing to mix structured + unstructured input

---

## 7. Recommended Approach & Data Structure

### Proposed View: `DailyContextInputView`

**Purpose:** Capture free-form daily context via voice or text that AI can use to optimize meal windows

**When to Show:**
- As part of DailySync flow (after schedule screen)
- Make it **optional** with "Skip" option
- Show example prompts to guide user

**UI Structure (Based on Voice Input Patterns):**
```swift
struct DailyContextInputView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var contextText = ""
    @State private var useVoiceInput = true  // Toggle between voice/text

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots (if in DailySync flow)
            DailySyncProgressDots(...)

            // Header
            DailySyncHeader(
                title: "What's your day like?",
                subtitle: "Help me optimize your meal timing"
            )

            Spacer()

            // Voice input section (similar to QuickVoiceAddView)
            if useVoiceInput {
                listeningIndicator
            } else {
                // Text input area
                TextEditor(text: $contextText)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }

            // Example prompts (when empty)
            if contextText.isEmpty {
                examplePrompts
            }

            Spacer()

            // Toggle voice/text + Navigation
            VStack(spacing: 16) {
                Button("Switch to \(useVoiceInput ? "text" : "voice") input") {
                    useVoiceInput.toggle()
                }

                DailySyncBottomNav(
                    onBack: { viewModel.previousScreen() },
                    onNext: {
                        viewModel.saveDailyContext(contextText)
                        viewModel.nextScreen()
                    },
                    nextButtonTitle: contextText.isEmpty ? "Skip" : "Continue"
                )
            }
        }
    }
}
```

**Example Prompts to Show:**
- "I have back-to-back meetings from 9am to 3pm"
- "Working from home today, pretty flexible"
- "Gym at 6pm, then dinner with friends at 8pm"
- "Early morning client calls, need energy boost before noon"
- "Night shift tonight, sleeping during the day"
- "Long drive to the airport at 2pm, need portable meals"

### Updated DailySync Model:
```swift
struct DailySync {
    // Existing fields...
    let syncContext: SyncContext
    let alreadyConsumed: [QuickMeal]
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let currentEnergy: SimpleEnergyLevel
    let specialEvents: [SpecialEvent]

    // NEW: Free-form daily context
    let dailyContextDescription: String?  // ← Voice/text input

    // Computed helper
    var hasDetailedContext: Bool {
        return dailyContextDescription?.isEmpty == false
    }
}
```

### AI Prompt Integration:
The `buildPrompt()` in `AIWindowGenerationService` would add:
```swift
if let context = dailySync?.dailyContextDescription, !context.isEmpty {
    prompt += """

    ## Today's Context (User's Own Words)
    "\(context)"

    IMPORTANT: Parse this description for:
    - Meetings, calls, or work commitments (adjust meal timing to avoid interruptions)
    - Travel plans (suggest portable meals)
    - Social events (plan around them)
    - Flexibility indicators (e.g., "working from home" = more flexible windows)
    - Stress or busy periods (prioritize convenient, quick meals)
    - Energy needs (e.g., "early morning meetings" = need breakfast energy boost)
    """
}
```

---

## 8. Implementation Checklist

### Phase 1: UI Component (Voice Input View)
- [ ] Create `DailyContextInputView.swift`
- [ ] Implement voice recording (copy pattern from `QuickVoiceAddView`)
- [ ] Add text input fallback (TextEditor)
- [ ] Design example prompts section
- [ ] Add voice/text toggle button
- [ ] Implement edit functionality (long-press)
- [ ] Handle permissions properly

### Phase 2: Data Flow Integration
- [ ] Add `dailyContextDescription: String?` to `DailySync` model
- [ ] Update `DailySync.toFirestore()` to save new field
- [ ] Update `DailySync.fromFirestore()` to load new field
- [ ] Add to `DailySyncViewModel` state
- [ ] Insert into `DailySyncCoordinator` screen flow

### Phase 3: AI Prompt Enhancement
- [ ] Update `buildPrompt()` in `AIWindowGenerationService`
- [ ] Add context parsing instructions for AI
- [ ] Test with various context descriptions
- [ ] Handle edge cases (empty, very long descriptions)

### Phase 4: Optional Enhancements
- [ ] Add context suggestions based on time of day
- [ ] Save common contexts as templates
- [ ] Show previous day's context as reference
- [ ] Add "Use yesterday's context" quick option

---

## 9. Key Files Reference

**UI Components:**
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/CheckIn/DailySync/DailySyncCoordinator.swift` - Main flow
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/CheckIn/DailySync/QuickVoiceAddView.swift` - Voice input pattern
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Views/Scan/Camera/RealVoiceInputView.swift` - Full-featured voice input

**Data Models:**
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/DailySyncData.swift` - DailySync struct
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/CheckInData.swift` - MorningCheckIn (legacy reference)
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Models/UserProfile.swift` - User preferences

**AI Service:**
- `/Users/brennenprice/Documents/Phyllo/NutriSync/Services/AI/AIWindowGenerationService.swift` - Window generation

---

## 10. Next Steps

### To Begin Implementation:
1. **START NEW SESSION** for Phase 2 (Planning)
2. Provide this research document: `@research-daily-context-input.md`
3. User should specify preferences:
   - Where to insert in DailySync flow?
   - Voice-first or text-first?
   - Required or optional step?
   - Example prompts style?

### Open Questions for User:
1. Should this replace the current schedule screen or be a separate screen?
2. Should we keep structured inputs (work schedule, workout time) AND add free-form context?
3. How important is the voice input vs. just allowing text?
4. Should we provide AI-suggested prompts based on previous days' patterns?

---

**Research completed. Ready for planning phase in new session.**
