//
//  YourPlanChapter.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  The science-first chapter showing new users their personalized nutrition plan

import SwiftUI

struct YourPlanChapter: View {
    @Binding var animateContent: Bool
    let scoreBreakdown: InsightsEngine.ScoreBreakdown?
    let micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @State private var selectedPhase = 0
    @State private var expandedProtocol: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Personalized Nutrition Science")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.phylloAccent)
                        Text("Muscle Building") // TODO: Get from actual user profile
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Here's the exact science we'll apply to transform your nutrition over the next 30 days.")
                        .font(.system(size: 16))
                        .foregroundColor(.phylloTextSecondary)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Research Foundation
            VStack(spacing: 16) {
                SectionHeader(title: "The Research Foundation", icon: "brain")
                
                // Circadian Protocol
                ScienceProtocolCard(
                    title: "Your Circadian Nutrition Protocol",
                    icon: "moon.circle.fill",
                    color: .purple,
                    science: "Your body has evolved to process nutrients differently throughout the day. By aligning meals with your natural rhythms, we optimize hormone production and energy.",
                    implementation: [
                        "Morning protein window (7-9 AM): Cortisol peak",
                        "Complex carb window (12-1 PM): Insulin sensitivity",
                        "Recovery window (3-4 PM): Glycogen replenishment",
                        "Anabolic window (6-7 PM): Growth hormone prep"
                    ],
                    expectedResult: "34% improved energy stability",
                    isExpanded: expandedProtocol == "circadian",
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedProtocol = expandedProtocol == "circadian" ? nil : "circadian"
                        }
                    }
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
                
                // Metabolic Efficiency
                ScienceProtocolCard(
                    title: "Metabolic Efficiency Timing",
                    icon: "bolt.circle.fill",
                    color: .orange,
                    science: "Consistent meal timing trains your metabolism to anticipate and efficiently process nutrients, reducing energy crashes and improving nutrient partitioning.",
                    implementation: [
                        "5 meals at consistent times daily",
                        "3-4 hour intervals for stable blood sugar",
                        "No meals 3 hours before sleep",
                        "16-hour overnight fast for cellular repair"
                    ],
                    expectedResult: "67% reduction in energy crashes",
                    isExpanded: expandedProtocol == "metabolic",
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedProtocol = expandedProtocol == "metabolic" ? nil : "metabolic"
                        }
                    }
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.35), value: animateContent)
                
                // Goal-specific protocol (muscle building)
                if true { // TODO: Get from actual user profile
                    ScienceProtocolCard(
                        title: "Progressive Caloric Surplus",
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        color: .blue,
                        science: "Gradual calorie increases allow your metabolism to adapt without storing excess fat, promoting lean muscle gain through improved nutrient partitioning.",
                        implementation: [
                            "Week 1: 2,600 calories (maintenance + 200)",
                            "Week 2: 2,700 calories (maintenance + 300)",
                            "Week 3: 2,800 calories (maintenance + 400)",
                            "Week 4: 2,900 calories (optimal surplus)"
                        ],
                        expectedResult: "0.5-1 lb/week lean gain",
                        isExpanded: expandedProtocol == "surplus",
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                expandedProtocol = expandedProtocol == "surplus" ? nil : "surplus"
                            }
                        }
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
                }
            }
            
            // 30-Day Transformation Map
            TransformationMapView(selectedPhase: $selectedPhase)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.95)
                .animation(.spring(response: 0.8).delay(0.45), value: animateContent)
            
            // Today's Mission
            TodaysMissionCard()
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.spring(response: 0.8).delay(0.5), value: animateContent)
            
            // Today's Starting Point
            VStack(spacing: 16) {
                SectionHeader(title: "Today's Starting Point", icon: "gauge")
                
                HStack(spacing: 16) {
                    // PhylloScore
                    if let score = scoreBreakdown {
                        VStack(spacing: 12) {
                            PhylloScoreMini(score: score.totalScore, trend: score.trend)
                                .opacity(animateContent ? 1 : 0)
                                .scaleEffect(animateContent ? 1 : 0.9)
                                .animation(.spring(response: 0.8).delay(0.55), value: animateContent)
                            
                            Text("Your baseline score")
                                .font(.system(size: 12))
                                .foregroundColor(.phylloTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.6), value: animateContent)
                
                // Micronutrient Status
                if let microStatus = micronutrientStatus {
                    MicronutrientHighlights(status: microStatus)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(response: 0.8).delay(0.65), value: animateContent)
                }
            }
        }
    }
}

// MARK: - Science Protocol Card

struct ScienceProtocolCard: View {
    let title: String
    let icon: String
    let color: Color
    let science: String
    let implementation: [String]
    let expectedResult: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Tap to expand")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.phylloTextTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // The Science
                    VStack(alignment: .leading, spacing: 8) {
                        Label("The Science", systemImage: "flask.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(color)
                        
                        Text(science)
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Your Implementation
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Implementation", systemImage: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(color)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(implementation, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 6, height: 6)
                                        .offset(y: 6)
                                    
                                    Text(item)
                                        .font(.system(size: 14))
                                        .foregroundColor(.phylloTextSecondary)
                                }
                            }
                        }
                    }
                    
                    // Expected Result
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14))
                            .foregroundColor(color)
                        
                        Text("Expected Result: ")
                            .font(.system(size: 14))
                            .foregroundColor(.phylloTextSecondary)
                        
                        Text(expectedResult)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isExpanded ? color.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Transformation Map

struct TransformationMapView: View {
    @Binding var selectedPhase: Int
    
    let phases = [
        TransformationPhase(
            id: 0,
            name: "Metabolic Adaptation",
            days: "Days 1-7",
            description: "Your body learns new meal timing patterns",
            keyChanges: ["Hunger hormones reset", "Circadian rhythm aligns", "Energy stabilizes"]
        ),
        TransformationPhase(
            id: 1,
            name: "Energy Stabilization",
            days: "Days 8-14",
            description: "Consistent energy throughout the day",
            keyChanges: ["No more crashes", "Better sleep quality", "Improved focus"]
        ),
        TransformationPhase(
            id: 2,
            name: "Growth Acceleration",
            days: "Days 15-21",
            description: "Optimized nutrient partitioning begins",
            keyChanges: ["Strength increases", "Recovery improves", "Muscle synthesis peaks"]
        ),
        TransformationPhase(
            id: 3,
            name: "Peak Optimization",
            days: "Days 22-30",
            description: "Full metabolic efficiency achieved",
            keyChanges: ["Peak performance", "Sustained progress", "Habits locked in"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Your 30-Day Transformation Map", systemImage: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Phase Timeline
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Timeline track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                    
                    // Progress indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(selectedPhase + 1) / 4, height: 8)
                    
                    // Phase markers
                    HStack(spacing: 0) {
                        ForEach(phases) { phase in
                            PhaseMarker(
                                phase: phase,
                                isSelected: selectedPhase == phase.id,
                                onTap: { selectedPhase = phase.id }
                            )
                            .frame(width: geometry.size.width / 4)
                        }
                    }
                }
            }
            .frame(height: 40)
            
            // Selected Phase Details
            if let phase = phases.first(where: { $0.id == selectedPhase }) {
                PhaseDetailCard(phase: phase)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.15), Color.phylloAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TransformationPhase: Identifiable {
    let id: Int
    let name: String
    let days: String
    let description: String
    let keyChanges: [String]
}

struct PhaseMarker: View {
    let phase: TransformationPhase
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(isSelected ? Color.phylloAccent : Color.white.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(phase.id + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .black : .white)
                )
                .scaleEffect(isSelected ? 1.2 : 1.0)
            
            Text(phase.days)
                .font(.system(size: 10))
                .foregroundColor(isSelected ? .white : .phylloTextTertiary)
        }
        .offset(y: -16)
        .onTapGesture(perform: onTap)
    }
}

struct PhaseDetailCard: View {
    let phase: TransformationPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(phase.id + 1)")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    Text(phase.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(phase.days)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.phylloAccent)
            }
            
            Text(phase.description)
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(phase.keyChanges, id: \.self) { change in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloAccent)
                        
                        Text(change)
                            .font(.system(size: 13))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Today's Mission

struct TodaysMissionCard: View {
    @State private var checkedSteps = Set<Int>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Mission", systemImage: "flag.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Start your scientific transformation:")
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
            
            VStack(spacing: 12) {
                MissionStep(
                    stepNumber: 1,
                    title: "Morning Check-in",
                    description: "Establishes your circadian baseline",
                    isChecked: checkedSteps.contains(1),
                    onTap: { toggleStep(1) }
                )
                
                MissionStep(
                    stepNumber: 2,
                    title: "Log First Meal",
                    description: "Begins metabolic tracking",
                    isChecked: checkedSteps.contains(2),
                    onTap: { toggleStep(2) }
                )
                
                MissionStep(
                    stepNumber: 3,
                    title: "Hit Your Windows",
                    description: "Activates timing protocols",
                    isChecked: checkedSteps.contains(3),
                    onTap: { toggleStep(3) }
                )
            }
            
            HStack {
                Image(systemName: "flask.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.phylloAccent)
                
                Text("Your data starts building your success story today.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.phylloAccent)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func toggleStep(_ step: Int) {
        withAnimation(.spring(response: 0.3)) {
            if checkedSteps.contains(step) {
                checkedSteps.remove(step)
            } else {
                checkedSteps.insert(step)
            }
        }
    }
}

struct MissionStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    let isChecked: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isChecked ? Color.phylloAccent : Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.phylloAccent)
                } else {
                    Text("\(stepNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isChecked ? .phylloAccent : .white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Section Header Component

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.phylloAccent)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var animateContent = true
    YourPlanChapter(
        animateContent: $animateContent,
        scoreBreakdown: InsightsEngine.ScoreBreakdown(
            totalScore: 42,
            mealTimingScore: 10,
            macroBalanceScore: 12,
            micronutrientScore: 8,
            consistencyScore: 12,
            trend: .stable
        ),
        micronutrientStatus: InsightsEngine.MicronutrientStatus(
            nutrients: [],
            topDeficiencies: [
                InsightsEngine.MicronutrientStatus.NutrientStatus(
                    nutrient: MicronutrientData(name: "Vitamin D", unit: "mcg", rda: 20.0),
                    consumed: 5.0,
                    percentageOfRDA: 25.0,
                    status: .deficient
                )
            ],
            wellSupplied: []
        )
    )
    .padding()
    .background(Color.phylloBackground)
    .preferredColorScheme(.dark)
}