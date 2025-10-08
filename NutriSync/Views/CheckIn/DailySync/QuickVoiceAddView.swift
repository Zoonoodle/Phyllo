//
//  QuickVoiceAddView.swift
//  NutriSync
//
//  Ultra-simple voice-first meal entry for Daily Sync
//

import SwiftUI
import Speech
import AVFoundation

struct QuickVoiceAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isListening = false
    @State private var isPaused = false
    @State private var circleScale: CGFloat = 1.0
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.5, count: 5)
    @State private var transcribedText = ""
    @State private var showPermissionAlert = false
    @State private var permissionStatus = SFSpeechRecognizerAuthorizationStatus.notDetermined

    // Manual text editing states
    @State private var isEditingText = false
    @State private var editableText = ""
    @FocusState private var isTextFieldFocused: Bool

    // Speech recognition properties
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    // Callback
    let onComplete: (String) -> Void

    // Service references
    @StateObject private var mealCaptureService = MealCaptureService.shared
    @State private var isProcessing = false

    // Timer for updating audio levels
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Main content
            VStack(spacing: 12) {
                // Compact header with context
                VStack(spacing: 8) {
                    Text("Quick Add Meal")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Describe what you ate today")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)

                // Instructional content or transcribed text
                if transcribedText.isEmpty && !isListening {
                    instructionalContent
                        .transition(.opacity.combined(with: .scale(0.95)))
                } else if !transcribedText.isEmpty {
                    ScrollView {
                        Group {
                            if isEditingText {
                                TextField("Type or edit your meal description", text: $editableText, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .focused($isTextFieldFocused)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .onSubmit {
                                        transcribedText = editableText
                                        isEditingText = false
                                    }
                            } else {
                                Text(transcribedText)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        editableText = transcribedText
                                        isEditingText = true
                                        isTextFieldFocused = true
                                    }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isEditingText ? Color.nutriSyncAccent : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .frame(maxHeight: 150)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    // Hint text for long-press capability
                    if !isEditingText && !transcribedText.isEmpty {
                        Text("Long press to edit")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 4)
                    }

                    // Done editing button when in edit mode
                    if isEditingText {
                        Button(action: {
                            transcribedText = editableText
                            isEditingText = false
                            isTextFieldFocused = false
                        }) {
                            Text("Done Editing")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nutriSyncAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer(minLength: 20)

                // Central listening indicator
                listeningIndicator

                Spacer(minLength: 20)

                // Bottom controls
                bottomControls
                    .padding(.bottom, 30)
            }
            .padding(.top, 20)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .onAppear {
            checkSpeechAuthorization()
        }
        .onDisappear {
            stopRecording()
        }
        .onReceive(timer) { _ in
            updateAudioLevels()
        }
        .alert("Speech Recognition Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable speech recognition in Settings to describe your meal with voice.")
        }
    }

    // MARK: - Components

    private var instructionalContent: some View {
        VStack(spacing: 8) {
            // Instructions - ultra simple
            VStack(spacing: 8) {
                Text("Just describe what you ate:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 8) {
                    exampleItem(text: "\"Two scrambled eggs with toast and coffee\"")
                    exampleItem(text: "\"Chipotle chicken burrito bowl\"")
                    exampleItem(text: "\"Protein shake and banana\"")
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.3), value: isListening)
    }

    private func exampleItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .italic()
        }
    }

    private var listeningIndicator: some View {
        VStack(spacing: 30) {
            // Main circle with waveform
            ZStack {
                // Outer pulse circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 220, height: 220)
                    .scaleEffect(circleScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            circleScale = 1.15
                        }
                    }

                // Main white circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                // Waveform inside circle
                if isListening && !isPaused {
                    HStack(spacing: 6) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 5, height: audioLevels[index] * 45)
                                .animation(.spring(response: 0.3), value: audioLevels[index])
                        }
                    }
                } else if isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.black)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.black)
                }
            }

            // Status text
            Text(isPaused ? "Paused" : (isListening ? "Listening" : "Tap to start"))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .onTapGesture {
            if !isListening {
                startRecording()
            } else {
                withAnimation(.spring(response: 0.3)) {
                    isPaused.toggle()
                }
                if isPaused {
                    audioEngine.pause()
                } else {
                    try? audioEngine.start()
                }
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Voice level indicator
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(Color.white.opacity(isListening && !isPaused ? 0.8 : 0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Control buttons
            HStack(spacing: 20) {
                // Cancel button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    stopRecording()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }

                // Done button
                Button(action: addQuickMeal) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(transcribedText.isEmpty ? Color.white.opacity(0.3) : Color.nutriSyncAccent)
                    )
                }
                .disabled(transcribedText.isEmpty || isProcessing)
            }
        }
    }

    // MARK: - Helper Functions

    private func addQuickMeal() {
        guard !transcribedText.isEmpty, !isProcessing else { return }

        isProcessing = true
        stopRecording()

        Task {
            do {
                // Use AI to analyze the quick description
                let _ = try await mealCaptureService.startMealAnalysis(
                    image: nil,
                    voiceTranscript: transcribedText,
                    timestamp: Date() // Current time
                )

                // Call completion and dismiss
                await MainActor.run {
                    onComplete(transcribedText)
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isProcessing = false
                    // TODO: Show error alert
                }
            }
        }
    }

    // MARK: - Speech Recognition Methods

    private func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.permissionStatus = authStatus
                if authStatus != .authorized {
                    self.showPermissionAlert = true
                }
            }
        }
    }

    private func startRecording() {
        // Check authorization
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        guard authStatus == .authorized else {
            showPermissionAlert = true
            return
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            self.updateRealAudioLevels(from: buffer)
        }

        // Start audio engine
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    private func updateAudioLevels() {
        guard isListening else { return }

        // Only use simulated levels if we don't have real audio
        if audioLevels.allSatisfy({ $0 == 0.5 }) {
            for i in 0..<audioLevels.count {
                audioLevels[i] = CGFloat.random(in: 0.3...1.0)
            }
        }
    }

    private func updateRealAudioLevels(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)

        // Convert to 0-1 range for visualization
        let normalizedPower = (avgPower + 50) / 50
        let clampedPower = min(max(normalizedPower, 0), 1)

        DispatchQueue.main.async {
            // Shift levels and add new one
            self.audioLevels.removeFirst()
            self.audioLevels.append(CGFloat(clampedPower))
        }
    }
}

#Preview {
    QuickVoiceAddView { description in
        print("Added meal: \(description)")
    }
}
