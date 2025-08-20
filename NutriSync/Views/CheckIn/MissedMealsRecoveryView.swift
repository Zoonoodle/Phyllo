//
//  MissedMealsRecoveryView.swift
//  NutriSync
//
//  Created on 8/12/25.
//

import SwiftUI
import Speech
import AVFoundation

struct MissedMealsRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ScheduleViewModel
    
    @State private var mealDescription = ""
    @State private var isProcessing = false
    @State private var showTimingRefinement = false
    @State private var parsedMeals: [ParsedMealWithTiming] = []
    
    // Speech recognition states
    @State private var isListening = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var showPermissionAlert = false
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.5, count: 5)
    @State private var waveformAnimation = false
    
    let missedWindows: [MealWindow]
    
    // Timer for updating audio levels
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                if showTimingRefinement {
                    MealTimingRefinementView(
                        parsedMeals: $parsedMeals,
                        missedWindows: missedWindows,
                        onComplete: { mealsWithTiming in
                            processMealsWithTiming(mealsWithTiming)
                        },
                        onBack: {
                            showTimingRefinement = false
                            parsedMeals = []
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    mainInputView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        stopRecording()
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
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
            Button("Type Instead", role: .cancel) { }
        } message: {
            Text("Please enable speech recognition in Settings to describe your meals with voice. You can also type your description instead.")
        }
    }
    
    private var mainInputView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(.nutriSyncAccent)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 40)
                
                Text("Catch Up on Today's Meals")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("You've missed \(missedWindows.count) meal \(missedWindows.count == 1 ? "window" : "windows")")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 40)
            
            // Main content area
            if mealDescription.isEmpty && !isListening {
                instructionalContent
                    .transition(.opacity.combined(with: .scale(0.95)))
            } else if !mealDescription.isEmpty {
                transcriptionDisplay
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer(minLength: 20)
            
            // Voice input circle
            voiceInputCircle
                .padding(.bottom, 40)
            
            // Text input field
            textInputField
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            
            // Action buttons
            actionButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
        }
    }
    
    // MARK: - Subviews
    
    private var instructionalContent: some View {
        VStack(spacing: 20) {
            Text("Describe all the meals you had today")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                instructionItem(
                    icon: "tag.fill",
                    text: "Include restaurant names for accurate nutrition"
                )
                instructionItem(
                    icon: "clock.fill",
                    text: "We'll ask when you ate each meal next"
                )
                instructionItem(
                    icon: "list.bullet",
                    text: "Describe everything - drinks, sides, desserts"
                )
            }
            .padding(.horizontal, 40)
            
            Text("Examples:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
            
            Text("\"I had scrambled eggs and toast for breakfast, a Chipotle chicken bowl for lunch, and grilled salmon with rice for dinner\"")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func instructionItem(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    private var transcriptionDisplay: some View {
        ScrollView {
            Text(mealDescription)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .frame(maxHeight: 150)
        .padding(.horizontal, 24)
    }
    
    private var voiceInputCircle: some View {
        ZStack {
            // Outer pulse circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 180, height: 180)
                .scaleEffect(waveformAnimation ? 1.15 : 1.0)
                .opacity(isListening ? 1 : 0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: waveformAnimation)
            
            // Main circle
            Circle()
                .fill(isListening ? Color.white : Color.white.opacity(0.1))
                .frame(width: 140, height: 140)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                )
            
            // Content inside circle
            if isListening {
                // Waveform
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 4, height: audioLevels[index] * 35)
                            .animation(.spring(response: 0.3), value: audioLevels[index])
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isListening ? .black : .white)
                    
                    Text("Tap to speak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isListening ? .black : .white.opacity(0.7))
                }
            }
        }
        .onTapGesture {
            if isListening {
                stopRecording()
            } else {
                startRecording()
            }
        }
        .onAppear {
            if isListening {
                waveformAnimation = true
            }
        }
    }
    
    private var textInputField: some View {
        VStack(spacing: 8) {
            HStack {
                Text("or type your description:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            
            TextField("Eggs and toast, Chipotle bowl, salmon dinner...", text: $mealDescription, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .lineLimit(2...4)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: processInitialDescription) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.nutriSyncAccent)
                .foregroundColor(.black)
                .cornerRadius(26)
            }
            .disabled(isProcessing || mealDescription.isEmpty)
            
            Button(action: {
                viewModel.markWindowsAsFasted(missedWindows)
                dismiss()
            }) {
                Text("I was fasting")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Processing Functions
    
    private func processInitialDescription() {
        guard !mealDescription.isEmpty else { return }
        
        isProcessing = true
        stopRecording()
        
        Task {
            do {
                // Parse meals from description using AI
                let meals = try await parseMealsFromDescription(mealDescription)
                
                await MainActor.run {
                    self.parsedMeals = meals
                    self.isProcessing = false
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        self.showTimingRefinement = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    // Fallback to original simple processing
                    processMealsDirectly()
                }
            }
        }
    }
    
    private func parseMealsFromDescription(_ description: String) async throws -> [ParsedMealWithTiming] {
        // This will be replaced with actual AI parsing
        // For now, create mock parsed meals
        let mealDescriptions = description
            .replacingOccurrences(of: " and ", with: ", ")
            .components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return mealDescriptions.enumerated().map { index, desc in
            ParsedMealWithTiming(
                name: desc,
                description: desc,
                suggestedWindow: index < missedWindows.count ? missedWindows[index] : nil,
                assignedWindow: nil
            )
        }
    }
    
    private func processMealsWithTiming(_ mealsWithTiming: [ParsedMealWithTiming]) {
        isProcessing = true
        
        Task {
            // Create full description with timing info
            var timedDescription = ""
            for meal in mealsWithTiming {
                if let window = meal.assignedWindow {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    let timeStr = formatter.string(from: window.startTime)
                    timedDescription += "\(meal.description) at \(timeStr). "
                } else {
                    timedDescription += "\(meal.description). "
                }
            }
            
            // Process with the view model
            await viewModel.processRetrospectiveMeals(
                description: timedDescription,
                missedWindows: missedWindows
            )
            
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }
    
    private func processMealsDirectly() {
        Task {
            await viewModel.processRetrospectiveMeals(
                description: mealDescription,
                missedWindows: missedWindows
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    // MARK: - Speech Recognition Methods
    
    private func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // Ready to record
                    break
                case .denied, .restricted:
                    // Will show alert when trying to record
                    break
                case .notDetermined:
                    break
                @unknown default:
                    break
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
                self.mealDescription = result.bestTranscription.formattedString
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
            waveformAnimation = true
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
        waveformAnimation = false
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

// MARK: - Supporting Types

struct ParsedMealWithTiming: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var suggestedWindow: MealWindow?
    var assignedWindow: MealWindow?
}

#Preview {
    // Create some mock missed windows for preview
    let mockWindows = [
        MealWindow(
            startTime: Date().addingTimeInterval(-7200), // 2 hours ago
            endTime: Date().addingTimeInterval(-3600),   // 1 hour ago
            targetCalories: 400,
            targetMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
            purpose: .metabolicBoost,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        ),
        MealWindow(
            startTime: Date().addingTimeInterval(-14400), // 4 hours ago
            endTime: Date().addingTimeInterval(-10800),   // 3 hours ago
            targetCalories: 500,
            targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 20),
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        )
    ]
    
    return MissedMealsRecoveryView(
        viewModel: ScheduleViewModel(),
        missedWindows: mockWindows
    )
}