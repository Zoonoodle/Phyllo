//
//  MacroTag.swift
//  NutriSync
//
//  Shared component for displaying macro nutrient tags
//

import SwiftUI

struct MacroTag: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
            Text("\(Int(value))g")
                .font(.system(size: 11))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }
}