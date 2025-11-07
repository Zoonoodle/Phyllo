//
//  SuperwallDelegateHandler.swift
//  NutriSync
//
//  Handles Superwall events (paywall presentations, purchases, dismissals)
//

import Foundation
import SuperwallKit
import RevenueCat

@MainActor
class SuperwallDelegateHandler: SuperwallDelegate {
    static let shared = SuperwallDelegateHandler()

    private init() {}

    // MARK: - SuperwallDelegate Methods

    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .paywallOpen(let paywallInfo):
            print("🎨 Superwall paywall opened: \(paywallInfo.name)")

        case .paywallClose(let paywallInfo):
            print("🎨 Superwall paywall closed: \(paywallInfo.name)")

        case .transactionComplete(let transaction, let product, let paywallInfo):
            print("✅ Purchase completed!")
            print("   Product: \(product.productIdentifier)")
            print("   Paywall: \(paywallInfo.name)")

            // Refresh subscription status
            Task {
                await SubscriptionManager.shared.checkSubscriptionStatus()
                print("✅ Subscription status refreshed after purchase")
            }

        case .transactionFail(let error, let paywallInfo):
            print("❌ Purchase failed: \(error.localizedDescription)")
            print("   Paywall: \(paywallInfo.name)")

        case .transactionRestore(let paywallInfo):
            print("✅ Purchases restored")
            print("   Paywall: \(paywallInfo.name)")

            // Refresh subscription status
            Task {
                await SubscriptionManager.shared.checkSubscriptionStatus()
                print("✅ Subscription status refreshed after restore")
            }

        case .subscriptionStart(let product, let paywallInfo):
            print("🎉 Subscription started!")
            print("   Product: \(product.productIdentifier)")
            print("   Paywall: \(paywallInfo.name)")

        case .freeTrialStart(let product, let paywallInfo):
            print("🎉 Free trial started!")
            print("   Product: \(product.productIdentifier)")
            print("   Paywall: \(paywallInfo.name)")

        case .nonRecurringProductPurchase(let product, let paywallInfo):
            print("✅ Non-recurring product purchased")
            print("   Product: \(product.productIdentifier)")
            print("   Paywall: \(paywallInfo.name)")

        case .paywallDecline(let paywallInfo):
            print("⚠️ User declined paywall: \(paywallInfo.name)")

        case .userAttributes(let attributes):
            print("👤 User attributes: \(attributes)")

        default:
            print("🎨 Superwall event: \(eventInfo.event)")
        }
    }

    func handleLog(level: String, scope: String, message: String?, info: [String: Any]?, error: Error?) {
        // Only log important events, not debug spam
        if level == "error" {
            print("❌ Superwall error [\(scope)]: \(message ?? "")")
            if let error = error {
                print("   Error: \(error.localizedDescription)")
            }
        } else if level == "warn" {
            print("⚠️ Superwall warning [\(scope)]: \(message ?? "")")
        }
    }
}
