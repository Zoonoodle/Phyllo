import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        FloatingTab(icon: "calendar", id: 0),
        FloatingTab(icon: "chart.line.uptrend.xyaxis", id: 1),
        FloatingTab(icon: "camera", id: 2)
    ]
    
    var isScanView: Bool {
        selectedTab == 2
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                FloatingTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab.id,
                    isScanView: isScanView,
                    action: { selectedTab = tab.id }
                )
            }
        }
        .frame(width: 180, height: 56) // Fixed width to prevent resizing
        .background(
            Group {
                if isScanView {
                    // Ultra transparent background for ScanView
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.2))
                        .background(
                            .ultraThinMaterial.opacity(0.3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                } else {
                    // Regular solid background for other views
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
        )
        .shadow(color: .black.opacity(isScanView ? 0.1 : 0.15), radius: isScanView ? 4 : 8, y: isScanView ? 2 : 4)
    }
}

struct FloatingTabButton: View {
    let tab: FloatingTab
    let isSelected: Bool
    let isScanView: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(
                    isSelected ? 
                    (isScanView ? .white.opacity(0.9) : .white) : 
                    (isScanView ? .white.opacity(0.5) : .white.opacity(0.4))
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FloatingTab: Identifiable {
    let icon: String
    let id: Int
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            FloatingTabBar(selectedTab: .constant(0))
                .padding(.bottom, 20)
        }
    }
}
