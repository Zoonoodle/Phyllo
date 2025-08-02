//
//  LockedChapterView.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Shows preview content for locked chapters with progress indicators

import SwiftUI

struct LockedChapterView: View {
    let chapter: MomentumTabView.StoryChapter
    let progress: StoryChapterProgress
    @State private var pulseAnimation = false
    
    private var unlockProgress: (days: Int, meals: Int) {
        progress.progressToUnlock(chapter.chapterId)
    }
    
    private var daysProgress: Double {
        guard let req = progress.requirements[chapter.chapterId] else { return 0 }
        return min(1.0, Double(progress.totalDaysUsed) / Double(req.daysRequired))
    }
    
    private var mealsProgress: Double {
        guard let req = progress.requirements[chapter.chapterId] else { return 0 }
        return min(1.0, Double(progress.totalMealsLogged) / Double(req.mealsRequired))
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Lock Icon with Progress Ring
            ZStack {
                // Pulsing background
                Circle()
                    .fill(chapter.color.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.5)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Progress rings
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    // Days progress ring
                    Circle()
                        .trim(from: 0, to: daysProgress)
                        .stroke(chapter.color.opacity(0.5), lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    // Meals progress ring
                    Circle()
                        .trim(from: 0, to: mealsProgress)
                        .stroke(chapter.color, lineWidth: 4)
                        .frame(width: 92, height: 92)
                        .rotationEffect(.degrees(-90))
                    
                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.phylloTextTertiary)
                }
            }
            
            // Chapter Info
            VStack(spacing: 16) {
                Text(chapter.rawValue)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This chapter will unlock once you meet the requirements below")
                    .font(.system(size: 16))
                    .foregroundColor(.phylloTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Unlock Requirements
            VStack(spacing: 16) {
                UnlockRequirementRow(
                    icon: "calendar",
                    label: "Days Required",
                    current: progress.totalDaysUsed,
                    required: progress.requirements[chapter.chapterId]?.daysRequired ?? 0,
                    remaining: unlockProgress.days
                )
                
                UnlockRequirementRow(
                    icon: "fork.knife",
                    label: "Meals Required",
                    current: progress.totalMealsLogged,
                    required: progress.requirements[chapter.chapterId]?.mealsRequired ?? 0,
                    remaining: unlockProgress.meals
                )
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            
            // Sneak Peek
            SneakPeekCard(chapter: chapter)
        }
        .padding(.horizontal)
        .onAppear {
            pulseAnimation = true
        }
    }
}

struct UnlockRequirementRow: View {
    let icon: String
    let label: String
    let current: Int
    let required: Int
    let remaining: Int
    
    private var progress: Double {
        guard required > 0 else { return 0 }
        return min(1.0, Double(current) / Double(required))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.phylloTextSecondary)
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                Spacer()
                
                Text("\(current)/\(required)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            if remaining > 0 {
                let singularLabel = label.lowercased()
                    .replacingOccurrences(of: "required", with: "")
                    .trimmingCharacters(in: .whitespaces)
                let pluralLabel = singularLabel
                let labelText = remaining == 1 ? String(singularLabel.dropLast()) : singularLabel
                
                Text("\(remaining) \(labelText) remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
            } else {
                Text("Requirement met!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.phylloAccent)
            }
        }
    }
}

struct SneakPeekCard: View {
    let chapter: MomentumTabView.StoryChapter
    
    private var previewContent: (title: String, items: [String]) {
        switch chapter {
        case .yourPlan:
            return ("", []) // Never locked
            
        case .firstWeek:
            return (
                "Your Energy Transformation",
                [
                    "See your actual energy patterns vs predictions",
                    "Discover which meal windows work best for you",
                    "Get personalized timing adjustments",
                    "View your metabolic efficiency score"
                ]
            )
            
        case .patterns:
            return (
                "Deep Pattern Analysis",
                [
                    "AI-discovered correlations in your data",
                    "Foods that boost vs drain your energy",
                    "Your optimal macro distribution",
                    "Personalized supplement recommendations"
                ]
            )
            
        case .peakState:
            return (
                "Your Optimized Protocol",
                [
                    "Your complete nutrition blueprint",
                    "Advanced bio-hacking strategies",
                    "Long-term sustainability plan",
                    "Next-level performance protocols"
                ]
            )
        }
    }
    
    var body: some View {
        if !previewContent.items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Label("Preview", systemImage: "eye.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(previewContent.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(previewContent.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(chapter.color.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .offset(y: 6)
                            
                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(.phylloTextSecondary)
                                .blur(radius: 1)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [chapter.color.opacity(0.15), chapter.color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Lock overlay
                    Color.black.opacity(0.3)
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(chapter.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    LockedChapterView(
        chapter: .firstWeek,
        progress: StoryChapterProgress()
    )
    .padding()
    .background(Color.phylloBackground)
    .preferredColorScheme(.dark)
}