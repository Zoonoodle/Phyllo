import SwiftUI

// Moon Phase Slider - unique circular slider for sleep hours
struct MoonPhaseSlider: View {
    @Binding var hours: Double
    let range: ClosedRange<Double> = 4...12
    let onChanged: ((Double) -> Void)?
    
    @State private var isDragging = false
    @State private var angle: Double = 0
    
    private let accentColor = Color(hex: "C0FF73")
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2 - 30
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 40)
                    .frame(width: size - 60, height: size - 60)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: normalizedValue)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 40, lineCap: .round)
                    )
                    .frame(width: size - 60, height: size - 60)
                    .rotationEffect(.degrees(-90))
                
                // Moon phases around the circle
                ForEach(0..<9) { index in
                    let moonAngle = Double(index) * 40 - 90
                    let moonPhase = Double(index + 4)
                    let isActive = moonPhase <= hours
                    
                    VStack(spacing: 4) {
                        Image(systemName: moonIconForPhase(index))
                            .font(.system(size: 20))
                            .foregroundColor(isActive ? accentColor : Color.white.opacity(0.3))
                        
                        Text("\(Int(moonPhase))h")
                            .font(.system(size: 12))
                            .foregroundColor(isActive ? accentColor : Color.white.opacity(0.5))
                    }
                    .position(
                        x: size/2 + CGFloat(cos(moonAngle * .pi / 180)) * radius,
                        y: size/2 + CGFloat(sin(moonAngle * .pi / 180)) * radius
                    )
                }
                
                // Center display
                VStack(spacing: 8) {
                    Text("\(String(format: "%.1f", hours))")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("hours")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Sleep quality indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    hours >= Double(star * 2 + 4) ? accentColor : Color.white.opacity(0.2)
                                )
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Draggable handle
                Circle()
                    .fill(accentColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "moon.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    )
                    .shadow(color: accentColor.opacity(0.5), radius: 10)
                    .position(
                        x: size/2 + CGFloat(cos(angleForValue * .pi / 180)) * (radius - 20),
                        y: size/2 + CGFloat(sin(angleForValue * .pi / 180)) * (radius - 20)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    selectionFeedback.prepare()
                                }
                                
                                let center = CGPoint(x: size/2, y: size/2)
                                let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                                var degrees = angle * 180 / .pi + 90
                                if degrees < 0 { degrees += 360 }
                                if degrees > 320 { degrees = 320 } // Max at 12 hours
                                
                                let newHours = 4 + (degrees / 40)
                                let clampedHours = min(max(newHours, range.lowerBound), range.upperBound)
                                
                                if abs(clampedHours - hours) >= 0.1 {
                                    hours = round(clampedHours * 10) / 10
                                    onChanged?(hours)
                                    selectionFeedback.selectionChanged()
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                impactFeedback.impactOccurred()
                            }
                    )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var normalizedValue: Double {
        (hours - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var angleForValue: Double {
        -90 + (normalizedValue * 320)
    }
    
    private func moonIconForPhase(_ index: Int) -> String {
        let icons = [
            "moon.zzz", "moon.circle", "moon", "moon.circle.fill",
            "moon.fill", "moon.stars", "moon.stars.fill", "moon.haze", "moon.zzz.fill"
        ]
        return icons[index]
    }
}

struct SleepQualityGoalView: View {
    @State private var targetHours: Double = 8.0
    @State private var currentAverage: Double = 5.5
    
    private let accentColor = Color(hex: "C0FF73")
    
    var lastMealCutoff: String {
        // Calculate based on target hours (e.g., stop eating 3 hours before sleep)
        let bedtime = 23.0 // 11 PM default
        let cutoff = bedtime - 3
        let hour = Int(cutoff)
        let minutes = Int((cutoff - Double(hour)) * 60)
        return String(format: "%d:%02d PM", hour > 12 ? hour - 12 : hour, minutes)
    }
    
    var projectedDate: String {
        // Calculate days to achieve goal
        let improvement = targetHours - currentAverage
        let daysNeeded = Int(improvement * 7) // Rough estimate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let targetDate = Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date()) ?? Date()
        return formatter.string(from: targetDate)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0a0a0a")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Sleep Quality Goal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("\(String(format: "%.1f", currentAverage)) hrs")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("current average")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            VStack(spacing: 4) {
                                Text(lastMealCutoff)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(accentColor)
                                Text("last meal cutoff")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.top, 16)
                    }
                    
                    // Question
                    Text("What is your target sleep duration?")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)
                    
                    // Moon Phase Slider
                    MoonPhaseSlider(hours: $targetHours) { value in
                        // Handle changes
                    }
                    .frame(height: 300)
                    .padding(.horizontal, 20)
                    
                    // Sleep optimization info
                    VStack(spacing: 16) {
                        Text("Sleep optimization strategy")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach([
                                ("No meals", "3 hours before bed"),
                                ("Light dinner", "Optimized for sleep"),
                                ("Morning protein", "Enhanced recovery")
                            ], id: \.0) { item in
                                HStack {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 6, height: 6)
                                    Text(item.0)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(item.1)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    // Projected timeline
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Projected achievement")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Text(projectedDate)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Daily improvement")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Text("+15 min")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Warning if aggressive
                    if targetHours - currentAverage > 3 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("This is an ambitious goal. We'll adjust your meal windows gradually.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 40)
            }
        }
    }
}

#Preview {
    SleepQualityGoalView()
}