//
//  GracePeriodManager.swift
//  NutriSync
//
//  Created by Claude on 2025-10-29.
//  Grace period tracking: 24-hour timer + usage limits (4 scans, 1 window gen)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

@MainActor
class GracePeriodManager: ObservableObject {
    static let shared = GracePeriodManager()

    // MARK: - Published Properties
    @Published var isInGracePeriod: Bool = false
    @Published var remainingScans: Int = 4
    @Published var remainingWindowGens: Int = 1
    @Published var gracePeriodEndDate: Date?
    @Published var hasSeenPaywallOnce: Bool = false

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let GRACE_PERIOD_HOURS: TimeInterval = 24
    private let MAX_SCANS_IN_GRACE = 4
    private let MAX_WINDOW_GENS_IN_GRACE = 1

    // MARK: - Computed Properties
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Initialization
    private init() {}

    func initialize() async {
        await loadGracePeriodStatus()
        await checkGracePeriodExpiration()
    }

    // MARK: - Grace Period Management

    /// Start grace period for new user (called after account creation)
    func startGracePeriod() async throws {
        guard !userId.isEmpty else {
            throw GracePeriodError.noUser
        }

        // Check if device has already used grace period
        let deviceDoc = try await db.collection("gracePeriodDevices").document(deviceId).getDocument()
        if deviceDoc.exists {
            print("⚠️ Device has already used grace period")
            // Don't start new grace period, but load existing status
            await loadGracePeriodStatus()
            return
        }

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(GRACE_PERIOD_HOURS * 3600)

        let gracePeriodData: [String: Any] = [
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "remainingScans": MAX_SCANS_IN_GRACE,
            "remainingWindowGens": MAX_WINDOW_GENS_IN_GRACE,
            "hasSeenPaywallOnce": false,
            "deviceId": deviceId
        ]

        // Save to Firestore
        try await db.collection("users").document(userId)
            .collection("subscription").document("gracePeriod")
            .setData(gracePeriodData)

        // Mark device as used
        try await db.collection("gracePeriodDevices").document(deviceId).setData([
            "usedAt": Timestamp(date: Date()),
            "userId": userId
        ])

        // Update local state
        isInGracePeriod = true
        remainingScans = MAX_SCANS_IN_GRACE
        remainingWindowGens = MAX_WINDOW_GENS_IN_GRACE
        gracePeriodEndDate = endDate
        hasSeenPaywallOnce = false

        // Save to UserDefaults as backup
        saveToUserDefaults()

        print("✅ Grace period started: \(MAX_SCANS_IN_GRACE) scans, \(MAX_WINDOW_GENS_IN_GRACE) window gen, expires \(endDate)")
    }

    /// Load grace period status from Firestore
    private func loadGracePeriodStatus() async {
        guard !userId.isEmpty else {
            print("⚠️ No user ID, loading from UserDefaults")
            loadFromUserDefaults()
            return
        }

        do {
            let doc = try await db.collection("users").document(userId)
                .collection("subscription").document("gracePeriod")
                .getDocument()

            if let data = doc.data() {
                remainingScans = data["remainingScans"] as? Int ?? 0
                remainingWindowGens = data["remainingWindowGens"] as? Int ?? 0
                hasSeenPaywallOnce = data["hasSeenPaywallOnce"] as? Bool ?? false

                if let endTimestamp = data["endDate"] as? Timestamp {
                    gracePeriodEndDate = endTimestamp.dateValue()
                    isInGracePeriod = Date() < endTimestamp.dateValue()
                }

                // Save to UserDefaults as backup
                saveToUserDefaults()

                print("✅ Loaded grace period: \(remainingScans) scans, \(remainingWindowGens) gens, in grace: \(isInGracePeriod)")
            } else {
                print("⚠️ No grace period data found")
                isInGracePeriod = false
            }
        } catch {
            print("❌ Failed to load grace period: \(error.localizedDescription)")
            // Fallback to UserDefaults
            loadFromUserDefaults()
        }
    }

    /// Check if grace period has expired
    func checkGracePeriodExpiration() async {
        guard let endDate = gracePeriodEndDate else { return }

        if Date() > endDate {
            isInGracePeriod = false

            // Notify app to show paywall
            NotificationCenter.default.post(
                name: .gracePeriodExpired,
                object: nil
            )

            print("⏰ Grace period EXPIRED")
        }
    }

    // MARK: - Usage Tracking

    /// Check if user can scan a meal
    func canScanMeal() -> Bool {
        return isInGracePeriod && remainingScans > 0
    }

    /// Record a meal scan (decrements counter)
    func recordMealScan() async throws {
        guard !userId.isEmpty else {
            throw GracePeriodError.noUser
        }

        guard canScanMeal() else {
            throw GracePeriodError.scanLimitReached
        }

        // Decrement in Firestore atomically
        try await db.collection("users").document(userId)
            .collection("subscription").document("gracePeriod")
            .updateData([
                "remainingScans": FieldValue.increment(Int64(-1))
            ])

        // Update local state
        remainingScans -= 1
        saveToUserDefaults()

        print("📸 Scan recorded: \(remainingScans) remaining")

        // Check if limit reached
        if remainingScans <= 0 {
            await showLimitReachedPaywall(type: .scans)
        }
    }

    /// Check if user can generate windows
    func canGenerateWindows() -> Bool {
        return isInGracePeriod && remainingWindowGens > 0
    }

    /// Record window generation (decrements counter)
    func recordWindowGeneration() async throws {
        guard !userId.isEmpty else {
            throw GracePeriodError.noUser
        }

        guard canGenerateWindows() else {
            throw GracePeriodError.windowGenLimitReached
        }

        // Decrement in Firestore atomically
        try await db.collection("users").document(userId)
            .collection("subscription").document("gracePeriod")
            .updateData([
                "remainingWindowGens": FieldValue.increment(Int64(-1))
            ])

        // Update local state
        remainingWindowGens -= 1
        saveToUserDefaults()

        print("🪟 Window gen recorded: \(remainingWindowGens) remaining")

        // Check if limit reached
        if remainingWindowGens <= 0 {
            await showLimitReachedPaywall(type: .windowGeneration)
        }
    }

    // MARK: - Paywall Triggers

    enum LimitType {
        case scans
        case windowGeneration
        case timeExpired
    }

    /// Show paywall when limit is reached
    func showLimitReachedPaywall(type: LimitType) async {
        // Mark that user has seen paywall (subsequent ones will be HARD)
        if !hasSeenPaywallOnce {
            hasSeenPaywallOnce = true

            // Update Firestore
            if !userId.isEmpty {
                try? await db.collection("users").document(userId)
                    .collection("subscription").document("gracePeriod")
                    .updateData(["hasSeenPaywallOnce": true])
            }

            saveToUserDefaults()
        }

        // Determine placement based on limit type
        let placement: String
        switch type {
        case .scans:
            placement = "meal_scan_limit_reached"
        case .windowGeneration:
            placement = "window_gen_limit_reached"
        case .timeExpired:
            placement = "grace_period_expired"
        }

        // Post notification to show paywall
        NotificationCenter.default.post(
            name: .showPaywall,
            object: placement
        )

        print("💳 Showing paywall: \(placement)")
    }

    // MARK: - UserDefaults Backup (for offline scenarios)

    private func saveToUserDefaults() {
        UserDefaults.standard.set(isInGracePeriod, forKey: "gracePeriod_isActive")
        UserDefaults.standard.set(remainingScans, forKey: "gracePeriod_scans")
        UserDefaults.standard.set(remainingWindowGens, forKey: "gracePeriod_gens")
        UserDefaults.standard.set(hasSeenPaywallOnce, forKey: "gracePeriod_seenPaywall")

        if let endDate = gracePeriodEndDate {
            UserDefaults.standard.set(endDate, forKey: "gracePeriod_endDate")
        }
    }

    private func loadFromUserDefaults() {
        isInGracePeriod = UserDefaults.standard.bool(forKey: "gracePeriod_isActive")
        remainingScans = UserDefaults.standard.integer(forKey: "gracePeriod_scans")
        remainingWindowGens = UserDefaults.standard.integer(forKey: "gracePeriod_gens")
        hasSeenPaywallOnce = UserDefaults.standard.bool(forKey: "gracePeriod_seenPaywall")
        gracePeriodEndDate = UserDefaults.standard.object(forKey: "gracePeriod_endDate") as? Date

        print("📱 Loaded from UserDefaults: \(remainingScans) scans, \(remainingWindowGens) gens")
    }
}

// MARK: - Error Types

enum GracePeriodError: Error, LocalizedError {
    case noUser
    case scanLimitReached
    case windowGenLimitReached
    case gracePeriodExpired

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user signed in"
        case .scanLimitReached:
            return "You've used all 4 free scans. Upgrade to continue!"
        case .windowGenLimitReached:
            return "You've used your free window generation. Upgrade to continue!"
        case .gracePeriodExpired:
            return "Your 24-hour trial has expired. Upgrade to continue!"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showPaywall = Notification.Name("showPaywall")
    static let gracePeriodExpired = Notification.Name("gracePeriodExpired")
}
