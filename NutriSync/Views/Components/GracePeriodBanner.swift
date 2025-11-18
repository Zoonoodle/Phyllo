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
    @Binding var isCollapsed: Bool

    var hoursRemaining: Int {
        guard let endDate = gracePeriodManager.gracePeriodEndDate else { return 0 }
        let remaining = endDate.timeIntervalSince(Date())
        return max(0, Int(remaining / 3600))
    }

    var body: some View {
        if gracePeriodManager.isInGracePeriod {
            VStack(spacing: 0) {
                if isCollapsed {
                    // Collapsed state - moves to top of screen including status bar area
                    VStack(spacing: 0) {
                        // Spacer for status bar area
                        Color.clear
                            .frame(height: 50) // Approximate status bar height

                        // Collapsed indicator bar
                        HStack {
                            Text("Free Trial Active")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.phylloBackground)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.phylloBackground.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(
                        // Prominent lime green background (#C0FF73)
                        Color.nutriSyncAccent
                            .ignoresSafeArea(edges: .top)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCollapsed = false
                        }
                    }
                } else {
                    // Expanded state - full banner with info (with safe area padding for Dynamic Island)
                    VStack(spacing: 0) {
                        // Spacer for status bar/Dynamic Island area
                        Color.clear
                            .frame(height: 50)

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

                            // Subscribe button
                            Button {
                                NotificationCenter.default.post(
                                    name: .showPaywall,
                                    object: "grace_period_banner"
                                )
                            } label: {
                                Text("Subscribe")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.phylloBackground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.nutriSyncAccent)
                                    .cornerRadius(8)
                            }

                            // Collapse button
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isCollapsed = true
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(8)
                            }
                        }
                        .padding(16)
                    }
                    .background(
                        ZStack {
                            // Solid black background to block content underneath
                            Color.phylloBackground

                            // Subtle accent gradient on top
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.nutriSyncAccent.opacity(0.15),
                                    Color.nutriSyncAccent.opacity(0.05)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                        .ignoresSafeArea(edges: .top)
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isCollapsed = false

    VStack {
        GracePeriodBanner(isCollapsed: $isCollapsed)
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
