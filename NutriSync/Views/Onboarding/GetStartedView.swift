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
        "Image 1",
        "Image",
        "Image 4",
        "Image 5",
        "Image 6",
        "Image 3"
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            // Device carousel layer (behind everything)
            TabView(selection: $currentIndex) {
                ForEach(0..<screenshots.count, id: \.self) { index in
                    ScreenshotView(imageName: screenshots[index])
                        .tag(index)
                        .scaleEffect(1.1) // Slightly larger to extend into space
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea() // Allow it to extend beyond safe area
            
            // Content layer (on top)
            VStack(spacing: 0) {
                // Top section with tagline
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Smart meal timing,\n")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            + Text("Simplified.")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "C0FF73"))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 15)
                    .padding(.bottom, 30)
                    .shadow(color: Color(hex: "C0FF73").opacity(0.3), radius: 8, x: 0, y: 0)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.nutriSyncBackground,
                            Color.nutriSyncBackground.opacity(0.8),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .ignoresSafeArea()
                )
                
                Spacer()
                
                // Navigation arrows in middle
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
                
                Spacer()
                
                // Bottom section with gradient background
                VStack(spacing: 16) {
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
                    
                    // Terms text
                    Text("By continuing, you agree to our Terms of Service")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 34)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.nutriSyncBackground.opacity(0.8),
                            Color.nutriSyncBackground
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                    .ignoresSafeArea()
                )
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
            
            // Screenshot - use imageset name directly
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 260, height: 580) // Larger to fill frame better
                    .clipped()
                    .cornerRadius(35)
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 35)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 260, height: 580)
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
            }
        }
    }
    
    var iPhoneFrame: some View {
        ZStack {
            // Outer frame - taller to extend into space
            RoundedRectangle(cornerRadius: 42)
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: 280, height: 620)
                .background(
                    RoundedRectangle(cornerRadius: 42)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Notch/Dynamic Island representation
            VStack {
                Capsule()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 90, height: 26)
                    .padding(.top, 12)
                Spacer()
            }
            .frame(width: 280, height: 620)
        }
    }
}

// MARK: - Preview
struct GetStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GetStartedView()
            .environmentObject(FirebaseConfig.shared)
    }
}
