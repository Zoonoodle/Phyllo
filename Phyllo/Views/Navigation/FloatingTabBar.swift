import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        FloatingTab(icon: "house.fill", id: 0),
        FloatingTab(icon: "chart.bar.fill", id: 1),
        FloatingTab(icon: "plus", id: 2)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                FloatingTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab.id,
                    action: { selectedTab = tab.id }
                )
            }
        }
        .frame(height: 56) // 70 * 0.8
        .background(
            RoundedRectangle(cornerRadius: 28) // 35 * 0.8
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 48) // 60 * 0.8
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

struct FloatingTabButton: View {
    let tab: FloatingTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
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

struct FloatingTabBarContainer<Content: View>: View {
    @Binding var selectedTab: Int
    let content: Content
    
    init(selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 24)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FloatingTabBarContainer(selectedTab: .constant(0)) {
            Text("Content Area")
                .foregroundColor(.white)
        }
    }
}