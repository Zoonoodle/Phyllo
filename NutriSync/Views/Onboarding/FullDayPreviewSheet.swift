//
//  FullDayPreviewSheet.swift
//  NutriSync
//
//  Shows a read-only preview of what a typical day looks like
//  Displayed when users complete onboarding late in the day
//

import SwiftUI

struct FullDayPreviewSheet: View {
    let profile: UserProfile
    let onDismiss: () -> Void

    @State private var sampleWindows: [MealWindow] = []
    @State private var sampleMeals: [LoggedMeal] = []
    @State private var isVisible = false

    // Animation states
    @State private var headerAppeared = false
    @State private var timelineAppeared = false
    @State private var messageAppeared = false
    @State private var buttonAppeared = false

    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -20)

                // Timeline preview
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        previewTimeline
                            .opacity(timelineAppeared ? 1 : 0)
                            .scaleEffect(timelineAppeared ? 1 : 0.95)

                        Spacer(minLength: 120)
                    }
                }

                // Bottom message and CTA
                bottomSection
                    .opacity(messageAppeared ? 1 : 0)
                    .offset(y: messageAppeared ? 0 : 20)
            }
        }
        .onAppear {
            generateSampleData()
            animateIn()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR TYPICAL DAY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)

                    Text("Tomorrow's Preview")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Moon icon to indicate it's late
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.nutriSyncAccent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
        .background(Color.nutriSyncBackground)
    }

    // MARK: - Preview Timeline

    private var previewTimeline: some View {
        VStack(spacing: 0) {
            ForEach(sampleWindows) { window in
                PreviewWindowRow(
                    window: window,
                    meals: sampleMeals.filter { $0.windowId?.uuidString == window.id }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            VStack(spacing: 12) {
                Text("Since it's late, your plan starts tomorrow")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text("We'll remind you to check in when you wake up, and your personalized windows will be ready.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)

            // CTA Button
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Text("Got it, see you tomorrow")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 10)
        }
        .background(
            Color.nutriSyncBackground
                .shadow(color: .black.opacity(0.3), radius: 20, y: -10)
        )
    }

    // MARK: - Helpers

    private func generateSampleData() {
        // Use tomorrow's date for the preview
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        sampleWindows = SampleDataGenerator.shared.generateSampleWindows(for: profile, on: tomorrow)
        sampleMeals = SampleDataGenerator.shared.generateSampleMeals(for: sampleWindows, profile: profile)
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) {
            headerAppeared = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
            timelineAppeared = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            messageAppeared = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            buttonAppeared = true
        }
    }
}

// MARK: - Preview Window Row

private struct PreviewWindowRow: View {
    let window: MealWindow
    let meals: [LoggedMeal]

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.nutriSyncAccent)
                    .frame(width: 8, height: 8)

                Text(timeFormatter.string(from: window.startTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }
            .padding(.leading, 4)

            // Window card
            VStack(alignment: .leading, spacing: 12) {
                // Window header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(window.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text(window.purpose.legacyDisplayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                    }

                    Spacer()

                    // Calorie target
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(window.targetCalories)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("cal")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Macro targets
                HStack(spacing: 16) {
                    macroIndicator(value: window.targetProtein, label: "P", color: .blue)
                    macroIndicator(value: window.targetCarbs, label: "C", color: .orange)
                    macroIndicator(value: window.targetFat, label: "F", color: .purple)
                }

                // Sample meals (if any)
                if !meals.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXAMPLE MEALS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(0.5)

                        ForEach(meals) { meal in
                            sampleMealRow(meal)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .padding(.leading, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func macroIndicator(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 6, height: 6)

            Text("\(value)g")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private func sampleMealRow(_ meal: LoggedMeal) -> some View {
        HStack {
            Image(systemName: "fork.knife")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 20)

            Text(meal.name)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text("\(meal.calories) cal")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
        )
    }
}

// MARK: - Preview

#Preview {
    FullDayPreviewSheet(
        profile: UserProfile.defaultProfile
    ) {
        print("Dismissed")
    }
}
