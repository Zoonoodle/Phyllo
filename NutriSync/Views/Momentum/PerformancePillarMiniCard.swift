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
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header with title and percentage
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Three dots menu button (visual only for now)
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 20, height: 20)
                }
                
                // Progress bar
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
                .frame(height: 8)
                
                // Bottom section with percentage and detail
                HStack {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(Int(percentage))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .monospacedDigit()
                }
            }
            .padding(16)
        }
        .frame(height: 110)
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
                onTap?()
            }
        }
    }
}

// Preview
#Preview {
    HStack(spacing: 12) {
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