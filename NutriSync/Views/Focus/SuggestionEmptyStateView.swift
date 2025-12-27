//
//  SuggestionEmptyStateView.swift
//  NutriSync
//
//  Empty state views for different suggestion states
//

import SwiftUI

struct SuggestionEmptyStateView: View {
    let status: SuggestionStatus
    let onRetry: (() -> Void)?

    init(status: SuggestionStatus, onRetry: (() -> Void)? = nil) {
        self.status = status
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 12) {
            switch status {
            case .pending:
                pendingState
            case .generating:
                generatingState
            case .ready:
                EmptyView() // Should never show - suggestions are available
            case .failed:
                failedState
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Pending State

    private var pendingState: some View {
        VStack(spacing: 8) {
            Text("⏳")
                .font(.system(size: 32))

            Text("Suggestions appear 15 minutes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("before this window starts")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 4) {
                Text("They'll be personalized based on what")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))

                Text("you eat in earlier windows.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 8)

            Text("The more you log, the smarter")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            Text("your suggestions become!")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Generating State

    private var generatingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .nutriSyncAccent))
                .scaleEffect(1.2)

            Text("Preparing your suggestions...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Failed State

    private var failedState: some View {
        VStack(spacing: 12) {
            Text("⚠️")
                .font(.system(size: 32))

            Text("Couldn't generate suggestions")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nutriSyncBackground)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.nutriSyncAccent)
                        )
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Context Note View

struct SuggestionContextNoteView: View {
    let contextNote: String
    let isFirstWindow: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isFirstWindow {
                Text("☀️")
                    .font(.system(size: 16))
            }

            Text(contextNote)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .italic()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview("Pending") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        SuggestionEmptyStateView(status: .pending)
    }
}

#Preview("Generating") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        SuggestionEmptyStateView(status: .generating)
    }
}

#Preview("Failed") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        SuggestionEmptyStateView(status: .failed, onRetry: {})
    }
}
