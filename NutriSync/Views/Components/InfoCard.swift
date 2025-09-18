import SwiftUI

struct InfoCard: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    
    init(title: String, value: String, isHighlighted: Bool = false) {
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color(hex: "C0FF73") : Color.clear, lineWidth: 1)
        )
    }
}