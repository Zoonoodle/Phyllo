# Implementation Plan: Daily Context Voice Input (Replaces Energy Screen)

**Date:** 2025-10-02
**Based on:** `research-daily-context-input.md`
**Status:** Planning Phase - Awaiting User Approval

---

## Executive Summary

**Goal:** Replace the current "How's your energy?" selection screen in DailySync with a rich voice/text input view that captures daily context for AI window generation.

**Key Design Decisions:**
1. ✅ **Replaces energy screen** (last screen before complete)
2. ✅ **Voice-first** with visible text input option
3. ✅ **Skippable but discouraged** (subtle skip option)
4. ✅ **Keep structured pickers** (work schedule, workout time remain)
5. ✅ **1 example + topic suggestions** (not full example sentences)
6. ✅ **Editable transcription** (long-press to edit)
7. ✅ **Character limit display** (show character count)
8. ✅ **Draft saving** (preserve input when going back)
9. ✅ **AI insights display** (show what AI understood)
10. ✅ **Delete old energy view** (completely remove)

**Impact:**
- Simplified DailySync flow (energy selection merged into context)
- Richer AI input for window generation
- More natural user interaction (speak freely vs select from list)

---

## Architecture Overview

### Data Flow
```
User speaks/types context
    ↓
DailyContextInputView captures transcript
    ↓
DailySyncViewModel.saveDailyContext()
    ↓
DailySync model (new field: dailyContextDescription)
    ↓
AIWindowGenerationService receives context
    ↓
AI parses for energy, meetings, flexibility, etc.
    ↓
Optimized meal windows generated
```

### File Changes Required

**New Files:**
1. `NutriSync/Views/CheckIn/DailySync/DailyContextInputView.swift` - Main UI

**Modified Files:**
1. `NutriSync/Models/DailySyncData.swift` - Add context field
2. `NutriSync/ViewModels/DailySyncViewModel.swift` - Add save method
3. `NutriSync/Views/CheckIn/DailySync/DailySyncCoordinator.swift` - Replace energy screen
4. `NutriSync/Services/AI/AIWindowGenerationService.swift` - Enhanced prompt
5. `NutriSync/Services/DataProvider/FirebaseDataProvider.swift` - Save/load context

---

## Detailed Implementation Plan

### Phase 1: Data Model Extension

#### 1.1 Update DailySync Model
**File:** `NutriSync/Models/DailySyncData.swift`

**Changes:**
```swift
struct DailySync {
    // Existing fields
    let syncContext: SyncContext
    let alreadyConsumed: [QuickMeal]
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let specialEvents: [SpecialEvent]

    // REMOVED: currentEnergy field (migrated to context parsing)

    // NEW: Free-form daily context
    let dailyContextDescription: String?

    // NEW: Computed property for backward compatibility
    var inferredEnergyLevel: SimpleEnergyLevel? {
        guard let context = dailyContextDescription?.lowercased() else { return nil }

        // AI will parse, but we can infer for legacy code
        if context.contains("tired") || context.contains("exhausted") || context.contains("low energy") {
            return .low
        } else if context.contains("great") || context.contains("high energy") || context.contains("feeling good") {
            return .high
        } else {
            return .good  // Default
        }
    }

    var hasDetailedContext: Bool {
        guard let context = dailyContextDescription else { return false }
        return !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

**Firestore Schema:**
```swift
// Update toFirestore()
func toFirestore() -> [String: Any] {
    var data: [String: Any] = [
        "syncContext": syncContext.rawValue,
        // ... existing fields ...
    ]

    // Add context if present
    if let context = dailyContextDescription {
        data["dailyContextDescription"] = context
    }

    // REMOVED: currentEnergy field

    return data
}

// Update fromFirestore()
static func fromFirestore(_ data: [String: Any]) -> DailySync? {
    // ... existing parsing ...

    let contextDescription = data["dailyContextDescription"] as? String

    return DailySync(
        // ... existing fields ...
        dailyContextDescription: contextDescription
    )
}
```

**Testing:**
- ✅ Compile check with `swiftc -parse`
- ✅ Verify Firestore save/load
- ✅ Test empty/nil context handling
- ✅ Test inferredEnergyLevel computation

---

### Phase 2: UI Component Creation

#### 2.1 Create DailyContextInputView
**File:** `NutriSync/Views/CheckIn/DailySync/DailyContextInputView.swift`

**Component Structure:**
```swift
import SwiftUI
import Speech
import AVFoundation

struct DailyContextInputView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @Environment(\.dismiss) private var dismiss

    // Voice input state
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    // UI state
    @State private var transcribedText = ""
    @State private var editableText = ""
    @State private var isListening = false
    @State private var isPaused = false
    @State private var isEditingText = false
    @State private var useVoiceInput = true  // Default to voice
    @State private var showPermissionAlert = false
    @State private var audioLevels: [CGFloat] = [0.3, 0.5, 0.3, 0.5, 0.3]
    @State private var circleScale: CGFloat = 1.0
    @FocusState private var isTextFieldFocused: Bool

    // NEW: Character limit
    private let maxCharacters = 500

    // Computed character count
    private var characterCount: Int {
        transcribedText.count
    }

    private var isApproachingLimit: Bool {
        characterCount >= maxCharacters - 50  // Warning at 450 characters
    }

    private var isOverLimit: Bool {
        characterCount > maxCharacters
    }

    // Topics to suggest (not full examples)
    private let suggestionTopics = [
        "Meetings or calls",
        "Energy level",
        "Workout plans",
        "Social events",
        "Work schedule",
        "Travel plans",
        "Sleep quality",
        "Stress level"
    ]

    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                DailySyncProgressDots(
                    currentStep: viewModel.currentScreenIndex,
                    totalSteps: viewModel.screens.count
                )
                .padding(.top, 8)

                // Header
                DailySyncHeader(
                    title: "How's your day looking?",
                    subtitle: "Tell me about your day so I can optimize your meal timing"
                )
                .padding(.horizontal)
                .padding(.top, 24)

                Spacer()

                // Main content area
                if useVoiceInput {
                    voiceInputSection
                } else {
                    textInputSection
                }

                Spacer()

                // NEW: Character count display
                characterCountDisplay
                    .padding(.bottom, 8)

                // Input mode toggle
                inputModeToggle
                    .padding(.bottom, 16)

                // Bottom navigation
                DailySyncBottomNav(
                    onBack: {
                        stopRecording()
                        // NEW: Save draft when going back
                        saveDraft()
                        viewModel.previousScreen()
                    },
                    onNext: {
                        stopRecording()
                        saveAndContinue()
                    },
                    nextButtonTitle: transcribedText.isEmpty ? "Skip" : "Continue",
                    showBack: true
                )
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            checkSpeechAuthorization()
            // NEW: Load draft if available
            loadDraft()
        }
        .onDisappear {
            stopRecording()
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable microphone access in Settings to use voice input.")
        }
    }

    // MARK: - Voice Input Section

    private var voiceInputSection: some View {
        VStack(spacing: 24) {
            // Transcribed text or instructions
            if isEditingText {
                // Editable text field
                TextField("Edit your input", text: $editableText, axis: .vertical)
                    .font(.body)
                    .foregroundColor(.phylloText)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                    .frame(maxHeight: 200)
                    .padding(.horizontal, 32)
            } else if !transcribedText.isEmpty {
                // Display transcribed text
                ScrollView {
                    Text(transcribedText)
                        .font(.body)
                        .foregroundColor(.phylloText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxHeight: 200)
                .onLongPressGesture(minimumDuration: 0.5) {
                    editableText = transcribedText
                    isEditingText = true
                    isTextFieldFocused = true
                }

                // Edit hint
                Text("Long press to edit")
                    .font(.caption)
                    .foregroundColor(.phylloTextTertiary)
            } else {
                // Instructions when empty
                instructionalContent
            }

            Spacer().frame(height: 40)

            // Listening indicator (center)
            listeningIndicator

            Spacer().frame(height: 40)

            // Pause/Resume button (when recording)
            if isListening {
                Button(action: togglePauseResume) {
                    HStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.phylloText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(24)
                }
            }
        }
    }

    private var instructionalContent: some View {
        VStack(spacing: 20) {
            // Single example
            VStack(alignment: .leading, spacing: 8) {
                Text("Example:")
                    .font(.caption)
                    .foregroundColor(.phylloTextSecondary)

                Text("\"I have back-to-back meetings until 3pm, then gym at 6. Feeling pretty tired today, didn't sleep great.\"")
                    .font(.body)
                    .foregroundColor(.phylloText)
                    .italic()
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            // Topic suggestions (not full examples)
            VStack(alignment: .leading, spacing: 12) {
                Text("What to mention:")
                    .font(.caption)
                    .foregroundColor(.phylloTextSecondary)
                    .padding(.horizontal, 32)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(suggestionTopics, id: \.self) { topic in
                        Text(topic)
                            .font(.caption)
                            .foregroundColor(.phylloTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 32)
            }

            // Tap to start hint
            Text("Tap the circle to start speaking")
                .font(.subheadline)
                .foregroundColor(.nutriSyncAccent)
                .padding(.top, 8)
        }
    }

    private var listeningIndicator: some View {
        ZStack {
            // Outer pulse (when listening)
            if isListening && !isPaused {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 220, height: 220)
                    .scaleEffect(circleScale)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            circleScale = 1.15
                        }
                    }
            }

            // Main white circle
            Circle()
                .fill(isListening && !isPaused ? Color.white : Color.white.opacity(0.1))
                .frame(width: 180, height: 180)

            // Waveform OR mic icon
            if isListening && !isPaused {
                // Animated waveform
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 5, height: audioLevels[index] * 45)
                            .animation(
                                Animation.easeInOut(duration: 0.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: audioLevels[index]
                            )
                    }
                }
                .onAppear {
                    startAudioLevelAnimation()
                }
            } else {
                // Mic icon (idle state)
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isListening ? Color.black : Color.white)
            }
        }
        .onTapGesture {
            if !isListening {
                startRecording()
            } else if !isPaused {
                stopRecording()
            }
        }
    }

    // MARK: - Text Input Section

    private var textInputSection: some View {
        VStack(spacing: 16) {
            TextEditor(text: $transcribedText)
                .font(.body)
                .foregroundColor(.phylloText)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .frame(height: 200)
                .padding(.horizontal, 32)
                .overlay(
                    Group {
                        if transcribedText.isEmpty {
                            Text("Type your daily context here...")
                                .foregroundColor(.phylloTextTertiary)
                                .padding(.horizontal, 40)
                                .padding(.top, 40)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )

            // Show suggestions
            if transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What to mention:")
                        .font(.caption)
                        .foregroundColor(.phylloTextSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(suggestionTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .foregroundColor(.phylloTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Character Count Display

    private var characterCountDisplay: some View {
        HStack(spacing: 4) {
            Text("\(characterCount)/\(maxCharacters)")
                .font(.caption)
                .foregroundColor(isOverLimit ? .red : (isApproachingLimit ? .orange : .phylloTextTertiary))

            if isOverLimit {
                Text("(too long, will be truncated)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .opacity(transcribedText.isEmpty ? 0 : 1)
    }

    // MARK: - Input Mode Toggle

    private var inputModeToggle: some View {
        Button(action: {
            if isListening {
                stopRecording()
            }
            useVoiceInput.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: useVoiceInput ? "keyboard" : "mic.fill")
                    .font(.system(size: 16))
                Text(useVoiceInput ? "Switch to text input" : "Switch to voice input")
                    .font(.subheadline)
            }
            .foregroundColor(.phylloTextSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
    }

    // MARK: - Speech Recognition Methods

    private func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    showPermissionAlert = true
                @unknown default:
                    break
                }
            }
        }
    }

    private func startRecording() {
        // Check permission
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            showPermissionAlert = true
            return
        }

        // Stop any existing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        // Start recording
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                transcribedText = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                stopRecording()
            }
        }

        isListening = true
        isPaused = false
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        isListening = false
        isPaused = false
        circleScale = 1.0
    }

    private func togglePauseResume() {
        if isPaused {
            // Resume
            do {
                try audioEngine.start()
                isPaused = false
            } catch {
                print("Failed to resume: \(error)")
            }
        } else {
            // Pause
            audioEngine.pause()
            isPaused = true
        }
    }

    private func startAudioLevelAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isListening && !isPaused else {
                timer.invalidate()
                return
            }

            for i in 0..<audioLevels.count {
                audioLevels[i] = CGFloat.random(in: 0.3...1.0)
            }
        }
    }

    // MARK: - Draft Management

    private func loadDraft() {
        // Load saved draft from UserDefaults
        if let draft = UserDefaults.standard.string(forKey: "dailyContextDraft") {
            transcribedText = draft
        }
    }

    private func saveDraft() {
        // Save draft to UserDefaults for persistence
        if !transcribedText.isEmpty {
            UserDefaults.standard.set(transcribedText, forKey: "dailyContextDraft")
        }
    }

    private func clearDraft() {
        // Clear draft after successful save
        UserDefaults.standard.removeObject(forKey: "dailyContextDraft")
    }

    // MARK: - Save and Continue

    private func saveAndContinue() {
        // Use edited text if available, otherwise transcribed
        var finalText = isEditingText ? editableText : transcribedText

        // NEW: Truncate if over limit
        if finalText.count > maxCharacters {
            finalText = String(finalText.prefix(maxCharacters))
        }

        // Save to view model
        viewModel.saveDailyContext(finalText)

        // NEW: Clear draft after successful save
        clearDraft()

        // Move to next screen (complete)
        viewModel.nextScreen()
    }
}

// MARK: - Preview

#Preview {
    DailyContextInputView(viewModel: DailySyncViewModel())
        .environmentObject(FirebaseDataProvider.shared)
}
```

**Key Features:**
1. ✅ Voice-first with prominent text toggle
2. ✅ Single example + topic suggestions (not full sentences)
3. ✅ Editable transcription (long-press)
4. ✅ Skip discouraged (button says "Skip" only when empty, "Continue" when filled)
5. ✅ Listening indicator with animated waveform
6. ✅ Pause/resume during recording
7. ✅ Permission handling with alert

**Testing:**
- ✅ Compile check with `swiftc -parse`
- ✅ Test voice recording and transcription
- ✅ Test text input mode
- ✅ Test mode switching
- ✅ Test edit functionality
- ✅ Test skip vs continue states

---

### Phase 3: View Model Integration

#### 3.1 Update DailySyncViewModel
**File:** `NutriSync/ViewModels/DailySyncViewModel.swift`

**Changes:**
```swift
@Observable
class DailySyncViewModel {
    // Existing state...

    // NEW: Store daily context
    var dailyContextDescription: String?

    // NEW: Save method
    func saveDailyContext(_ context: String?) {
        self.dailyContextDescription = context
    }

    // UPDATE: buildDailySync() to include context
    func buildDailySync() -> DailySync {
        return DailySync(
            syncContext: determineSyncContext(),
            alreadyConsumed: alreadyConsumedMeals,
            workSchedule: workSchedule,
            workoutTime: workoutTime,
            specialEvents: specialEvents,
            dailyContextDescription: dailyContextDescription  // NEW
        )
    }
}
```

**Testing:**
- ✅ Verify context is saved to view model
- ✅ Verify buildDailySync includes context

---

### Phase 4: Coordinator Flow Update

#### 4.1 Replace Energy Screen
**File:** `NutriSync/Views/CheckIn/DailySync/DailySyncCoordinator.swift`

**Changes:**
```swift
enum DailySyncScreen {
    case greeting
    case weightCheck
    case alreadyEaten
    case schedule
    case dailyContext  // REPLACES: energy
    case complete
}

// UPDATE: setupFlow() method
private func setupFlow() {
    screens = []

    // Greeting (always first)
    screens.append(.greeting)

    // Weight check (conditional)
    if shouldShowWeightCheck() {
        screens.append(.weightCheck)
    }

    // Already eaten (conditional)
    if syncContext.shouldAskAboutPreviousMeals {
        screens.append(.alreadyEaten)
    }

    // Schedule (always show)
    screens.append(.schedule)

    // Daily context (NEW - replaces energy)
    screens.append(.dailyContext)

    // Complete (always last)
    screens.append(.complete)

    currentScreenIndex = 0
}

// UPDATE: currentScreenView computed property
@ViewBuilder
private var currentScreenView: some View {
    switch currentScreen {
    case .greeting:
        DailySyncGreetingView(viewModel: viewModel)
    case .weightCheck:
        WeightCheckView(viewModel: viewModel)
    case .alreadyEaten:
        AlreadyEatenView(viewModel: viewModel)
    case .schedule:
        DailySyncScheduleView(viewModel: viewModel)
    case .dailyContext:  // NEW
        DailyContextInputView(viewModel: viewModel)
    case .complete:
        DailySyncCompleteView(viewModel: viewModel)
    }
}
```

**Remove References to Energy Screen:**
- Delete `DailySyncEnergyView.swift` (or keep for reference but don't use)
- Remove `SimpleEnergyLevel` enum from DailySync model
- Remove energy selection logic from view model

**Testing:**
- ✅ Verify flow progresses correctly
- ✅ Verify progress dots show correct count
- ✅ Verify back button works from context screen
- ✅ Test skip functionality

---

### Phase 5: Firebase Integration

#### 5.1 Update FirebaseDataProvider
**File:** `NutriSync/Services/DataProvider/FirebaseDataProvider.swift`

**Changes:**
```swift
// ADD: Method to save daily sync with context
func saveDailySync(_ dailySync: DailySync, for userId: String) async throws {
    let db = Firestore.firestore()
    let dateStr = formatDateForDocument(dailySync.syncContext.date)

    let docRef = db.collection("users").document(userId)
        .collection("dailySyncs").document(dateStr)

    try await docRef.setData(dailySync.toFirestore(), merge: true)
}

// ADD: Method to load daily sync
func loadDailySync(for userId: String, date: Date) async throws -> DailySync? {
    let db = Firestore.firestore()
    let dateStr = formatDateForDocument(date)

    let docRef = db.collection("users").document(userId)
        .collection("dailySyncs").document(dateStr)

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
        return nil
    }

    return DailySync.fromFirestore(data)
}

private func formatDateForDocument(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
```

**Testing:**
- ✅ Test save to Firestore
- ✅ Test load from Firestore
- ✅ Verify context field is persisted
- ✅ Test with nil/empty context

---

### Phase 6: AI Prompt Enhancement

#### 6.1 Update AIWindowGenerationService
**File:** `NutriSync/Services/AI/AIWindowGenerationService.swift`

**Changes:**
```swift
private func buildPrompt(
    profile: UserProfile,
    checkIn: MorningCheckInData?,
    dailySync: DailySync?,
    date: Date
) -> String {
    var prompt = """
    You are an expert nutrition coach creating personalized meal windows.

    """

    // ... existing profile, goals, schedule sections ...

    // ADD: Daily context section (HIGH PRIORITY)
    if let context = dailySync?.dailyContextDescription, !context.isEmpty {
        prompt += """

        ## Today's Context (User's Own Words)
        "\(context)"

        CRITICAL PARSING INSTRUCTIONS:
        Analyze this description for:

        1. **Energy Level** - Parse mentions of:
           - Tired, exhausted, low energy → Prioritize easy-to-digest meals, avoid heavy foods
           - Great, energized, high energy → Can handle larger meals, complex macros
           - Normal, okay, decent → Standard meal distribution

        2. **Meetings & Work Commitments** - Parse mentions of:
           - "Meetings until 3pm" → Schedule windows BEFORE/AFTER, not during
           - "Back-to-back calls" → Suggest quick, convenient meals
           - "Important presentation" → Avoid heavy meals right before (energy crash risk)
           - "Flexible schedule" → Can use wider time ranges for windows

        3. **Social Events** - Parse mentions of:
           - "Dinner with friends at 8pm" → Plan lighter earlier windows, save calories
           - "Lunch meeting" → Accommodate the meal timing
           - "Date night" → Adjust macros to allow flexibility

        4. **Travel Plans** - Parse mentions of:
           - "Long drive", "airport", "commute" → Suggest portable, easy-to-eat meals
           - "On the road" → Prioritize convenience

        5. **Workout Details** - Parse mentions of:
           - "Gym at 6pm" → Create pre-workout window (carbs) + post-workout window (protein+carbs)
           - "Morning run" → Ensure adequate fuel or fasted options based on preference
           - "Rest day" → Adjust calorie distribution slightly lower

        6. **Sleep Quality** - Parse mentions of:
           - "Didn't sleep well" → Prioritize protein, avoid high-carb crashes
           - "Slept great" → Standard distribution

        7. **Stress Indicators** - Parse mentions of:
           - "Busy day", "stressful", "hectic" → Prioritize convenient, satisfying meals
           - "Relaxed", "chill" → Can suggest more complex meal prep

        8. **Work Location** - Parse mentions of:
           - "Working from home" → More flexible windows, can suggest longer meal prep
           - "In office" → More structured windows, portable options
           - "On-site" → Adjust for convenience

        **Use this context to override structured data when appropriate.**
        For example: If context says "feeling great" but energy was marked low earlier, trust the context.

        """
    }

    // ... rest of existing prompt (macros, goals, etc.) ...

    return prompt
}
```

**AI Response Enhancement:**
```swift
// In window generation response parsing
struct WindowResponse: Codable {
    let windows: [MealWindow]
    let dayPurpose: DayPurpose?
    let contextInsights: [String]?  // NEW: What AI learned from context
}

// Example AI response:
{
  "windows": [...],
  "dayPurpose": {...},
  "contextInsights": [
    "Detected low energy - prioritized lighter, frequent meals",
    "Scheduled windows around 3pm meeting block",
    "Added portable meal before 2pm airport drive"
  ]
}
```

**Update AIWindowGenerationService to request insights:**
```swift
// In buildPrompt(), add at the end:
prompt += """

**IMPORTANT: In your JSON response, include a "contextInsights" array summarizing what you learned from the user's daily context. Format as 2-4 short bullets:**

Example format:
{
  "windows": [...],
  "dayPurpose": {...},
  "contextInsights": [
    "Low energy detected - planned lighter meals",
    "Meetings until 3pm - windows scheduled around them"
  ]
}
"""

// In generateWindows() method after parsing response:
if let insights = response.contextInsights, !insights.isEmpty {
    // Store insights with the daily sync for display
    // Will be shown in DailySyncCompleteView
    await dataProvider.saveContextInsights(insights, for: userId, date: date)
}
```

**Testing:**
- ✅ Test with various context descriptions
- ✅ Verify AI parses energy levels correctly
- ✅ Verify meeting times are respected
- ✅ Test with empty context (should work normally)
- ✅ Test with very long context (token limit handling)

---

## Implementation Sequence & Checkpoints

### Sprint 1: Foundation (Data Layer)
**Goal:** Data model ready, compiles successfully

**Tasks:**
1. Update `DailySyncData.swift` with new field
2. Remove `currentEnergy` field references
3. Update `toFirestore()` and `fromFirestore()`
4. Add `inferredEnergyLevel` computed property
5. Update `FirebaseDataProvider` save/load methods
6. **CHECKPOINT:** Compile all modified files with `swiftc -parse`

**Success Criteria:**
- ✅ All files compile without errors
- ✅ Firestore schema updated
- ✅ No references to old energy field remain

---

### Sprint 2: UI Component (View Layer)
**Goal:** DailyContextInputView fully functional

**Tasks:**
1. Create `DailyContextInputView.swift`
2. Implement voice recording (copy from QuickVoiceAddView)
3. Add text input mode with TextEditor
4. Create topic suggestions section
5. Add single example text
6. Implement mode toggle button
7. Add edit functionality (long-press)
8. Handle permissions properly
9. **CHECKPOINT:** Compile and test voice/text input

**Success Criteria:**
- ✅ View compiles without errors
- ✅ Voice recording works
- ✅ Text input works
- ✅ Mode switching works
- ✅ Edit functionality works

---

### Sprint 3: Integration (Coordinator & ViewModel)
**Goal:** Context screen replaces energy screen in flow

**Tasks:**
1. Update `DailySyncViewModel.swift` with save method
2. Update `DailySyncCoordinator.swift` screen enum
3. Replace `.energy` with `.dailyContext` in flow
4. Update `currentScreenView` to show new view
5. Remove old energy view references
6. Test complete flow from greeting to finish
7. **CHECKPOINT:** Full DailySync flow works end-to-end

**Success Criteria:**
- ✅ Flow progresses correctly
- ✅ Back button works
- ✅ Progress dots show correct count
- ✅ Data is saved properly
- ✅ Skip button works

---

### Sprint 3.5: Insights Display UI
**Goal:** Show user what AI understood from their context

**Update DailySyncCompleteView:**
```swift
// In DailySyncCompleteView.swift

// Add state for insights
@State private var contextInsights: [String] = []

// In body, after success animation:
if !contextInsights.isEmpty {
    VStack(alignment: .leading, spacing: 12) {
        Text("I understood:")
            .font(.subheadline.weight(.medium))
            .foregroundColor(.phylloTextSecondary)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(contextInsights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.nutriSyncAccent)

                    Text(insight)
                        .font(.body)
                        .foregroundColor(.phylloText)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    .padding(.horizontal)
    .padding(.top, 16)
}

// Load insights in onAppear
.onAppear {
    Task {
        // Load insights after window generation completes
        if let insights = viewModel.lastGeneratedInsights {
            contextInsights = insights
        }
    }
}
```

**Update DailySyncViewModel:**
```swift
// Add property to store insights
@Published var lastGeneratedInsights: [String]?

// Update after window generation
func completeSync() async {
    // ... existing window generation code ...

    // Store insights for display
    if let insights = generatedInsights {
        lastGeneratedInsights = insights
    }
}
```

**Testing:**
- ✅ Verify insights display after window generation
- ✅ Test with various context inputs
- ✅ Verify layout looks good (1-4 insights)
- ✅ Test with no context (no insights shown)

---

### Sprint 4: AI Enhancement (Service Layer)
**Goal:** AI uses context to generate better windows

**Tasks:**
1. Update `buildPrompt()` in AIWindowGenerationService
2. Add context parsing instructions
3. Add `contextInsights` to response model
4. Test with various context examples
5. Handle edge cases (empty, very long)
6. **CHECKPOINT:** Generate windows with context

**Success Criteria:**
- ✅ Prompt includes context section
- ✅ AI parses energy, meetings, workouts
- ✅ Windows adapt to context
- ✅ Insights show what AI learned

---

### Sprint 5: Testing & Polish
**Goal:** Production-ready feature

**Tasks:**
1. Manual testing in Xcode simulator
2. Test all voice/text scenarios
3. Test skip functionality
4. Test with various context inputs
5. Verify Firestore persistence
6. Check for memory leaks (audio engine cleanup)
7. Test permission flows
8. UI polish (animations, spacing)
9. **CHECKPOINT:** User acceptance testing

**Success Criteria:**
- ✅ No crashes or errors
- ✅ All scenarios work correctly
- ✅ UI feels polished
- ✅ Performance is good
- ✅ User feedback is positive

---

## Edge Cases & Error Handling

### Voice Input Issues
1. **Permission Denied:**
   - Show alert with "Open Settings" button
   - Fall back to text input mode
   - Store preference to default to text

2. **Audio Engine Failure:**
   - Catch errors in `startRecording()`
   - Show error message to user
   - Automatically switch to text mode

3. **Recognition Task Timeout:**
   - Set 60-second limit per recording
   - Auto-stop and use partial results
   - Show "Recording stopped" message

### Context Parsing Edge Cases
1. **Empty Context:**
   - AI uses structured data only (work schedule, workout time)
   - No special parsing needed
   - Default energy level to "good"

2. **Very Long Context (>500 words):**
   - Truncate to 500 words before sending to AI
   - Show character count in UI
   - Warn user if approaching limit

3. **Conflicting Information:**
   - Example: Context says "high energy" but earlier marked "tired"
   - **AI should trust context over structured data**
   - Add note in AI prompt to prioritize context

4. **Ambiguous Time References:**
   - "Lunch meeting" - AI should infer ~12-1pm
   - "Late afternoon workout" - AI should infer ~4-6pm
   - Use time-of-day heuristics

### Data Persistence Issues
1. **Firestore Save Failure:**
   - Cache locally using UserDefaults
   - Retry on next app launch
   - Show "Saved locally" indicator

2. **Network Offline:**
   - Firestore handles offline writes automatically
   - Show "Will sync when online" message
   - Don't block user flow

---

## Performance Considerations

### Memory Management
```swift
// CRITICAL: Clean up audio resources
deinit {
    stopRecording()
    audioEngine.stop()
    recognitionTask?.cancel()
    recognitionRequest = nil
}

// In onDisappear
.onDisappear {
    stopRecording()  // Always stop when view disappears
}
```

### Token Usage Optimization
```swift
// Limit context length to control costs
private func truncateContextIfNeeded(_ context: String) -> String {
    let maxLength = 500  // ~125 tokens
    if context.count > maxLength {
        return String(context.prefix(maxLength)) + "..."
    }
    return context
}

// Include token estimate in prompt
// Estimated tokens: ~200 (context) + 1500 (existing prompt) = 1700 input tokens
// Target output: ~1000 tokens
// Cost: ~$0.02 per generation (within budget)
```

### UI Responsiveness
```swift
// Run speech recognition on background thread
Task {
    await startRecording()  // Async operation
}

// Update UI on main thread
DispatchQueue.main.async {
    transcribedText = result.bestTranscription.formattedString
}
```

---

## Testing Plan

### Unit Tests
```swift
// DailySyncDataTests.swift
func testDailySyncWithContext() {
    let sync = DailySync(
        syncContext: .earlyMorning(date: Date()),
        alreadyConsumed: [],
        workSchedule: nil,
        workoutTime: nil,
        specialEvents: [],
        dailyContextDescription: "Feeling tired, meetings until 3pm"
    )

    XCTAssertEqual(sync.inferredEnergyLevel, .low)
    XCTAssertTrue(sync.hasDetailedContext)
}

func testDailySyncWithoutContext() {
    let sync = DailySync(
        syncContext: .earlyMorning(date: Date()),
        alreadyConsumed: [],
        workSchedule: nil,
        workoutTime: nil,
        specialEvents: [],
        dailyContextDescription: nil
    )

    XCTAssertNil(sync.inferredEnergyLevel)
    XCTAssertFalse(sync.hasDetailedContext)
}
```

### Integration Tests
1. **Voice Recording Test:**
   - Record 10-second clip
   - Verify transcription accuracy
   - Test pause/resume
   - Test stop and restart

2. **Text Input Test:**
   - Type long text (500+ characters)
   - Switch to voice and back
   - Verify text is preserved

3. **Flow Test:**
   - Complete entire DailySync flow
   - Skip context screen
   - Fill context and continue
   - Verify data is saved to Firestore

4. **AI Test:**
   - Generate windows with various contexts
   - Verify windows adapt correctly
   - Check token usage

### Manual Testing Checklist
- [ ] Voice input works (10s, 30s, 60s recordings)
- [ ] Text input works (short, long, emoji)
- [ ] Mode switching preserves input
- [ ] Edit functionality works (long-press)
- [ ] Permission alert shows when denied
- [ ] Skip button shows when empty
- [ ] Continue button shows when filled
- [ ] Progress dots show correct position
- [ ] Back button returns to schedule screen
- [ ] Data persists after closing app
- [ ] AI generates windows using context
- [ ] Works with no internet (local cache)

---

## Success Metrics

### User Experience Goals
- **Completion Rate:** >60% of users provide context (vs skipping)
- **Input Method:** Track voice vs text usage ratio
- **Length:** Average context length 30-100 words
- **Retention:** Users who provide context return more often

### Technical Goals
- **Performance:** View loads in <1s
- **Accuracy:** Speech recognition >90% accurate
- **Cost:** <$0.03 per window generation (including context)
- **Reliability:** <1% crash rate on this screen

### AI Quality Goals
- **Relevance:** Windows adapt to context >80% of time
- **Parsing:** AI correctly identifies energy/meetings/workouts >90%
- **User Satisfaction:** Thumbs up rate >70%

---

## Future Enhancements (Post-Launch)

### Phase 2 Improvements
1. **Smart Suggestions:**
   - "Use yesterday's context" quick button
   - AI-suggested prompts based on patterns
   - Time-of-day context templates

2. **Context History:**
   - Show previous 7 days of context
   - Identify patterns ("You often mention...")
   - Copy from previous day

3. **Enhanced Parsing:**
   - Extract meeting times automatically
   - Detect mood/stress from language
   - Identify food preferences mentioned

4. **Voice Improvements:**
   - Multi-language support
   - Accent adaptation
   - Noise cancellation

### Phase 3 Features
1. **Context Shortcuts:**
   - "Busy day" template
   - "Relaxed day" template
   - "Workout day" template

2. **Integration with Calendar:**
   - Auto-detect meetings from iOS Calendar
   - Pre-fill context with "You have 3 meetings today"

3. **Insights Feedback:**
   - Show user what AI learned from their context
   - "I noticed you mention tiredness often on Mondays"

---

## File Structure Summary

### New Files (1)
```
NutriSync/Views/CheckIn/DailySync/DailyContextInputView.swift  (~500 lines)
```

### Modified Files (6)
```
NutriSync/Models/DailySyncData.swift                           (+30 lines)
NutriSync/ViewModels/DailySyncViewModel.swift                  (+10 lines)
NutriSync/Views/CheckIn/DailySync/DailySyncCoordinator.swift   (~10 lines changed)
NutriSync/Views/CheckIn/DailySync/DailySyncCompleteView.swift  (+40 lines - insights display)
NutriSync/Services/AI/AIWindowGenerationService.swift          (+80 lines)
NutriSync/Services/DataProvider/FirebaseDataProvider.swift     (+40 lines)
```

### Deleted/Deprecated Files (1)
```
NutriSync/Views/CheckIn/DailySync/DailySyncEnergyView.swift    (remove from coordinator)
```

### Total Lines of Code
- **New:** ~500 lines (DailyContextInputView)
- **Modified:** ~200 lines (6 files)
- **Deleted:** ~100 lines (DailySyncEnergyView)
- **Net Change:** +600 lines

---

## Risk Assessment & Mitigation

### High Risk
1. **Speech Recognition Accuracy:**
   - **Risk:** Poor transcription quality
   - **Mitigation:** Edit functionality, text input fallback, show confidence warnings

2. **Token Cost Overruns:**
   - **Risk:** Long contexts exceed budget
   - **Mitigation:** 500-word limit, truncate before sending, monitor costs

### Medium Risk
1. **User Adoption:**
   - **Risk:** Users skip this screen
   - **Mitigation:** Show value ("Better meal timing!"), make it easy, provide examples

2. **Audio Engine Conflicts:**
   - **Risk:** Conflicts with music/podcasts
   - **Mitigation:** Proper audio session configuration, test with background audio

### Low Risk
1. **Firestore Write Failures:**
   - **Risk:** Data not saved
   - **Mitigation:** Offline persistence, retry logic, local caching

2. **Memory Leaks:**
   - **Risk:** Audio engine not cleaned up
   - **Mitigation:** Proper deinit, onDisappear cleanup, test in Instruments

---

## Launch Checklist

### Before Implementation
- [x] Research document reviewed
- [x] User preferences confirmed
- [x] Plan document created
- [ ] **USER APPROVAL REQUIRED** ← You are here

### Before Testing
- [ ] All code changes compiled successfully
- [ ] No mock data references remain
- [ ] Firebase security rules updated
- [ ] Firestore indexes created (if needed)

### Before Release
- [ ] Manual testing completed (all scenarios)
- [ ] User acceptance testing passed
- [ ] Performance profiling done (no leaks)
- [ ] Token costs verified (within budget)
- [ ] Error handling tested (offline, permissions)
- [ ] Edge cases tested (midnight, long context)

### Post-Release
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Track completion rates (Analytics)
- [ ] Monitor token costs (Vertex AI dashboard)
- [ ] Collect user feedback
- [ ] Iterate based on data

---

## Questions for Final Approval

Before starting implementation, please confirm:

1. ✅ **Replace energy screen** - Confirmed
2. ✅ **Voice-first with text toggle** - Confirmed
3. ✅ **Skippable but discouraged** - Confirmed
4. ✅ **Keep schedule pickers** - Confirmed
5. ✅ **1 example + topic suggestions** - Confirmed
6. ✅ **Edit functionality** - Confirmed

**User Confirmed Preferences:**
- ✅ Character limit display (500 characters with warning at 450)
- ✅ Draft saving (persists when going back, clears on complete)
- ✅ Context insights display (show "I understood: ..." on complete screen)
- ✅ Delete old energy view completely (DailySyncEnergyView.swift)

---

## Next Steps

**Once approved, start NEW SESSION for Phase 3 (Implementation) with:**
```
@plan-daily-context-voice-input.md
@research-daily-context-input.md

"Implement Sprint 1: Foundation (Data Layer)"
```

**Implementation will follow sprints exactly:**
1. Sprint 1: Data layer (models, Firestore)
2. Sprint 2: UI component (DailyContextInputView with character limit + draft saving)
3. Sprint 3: Integration (coordinator, view model)
4. Sprint 3.5: Insights display UI
5. Sprint 4: AI enhancement (prompt updates + insights generation)
6. Sprint 5: Testing & polish
7. Sprint 6: Delete old energy view

**Estimated Timeline:**
- Sprint 1: 1 session (data layer)
- Sprint 2: 2-3 sessions (UI with character limit + draft)
- Sprint 3: 1 session (coordinator integration)
- Sprint 3.5: 1 session (insights display UI)
- Sprint 4: 1 session (AI prompt enhancement)
- Sprint 5: 1-2 sessions (testing & polish)
- Sprint 6: 1 session (delete old energy view, verify no references)
- **Total: 8-11 sessions** (depends on testing iterations)

---

---

## Summary of Enhancements

### Character Limit Display
- **500 character max** to control token costs
- Orange warning at 450+ characters
- Red error + truncation notice at 500+
- Auto-truncate on save if over limit
- Display: `"250/500"` in caption font below input

### Draft Saving
- **Auto-save to UserDefaults** when user taps back button
- **Auto-load draft** on view appear (persists across app sessions)
- **Clear draft** after successful save to avoid stale data
- Key: `"dailyContextDraft"` in UserDefaults

### AI Insights Display
- **Show on complete screen** what AI understood from context
- Format: "I understood:" header with checkmark bullets
- 2-4 insights per generation (e.g., "Low energy detected - planned lighter meals")
- Only shown if context was provided (not for skipped contexts)
- Stored in `viewModel.lastGeneratedInsights`

### Delete Old Energy View
- **Complete removal** of `DailySyncEnergyView.swift`
- Remove `SimpleEnergyLevel` enum from DailySync model
- Remove `.energy` case from `DailySyncScreen` enum
- Verify no references remain in codebase
- Energy level now inferred from context parsing

---

**Plan Status:** ✅ Complete & Updated with User Preferences

**Ready to implement when you are!** 🚀
