//
//  MockPaywallView.swift
//  NutriSync
//
//  Created for taking screenshots of paywall design
//  DELETE THIS FILE after taking screenshots
//

import SwiftUI

struct MockPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                            .padding(.top, 60)

                        Text("Subscribe for Access")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Continue your nutrition journey with full access to all features.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            title: "Unlimited AI Meal Analysis",
                            subtitle: "Scan and analyze unlimited meals with AI-powered nutrition insights"
                        )

                        FeatureRow(
                            title: "Personalized Meal Windows",
                            subtitle: "Get daily custom meal schedules optimized for your goals"
                        )

                        FeatureRow(
                            title: "Smart Window Adjustments",
                            subtitle: "Automatic redistribution when you miss a meal"
                        )

                        FeatureRow(
                            title: "Advanced Analytics",
                            subtitle: "Track trends, patterns, and progress over time"
                        )

                        FeatureRow(
                            title: "Priority Support",
                            subtitle: "Get help from our team whenever you need it"
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                    // Pricing packages
                    VStack(spacing: 12) {
                        MockPackageCard(
                            title: "Monthly",
                            price: "$6.00",
                            period: "/month",
                            isSelected: true,
                            isBestValue: false
                        )

                        MockPackageCard(
                            title: "Monthly",
                            price: "$8.00",
                            period: "/month",
                            isSelected: false,
                            isBestValue: false
                        )

                        MockPackageCard(
                            title: "Annual",
                            price: "$72.00",
                            period: "/year",
                            isSelected: false,
                            isBestValue: true,
                            savings: "Save 33% compared to monthly"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Purchase button
                    Button(action: {}) {
                        Text("Start for $6.00")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    // Bottom links
                    VStack(spacing: 16) {
                        Button(action: {}) {
                            Text("Restore Purchases")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        HStack(spacing: 8) {
                            Text("Terms")
                            Text("•")
                            Text("Privacy")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 24)

                    Spacer(minLength: 40)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
        }
    }
}

struct FeatureRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.nutriSyncAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }
}

struct MockPackageCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let isBestValue: Bool
    var savings: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if isBestValue {
                        Text("BEST VALUE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(4)
                    }
                }

                Text(price + period)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))

                if let savings = savings {
                    Text(savings)
                        .font(.system(size: 13))
                        .foregroundColor(.nutriSyncAccent)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.3))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color.nutriSyncAccent : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MockPaywallView()
        .preferredColorScheme(.dark)
}
