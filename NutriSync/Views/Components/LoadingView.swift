//
//  LoadingView.swift
//  NutriSync
//
//  Authentication loading state view
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .phylloAccent))
                .scaleEffect(1.5)
                .onAppear {
                    isAnimating = true
                }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.nutriSyncTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phylloBackground)
    }
}

#Preview {
    LoadingView(message: "Initializing...")
        .preferredColorScheme(.dark)
}