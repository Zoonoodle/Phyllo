//
//  MissedWindowNudge.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct MissedWindowNudge: View {
    let window: MealWindow
    let onResponse: (Bool) -> Void // true = ate, false = skipped
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap for this nudge
                }
            
            VStack {
                Spacer()
                
                CoachingCard(
                    message: "I noticed your \(windowName) window just ended. Did you have a chance to eat during this time?",
                    suggestion: "Logging meals helps us better understand your patterns and provide more accurate recommendations.",
                    actions: [
                        ("Yes, I ate", {
                            onResponse(true)
                        }),
                        ("No, I skipped", {
                            onResponse(false)
                        })
                    ],
                    onDismiss: {
                        onResponse(false) // Treat dismiss as skip
                    },
                    avatarIcon: "questionmark.circle.fill",
                    mood: .concerned
                )
                .padding(.horizontal, 20)
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private var windowName: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        
        switch hour {
        case 5...10:
            return "breakfast"
        case 11...14:
            return "lunch"
        case 15...17:
            return "snack"
        case 18...21:
            return "dinner"
        default:
            return "late snack"
        }
    }
}

// Preview
struct MissedWindowNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            MissedWindowNudge(
                window: MealWindow.mockWindows(for: .performanceFocus)[0],
                onResponse: { ate in
                    print(ate ? "User ate" : "User skipped")
                }
            )
        }
    }
}