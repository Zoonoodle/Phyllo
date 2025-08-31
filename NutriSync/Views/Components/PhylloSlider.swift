import SwiftUI

struct PhylloSlider: View {
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let gradient: LinearGradient
    let lowLabel: String
    let highLabel: String
    
    @State private var lastHapticValue: Double = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.body)
                .foregroundColor(.nutriSyncTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                        .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 8)
                    
                    // Draggable thumb circle at end of progress
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 12)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let newValue = range.lowerBound + (gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound)
                            let steppedValue = round(newValue / step) * step
                            value = min(max(steppedValue, range.lowerBound), range.upperBound)
                            
                            if abs(value - lastHapticValue) >= step {
                                hapticGenerator.impactOccurred()
                                lastHapticValue = value
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)
            .padding(.vertical, 8)
            
            HStack {
                Text(lowLabel)
                    .font(.caption)
                    .foregroundColor(.nutriSyncTextSecondary)
                Spacer()
                Text(highLabel)
                    .font(.caption)
                    .foregroundColor(.nutriSyncTextSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nutriSyncElevated.opacity(0.5))
        )
        .onAppear {
            lastHapticValue = value
        }
    }
}