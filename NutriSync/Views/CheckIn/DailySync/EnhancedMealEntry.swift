//
//  EnhancedMealEntry.swift
//  NutriSync
//
//  Voice-enabled meal logging with simple text input
//

import SwiftUI
import Speech
import AVFoundation

struct EnhancedMealEntry: View {
    @Binding var mealName: String
    @Binding var mealTime: Date
    @Binding var estimatedCalories: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    
    // Voice input states
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var voiceInputText = ""
    @State private var showVoiceError = false
    
    // Common meal suggestions with times
    var suggestions: [String] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<10:
            return ["Breakfast", "Coffee", "Oatmeal", "Eggs & Toast", "Smoothie", "Yogurt"]
        case 10..<14:
            return ["Lunch", "Salad", "Sandwich", "Soup", "Burrito", "Snack"]
        case 14..<17:
            return ["Snack", "Protein Bar", "Fruit", "Coffee", "Nuts", "Yogurt"]
        default:
            return ["Dinner", "Chicken", "Pasta", "Steak", "Fish", "Salad"]
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Quick meal suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: { 
                                    mealName = suggestion
                                    // Auto-estimate calories for common meals
                                    autoEstimateCalories(for: suggestion)
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(mealName == suggestion ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            mealName == suggestion ? 
                                            Color.nutriSyncAccent : Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 20) {
                        // Meal name with voice input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What did you eat?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                TextField("e.g. Grilled chicken with rice", text: $mealName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .focused($isNameFocused)
                                
                                // Voice input button
                                Button(action: toggleVoiceInput) {
                                    Image(systemName: isRecording ? "mic.fill.badge.plus" : "mic.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isRecording ? .red : .nutriSyncAccent)
                                        .frame(width: 56, height: 56)
                                        .background(Color.white.opacity(isRecording ? 0.1 : 0.05))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isRecording ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                }
                                .scaleEffect(isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isRecording)
                            }
                            
                            if isRecording {
                                Text("Listening... Say your meal")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        // Time picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When did you eat?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack {
                                DatePicker("", selection: $mealTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                
                                Spacer()
                                
                                // Quick time buttons
                                HStack(spacing: 8) {
                                    Button("Now") {
                                        mealTime = Date()
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.nutriSyncAccent)
                                    
                                    Button("-30m") {
                                        mealTime = Date().addingTimeInterval(-30 * 60)
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    
                                    Button("-1h") {
                                        mealTime = Date().addingTimeInterval(-60 * 60)
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        // Calories (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Estimated calories")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("(optional)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            HStack {
                                TextField("e.g. 450", text: $estimatedCalories)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                
                                // Quick calorie buttons
                                HStack(spacing: 8) {
                                    ForEach(["200", "400", "600"], id: \.self) { cal in
                                        Button(cal) {
                                            estimatedCalories = cal
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Add meal button
                        Button(action: {
                            onSave()
                            dismiss()
                        }) {
                            Text("Add Meal")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.nutriSyncAccent)
                                .cornerRadius(16)
                        }
                        .disabled(mealName.isEmpty)
                        .opacity(mealName.isEmpty ? 0.5 : 1)
                        
                        // Skip for now button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Quick Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
        .onAppear {
            isNameFocused = true
            requestSpeechPermission()
        }
        .alert("Voice Input Error", isPresented: $showVoiceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to use voice input.")
        }
    }
    
    // MARK: - Voice Input Functions
    
    private func toggleVoiceInput() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        speechRecognizer.startRecording { result in
            switch result {
            case .success(let text):
                mealName = text
            case .failure(_):
                showVoiceError = true
            }
        }
        withAnimation {
            isRecording = true
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
        withAnimation {
            isRecording = false
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    private func autoEstimateCalories(for meal: String) {
        // Simple calorie estimates for common meals
        let estimates: [String: String] = [
            "Breakfast": "400",
            "Lunch": "600",
            "Dinner": "700",
            "Snack": "200",
            "Coffee": "50",
            "Salad": "350",
            "Sandwich": "450",
            "Smoothie": "250",
            "Oatmeal": "300",
            "Eggs & Toast": "350",
            "Yogurt": "150",
            "Protein Bar": "200",
            "Fruit": "100",
            "Nuts": "180",
            "Chicken": "500",
            "Pasta": "600",
            "Steak": "700",
            "Fish": "400",
            "Soup": "300",
            "Burrito": "650"
        ]
        
        if let estimate = estimates[meal] {
            estimatedCalories = estimate
        }
    }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(.failure(error))
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(NSError(domain: "SpeechRecognizer", code: 1, userInfo: nil)))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                completion(.success(text))
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            completion(.failure(error))
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
    }
}

// MARK: - Preview
struct EnhancedMealEntry_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedMealEntry(
            mealName: .constant(""),
            mealTime: .constant(Date()),
            estimatedCalories: .constant(""),
            onSave: {}
        )
    }
}