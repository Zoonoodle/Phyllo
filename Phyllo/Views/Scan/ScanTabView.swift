//
//  ScanTabView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScanTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @State private var selectedMode: ScanMode = .photo
    @State private var showQuickLog = false
    @State private var showResults = false
    @State private var captureAnimation = false
    
    enum ScanMode: String, CaseIterable {
        case photo = "Photo"
        case voice = "Voice"
        case barcode = "Barcode"
        
        var icon: String {
            switch self {
            case .photo: return "camera.fill"
            case .voice: return "mic.fill"
            case .barcode: return "barcode.viewfinder"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                // Camera preview layer
                CameraPreviewView()
                    .ignoresSafeArea()
                
                // Scanner overlay
                ScannerOverlayView()
                    .ignoresSafeArea()
                
                // Main UI layer
                VStack(spacing: 0) {
                    // Top navigation bar
                    HStack {
                        Button(action: {
                            // Close action - handled by tab navigation
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Scan")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // Show scan history
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 24) {
                        // Quick actions bar
                        QuickActionsBar(showQuickLog: $showQuickLog)
                            .padding(.horizontal, 20)
                        
                        // Mode selector
                        ScanModeSelector(selectedMode: $selectedMode)
                            .padding(.horizontal, 20)
                        
                        // Capture button
                        CaptureButton(
                            mode: selectedMode,
                            isAnimating: $captureAnimation,
                            onCapture: {
                                performCapture()
                            }
                        )
                        .padding(.bottom, 40)
                    }
                    .padding(.bottom, 30)
                }
                .ignoresSafeArea(.keyboard)
            }
            .sheet(isPresented: $showQuickLog) {
                QuickLogView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showResults) {
                FoodAnalysisView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func performCapture() {
        withAnimation(.spring(response: 0.3)) {
            captureAnimation = true
        }
        
        // Simulate capture delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showResults = true
            captureAnimation = false
        }
    }
}

// Placeholder views - will be replaced with actual implementations

struct QuickActionsBar: View {
    @Binding var showQuickLog: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { showQuickLog = true }) {
                Label("Recent", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
            
            Button(action: {}) {
                Label("Favorites", systemImage: "star.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
}





#Preview {
    ScanTabView(showDeveloperDashboard: .constant(false))
}