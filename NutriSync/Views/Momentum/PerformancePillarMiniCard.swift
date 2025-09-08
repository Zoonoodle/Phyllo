//
//  PerformancePillarMiniCard.swift
//  NutriSync
//
//  Mini card version of performance pillars for hero section
//

import SwiftUI

struct PerformancePillarMiniCard: View {
    let title: String
    let percentage: Double
    let color: Color
    let detail: String
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @State private var showInfoPopup = false
    
    var body: some View {
        PerformanceCard {
            HStack(spacing: 16) {
                // Left side: Title and detail
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Right side: Progress and percentage
                HStack(spacing: 12) {
                    // Progress bar (vertical orientation)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(percentage / 100, 1.0))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                        }
                    }
                    .frame(width: 100, height: 8)
                    
                    // Percentage
                    Text("\(Int(percentage))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 70)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                showInfoPopup = true
                onTap?()
            }
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 12) {
        PerformancePillarMiniCard(
            title: "Timing",
            percentage: 75,
            color: .green,
            detail: "On track today"
        )
        
        PerformancePillarMiniCard(
            title: "Nutrients", 
            percentage: 45,
            color: .orange,
            detail: "Building diversity"
        )
        
        PerformancePillarMiniCard(
            title: "Adherence",
            percentage: 90,
            color: .blue,
            detail: "Strong week"
        )
    }
    .padding()
    .background(Color.black)
}