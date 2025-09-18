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
    @State private var accumulatedDragOffset: CGFloat = 0
    @State private var hasHitBoundary = false
    @State private var currentDisplayValue: Double = 0
    
    private let tickSpacing: CGFloat = 40
    private let dragSensitivity: CGFloat = 1.5 // Higher = more sensitive
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
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
                    .scrollDisabled(true) // Disable native scrolling - only allow controlled drag
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { dragValue in
                                if !isDragging {
                                    isDragging = true
                                    dragStartValue = value
                                    currentDisplayValue = value
                                    accumulatedDragOffset = 0
                                    hasHitBoundary = false
                                    selectionFeedback.prepare()
                                }
                                
                                // Calculate the raw drag offset with sensitivity adjustment
                                let currentDragOffset = -dragValue.translation.width * dragSensitivity
                                
                                // More fluid calculation with fractional support
                                let effectiveTickSpacing = tickSpacing / dragSensitivity
                                let continuousValue = dragStartValue + (currentDragOffset / effectiveTickSpacing)
                                let targetValue = round(continuousValue)
                                
                                // Check if target is within valid range
                                if targetValue >= validRange.lowerBound && targetValue <= validRange.upperBound {
                                    // Valid move - allow it
                                    if targetValue != value {
                                        value = targetValue
                                        onChanged?(targetValue)
                                        hasHitBoundary = false
                                        
                                        // Lighter haptic feedback for smoother feel
                                        if abs(targetValue - lastHapticValue) >= 1.0 {
                                            selectionFeedback.selectionChanged()
                                            lastHapticValue = targetValue
                                        }
                                        
                                        // Faster, smoother animation
                                        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25)) {
                                            proxy.scrollTo(Int(targetValue), anchor: .center)
                                        }
                                    }
                                    
                                    // Update display value for smoother visual feedback
                                    currentDisplayValue = continuousValue
                                    accumulatedDragOffset = currentDragOffset
                                } else {
                                    // Hit boundary - don't allow scroll past it
                                    let boundaryValue = targetValue < validRange.lowerBound ? validRange.lowerBound : validRange.upperBound
                                    
                                    if value != boundaryValue {
                                        // Move to boundary if not already there
                                        value = boundaryValue
                                        onChanged?(boundaryValue)
                                        
                                        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.9)) {
                                            proxy.scrollTo(Int(boundaryValue), anchor: .center)
                                        }
                                    }
                                    
                                    // Provide feedback only once per boundary hit
                                    if !hasHitBoundary {
                                        impactFeedback.impactOccurred(intensity: 0.8)
                                        hasHitBoundary = true
                                    }
                                    
                                    currentDisplayValue = boundaryValue
                                    // Don't accumulate offset beyond boundary
                                    accumulatedDragOffset = (boundaryValue - dragStartValue) * effectiveTickSpacing
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                scrollPosition = value
                                dragStartValue = value
                                accumulatedDragOffset = 0
                                hasHitBoundary = false
                                
                                // Final snap animation to ensure proper position
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