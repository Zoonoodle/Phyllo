//
//  MFHealthDisclaimerView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 7 - Dark Theme
//

import SwiftUI

struct MFHealthDisclaimerView: View {
    @State private var acceptHealthDisclaimer = false
    @State private var acceptPrivacyNotice = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("Notice")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 32)
            
            // Progress icons
            HStack(spacing: 0) {
                // Profile icon
                ProgressIcon(icon: "person.fill", isActive: true, isCompleted: true)
                    .overlay(
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(-45))
                            .offset(x: 12, y: -8),
                        alignment: .topTrailing
                    )
                
                ProgressLine(isActive: true)
                
                // Shield icon (current)
                ProgressIcon(icon: "shield.fill", isActive: true, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Target icon
                ProgressIcon(icon: "target", isActive: false, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Graph icon
                ProgressIcon(icon: "chart.line.uptrend.xyaxis", isActive: false, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Food icon
                ProgressIcon(icon: "fork.knife", isActive: false, isCompleted: false)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Health Disclaimer")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("MacroFactor provides educational health information based on your input, not medical advice or personalized counseling. Always consult a healthcare professional before making significant health decisions, such as changes to your diet or exercise routine. Understand and accept the risks involved with using the app, including dietary and physical activity changes. You are responsible for your health decisions and should seek professional guidance when necessary.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Checkboxes
                    VStack(alignment: .leading, spacing: 20) {
                        CheckboxRow(
                            isChecked: $acceptHealthDisclaimer,
                            text: "I Acknowledge and Accept the Terms of the",
                            linkText: "Health Disclaimer",
                            linkColor: .blue
                        )
                        
                        CheckboxRow(
                            isChecked: $acceptPrivacyNotice,
                            text: "I Acknowledge and Accept the Terms of the",
                            linkText: "Consumer Health Privacy Notice",
                            linkColor: .blue
                        )
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Continue button
            Button {
                // Continue action
            } label: {
                Text("Accept and Continue")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(bothAccepted ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(bothAccepted ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(25)
            }
            .disabled(!bothAccepted)
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.nutriSyncBackground)
    }
    
    private var bothAccepted: Bool {
        acceptHealthDisclaimer && acceptPrivacyNotice
    }
}

struct CheckboxRow: View {
    @Binding var isChecked: Bool
    let text: String
    let linkText: String
    let linkColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Custom checkbox
            Button(action: { isChecked.toggle() }) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Text(linkText)
                    .font(.system(size: 17))
                    .foregroundColor(linkColor)
            }
            
            Spacer()
        }
    }
}

struct MFHealthDisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        MFHealthDisclaimerView()
    }
}