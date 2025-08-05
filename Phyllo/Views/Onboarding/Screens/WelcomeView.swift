//
//  WelcomeView.swift
//  Phyllo
//
//  Welcome screen for onboarding
//

import SwiftUI

struct WelcomeView: View {
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 24) {
                // Animated Logo
                ZStack {
                    Circle()
                        .fill(Color.phylloAccent.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: animateIn ? 20 : 40)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.phylloAccent)
                        .rotationEffect(.degrees(animateIn ? 0 : -30))
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIn)
                
                VStack(spacing: 12) {
                    Text("Welcome to Phyllo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your AI-Powered Nutrition Coach")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)
            }
            
            Spacer()
            
            // Feature Cards
            VStack(spacing: 16) {
                FeatureCard(
                    icon: "clock.fill",
                    title: "Smart Meal Windows",
                    description: "Personalized eating schedule for your goals"
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : -50)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
                
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "AI Nutrition Intelligence",
                    description: "Real-time coaching that adapts to you"
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : -50)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Progress",
                    description: "See how nutrition impacts your energy"
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : -50)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateIn)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.phylloAccent.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.phylloAccent)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WelcomeView()
    }
}