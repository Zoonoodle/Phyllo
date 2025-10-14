//
//  DailyContextInputView.swift
//  NutriSync
//
//  Voice/text input for daily context to optimize AI meal window generation
//  Replaces the energy selection screen with richer free-form input
//

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

    // Typewriter animation state
    @State private var displayedExampleText = ""
    private let fullExampleText = "\"Working 9-5 today with back-to-back meetings until 3pm, then hitting the gym at 6. Feeling pretty tired, didn't sleep great last night.\""

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
        "Work hours",
        "Workout timing",
        "Meetings or calls",
        "Energy level",
        "Sleep quality",
        "Social events",
        "Stress level",
        "Travel plans"
    ]

    // Timer for audio level animation
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (custom, no subtitle)
                Text("How's your day looking?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                Spacer()

                // Main content area
                if useVoiceInput {
                    voiceInputSection
                } else {
                    textInputSection
                }

                Spacer()

                // Character count
                characterCountDisplay
                    .padding(.bottom, 8)

                // Input mode toggle
                inputModeToggle
                    .padding(.bottom, 12)

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
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            checkSpeechAuthorization()
            // NEW: Load draft if available
            loadDraft()
            // Start typewriter animation
            startTypewriterAnimation()
        }
        .onDisappear {
            stopRecording()
        }
        .onReceive(timer) { _ in
            updateAudioLevels()
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
        VStack(spacing: 0) {
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
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
            } else if !transcribedText.isEmpty {
                // Display transcribed text prominently
                VStack(spacing: 12) {
                    ScrollView {
                        Text(transcribedText)
                            .font(.body)
                            .foregroundColor(.phylloText)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(minHeight: 100, maxHeight: 160)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .onLongPressGesture(minimumDuration: 0.5) {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        editableText = transcribedText
                        isEditingText = true
                        isTextFieldFocused = true
                    }

                    // Edit hint
                    Text("Long press to edit")
                        .font(.caption)
                        .foregroundColor(.phylloTextTertiary)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
            } else if !isListening {
                // Instructions when empty and not listening
                instructionalContent
                    .padding(.top, 20)
            } else {
                // During recording, show placeholder
                VStack(spacing: 12) {
                    Text("Listening...")
                        .font(.body)
                        .foregroundColor(.phylloTextSecondary)
                        .frame(minHeight: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
            }

            Spacer().frame(height: 24)

            // Listening indicator (center)
            listeningIndicator
                .padding(.vertical, 16)

            // Reset button (when recording)
            if isListening {
                Button(action: resetRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16))
                        Text("Reset")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.phylloText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(24)
                }
                .padding(.top, 12)
            }

            Spacer().frame(height: 20)
        }
    }

    private var instructionalContent: some View {
        VStack(spacing: 20) {
            // Single example with typewriter animation
            VStack(alignment: .leading, spacing: 8) {
                Text("Example:")
                    .font(.caption)
                    .foregroundColor(.phylloTextSecondary)

                ZStack(alignment: .topLeading) {
                    // Invisible full text to hold space (prevents layout shifting)
                    Text(fullExampleText)
                        .font(.body.weight(.medium))
                        .foregroundColor(.clear)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding()

                    // Visible animated text
                    Text(displayedExampleText)
                        .font(.body.weight(.medium))
                        .foregroundColor(.phylloText.opacity(0.85))
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)

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
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: circleScale)
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
                    }
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
            } else {
                // Toggle pause/resume when recording
                togglePauseResume()
            }
        }
        .onChange(of: isListening) { _, newValue in
            if newValue {
                circleScale = 1.15
            } else {
                circleScale = 1.0
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
                DispatchQueue.main.async {
                    transcribedText = result.bestTranscription.formattedString
                }
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

    private func resetRecording() {
        // Stop recording and clear transcribed text
        stopRecording()
        transcribedText = ""
        editableText = ""
        isEditingText = false
    }

    private func updateAudioLevels() {
        guard isListening && !isPaused else { return }

        for i in 0..<audioLevels.count {
            audioLevels[i] = CGFloat.random(in: 0.3...1.0)
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

    // MARK: - Typewriter Animation

    private func startTypewriterAnimation() {
        displayedExampleText = ""

        Task { @MainActor in
            for index in fullExampleText.indices {
                displayedExampleText.append(fullExampleText[index])
                try? await Task.sleep(nanoseconds: 20_000_000) // 0.02 seconds
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DailyContextInputView(viewModel: DailySyncViewModel())
        .environmentObject(FirebaseDataProvider.shared)
}
