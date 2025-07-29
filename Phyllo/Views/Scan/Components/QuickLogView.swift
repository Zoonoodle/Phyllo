//
//  QuickLogView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct QuickLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: QuickLogItem?
    
    // Mock recent meals
    let recentMeals = [
        QuickLogItem(
            id: UUID(),
            name: "Yesterday's Lunch",
            subtitle: "Chicken Bowl with Rice",
            calories: 520,
            icon: "clock.arrow.circlepath",
            lastLogged: Date().addingTimeInterval(-86400) // Yesterday
        ),
        QuickLogItem(
            id: UUID(),
            name: "Morning Coffee",
            subtitle: "Oat Milk Latte",
            calories: 120,
            icon: "cup.and.saucer.fill",
            lastLogged: Date().addingTimeInterval(-7200) // 2 hours ago
        ),
        QuickLogItem(
            id: UUID(),
            name: "Usual Breakfast",
            subtitle: "Scrambled Eggs & Toast",
            calories: 380,
            icon: "sunrise.fill",
            lastLogged: Date().addingTimeInterval(-172800) // 2 days ago
        ),
        QuickLogItem(
            id: UUID(),
            name: "Protein Shake",
            subtitle: "Post-Workout Blend",
            calories: 240,
            icon: "bolt.fill",
            lastLogged: Date().addingTimeInterval(-259200) // 3 days ago
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Quick log options
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(recentMeals) { meal in
                                QuickLogRow(
                                    item: meal,
                                    isSelected: selectedItem?.id == meal.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedItem = meal
                                        }
                                    }
                                )
                            }
                            
                            // Create custom meal button
                            createCustomMealButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    
                    // Bottom action bar
                    if selectedItem != nil {
                        bottomActionBar
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Quick Log")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for balance
                Text("Cancel")
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
        }
    }
    
    private var createCustomMealButton: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("Create Custom Meal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 8)
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedItem?.name ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(selectedItem?.calories ?? 0) calories")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: {
                    // Log the meal
                    dismiss()
                }) {
                    Text("Log Meal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black)
        }
    }
}

struct QuickLogRow: View {
    let item: QuickLogItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .green : .white.opacity(0.5))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(item.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("\(item.calories) cal")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.05),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickLogItem: Identifiable {
    let id: UUID
    let name: String
    let subtitle: String
    let calories: Int
    let icon: String
    let lastLogged: Date
}

#Preview {
    QuickLogView()
        .preferredColorScheme(.dark)
}