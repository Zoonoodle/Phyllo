//
//  RealVoiceInputView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI
import Speech
import AVFoundation

struct RealVoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isListening = false
    @State private var isPaused = false
    @State private var waveformAnimation = false
    @State private var circleScale: CGFloat = 1.0
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.5, count: 5)
    @State private var transcribedText = ""
    @State private var showPermissionAlert = false
    @State private var permissionStatus = SFSpeechRecognizerAuthorizationStatus.notDetermined
    @State private var showTips = false
    
    // Manual text editing states
    @State private var isEditingText = false
    @State private var editableText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Speech recognition properties
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    // Captured image from camera
    let capturedImage: UIImage?
    
    // Completion handler
    var onComplete: ((String) -> Void)?
    
    // Timer for updating audio levels
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Computed property for adaptive instruction height
    private var instructionMaxHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let minHeight: CGFloat = 150
        let maxHeight: CGFloat = 300
        
        // Adjust based on device size
        if screenHeight < 700 { // SE, mini
            return minHeight
        } else if screenHeight < 850 { // Standard
            return 220
        } else { // Pro Max
            return maxHeight
        }
    }
    
    var body: some View {
        ZStack {
            // Background with captured photo
            backgroundLayer
            
            // Dark overlay for better visibility
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 16) {
                // Top info icon
                HStack {
                    Spacer()
                    Button(action: { showTips.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(12)
                    }
                }
                
                // Instructional content or transcribed text
                if transcribedText.isEmpty && !isListening {
                    ScrollView {
                        instructionalContent
                    }
                    .frame(maxHeight: instructionMaxHeight)
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
                
                Spacer(minLength: 10)
                
                // Central listening indicator
                listeningIndicator
                
                Spacer(minLength: 10)
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 20)
            }
            .padding(.top, 60) // For safe area
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .onAppear {
            checkSpeechAuthorization()
            
            // Show voice tips nudge on first use
            let hasShownVoiceTips = UserDefaults.standard.bool(forKey: "hasShownVoiceInputTips")
            if !hasShownVoiceTips {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NudgeManager.shared.triggerNudge(.voiceInputTips)
                    UserDefaults.standard.set(true, forKey: "hasShownVoiceInputTips")
                }
            }
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
        .sheet(isPresented: $showTips) {
            tipsSheet
        }
    }
    
    // MARK: - Components
    
    private var backgroundLayer: some View {
        ZStack {
            // Always use black background as base
            Color.black
                .ignoresSafeArea()
            
            // Add blurred image overlay if available
            if let image = capturedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 30)
                        .opacity(0.3) // Make it subtle
                }
                .ignoresSafeArea()
            }
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
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    stopRecording()
                    onComplete?(transcribedText)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .medium))
                        Text(transcribedText.isEmpty ? "Done" : "Analyze Meal")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.nutriSyncAccent)
                            .opacity(isListening || !transcribedText.isEmpty ? 1 : 0.3)
                    )
                }
                .disabled(!isListening && transcribedText.isEmpty)
            }
            
            // Skip button as secondary action
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                stopRecording()
                onComplete?("")  // Empty description
                dismiss()
            }) {
                Text("Skip voice description")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.top, 8)
            }
        }
    }
    
    private var instructionalContent: some View {
        VStack(spacing: 16) {
            // Title
            Text("Describe Your Meal")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
            
            // Instructions box
            VStack(spacing: 12) {
                Text("For the most accurate nutrition data:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(alignment: .leading, spacing: 10) {
                    instructionItem(
                        icon: "tag.fill",
                        text: "Mention brand names",
                        example: "\"Starbucks venti iced coffee\""
                    )
                    
                    instructionItem(
                        icon: "scalemass.fill",
                        text: "Include portion sizes",
                        example: "\"Large bowl of pasta\" or \"8 oz steak\""
                    )
                    
                    instructionItem(
                        icon: "list.bullet",
                        text: "List all ingredients you know",
                        example: "\"Salad with chicken, avocado, and ranch\""
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.3), value: isListening)
    }
    
    private func instructionItem(icon: String, text: String, example: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(example)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    private var tipsSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Description Tips")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Get the most accurate nutrition analysis")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.bottom, 8)
                        
                        // Tips sections
                        tipSection(
                            title: "🏷️ Brand Names Matter",
                            description: "Our AI can search for exact nutrition data from restaurants and brands.",
                            examples: [
                                "\"McDonald's Big Mac with medium fries\"",
                                "\"Chipotle chicken burrito bowl\"",
                                "\"Trader Joe's cauliflower gnocchi\""
                            ]
                        )
                        
                        tipSection(
                            title: "📏 Be Specific About Portions",
                            description: "The more specific you are about amounts, the more accurate the analysis.",
                            examples: [
                                "\"12 oz ribeye steak\" instead of \"steak\"",
                                "\"2 cups of brown rice\" instead of \"rice\"",
                                "\"Half an avocado\" instead of \"avocado\""
                            ]
                        )
                        
                        tipSection(
                            title: "🥗 List All Ingredients",
                            description: "Don't forget sauces, dressings, and cooking methods.",
                            examples: [
                                "\"Grilled chicken Caesar salad with croutons and parmesan\"",
                                "\"Scrambled eggs cooked in butter with cheddar cheese\"",
                                "\"Whole wheat pasta with marinara sauce and olive oil\""
                            ]
                        )
                        
                        tipSection(
                            title: "🎯 Why This Helps",
                            description: "When you mention brands or restaurants, our AI automatically searches for official nutrition data. For homemade meals, detailed descriptions help estimate portions and identify all ingredients.",
                            examples: []
                        )
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTips = false
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
    }
    
    private func tipSection(title: String, description: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            if !examples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.nutriSyncAccent)
                            Text(example)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Helper Methods
    
    private func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.permissionStatus = authStatus
                switch authStatus {
                case .authorized:
                    // Permission granted, ready to record
                    break
                case .denied, .restricted:
                    self.showPermissionAlert = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func startRecording() {
        guard permissionStatus == .authorized else {
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
            
            // Update audio levels based on actual audio
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
        isPaused = false
    }
    
    private func updateAudioLevels() {
        guard isListening && !isPaused else { return }
        
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
    RealVoiceInputView(capturedImage: nil) { transcript in
        print("Transcript: \(transcript)")
    }
    .preferredColorScheme(.dark)
}