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
    
    var body: some View {
        ZStack {
            // Background with captured photo
            backgroundLayer
            
            // Dark overlay for better visibility
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Top info icon
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
                .padding(.top, 60)
                
                // Transcribed text
                if !transcribedText.isEmpty {
                    ScrollView {
                        Text(transcribedText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                    .frame(maxHeight: 150)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Central listening indicator
                listeningIndicator
                
                Spacer()
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 50)
            }
        }
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
    
    private var backgroundLayer: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    private var listeningIndicator: some View {
        VStack(spacing: 40) {
            // Main circle with waveform
            ZStack {
                // Outer pulse circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .scaleEffect(circleScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            circleScale = 1.15
                        }
                    }
                
                // Main white circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                
                // Waveform inside circle
                if isListening && !isPaused {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 6, height: audioLevels[index] * 60)
                                .animation(.spring(response: 0.3), value: audioLevels[index])
                        }
                    }
                } else if isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                }
            }
            
            // Status text
            Text(isPaused ? "Paused" : (isListening ? "Listening" : "Tap to start"))
                .font(.system(size: 24, weight: .medium))
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
        HStack(spacing: 120) {
            // Done button
            Button(action: {
                stopRecording()
                onComplete?(transcribedText)
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .opacity(isListening ? 1 : 0.3)
            .disabled(!isListening)
            
            // Voice level indicator (middle)
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(Color.white.opacity(isListening && !isPaused ? 0.8 : 0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Cancel button
            Button(action: { 
                stopRecording()
                dismiss() 
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
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
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
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
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Update audio levels based on actual audio
            self?.updateRealAudioLevels(from: buffer)
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