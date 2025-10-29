//
//  GracePeriodBanner.swift
//  NutriSync
//
//  Created by Claude on 2025-10-29.
//  Grace period status banner showing remaining scans and time
//

import SwiftUI

struct GracePeriodBanner: View {
    @EnvironmentObject var gracePeriodManager: GracePeriodManager

    var hoursRemaining: Int {
        guard let endDate = gracePeriodManager.gracePeriodEndDate else { return 0 }
        let remaining = endDate.timeIntervalSince(Date())
        return max(0, Int(remaining / 3600))
    }

    var body: some View {
        if gracePeriodManager.isInGracePeriod {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Info section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Trial Active")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(gracePeriodManager.remainingScans) scans • \(hoursRemaining)h remaining")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Upgrade button
                    Button {
                        NotificationCenter.default.post(
                            name: .showPaywall,
                            object: "grace_period_banner"
                        )
                    } label: {
                        Text("Upgrade")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.phylloBackground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.nutriSyncAccent.opacity(0.15),
                            Color.nutriSyncAccent.opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GracePeriodBanner()
            .environmentObject({
                let manager = GracePeriodManager.shared
                manager.isInGracePeriod = true
                manager.remainingScans = 3
                manager.gracePeriodEndDate = Date().addingTimeInterval(18 * 3600) // 18 hours
                return manager
            }())

        Spacer()
    }
    .background(Color.black)
}
