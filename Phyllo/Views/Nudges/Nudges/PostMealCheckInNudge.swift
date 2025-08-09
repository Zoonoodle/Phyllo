//
//  PostMealCheckInNudge.swift
//  Phyllo
//
//  Created on 8/9/25.
//

import SwiftUI

struct PostMealCheckInNudge: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @State private var animateContent = false
    
    let meal: LoggedMeal
    let onCheckIn: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.phylloAccent)
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .opacity(animateContent ? 1 : 0)
                
                VStack(spacing: 8) {
                    Text("How are you feeling?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Quick check-in after your \(meal.name)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Not Now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Button(action: onCheckIn) {
                        Text("Check In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.phylloAccent)
                            )
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.phylloBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(animateContent ? 1 : 0.9)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

// Preview
struct PostMealCheckInNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            PostMealCheckInNudge(
                meal: LoggedMeal(
                    name: "Grilled Salmon with Quinoa",
                    calories: 450,
                    protein: 35,
                    carbs: 42,
                    fat: 18,
                    timestamp: Date(),
                    windowId: UUID(),
                    micronutrients: [:],
                    ingredients: [],
                    imageData: nil,
                    appliedClarifications: [:]
                ),
                onCheckIn: {
                    print("Check-in tapped")
                },
                onDismiss: {
                    print("Nudge dismissed")
                }
            )
        }
    }
}