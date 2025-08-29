//
//  SleepHoursSlider.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct SleepHoursSlider: View {
    @Binding var hours: Double
    @State private var isDragging = false
    @State private var lastHapticValue: Double = 0
    
    private let minHours: Double = 0
    private let maxHours: Double = 12
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 20) {
            // Hours display
            HStack(spacing: 4) {
                Text(hoursText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hours)
                
                Text("hours")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .offset(y: 4)
            }
            
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    // Active track with gradient
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.nutriSyncAccent.opacity(0.6),
                                    Color.nutriSyncAccent
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(hours / maxHours), height: 6)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: hours)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                        .offset(x: thumbOffset(in: geometry.size.width))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDrag(value: value, in: geometry.size.width)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    
                    // Hour markers
                    ForEach(0...12, id: \.self) { hour in
                        if hour % 2 == 0 {
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 1, height: 8)
                                
                                Text("\(hour)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.nutriSyncTextTertiary)
                            }
                            .offset(x: markerOffset(for: hour, in: geometry.size.width) - 0.5, y: 10)
                        }
                    }
                }
                .frame(height: 40)
            }
            .frame(height: 40)
        }
        .onAppear {
            hapticGenerator.prepare()
        }
    }
    
    private var hoursText: String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        
        if minutes == 0 {
            return "\(wholeHours)"
        } else if minutes == 15 {
            return "\(wholeHours):15"
        } else if minutes == 30 {
            return "\(wholeHours):30"
        } else if minutes == 45 {
            return "\(wholeHours):45"
        } else {
            return String(format: "%.2f", hours)
        }
    }
    
    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let progress = hours / maxHours
        return progress * width - 14 // Center the thumb
    }
    
    private func markerOffset(for hour: Int, in width: CGFloat) -> CGFloat {
        let progress = Double(hour) / maxHours
        return progress * width
    }
    
    private func handleDrag(value: DragGesture.Value, in width: CGFloat) {
        if !isDragging {
            isDragging = true
        }
        
        let location = value.location.x
        let progress = max(0, min(1, location / width))
        let newHours = progress * maxHours
        
        // Round to nearest 0.25 hour (15 minutes)
        let roundedHours = round(newHours * 4) / 4
        hours = roundedHours
        
        // Haptic feedback on each 0.25 hour increment
        if roundedHours != lastHapticValue {
            hapticGenerator.impactOccurred()
            lastHapticValue = roundedHours
        }
    }
}

// MARK: - Alternative Circular Slider
struct CircularSleepSlider: View {
    @Binding var hours: Double
    @State private var angle: Double = 0
    @State private var isDragging = false
    
    private let minHours: Double = 0
    private let maxHours: Double = 12
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.nutriSyncAccent.opacity(0.6),
                                Color.nutriSyncAccent
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hours)
                
                // Center text
                VStack(spacing: 4) {
                    Text(hoursText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text("hours")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nutriSyncTextSecondary)
                }
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(y: -100)
                    .rotationEffect(.degrees(angle))
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleCircularDrag(value: value)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            // Quick select buttons
            HStack(spacing: 16) {
                ForEach([4.0, 6.0, 8.0, 10.0], id: \.self) { quickHours in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            hours = quickHours
                            angle = (quickHours / maxHours) * 360
                        }
                        hapticGenerator.impactOccurred()
                    }) {
                        Text("\(Int(quickHours))h")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(hours == quickHours ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(hours == quickHours ? Color.white : Color.white.opacity(0.1))
                            )
                    }
                }
            }
        }
        .onAppear {
            hapticGenerator.prepare()
            angle = (hours / maxHours) * 360
        }
    }
    
    private var progress: CGFloat {
        CGFloat(hours / maxHours)
    }
    
    private var hoursText: String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        
        if minutes == 0 {
            return "\(wholeHours)"
        } else {
            return String(format: "%.1f", hours)
        }
    }
    
    private func handleCircularDrag(value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
        }
        
        let center = CGPoint(x: 100, y: 100)
        let point = value.location
        
        let angle = atan2(point.y - center.y, point.x - center.x) + .pi / 2
        var degrees = angle * 180 / .pi
        
        if degrees < 0 {
            degrees += 360
        }
        
        self.angle = degrees
        
        let newHours = (degrees / 360) * maxHours
        let roundedHours = round(newHours * 4) / 4
        
        if hours != roundedHours {
            hours = roundedHours
            hapticGenerator.impactOccurred()
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack(spacing: 60) {
            VStack(spacing: 20) {
                Text("Linear Slider")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                SleepHoursSlider(hours: .constant(7.5))
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                Text("Circular Slider")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                CircularSleepSlider(hours: .constant(7.5))
            }
        }
        .padding()
    }
}