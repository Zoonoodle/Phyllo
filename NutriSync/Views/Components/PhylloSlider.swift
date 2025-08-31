import SwiftUI

struct PhylloSlider: View {
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
                    .foregroundColor(.phylloText)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.headline)
                    .foregroundColor(.phylloAccent)
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
                        HapticManager.shared.impact(style: .light)
                        lastHapticValue = newValue
                    }
                }
            
            HStack {
                Text(lowLabel)
                    .font(.caption)
                    .foregroundColor(.phylloTextSecondary)
                Spacer()
                Text(highLabel)
                    .font(.caption)
                    .foregroundColor(.phylloTextSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: PhylloDesignSystem.cornerRadius)
                .fill(Color.phylloCard)
        )
        .onAppear {
            lastHapticValue = value
        }
    }
}