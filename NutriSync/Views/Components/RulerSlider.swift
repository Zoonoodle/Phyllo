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
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var dragState = CGSize.zero
    @State private var lastHapticValue: Double = 0
    
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
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
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
                                .id(val)
                            }
                        }
                        .padding(.horizontal, centerX)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    scrollToValue(scrollProxy: scrollProxy, animated: false)
                                }
                            }
                        )
                    }
                    .onChange(of: value) { newValue in
                        if !isDragging {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scrollToValue(scrollProxy: scrollProxy, animated: true)
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .updating($dragState) { value, state, _ in
                                state = value.translation
                            }
                            .onChanged { dragValue in
                                if !isDragging {
                                    isDragging = true
                                    impactFeedback.prepare()
                                }
                                
                                let dragAmount = dragValue.translation.width
                                let ticksChanged = Int(round(-dragAmount / tickSpacing))
                                let newValue = max(validRange.lowerBound, min(validRange.upperBound, value + Double(ticksChanged)))
                                
                                if newValue != value {
                                    value = newValue
                                    onChanged?(newValue)
                                    
                                    if abs(newValue - lastHapticValue) >= 1.0 {
                                        impactFeedback.impactOccurred()
                                        lastHapticValue = newValue
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    scrollToValue(scrollProxy: scrollProxy, animated: true)
                                }
                            }
                    )
                }
                
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
        }
        .onAppear {
            impactFeedback.prepare()
            lastHapticValue = value
        }
    }
    
    private func scrollToValue(scrollProxy: ScrollViewProxy, animated: Bool) {
        let targetId = Int(value)
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollProxy.scrollTo(targetId, anchor: .center)
            }
        } else {
            scrollProxy.scrollTo(targetId, anchor: .center)
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}