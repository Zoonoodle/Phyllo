//
//  PhylloCard.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct PhylloCard<Content: View>: View {
    @State private var isExpanded: Bool
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        isExpanded: Bool = true,
        showChevron: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = State(initialValue: isExpanded)
        self.showChevron = showChevron
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if showChevron {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .push(from: .top)),
                        removal: .opacity.combined(with: .push(from: .bottom))
                    ))
            }
        }
        .background(Color.phylloElevated)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.phylloBorder, lineWidth: 1)
        )
    }
}

// Simple card without expansion
struct SimplePhylloCard<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .background(Color.phylloElevated)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.phylloBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            PhylloCard(title: "Daily Nutrition", subtitle: "0% Complete • 0 windows remaining") {
                Text("Card content")
                    .foregroundColor(.white)
            }
            
            SimplePhylloCard {
                Text("Simple card content")
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
}