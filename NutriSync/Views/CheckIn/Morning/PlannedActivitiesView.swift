//
//  PlannedActivitiesView.swift
//  NutriSync
//
//  Planned activities selection for morning check-in
//

import SwiftUI

struct PlannedActivitiesView: View {
    @Binding var selectedActivities: [String]
    let onContinue: () -> Void
    
    let activities = [
        ("briefcase.fill", "Work day"),
        ("figure.run", "Exercise"),
        ("house.fill", "Working from home"),
        ("airplane", "Travel"),
        ("person.2.fill", "Social events"),
        ("book.fill", "Studying"),
        ("sun.max.fill", "Outdoor activities"),
        ("moon.fill", "Late night"),
        ("gamecontroller.fill", "Relaxing"),
        ("heart.fill", "Date night")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("What's on your agenda?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We'll optimize your meal windows around your activities")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Activities grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(activities, id: \.1) { icon, activity in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedActivities.contains(activity) {
                                    selectedActivities.removeAll { $0 == activity }
                                } else {
                                    selectedActivities.append(activity)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(
                                        selectedActivities.contains(activity) ? .white : .white.opacity(0.5)
                                    )
                                
                                Text(activity)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(
                                        selectedActivities.contains(activity) ? .white : .white.opacity(0.7)
                                    )
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        selectedActivities.contains(activity) 
                                        ? Color.nutriSyncAccent.opacity(0.2) 
                                        : Color.white.opacity(0.03)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                selectedActivities.contains(activity) 
                                                ? Color.nutriSyncAccent 
                                                : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                        }
                    }
                }
            }
            
            // Selected count
            if !selectedActivities.isEmpty {
                Text("\(selectedActivities.count) selected")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer(minLength: 0)
            
            // Continue button
            Button {
                // If no activities selected, add "Regular day"
                if selectedActivities.isEmpty {
                    selectedActivities = ["Regular day"]
                }
                onContinue()
            } label: {
                Text("Complete Check-in")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        PlannedActivitiesView(selectedActivities: .constant([])) {
            print("Continue")
        }
    }
    .preferredColorScheme(.dark)
}