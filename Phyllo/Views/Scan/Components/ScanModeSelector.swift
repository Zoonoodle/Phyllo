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
        HStack(spacing: 0) {
            ForEach(ScanTabView.ScanMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedMode == mode ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
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
        
        ScanModeSelector(selectedMode: .constant(.photo))
            .padding()
    }
    .preferredColorScheme(.dark)
}