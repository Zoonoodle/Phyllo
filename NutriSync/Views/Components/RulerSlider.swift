import SwiftUI

struct RulerSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let validRange: ClosedRange<Double>
    let step: Double
    let onChanged: ((Double) -> Void)?
    
    let accentColor = Color(hex: "C0FF73")
    let tickHeight: CGFloat = 20
    let majorTickHeight: CGFloat = 30
    
    @State private var isDragging = false
    @State private var lastHapticValue: Double = 0
    @State private var scrollPosition: Double = 0
    @State private var dragStartValue: Double = 0
    
    private let tickSpacing: CGFloat = 40
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(value: Binding<Double>, 
         range: ClosedRange<Double>,
         validRange: ClosedRange<Double>,
         step: Double = 1.0,
         onChanged: ((Double) -> Void)? = nil) {
        self._value = value
        self.range = range
        self.validRange = validRange
        self.step = step
        self.onChanged = onChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            
            ZStack {
                // Scrollable ruler
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            // Leading spacer to center first value
                            Spacer()
                                .frame(width: centerX)
                            
                            // Ruler ticks
                            ForEach(Int(range.lowerBound)...Int(range.upperBound), id: \.self) { val in
                                let isValid = Double(val) >= validRange.lowerBound && Double(val) <= validRange.upperBound
                                let isMajor = val % 5 == 0
                                let isSelected = Int(value) == val
                                
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(isValid ? accentColor.opacity(isSelected ? 1.0 : 0.6) : Color.white.opacity(0.3))
                                        .frame(width: isSelected ? 3 : 2, height: isMajor ? majorTickHeight : tickHeight)
                                    
                                    if isMajor {
                                        Text("\(val)")
                                            .font(.system(size: 12))
                                            .foregroundColor(isValid ? (isSelected ? accentColor : accentColor.opacity(0.7)) : Color.white.opacity(0.5))
                                            .opacity(isDragging ? 0.6 : 1.0)
                                    }
                                }
                                .frame(width: tickSpacing)
                                .id(val)
                            }
                            
                            // Trailing spacer to center last value
                            Spacer()
                                .frame(width: centerX)
                        }
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { dragValue in
                                if !isDragging {
                                    isDragging = true
                                    dragStartValue = value
                                    impactFeedback.prepare()
                                }
                                
                                // Calculate target value based on drag
                                let dragOffset = -dragValue.translation.width
                                let ticksMoved = round(dragOffset / tickSpacing)
                                let targetValue = dragStartValue + ticksMoved
                                
                                // Clamp to valid range - hard stop at boundaries
                                let clampedValue = max(validRange.lowerBound, min(validRange.upperBound, targetValue))
                                
                                // Only scroll and update if within valid range
                                if clampedValue != value && clampedValue == targetValue {
                                    // This means targetValue is within valid range
                                    value = clampedValue
                                    onChanged?(clampedValue)
                                    
                                    // Haptic feedback for each change
                                    if abs(clampedValue - lastHapticValue) >= 1.0 {
                                        impactFeedback.impactOccurred()
                                        lastHapticValue = clampedValue
                                    }
                                    
                                    // Scroll to the new position
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        proxy.scrollTo(Int(clampedValue), anchor: .center)
                                    }
                                } else if clampedValue != targetValue {
                                    // Trying to drag beyond valid range - provide boundary feedback
                                    if value != clampedValue {
                                        // Snap to the boundary
                                        value = clampedValue
                                        onChanged?(clampedValue)
                                        impactFeedback.impactOccurred(intensity: 1.0) // Strong feedback at boundary
                                        
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            proxy.scrollTo(Int(clampedValue), anchor: .center)
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                scrollPosition = value
                                dragStartValue = value
                                
                                // Final snap animation
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    proxy.scrollTo(Int(value), anchor: .center)
                                }
                            }
                    )
                    .onAppear {
                        scrollPosition = value
                        dragStartValue = value
                        DispatchQueue.main.async {
                            proxy.scrollTo(Int(value), anchor: .center)
                        }
                    }
                    .onChange(of: value) { oldValue, newValue in
                        if !isDragging {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(Int(newValue), anchor: .center)
                            }
                        }
                    }
                }
                
                // Fixed center indicator with arrow
                VStack(spacing: 0) {
                    // Arrow pointing down
                    Triangle()
                        .fill(accentColor)
                        .frame(width: 16, height: 10)
                        .offset(y: -2)
                    
                    // Vertical line
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 3, height: majorTickHeight + 15)
                }
                .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            impactFeedback.prepare()
            lastHapticValue = value
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}