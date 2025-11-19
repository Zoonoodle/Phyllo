//
//  SubscriptionManager.swift
//  NutriSync
//
//  Created by Claude on 2025-10-29.
//  RevenueCat subscription management
//

import Foundation
import RevenueCat

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties
    @Published var isSubscribed: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var customerInfo: CustomerInfo?

    // MARK: - Subscription Status
    enum SubscriptionStatus {
        case unknown
        case trial
        case active
        case expired
        case gracePeriod  // Payment issue, still has access
    }

    // MARK: - Private Properties
    private let entitlementID = "NutriSync"  // Must match RevenueCat dashboard entitlement identifier

    // MARK: - Initialization
    private override init() {
        super.init()
    }

    func initialize() async {
        await checkSubscriptionStatus()
        setupPurchaseObserver()
    }

    // MARK: - Subscription Checking

    /// Check current subscription status from RevenueCat
    func checkSubscriptionStatus() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()

            // DEBUG: Print all entitlements
            print("📦 DEBUG checkSubscriptionStatus: All entitlements:")
            for (key, entitlement) in customerInfo?.entitlements.all ?? [:] {
                print("   - \(key): isActive=\(entitlement.isActive), productId=\(entitlement.productIdentifier)")
            }
            print("📦 DEBUG checkSubscriptionStatus: Looking for entitlement: '\(entitlementID)'")
            print("📦 DEBUG checkSubscriptionStatus: Active subscriptions: \(customerInfo?.activeSubscriptions ?? [])")

            let hasActiveEntitlement = customerInfo?.entitlements[entitlementID]?.isActive == true

            isSubscribed = hasActiveEntitlement
            updateSubscriptionStatus()

            print("✅ Subscription status: \(isSubscribed ? "ACTIVE" : "INACTIVE")")
        } catch {
            print("❌ Failed to check subscription: \(error.localizedDescription)")
            isSubscribed = false
            subscriptionStatus = .unknown
        }
    }

    /// Update detailed subscription status based on entitlement info
    private func updateSubscriptionStatus() {
        guard let entitlement = customerInfo?.entitlements[entitlementID] else {
            subscriptionStatus = .unknown
            return
        }

        if entitlement.isActive {
            // Check if in trial period
            if entitlement.periodType == .trial {
                subscriptionStatus = .trial
            } else {
                subscriptionStatus = .active
            }
        } else {
            // Check if in billing grace period (payment failed but still has access)
            if let expirationDate = entitlement.expirationDate,
               Date() < expirationDate {
                subscriptionStatus = .gracePeriod
            } else {
                subscriptionStatus = .expired
            }
        }
    }

    // MARK: - Purchase Methods

    /// Fetch available offerings
    func fetchOfferings() async throws -> Offerings {
        print("📦 Fetching offerings from RevenueCat...")
        let offerings = try await Purchases.shared.offerings()
        print("📦 Offerings response - Current: \(offerings.current?.identifier ?? "nil"), All: \(offerings.all.keys.joined(separator: ", "))")
        if let current = offerings.current {
            print("   Available packages: \(current.availablePackages.count)")
            for package in current.availablePackages {
                print("   - \(package.identifier): \(package.localizedPriceString)")
            }
        } else {
            print("   ⚠️ No current offering found!")
        }
        return offerings
    }

    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)

        // Update local state
        customerInfo = result.customerInfo
        isSubscribed = result.customerInfo.entitlements[entitlementID]?.isActive == true
        updateSubscriptionStatus()

        print("✅ Purchase successful: \(isSubscribed)")

        return result.customerInfo
    }

    /// Restore purchases
    func restorePurchases() async throws -> CustomerInfo {
        let customerInfo = try await Purchases.shared.restorePurchases()

        // Update local state
        self.customerInfo = customerInfo
        isSubscribed = customerInfo.entitlements[entitlementID]?.isActive == true
        updateSubscriptionStatus()

        print("✅ Purchases restored: \(isSubscribed)")

        return customerInfo
    }

    // MARK: - Purchase Observer

    private func setupPurchaseObserver() {
        Purchases.shared.delegate = self
    }

    // MARK: - Subscription Info

    /// Get subscription expiration date
    var expirationDate: Date? {
        return customerInfo?.entitlements[entitlementID]?.expirationDate
    }

    /// Get subscription period type (trial, intro, normal)
    var periodType: PeriodType? {
        return customerInfo?.entitlements[entitlementID]?.periodType
    }

    /// Check if user is in trial
    var isInTrial: Bool {
        return subscriptionStatus == .trial
    }

    /// Get days remaining in subscription
    var daysRemaining: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expirationDate).day
        return days
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: PurchasesDelegate {
    /// Called when customer info is updated (purchase, restore, etc.)
    nonisolated func purchases(
        _ purchases: Purchases,
        receivedUpdated customerInfo: CustomerInfo
    ) {
        Task { @MainActor in
            self.customerInfo = customerInfo

            // DEBUG: Print all entitlements
            print("📦 DEBUG: All entitlements:")
            for (key, entitlement) in customerInfo.entitlements.all {
                print("   - \(key): isActive=\(entitlement.isActive), productId=\(entitlement.productIdentifier)")
            }
            print("📦 DEBUG: Looking for entitlement: '\(self.entitlementID)'")
            print("📦 DEBUG: Active subscriptions: \(customerInfo.activeSubscriptions)")

            self.isSubscribed = customerInfo.entitlements[self.entitlementID]?.isActive == true
            self.updateSubscriptionStatus()

            print("🔄 Subscription updated: \(self.isSubscribed)")

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil
            )
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
