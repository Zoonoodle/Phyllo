//
//  HexagonFlowerView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct HexagonFlowerView: View {
    let micronutrients: [(name: String, percentage: Double)]
    var size: CGFloat = 180 // Default size, can be customized
    var showLabels: Bool = true // Option to show/hide labels
    var showPurposeText: Bool = true // Option to show/hide purpose text
    
    // Overall score is average of all micronutrients
    private var overallScore: Int {
        let average = micronutrients.reduce(0) { $0 + $1.percentage } / Double(micronutrients.count)
        return Int(average * 100)
    }
    
    // Calculate total petals based on new formula
    // 50% = 1 petal, >90% = 2 petals
    private var totalPetals: Int {
        micronutrients.reduce(0) { total, nutrient in
            if nutrient.percentage >= 0.9 {
                return total + 2
            } else if nutrient.percentage >= 0.5 {
                return total + 1
            }
            return total
        }
    }
    
    // Create petal data with colors based on which nutrient they represent
    private var petalData: [(color: Color, rotation: Double, nutrientName: String, icon: String)] {
        var petals: [(color: Color, rotation: Double, nutrientName: String, icon: String)] = []
        var petalIndex = 0
        
        // Map nutrient names to SF Symbol names
        let nutrientIcons: [String: String] = [
            "Iron": "drop.fill",
            "Vitamin D": "sun.max.fill",
            "Vit D": "sun.max.fill",
            "Calcium": "circle.hexagongrid.fill",
            "B12": "bolt.fill",
            "Folate": "leaf.fill",
            "Zinc": "shield.fill"
        ]
        
        for (index, nutrient) in micronutrients.enumerated() {
            // Use specific color for each nutrient position (not based on percentage)
            let nutrientColors = [
                Color.red,      // Iron
                Color.orange,   // Vitamin D
                Color.blue,     // Calcium
                Color.purple,   // B12
                Color.green,    // Folate
                Color.pink      // Zinc
            ]
            let color = index < nutrientColors.count ? nutrientColors[index] : Color.phylloAccent
            
            let petalCount = nutrient.percentage >= 0.9 ? 2 : (nutrient.percentage >= 0.5 ? 1 : 0)
            let icon = nutrientIcons[nutrient.name] ?? "💊"
            
            for i in 0..<petalCount {
                if petalIndex < 6 { // Max 6 petals
                    let rotation = Double(petalIndex) * 60
                    // Only add name to first petal of each nutrient
                    let name = i == 0 ? nutrient.name : ""
                    petals.append((color: color, rotation: rotation, nutrientName: name, icon: icon))
                    petalIndex += 1
                }
            }
        }
        
        return petals
    }
    
    // Create labels for petals showing which nutrient each represents
    private var petalLabels: [(name: String, rotation: Double)] {
        var labels: [(name: String, rotation: Double)] = []
        var petalIndex = 0
        
        for nutrient in micronutrients {
            let petalCount = nutrient.percentage >= 0.9 ? 2 : (nutrient.percentage >= 0.5 ? 1 : 0)
            
            // Add label for first petal of each nutrient
            if petalCount > 0 && petalIndex < 6 {
                let rotation = Double(petalIndex) * 60
                labels.append((name: nutrient.name, rotation: rotation))
                petalIndex += petalCount
            }
        }
        
        return labels
    }
    
    // Get purpose text for each petal based on current window
    private func purposeForPetal(at index: Int) -> String {
        // Map specific micronutrients to their benefits
        let micronutrientToPurpose: [String: String] = [
            "B12": "Energy",
            "Iron": "Energy", 
            "Magnesium": "Recovery",
            "Omega-3": "Focus",
            "B6": "Focus",
            "Vitamin D": "Strength",
            "Vitamin C": "Recovery",
            "Zinc": "Recovery",
            "Potassium": "Recovery",
            "B-Complex": "Energy",
            "Caffeine": "Focus",
            "L-Arginine": "Strength",
            "Protein": "Strength",
            "Leucine": "Strength",
            "Green Tea": "Energy",
            "Chromium": "Energy",
            "L-Carnitine": "Energy",
            "Tryptophan": "Sleep"
        ]
        
        // Find which nutrient this petal belongs to
        var petalIndex = 0
        for nutrient in micronutrients {
            let petalCount = nutrient.percentage >= 0.9 ? 2 : (nutrient.percentage >= 0.5 ? 1 : 0)
            if index >= petalIndex && index < petalIndex + petalCount {
                return micronutrientToPurpose[nutrient.name] ?? "Health"
            }
            petalIndex += petalCount
        }
        return "Health"
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return Color.phylloAccent
        }
    }
    
    var body: some View {
        ZStack {
            // Hexagon petals (draw before circle for proper layering)
            ForEach(Array(petalData.enumerated()), id: \.offset) { index, petal in
                HexagonPetal(
                    color: petal.color,
                    rotation: petal.rotation,
                    purposeText: purposeForPetal(at: index),
                    nutrientName: petal.nutrientName,
                    icon: petal.icon,
                    size: size,
                    showPurposeText: showPurposeText
                )
                .zIndex(0)
            }
            
            // Petal labels with arrows
            if showLabels {
                ForEach(Array(petalLabels.enumerated()), id: \.offset) { index, label in
                    PetalLabel(
                        text: label.name,
                        rotation: label.rotation,
                        offset: size * 0.55,  // Scale with size
                        size: size
                    )
                    .zIndex(2)
                }
            }
            
            // Center circle with overall score (enlarged)
            Circle()
                .fill(Color.phylloBackground)
                .frame(width: size * 0.55, height: size * 0.55) // Scale with size
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 2) {
                        Text("\(overallScore)%")
                            .font(.system(size: size * 0.15, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Micros")
                            .font(.system(size: size * 0.08))
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .zIndex(1)
        }
        .frame(width: size, height: size)
    }
}

struct HexagonPetal: View {
    let color: Color
    let rotation: Double
    let purposeText: String
    var nutrientName: String = ""
    var icon: String = ""
    var size: CGFloat = 180 // Parent size
    var showPurposeText: Bool = true
    
    var body: some View {
        HexagonShape()
            .fill(color.opacity(0.3))
            .overlay(
                HexagonShape()
                    .stroke(color, lineWidth: 2)
            )
            .overlay(
                // Nutrient icon and name inside petal
                VStack(spacing: 2) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.07, weight: .medium))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep upright
                    }
                    
                    if !nutrientName.isEmpty && showPurposeText {
                        Text(nutrientName)
                            .font(.system(size: size * 0.04, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep upright
                    }
                }
            )
            .frame(width: size * 0.33, height: size * 0.4)
            .scaleEffect(0.9) // Larger scale
            .offset(x: size * 0.3) // Scale offset with size
            .rotationEffect(.degrees(rotation))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: rotation)
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        let radius = min(width, height) / 2
        
        var path = Path()
        
        for i in 0..<6 {
            let angle = (Double(i) * 60 - 30) * .pi / 180
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct PetalLabel: View {
    let text: String
    let rotation: Double
    let offset: CGFloat
    var size: CGFloat = 180 // Parent size for scaling
    
    // Determine if text should be on left or right side based on rotation
    private var isLeftSide: Bool {
        let normalizedRotation = rotation.truncatingRemainder(dividingBy: 360)
        // Fix the logic: 120-240 degrees should have text on left
        return normalizedRotation >= 120 && normalizedRotation <= 240
    }
    
    // Determine if arrow should point vertically
    private var isVertical: Bool {
        let normalizedRotation = rotation.truncatingRemainder(dividingBy: 360)
        return (normalizedRotation >= 45 && normalizedRotation <= 135) || 
               (normalizedRotation >= 225 && normalizedRotation <= 315)
    }
    
    var body: some View {
        Group {
            if isLeftSide {
                // Text on left, arrow pointing right
                HStack(spacing: 4) {
                    Text(text)
                        .font(.system(size: size * 0.06, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ArrowShape(pointingLeft: false, isVertical: isVertical)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 15, height: 15)
                }
            } else {
                // Arrow pointing left, text on right
                HStack(spacing: 4) {
                    ArrowShape(pointingLeft: true, isVertical: isVertical)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 15, height: 15)
                    
                    Text(text)
                        .font(.system(size: size * 0.06, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .offset(x: offset * cos(rotation * .pi / 180), y: offset * sin(rotation * .pi / 180))
    }
}

struct ArrowShape: Shape {
    let pointingLeft: Bool
    let isVertical: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isVertical {
            // Vertical arrow
            let midX = rect.midX
            path.move(to: CGPoint(x: midX, y: pointingLeft ? rect.maxY : rect.minY))
            path.addLine(to: CGPoint(x: midX, y: pointingLeft ? rect.minY : rect.maxY))
            
            // Arrowhead
            if pointingLeft {
                path.move(to: CGPoint(x: midX - 3, y: rect.minY + 3))
                path.addLine(to: CGPoint(x: midX, y: rect.minY))
                path.addLine(to: CGPoint(x: midX + 3, y: rect.minY + 3))
            } else {
                path.move(to: CGPoint(x: midX - 3, y: rect.maxY - 3))
                path.addLine(to: CGPoint(x: midX, y: rect.maxY))
                path.addLine(to: CGPoint(x: midX + 3, y: rect.maxY - 3))
            }
        } else {
            // Horizontal arrow
            let midY = rect.midY
            path.move(to: CGPoint(x: pointingLeft ? rect.maxX : rect.minX, y: midY))
            path.addLine(to: CGPoint(x: pointingLeft ? rect.minX : rect.maxX, y: midY))
            
            // Arrowhead
            if pointingLeft {
                path.move(to: CGPoint(x: rect.minX + 3, y: midY - 3))
                path.addLine(to: CGPoint(x: rect.minX, y: midY))
                path.addLine(to: CGPoint(x: rect.minX + 3, y: midY + 3))
            } else {
                path.move(to: CGPoint(x: rect.maxX - 3, y: midY - 3))
                path.addLine(to: CGPoint(x: rect.maxX, y: midY))
                path.addLine(to: CGPoint(x: rect.maxX - 3, y: midY + 3))
            }
        }
        
        return path
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        HexagonFlowerView(micronutrients: [
            ("B12", 0.82),
            ("Iron", 0.91),
            ("Magnesium", 0.78),
            ("Vitamin D", 0.65),
            ("Omega-3", 0.45),
            ("Zinc", 0.88)
        ])
    }
}