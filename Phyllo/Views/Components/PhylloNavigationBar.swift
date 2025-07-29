//
//  PhylloNavigationBar.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct PhylloNavigationBar: View {
    let title: String
    var showSettingsButton: Bool = false
    var onSettingsTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Phyllo logo
            Image("Image")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 28)
                .foregroundColor(.white)
            
            // Title
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Settings button (if needed)
            if showSettingsButton {
                Button(action: {
                    onSettingsTap?()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.phylloBackground)
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack {
            PhylloNavigationBar(title: "Focus", showSettingsButton: true)
            Spacer()
        }
    }
}