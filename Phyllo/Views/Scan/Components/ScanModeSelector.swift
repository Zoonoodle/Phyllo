//
//  ScanModeSelector.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScanModeSelector: View {
    @Binding var selectedMode: ScanTabView.ScanMode
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(ScanTabView.ScanMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .semibold))
                        
                        if selectedMode == mode {
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                        }
                    }
                    .foregroundColor(selectedMode == mode ? .black : .white.opacity(0.6))
                    .padding(.horizontal, selectedMode == mode ? 16 : 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedMode == mode {
                                Capsule()
                                    .fill(Color.white)
                                    .matchedGeometryEffect(id: "selector", in: namespace)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, y: 2)
    }
}

// Extension to make scan mode work better
extension ScanTabView.ScanMode {
    var description: String {
        switch self {
        case .photo:
            return "Take a photo of your meal"
        case .voice:
            return "Describe your meal verbally"
        case .barcode:
            return "Scan product barcodes"
        }
    }
    
    var color: Color {
        switch self {
        case .photo:
            return .blue
        case .voice:
            return .green
        case .barcode:
            return .orange
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            ScanModeSelector(selectedMode: .constant(.photo))
            ScanModeSelector(selectedMode: .constant(.voice))
            ScanModeSelector(selectedMode: .constant(.barcode))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}