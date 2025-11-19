//
//  PaywallView.swift
//  NutriSync
//
//  RevenueCat paywall with visual UI
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    let placement: String
    var onDismiss: (() -> Void)?
    var onSubscribe: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var gracePeriodManager: GracePeriodManager

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var offerings: Offerings?
    @State private var selectedPackage: Package?

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let offering = offerings?.current {
                paywallContent(offering: offering)
            } else {
                errorView
            }
        }
        .task {
            await loadOfferings()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.nutriSyncAccent)
            Text("Loading subscription options...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Unable to load subscription options")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("Please check your internet connection and try again.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await loadOfferings()
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.nutriSyncAccent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Button(action: {
                onDismiss?()
                dismiss()
            }) {
                Text("Maybe Later")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Paywall Content

    @ViewBuilder
    private func paywallContent(offering: Offering) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                paywallHeader

                // Features
                featuresSection

                // Pricing packages
                packagesSection(offering: offering)

                // Purchase button
                purchaseButton

                // Restore & Terms
                bottomLinks

                Spacer(minLength: 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            if onDismiss != nil {
                closeButton
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .padding(.top, 60)

            Text(headerTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(headerSubtitle)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 40)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(appFeatures, id: \.0) { feature in
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.nutriSyncAccent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.0)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text(feature.1)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }

    private func packagesSection(offering: Offering) -> some View {
        VStack(spacing: 12) {
            ForEach(offering.availablePackages, id: \.identifier) { package in
                PackageCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    onSelect: {
                        selectedPackage = package
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchase()
            }
        }) {
            HStack(spacing: 12) {
                if isPurchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(purchaseButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.nutriSyncAccent)
            .cornerRadius(16)
        }
        .disabled(isPurchasing || selectedPackage == nil)
        .opacity((isPurchasing || selectedPackage == nil) ? 0.5 : 1.0)
        .padding(.horizontal, 24)
    }

    private var bottomLinks: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(isPurchasing)

            HStack(spacing: 8) {
                Link("Terms", destination: URL(string: "https://nutrisync.app/terms")!)
                Text("•")
                Link("Privacy", destination: URL(string: "https://nutrisync.app/privacy")!)
            }
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 24)
    }

    private var closeButton: some View {
        Button(action: {
            onDismiss?()
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

    // MARK: - Computed Properties

    private var headerTitle: String {
        switch placement {
        case "window_gen_limit_reached":
            return "Subscribe to Continue"
        case "meal_scan_limit_reached":
            return "Subscribe for Full Access"
        case "grace_period_expired":
            return "Free Trial Ended"
        default:
            return "Subscribe for Access"
        }
    }

    private var headerSubtitle: String {
        switch placement {
        case "window_gen_limit_reached":
            return "You've reached your trial limit. Subscribe to continue with unlimited personalized meal windows."
        case "meal_scan_limit_reached":
            return "You've reached your trial limit. Subscribe to continue with unlimited AI meal analysis."
        case "grace_period_expired":
            return "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition."
        default:
            return "Continue your nutrition journey with full access to all features."
        }
    }

    private var purchaseButtonTitle: String {
        if let package = selectedPackage {
            return "Start for \(package.localizedPriceString)"
        } else {
            return "Select a Plan"
        }
    }

    private var appFeatures: [(String, String)] {
        [
            ("Unlimited AI Meal Analysis", "Scan and analyze unlimited meals with AI-powered nutrition insights"),
            ("Personalized Meal Windows", "Get daily custom meal schedules optimized for your goals"),
            ("Smart Window Adjustments", "Automatic redistribution when you miss a meal"),
            ("Advanced Analytics", "Track trends, patterns, and progress over time"),
            ("Priority Support", "Get help from our team whenever you need it")
        ]
    }

    // MARK: - Actions

    private func loadOfferings() async {
        isLoading = true

        do {
            offerings = try await subscriptionManager.fetchOfferings()

            // Auto-select the first package
            if let firstPackage = offerings?.current?.availablePackages.first {
                selectedPackage = firstPackage
            }

            isLoading = false
            print("✅ Offerings loaded successfully: \(offerings?.current?.availablePackages.count ?? 0) packages")
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                print("❌ Failed to load offerings: \(error)")
                print("   Error details: \(error.localizedDescription)")
            }
        }
    }

    private func purchase() async {
        guard let package = selectedPackage else { return }

        await MainActor.run {
            isPurchasing = true
        }

        do {
            _ = try await subscriptionManager.purchase(package: package)

            await MainActor.run {
                isPurchasing = false
                onSubscribe?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func restorePurchases() async {
        await MainActor.run {
            isPurchasing = true
        }

        do {
            let customerInfo = try await subscriptionManager.restorePurchases()

            await MainActor.run {
                isPurchasing = false

                if customerInfo.entitlements["NutriSync"]?.isActive == true {
                    errorMessage = "Purchases restored successfully!"
                    showError = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onSubscribe?()
                        dismiss()
                    }
                } else {
                    errorMessage = "No active subscription found."
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Package Card

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(packageTitle)
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

                    Text(package.localizedPriceString + periodText)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))

                    if let savings = savingsText {
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
        .buttonStyle(.plain)
    }

    private var packageTitle: String {
        switch package.packageType {
        case .annual:
            return "Annual"
        case .monthly:
            return "Monthly"
        case .weekly:
            return "Weekly"
        default:
            return package.storeProduct.localizedTitle
        }
    }

    private var periodText: String {
        switch package.packageType {
        case .annual:
            return "/year"
        case .monthly:
            return "/month"
        case .weekly:
            return "/week"
        default:
            return ""
        }
    }

    private var isBestValue: Bool {
        package.packageType == .annual
    }

    private var savingsText: String? {
        switch package.packageType {
        case .annual:
            return "Save 40% compared to monthly"
        default:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        placement: "window_gen_limit_reached",
        onDismiss: { print("Dismissed") },
        onSubscribe: { print("Subscribed") }
    )
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(GracePeriodManager.shared)
    .preferredColorScheme(.dark)
}
