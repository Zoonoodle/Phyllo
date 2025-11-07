//
//  SuperwallPaywallView.swift
//  NutriSync
//
//  Superwall-powered paywall (replaces RevenueCat PaywallView)
//
//  IMPORTANT: Configure paywalls in Superwall dashboard at https://superwall.com/dashboard
//  Create campaigns for these placements:
//  - grace_period_expired
//  - meal_scan_limit_reached
//  - window_gen_limit_reached
//

import SwiftUI
import SuperwallKit

struct SuperwallPaywallView: View {
    let placement: String
    var onDismiss: (() -> Void)?
    var onSubscribe: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .tint(.nutriSyncAccent)
                Text("Loading subscription options...")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .onAppear {
            presentSuperwallPaywall()
        }
    }

    private func presentSuperwallPaywall() {
        Task { @MainActor in
            print("🎨 Presenting Superwall paywall for: \(placement)")

            // Register the event with Superwall
            // Superwall will automatically show the paywall based on your dashboard configuration
            let result = await Superwall.shared.register(event: placement)

            switch result {
            case .presented(let paywallInfo):
                print("✅ Superwall paywall presented: \(paywallInfo.name)")
                // Superwall handles the rest - wait for delegate callbacks

            case .userIsSubscribed:
                print("✅ User is already subscribed")
                onSubscribe?()
                dismiss()

            case .paywallNotAvailable:
                print("⚠️ Paywall not configured in Superwall dashboard for: \(placement)")
                print("   Go to https://superwall.com/dashboard to create a campaign")
                fallbackToOldPaywall()

            case .holdout:
                print("⚠️ User in holdout group - not showing paywall")
                onDismiss?()
                dismiss()

            case .noRuleMatch:
                print("⚠️ No campaign rule matches placement: \(placement)")
                print("   Check your campaign rules in Superwall dashboard")
                fallbackToOldPaywall()

            @unknown default:
                print("⚠️ Unknown Superwall result")
                onDismiss?()
                dismiss()
            }
        }
    }

    private func fallbackToOldPaywall() {
        // If Superwall isn't configured, show a simple error
        print("⚠️ Superwall not configured - showing fallback")
        onDismiss?()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SuperwallPaywallView(
        placement: "grace_period_expired",
        onDismiss: { print("Dismissed") },
        onSubscribe: { print("Subscribed") }
    )
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
