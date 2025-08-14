//
//  MoodFocusView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct MoodFocusView: View {
    @Binding var selectedMood: MoodLevel?
    let onComplete: () -> Void
    
    @State private var showCompletion = false
    @State private var animateEmojis = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How's your mood & focus?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll learn which foods boost your mental clarity and mood.")
                    .font(.system(size: 15))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Mood selector
            VStack(spacing: 40) {
                // Emoji mood scale
                HStack(spacing: 24) {
                    ForEach(MoodLevel.allCases, id: \.self) { mood in
                        MoodEmojiButton(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            onSelect: {
                                selectMood(mood)
                            }
                        )
                        .scaleEffect(animateEmojis ? 1.0 : 0.5)
                        .opacity(animateEmojis ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(Double(MoodLevel.allCases.firstIndex(of: mood) ?? 0) * 0.1),
                            value: animateEmojis
                        )
                    }
                }
                
                // Selected mood label
                if let selected = selectedMood {
                    VStack(spacing: 8) {
                        Text(selected.label)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(moodDescription(for: selected))
                            .font(.system(size: 14))
                            .foregroundColor(.nutriSyncTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
            
            // Complete button
            HStack {
                Spacer()
                CheckInButton("", style: .minimal) {
                    completeCheckIn()
                }
                .disabled(selectedMood == nil)
                .opacity(selectedMood == nil ? 0.3 : 1.0)
                .scaleEffect(selectedMood == nil ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMood)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .opacity(showCompletion ? 1.0 : 0.0)
                        .scaleEffect(showCompletion ? 1.0 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCompletion)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateEmojis = true
            }
        }
    }
    
    private func selectMood(_ mood: MoodLevel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedMood = mood
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
    }
    
    private func completeCheckIn() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCompletion = true
        }
        
        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete()
        }
    }
    
    private func moodDescription(for mood: MoodLevel) -> String {
        switch mood {
        case .veryLow: return "We'll find foods to lift your spirits"
        case .low: return "Let's work on boosting your mood"
        case .neutral: return "Room for improvement"
        case .good: return "Great! Let's maintain this"
        case .excellent: return "Amazing! Keep it up"
        }
    }
}

// MARK: - Mood Emoji Button
struct MoodEmojiButton: View {
    let mood: MoodLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var animatePress = false
    @State private var animatePulse = false
    
    var body: some View {
        Button(action: {
            animatePress = true
            onSelect()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePress = false
            }
        }) {
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.nutriSyncAccent, lineWidth: 3)
                        .frame(width: 64, height: 64)
                        .scaleEffect(animatePulse ? 1.1 : 1.0)
                        .opacity(animatePulse ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: animatePulse
                        )
                }
                
                // Emoji
                Text(mood.emoji)
                    .font(.system(size: 48))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .scaleEffect(animatePress ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: animatePress)
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                animatePulse = true
            } else {
                animatePulse = false
            }
        }
    }
}

// MARK: - Completion Animation View
struct CheckInCompletionView: View {
    @State private var animateCheckmark = false
    @State private var animateCircle = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.nutriSyncAccent, lineWidth: 3)
                .frame(width: 120, height: 120)
                .scaleEffect(animateCircle ? 1.0 : 0.5)
                .opacity(animateCircle ? 1.0 : 0)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                .opacity(animateCheckmark ? 1.0 : 0)
                .rotationEffect(.degrees(animateCheckmark ? 0 : -30))
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animateCircle = true
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                animateCheckmark = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        MoodFocusView(
            selectedMood: .constant(nil),
            onComplete: {}
        )
    }
}