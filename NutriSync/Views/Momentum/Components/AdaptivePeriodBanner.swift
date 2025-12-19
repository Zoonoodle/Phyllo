//
//  AdaptivePeriodBanner.swift
//  NutriSync
//
//  Explains the adaptive time period selection to users
//

import SwiftUI

// MARK: - Time Period Enum

enum TimePeriod: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"

    var dayCount: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        }
    }

    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        }
    }

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}

// MARK: - Adaptive Period Banner

struct AdaptivePeriodBanner: View {
    let period: TimePeriod
    let daysActive: Int
    let onPeriodChange: ((TimePeriod) -> Void)?

    @State private var showingPeriodPicker = false

    private var canSwitchToMonthly: Bool {
        daysActive >= 14
    }

    private var reason: String {
        switch period {
        case .weekly:
            if daysActive < 14 {
                return "Building your baseline (\(daysActive)/14 days)"
            } else {
                return "Viewing weekly trends"
            }
        case .monthly:
            return "Tracking monthly progress"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: period.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .frame(width: 32, height: 32)
                .background(Color.nutriSyncAccent.opacity(0.15))
                .cornerRadius(8)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(period == .weekly ? "Weekly View" : "Monthly View")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(reason)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Period switcher (if eligible for monthly)
            if canSwitchToMonthly {
                Button(action: { showingPeriodPicker.toggle() }) {
                    HStack(spacing: 4) {
                        Text(period.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.nutriSyncAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nutriSyncAccent.opacity(0.15))
                    .cornerRadius(8)
                }
                .confirmationDialog("Select Time Period", isPresented: $showingPeriodPicker) {
                    Button("Weekly (7 days)") {
                        onPeriodChange?(.weekly)
                    }
                    Button("Monthly (30 days)") {
                        onPeriodChange?(.monthly)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        // New user - can't switch yet
        AdaptivePeriodBanner(
            period: .weekly,
            daysActive: 5,
            onPeriodChange: nil
        )

        // Established user - weekly view
        AdaptivePeriodBanner(
            period: .weekly,
            daysActive: 21,
            onPeriodChange: { _ in }
        )

        // Established user - monthly view
        AdaptivePeriodBanner(
            period: .monthly,
            daysActive: 45,
            onPeriodChange: { _ in }
        )
    }
    .padding()
    .background(Color.nutriSyncBackground)
}
