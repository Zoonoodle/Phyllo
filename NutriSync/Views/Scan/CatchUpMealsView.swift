//
//  CatchUpMealsView.swift
//  NutriSync
//
//  Created on 8/20/25.
//

import SwiftUI
import AVFoundation

struct CatchUpMealsView: View {
    @State private var mealDescription: String = ""
    @State private var isRecording = false
    @State private var audioSession = AVAudioSession.sharedInstance()
    @State private var speechRecognizer = MockSpeechRecognizer()
    @Environment(\.dismiss) var dismiss
    
    // Callback for when user submits their description
    let onSubmit: (String) -> Void
    
    var body: some View {
        ZStack {
            // Pure black background for minimal look
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header area
                HStack {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 17))
                    
                    Spacer()
                    
                    // Subtle clock icon instead of prominent green
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 20))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Main content
                VStack(spacing: 24) {
                    // Title - less prominent
                    Text("Catch Up on Today's Meals")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Subtitle - more subtle
                    Text("You've missed 2 meal windows")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    
                    // Instructions - cleaner layout
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Describe all the meals you had today")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        // Bullet points - minimal styling
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                Text("Include restaurant names for accurate nutrition")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                Text("We'll ask when you ate each meal next")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                Text("Describe everything - drinks, sides, desserts")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Example text - very subtle
                    Text("Examples:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.top, 30)
                    
                    Text("\"I had scrambled eggs and toast for breakfast, a Ch...\"")
                        .font(.system(size: 14))
                        .italic()
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Voice input button - minimal design
                    Button(action: {
                        toggleRecording()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .stroke(Color.white.opacity(isRecording ? 0.3 : 0.1), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 28))
                                .foregroundColor(isRecording ? .white : .white.opacity(0.5))
                        }
                    }
                    
                    Text(isRecording ? "Listening..." : "Tap to speak")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 8)
                    
                    // Text input option
                    Text("or type your description:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.top, 30)
                    
                    // Text field - minimal styling
                    TextField("", text: $mealDescription, axis: .vertical)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .lineLimit(3...6)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Continue button - much more subtle
                    Button(action: {
                        if !mealDescription.isEmpty {
                            onSubmit(mealDescription)
                        }
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.system(size: 17, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(mealDescription.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(mealDescription.isEmpty ? Color.white.opacity(0.05) : Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(mealDescription.isEmpty ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(mealDescription.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    isRecording = true
                    speechRecognizer.startTranscribing { transcription in
                        mealDescription = transcription
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        speechRecognizer.stopTranscribing()
    }
}

// Mock speech recognizer for development
private class MockSpeechRecognizer {
    private var timer: Timer?
    private var completion: ((String) -> Void)?
    
    func startTranscribing(completion: @escaping (String) -> Void) {
        self.completion = completion
        
        // Simulate gradual transcription
        var text = ""
        let words = ["I had", "scrambled eggs", "and toast", "for breakfast,", "a chicken salad", "for lunch,", "and pasta", "with marinara", "for dinner"]
        var wordIndex = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if wordIndex < words.count {
                text += (text.isEmpty ? "" : " ") + words[wordIndex]
                completion(text)
                wordIndex += 1
            } else {
                self.stopTranscribing()
            }
        }
    }
    
    func stopTranscribing() {
        timer?.invalidate()
        timer = nil
    }
}

// Preview
struct CatchUpMealsView_Previews: PreviewProvider {
    static var previews: some View {
        CatchUpMealsView { description in
            print("User described: \(description)")
        }
    }
}