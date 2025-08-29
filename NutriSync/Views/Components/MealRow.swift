//
//  MealRow.swift
//  NutriSync
//
//  Shared meal row component
//

import SwiftUI

struct MealRow: View {
    let meal: LoggedMeal
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(timeFormatter.string(from: meal.timestamp))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Food emoji
            Text(meal.emoji)
                .font(.system(size: 20))
            
            // Meal info
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("\(meal.calories) 🔥")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(meal.protein)P")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.orange.opacity(0.7))
                    Text("\(meal.fat)F")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.yellow.opacity(0.7))
                    Text("\(meal.carbs)C")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.blue.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Expand arrow
            Image(systemName: "chevron.right.2")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.nutriSyncBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
        )
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}