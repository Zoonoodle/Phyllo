//
//  CoachingCard.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct CoachingCard: View {
    let message: String
    let suggestion: String?
    let actions: [(title: String, action: () -> Void)]
    let onDismiss: (() -> Void)?
    var avatarIcon: String = "figure.wave"
    var mood: CoachMood = .encouraging
    
    @State private var animateIn = false
    @State private var typingAnimation = false
    @State private var showFullMessage = false
    
    enum CoachMood {
        case encouraging
        case celebratory
        case concerned
        case informative
        
        var color: Color {
            switch self {
            case .encouraging: return .phylloAccent
            case .celebratory: return .yellow
            case .concerned: return .orange
            case .informative: return .blue
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .encouraging: return Color.phylloAccent.opacity(0.1)
            case .celebratory: return Color.yellow.opacity(0.1)
            case .concerned: return Color.orange.opacity(0.1)
            case .informative: return Color.blue.opacity(0.1)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with avatar
            HStack(spacing: 12) {
                // Animated avatar
                Image(systemName: avatarIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(mood.color)
                    .rotationEffect(.degrees(typingAnimation ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                        value: typingAnimation
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NutriSync Coach")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 6, height: 6)
                        
                        Text(moodText)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if let dismiss = onDismiss {
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Message bubble
            VStack(alignment: .leading, spacing: 12) {
                // Main message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(showFullMessage ? nil : 3)
                    .animation(.spring(response: 0.3), value: showFullMessage)
                
                if message.count > 100 && !showFullMessage {
                    Button(action: { showFullMessage = true }) {
                        Text("Read more")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(mood.color)
                    }
                }
                
                // Suggestion (if any)
                if let suggestion = suggestion {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(mood.color)
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(mood.backgroundColor)
                    )
                }
            }
            
            // Action buttons
            if !actions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(actions.indices, id: \.self) { index in
                        Button(action: actions[index].action) {
                            Text(actions[index].title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(index == 0 ? .phylloBackground : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    index == 0 ? 
                                    AnyView(mood.color) : 
                                    AnyView(Color.white.opacity(0.1))
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            index == 0 ? Color.clear : Color.white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(mood.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: mood.color.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateIn = true
            }
            typingAnimation = true
        }
    }
    
    private var moodText: String {
        switch mood {
        case .encouraging: return "Here to help"
        case .celebratory: return "Celebrating with you"
        case .concerned: return "Checking in"
        case .informative: return "Sharing insights"
        }
    }
}

// Preview
struct CoachingCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    CoachingCard(
                        message: "I noticed you haven't logged lunch yet. Your window is closing in 30 minutes!",
                        suggestion: "Quick tip: Take a photo now and log details later",
                        actions: [
                            ("Log Meal", { print("Log meal") }),
                            ("Remind Later", { print("Remind later") })
                        ],
                        onDismiss: { print("Dismissed") },
                        mood: .concerned
                    )
                    
                    CoachingCard(
                        message: "Amazing job! You've hit your protein target 5 days in a row. Your muscle recovery must be thanking you!",
                        suggestion: nil,
                        actions: [
                            ("View Progress", { print("View progress") })
                        ],
                        onDismiss: nil,
                        avatarIcon: "trophy.fill",
                        mood: .celebratory
                    )
                    
                    CoachingCard(
                        message: "Based on your sleep data, having dinner 3 hours before bed could improve your sleep quality. Currently, you're eating 1.5 hours before sleep.",
                        suggestion: "Try moving your dinner window 30 minutes earlier this week",
                        actions: [
                            ("Adjust Schedule", { print("Adjust") }),
                            ("Learn More", { print("Learn") })
                        ],
                        onDismiss: { print("Dismissed") },
                        avatarIcon: "moon.zzz.fill",
                        mood: .informative
                    )
                }
                .padding()
            }
        }
    }
}