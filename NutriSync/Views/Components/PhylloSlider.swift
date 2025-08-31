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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundColor(.nutriSyncTextPrimary)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.headline)
                    .foregroundColor(.nutriSyncAccent)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                        .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 8)
                }
                .frame(height: 8)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(.clear)
                .onChange(of: value) { oldValue, newValue in
                    if abs(newValue - lastHapticValue) >= step {
                        hapticGenerator.impactOccurred()
                        lastHapticValue = newValue
                    }
                }
            
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