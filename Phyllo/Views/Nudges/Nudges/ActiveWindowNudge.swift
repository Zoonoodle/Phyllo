//
//  ActiveWindowNudge.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ActiveWindowNudge: View {
    let window: MealWindow
    let timeRemaining: Int // in minutes
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        FloatingNudgeCard(
            icon: "clock.fill",
            iconColor: timeRemaining > 30 ? .phylloAccent : .orange,
            title: "\(windowName) window active",
            subtitle: "\(timeRemaining) minutes remaining",
            primaryAction: ("Log Meal", {
                // Switch to scan tab
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootView = window.rootViewController?.view {
                    // Find MainTabView and switch to scan tab
                    NotificationCenter.default.post(name: .switchToScanTab, object: nil)
                }
                onDismiss()
            }),
            secondaryAction: ("Remind Later", {
                onDismiss()
            }),
            onDismiss: onDismiss,
            position: .bottomRight,
            style: .standard
        )
    }
    
    private var windowName: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        
        switch hour {
        case 5...10:
            return "Breakfast"
        case 11...14:
            return "Lunch"
        case 15...17:
            return "Snack"
        case 18...21:
            return "Dinner"
        default:
            return "Late snack"
        }
    }
}

// Notification name for tab switching
extension Notification.Name {
    static let switchToScanTab = Notification.Name("switchToScanTab")
}

// Preview
struct ActiveWindowNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            ActiveWindowNudge(
                window: MockDataManager.shared.mealWindows[0],
                timeRemaining: 45
            ) {
                print("Dismissed")
            }
        }
        .onAppear {
            MockDataManager.shared.completeMorningCheckIn()
            MockDataManager.shared.simulateTime(hour: 12)
        }
    }
}