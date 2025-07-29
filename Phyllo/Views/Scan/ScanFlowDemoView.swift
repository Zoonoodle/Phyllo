//
//  ScanFlowDemoView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

// This view demonstrates the complete scan flow for testing
struct ScanFlowDemoView: View {
    @State private var currentStep = 0
    
    let steps = [
        "Camera Capture",
        "Voice Input",
        "AI Processing",
        "Clarification",
        "Final Results"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.green : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Current step display
                    Text("Step \(currentStep + 1): \(steps[currentStep])")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Content based on step
                    Group {
                        switch currentStep {
                        case 0:
                            cameraStepPreview
                        case 1:
                            voiceInputPreview
                        case 2:
                            loadingPreview
                        case 3:
                            clarificationPreview
                        case 4:
                            resultsPreview
                        default:
                            EmptyView()
                        }
                    }
                    .frame(height: 500)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        Button("Previous") {
                            if currentStep > 0 {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                        }
                        .disabled(currentStep == 0)
                        .foregroundColor(currentStep == 0 ? .gray : .white)
                        
                        Button("Next") {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .disabled(currentStep == steps.count - 1)
                        .foregroundColor(currentStep == steps.count - 1 ? .gray : .white)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan Flow Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Step Previews
    
    private var cameraStepPreview: some View {
        VStack(spacing: 20) {
            Text("User takes a photo of their meal")
                .foregroundColor(.white.opacity(0.7))
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Camera Preview")
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .frame(height: 300)
            
            CaptureButton(mode: .photo, isAnimating: .constant(false), onCapture: {})
        }
        .padding()
    }
    
    private var voiceInputPreview: some View {
        VStack(spacing: 20) {
            Text("Voice input with captured photo background")
                .foregroundColor(.white.opacity(0.7))
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text("Photo Background (Blurred)")
                            .foregroundColor(.white.opacity(0.3))
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.black)
                    )
            }
            .frame(height: 300)
            
            Text("\"I had a grilled chicken salad with avocado\"")
                .italic()
                .foregroundColor(.green)
        }
        .padding()
    }
    
    private var loadingPreview: some View {
        VStack {
            Text("AI analyzes the meal")
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom)
            
            MealAnalysisLoadingView()
        }
    }
    
    private var clarificationPreview: some View {
        VStack(spacing: 20) {
            Text("AI asks clarifying questions if needed")
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Was any dressing added?")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(["No dressing", "Light dressing (+40 cal)", "Regular dressing (+120 cal)"], id: \.self) { option in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.white.opacity(0.5))
                        Text(option)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private var resultsPreview: some View {
        VStack(spacing: 20) {
            Text("Final nutrition analysis")
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 16) {
                Text("Grilled Chicken Salad")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("420 calories")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 30) {
                    MacroView(value: 35, label: "Protein", color: .blue)
                    MacroView(value: 12, label: "Carbs", color: .orange)
                    MacroView(value: 28, label: "Fat", color: .yellow)
                }
                
                Button("Confirm & Log") {
                    // Log meal
                }
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.top)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .padding()
    }
}

#Preview {
    ScanFlowDemoView()
}