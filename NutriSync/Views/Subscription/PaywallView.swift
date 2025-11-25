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

            // Only show "Maybe Later" if dismissable (onDismiss is not nil)
            if onDismiss != nil {
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
    }

    // MARK: - Paywall Content

    @ViewBuilder
    private func paywallContent(offering: Offering) -> some View {
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

            Spacer(minLength: 20)
        }
        .overlay(alignment: .topTrailing) {
            if onDismiss != nil {
                closeButton
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .padding(.top, 50)

            Text(headerTitle)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(headerSubtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 24)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(appFeatures, id: \.0) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.nutriSyncAccent)

                    Text(feature.0)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 20)
    }

    private func packagesSection(offering: Offering) -> some View {
        VStack(spacing: 12) {
            ForEach(filteredPackages(from: offering), id: \.identifier) { package in
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
        .padding(.bottom, 20)
    }

    // Filter to only show monthly and annual packages
    private func filteredPackages(from offering: Offering) -> [Package] {
        offering.availablePackages.filter { package in
            package.packageType == .monthly || package.packageType == .annual
        }
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
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(isPurchasing)

            HStack(spacing: 8) {
                Link("Terms", destination: URL(string: "https://nutrisync.app/terms")!)
                Text("•")
                Link("Privacy", destination: URL(string: "https://nutrisync.app/privacy")!)
            }
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 16)
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
        case "trial_welcome":
            return "Welcome to Your 24-Hour Trial! 🎉"
        case "window_gen_limit_reached":
            return "Subscribe to Continue"
        case "meal_scan_limit_reached":
            return "Subscribe for Full Access"
        case "grace_period_expired":
            return "Free Trial Ended"
        default:
            // For soft paywall - show trial ending soon
            if subscriptionManager.isInTrial, let expirationDate = subscriptionManager.expirationDate {
                let calendar = Calendar.current
                let now = Date()

                if calendar.isDateInToday(expirationDate) {
                    return "Free Trial Ends Today"
                } else if calendar.isDateInTomorrow(expirationDate) {
                    return "Free Trial Ends Tomorrow"
                } else {
                    let days = calendar.dateComponents([.day], from: now, to: expirationDate).day ?? 0
                    if days > 0 {
                        return "Free Trial Ends in \(days) Days"
                    }
                }
            }
            return "Subscribe for Access"
        }
    }

    private var headerSubtitle: String {
        switch placement {
        case "trial_welcome":
            return "You have 4 free meal scans to experience AI-powered nutrition tracking. Subscribe anytime for unlimited access and personalized meal windows."
        case "window_gen_limit_reached":
            return "You've reached your trial limit. Subscribe to continue with unlimited personalized meal windows."
        case "meal_scan_limit_reached":
            return "You've reached your trial limit. Subscribe to continue with unlimited AI meal analysis."
        case "grace_period_expired":
            return "Your 24-hour trial has ended. Subscribe to continue optimizing your nutrition."
        default:
            // For soft paywall - explain trial and encourage subscription
            return "Subscribe now to unlock unlimited access and continue your nutrition journey."
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
            ("Unlimited AI Meal Analysis", ""),
            ("Personalized Meal Windows", ""),
            ("Smart Window Adjustments", ""),
            ("Advanced Analytics", ""),
            ("Priority Support", "")
        ]
    }

    // MARK: - Actions

    private func loadOfferings() async {
        isLoading = true

        do {
            offerings = try await subscriptionManager.fetchOfferings()

            // Auto-select the first monthly or annual package
            if let offering = offerings?.current {
                let filtered = filteredPackages(from: offering)
                selectedPackage = filtered.first
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
