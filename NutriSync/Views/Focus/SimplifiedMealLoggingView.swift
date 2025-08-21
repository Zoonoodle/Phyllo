//
//  SimplifiedMealLoggingView.swift
//  NutriSync
//
//  Created on 8/20/25.
//

import SwiftUI
import PhotosUI

struct SimplifiedMealLoggingView: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mealDescription = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Voice input state
    @State private var isRecording = false
    @State private var voiceDescription = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Window info header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: windowIcon)
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Logging meal for \(windowTitle)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("\(formatTimeRange(start: window.startTime, end: window.endTime))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 20)
                    
                    // Input options
                    VStack(spacing: 16) {
                        // Photo picker
                        PhotosPicker(selection: $selectedPhotoItem) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                Text("Select Photo")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                if selectedPhotoItem != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Voice input button
                        Button(action: toggleRecording) {
                            HStack {
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 18))
                                    .foregroundColor(isRecording ? .red : .white)
                                Text(isRecording ? "Recording..." : "Voice Description")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                if !voiceDescription.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Text input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or describe your meal")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("e.g., Grilled chicken with rice and vegetables", text: $mealDescription)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Log meal button
                    Button(action: logMeal) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                            }
                            Text("Log Meal")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSubmit ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!canSubmit || isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            if newItem != nil {
                // Clear other inputs when photo is selected
                mealDescription = ""
                voiceDescription = ""
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private var canSubmit: Bool {
        selectedPhotoItem != nil || !mealDescription.isEmpty || !voiceDescription.isEmpty
    }
    
    private var windowTitle: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...12: return "Brunch"
        case 13...15: return "Lunch"
        case 16...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Snack"
        }
    }
    
    private var windowIcon: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "sun.max.fill"
        case 11...15: return "sun.min.fill"
        case 18...21: return "moon.fill"
        default: return "leaf.fill"
        }
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func toggleRecording() {
        // TODO: Implement voice recording
        // For now, just toggle the state
        isRecording.toggle()
        
        if !isRecording && voiceDescription.isEmpty {
            // Simulate voice input for testing
            voiceDescription = "Sample voice description"
        }
    }
    
    private func logMeal() {
        isProcessing = true
        
        Task {
            do {
                if let photoItem = selectedPhotoItem {
                    // Handle photo-based meal logging
                    if let data = try? await photoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Create analyzing meal
                        let analyzingMeal = AnalyzingMeal(
                            timestamp: window.startTime,
                            windowId: window.id
                        )
                        viewModel.addAnalyzingMeal(analyzingMeal)
                        
                        // Analyze the meal
                        await MealCaptureService.shared.analyzeMeal(
                            image: image,
                            voiceNote: voiceDescription.isEmpty ? nil : voiceDescription,
                            timestamp: window.startTime,
                            analyzingMealId: analyzingMeal.id
                        )
                        
                        isPresented = false
                    }
                } else {
                    // Handle text/voice-based meal logging
                    let description = voiceDescription.isEmpty ? mealDescription : voiceDescription
                    
                    // Create analyzing meal
                    let analyzingMeal = AnalyzingMeal(
                        timestamp: window.startTime,
                        windowId: window.id
                    )
                    viewModel.addAnalyzingMeal(analyzingMeal)
                    
                    // Analyze the meal with description only
                    await MealCaptureService.shared.analyzeMeal(
                        image: nil,
                        voiceNote: description,
                        timestamp: window.startTime,
                        analyzingMealId: analyzingMeal.id
                    )
                    
                    isPresented = false
                }
            } catch {
                errorMessage = "Failed to log meal: \(error.localizedDescription)"
                showError = true
                isProcessing = false
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    if let window = viewModel.mealWindows.first {
        SimplifiedMealLoggingView(
            window: window,
            viewModel: viewModel,
            isPresented: $isPresented
        )
    }
}