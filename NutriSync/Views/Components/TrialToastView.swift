//
//  TrialToastView.swift
//  NutriSync
//
//  Toast notification showing trial time remaining
//

import SwiftUI

struct TrialToastView: View {
    let hoursRemaining: Int
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 16))
                .foregroundColor(.nutriSyncAccent)

            Text(timeRemainingText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nutriSyncAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismissToast()
            }
        }
    }

    private var timeRemainingText: String {
        if hoursRemaining > 1 {
            return "Free trial: \(hoursRemaining) hours remaining"
        } else if hoursRemaining == 1 {
            return "Free trial: 1 hour remaining"
        } else {
            return "Free trial: Less than 1 hour remaining"
        }
    }

    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.phylloBackground
            .ignoresSafeArea()

        VStack {
            TrialToastView(hoursRemaining: 18) {
                print("Toast dismissed")
            }
            .padding(.top, 60)

            Spacer()
        }
    }
}
