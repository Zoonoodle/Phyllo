//
//  PaywallView.swift
//  NutriSync
//
//  Created by Claude on 2025-10-29.
//  Superwall paywall presentation
//

import SwiftUI
import SuperwallKit

struct PaywallView: View {
    let placement: String
    var onDismiss: (() -> Void)?
    var onSubscribe: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPresenting = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !isPresenting {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.green)
                    Text("Loading...")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            presentPaywall()
        }
        .alert("Paywall Error", isPresented: $showError) {
            Button("OK") {
                onDismiss?()
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func presentPaywall() {
        isPresenting = true

        // Register Superwall event to trigger paywall
        Superwall.shared.register(event: placement) { result in
            switch result {
            case .presented:
                print("✅ Paywall presented: \(placement)")

            case .purchased:
                print("✅ User subscribed!")
                onSubscribe?()
                dismiss()

            case .closed:
                print("ℹ️ Paywall dismissed")
                onDismiss?()
                dismiss()

            case .error(let error):
                print("❌ Paywall error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        placement: "test_placement",
        onDismiss: { print("Dismissed") },
        onSubscribe: { print("Subscribed") }
    )
}
