//
//  ChallengesView.swift
//  Phyllo
//
//  Current health challenges selection
//

import SwiftUI

struct ChallengesView: View {
    @Binding var challenges: Set<HealthChallenge>
    @State private var animateIn = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What challenges are you facing?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select all that apply - we'll help address these")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Challenge Grid
                VStack(spacing: 12) {
                    ForEach(Array(HealthChallenge.allCases.enumerated()), id: \.element) { index, challenge in
                        ChallengeCard(
                            challenge: challenge,
                            isSelected: challenges.contains(challenge),
                            animationDelay: Double(index) * 0.05
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if challenges.contains(challenge) {
                                    challenges.remove(challenge)
                                } else {
                                    challenges.insert(challenge)
                                }
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(x: animateIn ? 0 : -30)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: animateIn)
                    }
                }
                .padding(.horizontal)
                
                // Selection Summary
                if !challenges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(challenges.count) challenges selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.phylloAccent)
                        
                        Text("We'll create a nutrition plan that specifically addresses these areas")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.phylloAccent.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                
                // Skip Info
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("This step is optional. You can always update these later.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .onAppear {
            animateIn = true
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: HealthChallenge
    let isSelected: Bool
    let animationDelay: Double
    let action: () -> Void
    
    var icon: String {
        switch challenge {
        case .afternoonCrashes: return "battery.25"
        case .poorSleep: return "moon.zzz"
        case .irregularMeals: return "clock.badge.exclamationmark"
        case .emotionalEating: return "heart.text.square"
        case .slowMetabolism: return "flame"
        case .digestiveIssues: return "stomach"
        case .cravings: return "takeoutbag.and.cup.and.straw"
        case .lackOfTime: return "timer"
        case .weightLoss: return "arrow.down.circle"
        case .weightGain: return "arrow.up.circle"
        case .brainFog: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch challenge {
        case .afternoonCrashes: return .orange
        case .poorSleep: return .indigo
        case .irregularMeals: return .red
        case .emotionalEating: return .pink
        case .slowMetabolism: return .purple
        case .digestiveIssues: return .green
        case .cravings: return .brown
        case .lackOfTime: return .gray
        case .weightLoss: return .blue
        case .weightGain: return .cyan
        case .brainFog: return .yellow
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? color : .white.opacity(0.5))
                }
                
                // Text
                Text(challenge.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var challenges: Set<HealthChallenge> = []
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ChallengesView(challenges: $challenges)
            }
        }
    }
    
    return PreviewWrapper()
}