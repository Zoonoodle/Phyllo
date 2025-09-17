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
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastHapticValue: Double = 0
    @State private var viewWidth: CGFloat = 0
    
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
                // Custom draggable ruler
                HStack(spacing: 0) {
                    ForEach(Int(range.lowerBound)...Int(range.upperBound), id: \.self) { val in
                        let isValid = Double(val) >= validRange.lowerBound && Double(val) <= validRange.upperBound
                        let isMajor = val % 5 == 0
                        let isSelected = Int(value) == val
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(isValid ? accentColor.opacity(isSelected ? 1.0 : 0.5) : Color.white.opacity(0.3))
                                .frame(width: 2, height: isMajor ? majorTickHeight : tickHeight)
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                            
                            if isMajor {
                                Text("\(val)")
                                    .font(.system(size: 12))
                                    .foregroundColor(isValid ? accentColor : Color.white.opacity(0.5))
                                    .opacity(isDragging ? 0.7 : 1.0)
                            }
                        }
                        .frame(width: tickSpacing)
                    }
                }
                .offset(x: scrollOffset + centerX)
                .onAppear {
                    viewWidth = width
                    scrollOffset = -((value - range.lowerBound) * tickSpacing)
                }
                .onChange(of: value) { oldValue, newValue in
                    if !isDragging {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scrollOffset = -((newValue - range.lowerBound) * tickSpacing)
                        }
                    }
                }
                
                // Center indicator
                VStack {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 3, height: majorTickHeight + 10)
                        .overlay(
                            Triangle()
                                .fill(accentColor)
                                .frame(width: 12, height: 8)
                                .offset(y: -(majorTickHeight + 10) / 2 - 4)
                        )
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { dragValue in
                        if !isDragging {
                            isDragging = true
                            impactFeedback.prepare()
                        }
                        
                        // Update scroll offset based on drag
                        let newOffset = scrollOffset + dragValue.translation.width
                        
                        // Calculate value from offset
                        let offsetValue = -(newOffset / tickSpacing) + range.lowerBound
                        let clampedValue = max(validRange.lowerBound, min(validRange.upperBound, round(offsetValue)))
                        
                        // Update value if changed
                        if clampedValue != value {
                            // Haptic feedback for each pound change
                            if abs(clampedValue - lastHapticValue) >= 1.0 {
                                impactFeedback.impactOccurred()
                                lastHapticValue = clampedValue
                            }
                            
                            value = clampedValue
                            onChanged?(clampedValue)
                        }
                        
                        // Update visual offset
                        scrollOffset = -((clampedValue - range.lowerBound) * tickSpacing)
                    }
                    .onEnded { _ in
                        isDragging = false
                        
                        // Animate to snap to nearest value
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scrollOffset = -((value - range.lowerBound) * tickSpacing)
                        }
                    }
            )
            .clipped()
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