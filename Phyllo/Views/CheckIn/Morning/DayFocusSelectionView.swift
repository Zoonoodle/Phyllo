//
//  DayFocusSelectionView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct DayFocusSelectionView: View {
    @Binding var selectedFocuses: Set<MorningCheckIn.DayFocus>
    let onContinue: () -> Void
    
    @State private var animateAppear = false
    
    private let maxSelections = 3
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("What's your main focus for today?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Pick up to 3.")
                    .font(.system(size: 15))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            // Focus grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(MorningCheckIn.DayFocus.allCases, id: \.self) { focus in
                    FocusButton(
                        focus: focus,
                        isSelected: selectedFocuses.contains(focus),
                        isDisabled: !selectedFocuses.contains(focus) && selectedFocuses.count >= maxSelections,
                        onToggle: {
                            toggleFocus(focus)
                        }
                    )
                    .scaleEffect(animateAppear ? 1.0 : 0.8)
                    .opacity(animateAppear ? 1.0 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(MorningCheckIn.DayFocus.allCases.firstIndex(of: focus) ?? 0) * 0.05),
                        value: animateAppear
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            HStack {
                Spacer()
                CheckInButton("", style: .minimal) {
                    onContinue()
                }
                .disabled(selectedFocuses.isEmpty)
                .opacity(selectedFocuses.isEmpty ? 0.3 : 1.0)
                .scaleEffect(selectedFocuses.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedFocuses.isEmpty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateAppear = true
            }
        }
    }
    
    private func toggleFocus(_ focus: MorningCheckIn.DayFocus) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedFocuses.contains(focus) {
                selectedFocuses.remove(focus)
            } else if selectedFocuses.count < maxSelections {
                selectedFocuses.insert(focus)
            }
        }
    }
}

// MARK: - Focus Button
struct FocusButton: View {
    let focus: MorningCheckIn.DayFocus
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void
    
    @State private var animatePress = false
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            
            animatePress = true
            onToggle()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePress = false
            }
        }) {
            VStack(spacing: 8) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.phylloAccent : Color.white.opacity(0.1))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: focus.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? Color.black : Color.white.opacity(0.7))
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.phylloAccent, lineWidth: 3)
                            .frame(width: 76, height: 76)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(animatePress ? 0.85 : 1.0)
                
                // Label
                Text(focus.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color.white : Color.phylloTextSecondary)
            }
            .opacity(isDisabled ? 0.4 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: animatePress)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        DayFocusSelectionView(
            selectedFocuses: .constant(Set()),
            onContinue: {}
        )
    }
}