//
//  GetStartedView.swift
//  NutriSync
//
//  Welcome screen with app preview carousel before onboarding
//

import SwiftUI

struct GetStartedView: View {
    @State private var currentIndex = 0
    @State private var timer: Timer?
    @State private var dragAmount = CGSize.zero
    @State private var showLogin = false
    @State private var startOnboarding = false
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    
    let screenshots = [
        "Simulator Screenshot - iPhone 16 Pro - 2025-09-11 at 15.59.13",
        "Simulator Screenshot - iPhone 16 Pro - 2025-09-11 at 15.59.25",
        "Simulator Screenshot - iPhone 16 Pro - 2025-09-12 at 06.08.10",
        "Simulator Screenshot - iPhone 16 Pro - 2025-09-12 at 06.08.21"
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tagline
                Text("Smart meal timing,\nsimplified")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                
                // Carousel Container
                ZStack {
                    // Screenshots with iPhone frame
                    TabView(selection: $currentIndex) {
                        ForEach(0..<screenshots.count, id: \.self) { index in
                            ScreenshotView(imageName: screenshots[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 500)
                    
                    // Navigation arrows (optional, like MacroFactor)
                    HStack {
                        // Left arrow
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex = (currentIndex - 1 + screenshots.count) % screenshots.count
                            }
                            resetTimer()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .opacity(currentIndex > 0 ? 1 : 0.3)
                        
                        Spacer()
                        
                        // Right arrow
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex = (currentIndex + 1) % screenshots.count
                            }
                            resetTimer()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .opacity(currentIndex < screenshots.count - 1 ? 1 : 0.3)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<screenshots.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 20) {
                    // Already have an account
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button {
                            showLogin = true
                        } label: {
                            Text("Log In.")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    
                    // Get Started button
                    Button {
                        startOnboarding = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.nutriSyncBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    
                    // Terms text (smaller, at bottom)
                    Text("By continuing, you agree to our Terms of Service")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                }
                .padding(.bottom, 34)
            }
        }
        .onAppear {
            startAutoAdvance()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $startOnboarding) {
            NutriSyncOnboardingCoordinator()
                .environmentObject(firebaseConfig)
                .environmentObject(FirebaseDataProvider.shared)
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(firebaseConfig)
        }
    }
    
    private func startAutoAdvance() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % screenshots.count
            }
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        startAutoAdvance()
    }
}

// MARK: - Screenshot View with iPhone Frame
struct ScreenshotView: View {
    let imageName: String
    
    var body: some View {
        ZStack {
            // iPhone frame
            iPhoneFrame
            
            // Screenshot
            if let uiImage = UIImage(named: "\(imageName).png") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 541) // iPhone 16 Pro aspect ratio
                    .cornerRadius(30)
                    .padding(8) // Inner padding for frame
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 250, height: 541)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Screenshot")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    )
                    .padding(8)
            }
        }
    }
    
    var iPhoneFrame: some View {
        ZStack {
            // Outer frame
            RoundedRectangle(cornerRadius: 40)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 270, height: 560)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.black.opacity(0.3))
                )
            
            // Notch/Dynamic Island representation
            VStack {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 100, height: 30)
                    .padding(.top, 10)
                Spacer()
            }
            .frame(width: 270, height: 560)
        }
    }
}

// MARK: - Preview
struct GetStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GetStartedView()
            .environmentObject(FirebaseConfig())
    }
}