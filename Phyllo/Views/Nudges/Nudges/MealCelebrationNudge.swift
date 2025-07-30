//
//  MealCelebrationNudge.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct MealCelebrationNudge: View {
    let meal: LoggedMeal
    let onDismiss: () -> Void
    var onViewDetails: (() -> Void)? = nil
    
    @State private var animateContent = false
    @State private var animateConfetti = false
    @State private var showNudge = true
    
    var body: some View {
        if showNudge {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissNudge()
                    }
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Success icon with animation
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64, weight: .regular))
                            .foregroundColor(.phylloAccent)
                            .scaleEffect(animateContent ? 1 : 0)
                            .rotationEffect(.degrees(animateContent ? 0 : -30))
                        
                        VStack(spacing: 12) {
                            Text("Great job!")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("\(meal.name) logged")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 16) {
                                MacroTag(value: meal.calories, label: "cal", color: .white.opacity(0.7))
                                MacroTag(value: meal.protein, label: "P", color: .phylloAccent)
                                MacroTag(value: meal.carbs, label: "C", color: .blue)
                                MacroTag(value: meal.fat, label: "F", color: .orange)
                            }
                            .padding(.top, 8)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        // Fun message
                        Text(getRandomMessage())
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1 : 0)
                        
                        // View Details button
                        if onViewDetails != nil {
                            Button(action: {
                                dismissNudge()
                                onViewDetails?()
                            }) {
                                Text("View Details")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.phylloBackground)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.phylloAccent)
                                    )
                            }
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.8)
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: 340)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color.phylloAccent.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .offset(y: animateContent ? 0 : 50)
                    
                    Spacer()
                }
                
                // Confetti particles
                if animateConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateContent = true
                }
                
                withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                    animateConfetti = true
                }
                
                // Auto dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismissNudge()
                }
            }
        }
    }
    
    private func dismissNudge() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            animateContent = false
            showNudge = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private func getRandomMessage() -> String {
        let messages = [
            "You're on track for today!",
            "Every meal counts toward your goals",
            "Keep up the momentum!",
            "Your body thanks you",
            "Consistency is key!"
        ]
        return messages.randomElement() ?? messages[0]
    }
}

struct MacroTag: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
            Text(label)
                .font(.system(size: 14))
        }
        .foregroundColor(color)
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<20 {
            let particle = ConfettiParticle()
            particles.append(particle)
            
            animateParticle(particle)
        }
    }
    
    private func animateParticle(_ particle: ConfettiParticle) {
        withAnimation(.easeOut(duration: particle.duration)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].position.y = UIScreen.main.bounds.height + 50
                particles[index].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var duration: Double
    
    init() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        position = CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: screenHeight * 0.3
        )
        size = CGFloat.random(in: 4...8)
        color = [Color.phylloAccent, .white, .yellow, .orange].randomElement()!
        opacity = Double.random(in: 0.6...1.0)
        duration = Double.random(in: 1.5...2.5)
    }
}

// Preview
struct MealCelebrationNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            MealCelebrationNudge(
                meal: LoggedMeal(
                    name: "Grilled Chicken Salad",
                    calories: 450,
                    protein: 42,
                    carbs: 28,
                    fat: 18,
                    timestamp: Date()
                )
            ) {
                print("Dismissed")
            }
        }
    }
}